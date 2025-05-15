"""Product endpoints for API v1."""
import os
import uuid
import pandas as pd
from flask import request, current_app, jsonify, send_file
from flask_restx import Namespace, Resource, fields
from werkzeug.utils import secure_filename
from ...models.product import Product
from ...extensions import db
from .utils import (
    token_required,
    validate_schema,
    get_pagination_params,
    paginate,
    allowed_file
)
from ...services.import_service import import_products, generate_import_template
from .schemas import ProductSchema, ProductListSchema
from . import limiter

ns = Namespace("products", description="Product operations")

# API models for Swagger docs
product_model = ns.model("Product", {
    "sku": fields.String(required=True, description="Stock Keeping Unit"),
    "name": fields.String(required=True, description="Product name"),
    "description_html": fields.String(description="HTML description"),
    "barcode": fields.String(description="Product barcode"),
    "quantity": fields.Integer(description="Stock quantity", default=0),
    "delivery_days": fields.Integer(description="Delivery time in days"),
    "price_final": fields.String(required=True, description="Final price"),
    "price_old": fields.String(description="Old price (for discounts)"),
    "category": fields.String(description="Product category"),
    "main_image_url": fields.String(description="Main product image URL"),
    "manufacturer": fields.String(description="Product manufacturer"),
    "model": fields.String(description="Product model"),
})

file_upload_model = ns.model("FileUpload", {
    "file": fields.Raw(required=True, description="CSV or Excel file")
})

@ns.route("/")
class ProductList(Resource):
    """Product collection resource."""
    
    @ns.doc("list_products")
    @ns.response(200, "Success")
    @token_required()
    @limiter.limit("200/minute")
    def get(self, current_user):
        """List all products."""
        page, per_page = get_pagination_params()
        
        # Handle filtering
        query = Product.query
        
        # Filter by category if provided
        category = request.args.get("category")
        if category:
            query = query.filter(Product.category == category)
        
        # Filter by search term if provided
        search = request.args.get("search")
        if search:
            search_term = f"%{search}%"
            query = query.filter(
                (Product.name.ilike(search_term)) | 
                (Product.sku.ilike(search_term)) |
                (Product.description_html.ilike(search_term))
            )
            
        # Sort by field if provided
        sort_by = request.args.get("sort_by", "id")
        sort_dir = request.args.get("sort_dir", "asc")
        
        if hasattr(Product, sort_by):
            sort_col = getattr(Product, sort_by)
            query = query.order_by(sort_col.desc() if sort_dir == "desc" else sort_col.asc())
        else:
            query = query.order_by(Product.id.asc())
        
        # Return paginated results
        result = paginate(query, ProductSchema, page, per_page)
        return result
    
    @ns.doc("create_product")
    @ns.expect(product_model)
    @ns.response(201, "Product created")
    @ns.response(400, "Validation error")
    @token_required()
    @validate_schema(ProductSchema)
    def post(self, current_user, data):
        """Create a new product."""
        # Check if product with same SKU already exists
        existing = Product.query.filter_by(sku=data["sku"]).first()
        if existing:
            return {"message": f"Product with SKU '{data['sku']}' already exists"}, 400
        
        # Create new product
        product = Product(**data)
        
        db.session.add(product)
        db.session.commit()
        
        schema = ProductSchema()
        return schema.dump(product), 201

