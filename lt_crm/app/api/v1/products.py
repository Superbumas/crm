"""Product endpoints for API v1."""
import os
import uuid
import pandas as pd
from flask import request, current_app, jsonify, send_file
from flask_restx import Namespace, Resource, fields
from werkzeug.utils import secure_filename
from app.models.product import Product
from app.extensions import db
from app.api.v1.utils import (
    token_required,
    validate_schema,
    get_pagination_params,
    paginate,
    allowed_file
)
from app.services.import_service import import_products, generate_import_template
from app.api.v1.schemas import ProductSchema, ProductListSchema
from app.api.v1 import limiter

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
        if not allowed_file(file.filename, {"csv", "xlsx", "xls"}):
            return {"message": "File type not allowed. Use CSV or XLSX"}, 400
            
        try:
            # Import products using the import service
            reference_id = request.form.get("reference_id", f"API-{uuid.uuid4()}")
            channel = request.form.get("channel", "api")
            
            summary = import_products(
                file,
                channel=channel,
                reference_id=reference_id,
                user_id=current_user.id
            )
            
            return {
                "message": "Import completed",
                "summary": summary
            }
            
        except Exception as e:
            return {"message": f"Error processing file: {str(e)}"}, 400

@ns.route("/import/template")
class ProductImportTemplate(Resource):
    """Product import template resource."""
    
    @ns.doc("get_import_template")
    @ns.response(200, "Template file")
    @token_required()
    def get(self, current_user):
        """Get a template for product import."""
        format = request.args.get("format", "xlsx")
        if format not in ["csv", "xlsx"]:
            return {"message": "Invalid format. Use 'csv' or 'xlsx'"}, 400
            
        template = generate_import_template(format=format)
        
        filename = f"product_import_template.{format}"
        mimetype = "text/csv" if format == "csv" else "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        
        return send_file(
            template,
            mimetype=mimetype,
            as_attachment=True,
            download_name=filename
        ) 