@ns.route("/<string:sku>")
@ns.param("sku", "The product SKU")
class ProductResource(Resource):
    """Product resource."""
    
    @ns.doc("get_product")
    @ns.response(200, "Success")
    @ns.response(404, "Product not found")
    @token_required()
    def get(self, sku, current_user):
        """Get a product by SKU."""
        product = Product.query.filter_by(sku=sku).first_or_404()
        
        schema = ProductSchema()
        return schema.dump(product)
    
    @ns.doc("update_product")
    @ns.expect(product_model)
    @ns.response(200, "Product updated")
    @ns.response(400, "Validation error")
    @ns.response(404, "Product not found")
    @token_required()
    @validate_schema(ProductSchema)
    def put(self, sku, current_user, data):
        """Update a product by SKU."""
        product = Product.query.filter_by(sku=sku).first_or_404()
        
        # If SKU is being changed, check if new SKU is available
        if "sku" in data and data["sku"] != sku:
            existing = Product.query.filter_by(sku=data["sku"]).first()
            if existing:
                return {"message": f"Product with SKU '{data['sku']}' already exists"}, 400
        
        # Update product fields
        for key, value in data.items():
            setattr(product, key, value)
        
        db.session.commit()
        
        schema = ProductSchema()
        return schema.dump(product)
    
    @ns.doc("delete_product")
    @ns.response(204, "Product deleted")
    @ns.response(404, "Product not found")
    @token_required()
    def delete(self, sku, current_user):
        """Delete a product by SKU."""
        product = Product.query.filter_by(sku=sku).first_or_404()
        
        db.session.delete(product)
        db.session.commit()
        
        return "", 204

@ns.route("/import")
class ProductImport(Resource):
    """Product import resource."""
    
    @ns.doc("import_products")
    @ns.response(200, "Import successful")
    @ns.response(400, "Bad request")
    @token_required()
    def post(self, current_user):
        """Import products from CSV or Excel file."""
        # Check if file was uploaded
        if "file" not in request.files:
            return {"message": "No file part"}, 400
            
        file = request.files["file"]
        
        # Check if filename is empty
        if file.filename == "":
            return {"message": "No selected file"}, 400
            
        # Check if file is allowed
        if not allowed_file(file.filename, {"csv", "xlsx", "xls", "tsv", "txt"}):
            return {"message": "File type not allowed. Use CSV, TSV, XLSX, or XLS"}, 400
            
        try:
            # Get import parameters
            reference_id = request.form.get("reference_id", f"API-{uuid.uuid4()}")
            channel = request.form.get("channel", "api")
            encoding = request.form.get("encoding")
            delimiter = request.form.get("delimiter", ",")
            has_header = request.form.get("has_header", "true").lower() in ("true", "1", "yes")
            
            # Import products using the improved import service
            summary = import_products(
                file,
                channel=channel,
                reference_id=reference_id,
                user_id=current_user.id,
                encoding=encoding,
                delimiter=delimiter,
                has_header=has_header
            )
            
            # Prepare response
            response = {
                "message": "Import completed",
                "summary": {
                    "created": summary.get("created", 0),
                    "updated": summary.get("updated", 0),
                    "skipped": summary.get("skipped", 0),
                    "errors": summary.get("errors", 0),
                    "total": summary.get("total_rows", 0),
                    "timestamp": summary.get("timestamp")
                }
            }
            
            # Include error details if present and requested
            include_errors = request.form.get("include_errors", "false").lower() in ("true", "1", "yes")
            if include_errors and summary.get("errors", 0) > 0 and summary.get("error_details"):
                # Limit number of errors returned to avoid excessive response sizes
                error_limit = min(int(request.form.get("error_limit", "100")), 1000)
                response["errors"] = summary.get("error_details", [])[:error_limit]
                
                if len(summary.get("error_details", [])) > error_limit:
                    response["errors_truncated"] = True
                    response["total_errors"] = len(summary.get("error_details", []))
            
            return response
            
        except Exception as e:
            return {"message": f"Error processing file: {str(e)}"}, 400
            
    @ns.doc("get_import_template")
    @ns.response(200, "Template file")
    @token_required()
    def get(self, current_user):
        """Get product import template file."""
        format_type = request.args.get("format", "xlsx")
        if format_type not in ("csv", "xlsx"):
            return {"message": "Invalid format type. Use 'csv' or 'xlsx'"}, 400
            
        try:
            template = generate_import_template(format=format_type)
            mime_type = "text/csv" if format_type == "csv" else "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            filename = f"product_import_template.{format_type}"
            
            return send_file(
                template,
                mimetype=mime_type,
                as_attachment=True,
                download_name=filename
            )
        except Exception as e:
            return {"message": f"Error generating template: {str(e)}"}, 500 