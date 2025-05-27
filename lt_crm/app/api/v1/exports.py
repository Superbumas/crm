"""Export endpoints for API v1."""
import io
import json
from datetime import datetime
from flask import request, send_file, current_app
from flask_restx import Namespace, Resource, fields
from marshmallow import Schema, fields as ma_fields, validate, ValidationError
from ...models.export import ExportConfig, ExportFormat
from ...models.product import Product
from ...extensions import db
from ...services.export_service import ExportService
from .utils import token_required, validate_schema
from . import limiter

ns = Namespace("exports", description="Export operations")

@ns.route("/health")
class ExportHealth(Resource):
    """Health check for exports API."""
    
    @ns.doc("export_health_check")
    @ns.response(200, "Health check successful")
    def get(self):
        """Simple health check endpoint that doesn't require authentication."""
        return {
            "status": "ok",
            "service": "exports",
            "timestamp": datetime.now().isoformat()
        }

@ns.route("/test")
class ExportTest(Resource):
    """Test endpoint for debugging exports API."""
    
    @ns.doc("export_test")
    @ns.response(200, "Test successful")
    def post(self):
        """Test endpoint that accepts POST requests without authentication."""
        try:
            data = request.get_json() or {}
            return {
                "status": "ok",
                "message": "Test endpoint working",
                "received_data": data,
                "content_type": request.content_type,
                "method": request.method
            }
        except Exception as e:
            return {
                "status": "error",
                "message": str(e),
                "error_type": type(e).__name__
            }, 500

# Marshmallow schemas
class ColumnMapSchema(Schema):
    """Schema for validating column mappings."""
    
    # Define a field to hold all incoming data
    column_map = ma_fields.Dict(keys=ma_fields.Str(), values=ma_fields.Str())

class ExportPreviewSchema(Schema):
    """Schema for export preview requests."""
    
    format = ma_fields.Str(required=True, validate=validate.OneOf([f.value for f in ExportFormat]))
    column_map = ma_fields.Dict(keys=ma_fields.Str(), values=ma_fields.Str(), required=True)
    filter = ma_fields.Dict(keys=ma_fields.Str(), values=ma_fields.Raw(), required=False)
    limit = ma_fields.Int(required=False, validate=validate.Range(min=1, max=100), default=20)
    xml_root = ma_fields.Str(required=False, default="items")
    xml_item = ma_fields.Str(required=False, default="item")
    template = ma_fields.Str(required=False, validate=validate.OneOf(["generic", "google_merchant"]))

class ExportDownloadSchema(Schema):
    """Schema for export download requests."""
    
    format = ma_fields.Str(required=True, validate=validate.OneOf([f.value for f in ExportFormat]))
    column_map = ma_fields.Dict(keys=ma_fields.Str(), values=ma_fields.Str(), required=True)
    filter = ma_fields.Dict(keys=ma_fields.Str(), values=ma_fields.Raw(), required=False)
    xml_root = ma_fields.Str(required=False, default="items")
    xml_item = ma_fields.Str(required=False, default="item")
    template = ma_fields.Str(required=False, validate=validate.OneOf(["generic", "google_merchant"]))

class ExportConfigSchema(Schema):
    """Schema for export configuration."""
    
    id = ma_fields.Int(dump_only=True)
    name = ma_fields.Str(required=True, validate=validate.Length(min=1, max=100))
    format = ma_fields.Str(required=True, validate=validate.OneOf([f.value for f in ExportFormat]))
    column_map = ma_fields.Dict(keys=ma_fields.Str(), values=ma_fields.Str(), required=True)
    created_at = ma_fields.DateTime(dump_only=True)

# API models for Swagger docs
column_map_model = ns.model("ColumnMap", {
    "internal_name": fields.String(description="Internal model attribute name"),
})

export_preview_model = ns.model("ExportPreview", {
    "format": fields.String(required=True, enum=["csv", "xlsx", "xml"], description="Export format"),
    "column_map": fields.Raw(required=True, description="Mapping of internal attribute names to external column names"),
    "filter": fields.Raw(required=False, description="Filter criteria for the query"),
    "limit": fields.Integer(required=False, default=20, description="Maximum number of records to include"),
    "xml_root": fields.String(required=False, default="items", description="Root element name for XML"),
    "xml_item": fields.String(required=False, default="item", description="Item element name for XML"),
    "template": fields.String(required=False, enum=["generic", "google_merchant"], description="Predefined template")
})

export_download_model = ns.model("ExportDownload", {
    "format": fields.String(required=True, enum=["csv", "xlsx", "xml"], description="Export format"),
    "column_map": fields.Raw(required=True, description="Mapping of internal attribute names to external column names"),
    "filter": fields.Raw(required=False, description="Filter criteria for the query"),
    "xml_root": fields.String(required=False, default="items", description="Root element name for XML"),
    "xml_item": fields.String(required=False, default="item", description="Item element name for XML"),
    "template": fields.String(required=False, enum=["generic", "google_merchant"], description="Predefined template")
})

export_config_model = ns.model("ExportConfig", {
    "id": fields.Integer(readOnly=True, description="Unique identifier"),
    "name": fields.String(required=True, description="Name of the export configuration"),
    "format": fields.String(required=True, enum=["csv", "xlsx", "xml"], description="Export format"),
    "column_map": fields.Raw(required=True, description="Mapping of internal attribute names to external column names")
})

export_configs_model = ns.model("ExportConfigs", {
    "items": fields.List(fields.Nested(export_config_model)),
    "total": fields.Integer(description="Total number of configurations")
})

# Helper functions
def build_product_query(filter_criteria=None):
    """
    Build a SQLAlchemy query for products based on filter criteria.
    
    Args:
        filter_criteria: Dictionary of filter criteria
        
    Returns:
        SQLAlchemy query object
    """
    query = Product.query
    
    if not filter_criteria:
        return query
    
    # Apply filters if provided
    for key, value in filter_criteria.items():
        if key == "category" and value:
            query = query.filter(Product.category == value)
        elif key == "manufacturer" and value:
            query = query.filter(Product.manufacturer == value)
        elif key == "in_stock" and value in (True, "true", 1, "1"):
            query = query.filter(Product.quantity > 0)
        elif key == "search" and value:
            search_term = f"%{value}%"
            query = query.filter(
                (Product.name.ilike(search_term)) | 
                (Product.sku.ilike(search_term))
            )
    
    return query


@ns.route("/preview")
class ExportPreview(Resource):
    """Export preview resource."""
    
    @ns.doc("preview_export")
    @ns.expect(export_preview_model)
    @ns.response(200, "Preview generated")
    @ns.response(400, "Validation error")
    @token_required()
    @validate_schema(ExportPreviewSchema)
    @limiter.limit("30/minute")
    def post(self, current_user, data):
        """Generate a preview of exported data."""
        try:
            # Extract parameters
            export_format = data["format"]
            column_map = data["column_map"]
            filter_criteria = data.get("filter", {})
            limit = data.get("limit", 20)
            xml_root = data.get("xml_root", "items")
            xml_item = data.get("xml_item", "item")
            template = data.get("template")
            
            # Initialize export service
            export_service = ExportService()
            
            # Validate column map against Product model
            is_valid, invalid_keys = export_service.validate_column_map(column_map, Product)
            if not is_valid:
                return {
                    "message": "Invalid column map",
                    "invalid_keys": invalid_keys
                }, 400
            
            # Build query with filters
            query = build_product_query(filter_criteria).limit(limit)
            
            # Log query info for debugging
            current_app.logger.info(f"Export preview query: {query}")
            current_app.logger.info(f"Column map: {column_map}")
            
            # Generate dataframe
            df = export_service.build_dataframe(query, column_map)
            
            # Log dataframe info for debugging
            current_app.logger.info(f"Generated dataframe shape: {df.shape}")
            current_app.logger.info(f"Dataframe columns: {list(df.columns)}")
            
            # Return the first rows as JSON
            preview_data = df.to_dict(orient="records")
            
            return {
                "data": preview_data,
                "count": len(preview_data),
                "format": export_format,
                "xml_root": xml_root,
                "xml_item": xml_item,
                "template": template
            }
        except Exception as e:
            current_app.logger.error(f"Export preview error: {str(e)}")
            import traceback
            current_app.logger.error(f"Traceback: {traceback.format_exc()}")
            # Use ns.abort for proper Flask-RESTX error handling
            ns.abort(500, f"Export preview error: {str(e)}")


@ns.route("/download")
class ExportDownload(Resource):
    """Export download resource."""
    
    @ns.doc("download_export")
    @ns.expect(export_download_model)
    @ns.response(200, "Export file")
    @ns.response(400, "Validation error")
    @token_required()
    @limiter.limit("10/minute")
    def post(self, current_user):
        """Download exported data file."""
        try:
            # Check if data is coming from form
            if request.form and "params" in request.form:
                # Extract parameters from form
                params_json = request.form.get("params")
                data = json.loads(params_json)
            else:
                # Regular API call with JSON body
                data = request.get_json()
            
            # Validate with schema
            schema = ExportDownloadSchema()
            try:
                validated_data = schema.load(data)
            except ValidationError as err:
                return {"message": "Validation error", "errors": err.messages}, 400
            
            # Extract parameters
            export_format = validated_data["format"]
            column_map = validated_data["column_map"]
            filter_criteria = validated_data.get("filter", {})
            xml_root = validated_data.get("xml_root", "items")
            xml_item = validated_data.get("xml_item", "item")
            template = validated_data.get("template")
            
            # Initialize export service
            export_service = ExportService()
            
            # Validate column map against Product model
            is_valid, invalid_keys = export_service.validate_column_map(column_map, Product)
            if not is_valid:
                return {
                    "message": "Invalid column map",
                    "invalid_keys": invalid_keys
                }, 400
            
            # Build query with filters
            query = build_product_query(filter_criteria)
            
            # Generate dataframe
            df = export_service.build_dataframe(query, column_map)
            
            # Generate file in requested format
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            if export_format == ExportFormat.CSV.value:
                content, mime_type = export_service.to_csv(df)
                filename = f"export_{timestamp}.csv"
            elif export_format == ExportFormat.XLSX.value:
                content, mime_type = export_service.to_xlsx(df)
                filename = f"export_{timestamp}.xlsx"
            elif export_format == ExportFormat.XML.value:
                if template == "google_merchant":
                    content, mime_type = export_service.to_google_merchant_xml(df)
                    filename = f"google_merchant_{timestamp}.xml"
                else:
                    content, mime_type = export_service.to_xml(df, root=xml_root, item_tag=xml_item)
                    filename = f"export_{timestamp}.xml"
            else:
                return {"message": f"Unsupported format: {export_format}"}, 400
            
            # Create in-memory file
            buffer = io.BytesIO(content)
            buffer.seek(0)
            
            # Send file
            return send_file(
                buffer,
                mimetype=mime_type,
                as_attachment=True,
                download_name=filename
            )
        except Exception as e:
            current_app.logger.error(f"Export error: {str(e)}")
            return {"message": f"Export error: {str(e)}"}, 400


@ns.route("/configs")
class ExportConfigList(Resource):
    """Export configurations resource."""
    
    @ns.doc("list_export_configs")
    @ns.response(200, "Success")
    @token_required()
    @limiter.limit("60/minute")
    def get(self, current_user):
        """List all export configurations."""
        configs = ExportConfig.query.all()
        schema = ExportConfigSchema(many=True)
        
        return {
            "items": schema.dump(configs),
            "total": len(configs)
        }
    
    @ns.doc("create_export_config")
    @ns.expect(export_config_model)
    @ns.response(201, "Configuration created")
    @ns.response(400, "Validation error")
    @token_required()
    @validate_schema(ExportConfigSchema)
    def post(self, current_user, data):
        """Create a new export configuration."""
        # Extract parameters
        name = data["name"]
        export_format = data["format"]
        column_map = data["column_map"]
        
        # Initialize export service to validate column map
        export_service = ExportService()
        
        # Validate column map against Product model
        is_valid, invalid_keys = export_service.validate_column_map(column_map, Product)
        if not is_valid:
            return {
                "message": "Invalid column map",
                "invalid_keys": invalid_keys
            }, 400
        
        # Check if configuration with same name exists
        existing = ExportConfig.query.filter_by(name=name).first()
        if existing:
            return {"message": f"Export configuration '{name}' already exists"}, 400
        
        # Create new configuration
        config = ExportConfig(
            name=name,
            format=export_format,
            column_map=column_map,
            created_by_id=current_user.id
        )
        
        db.session.add(config)
        db.session.commit()
        
        schema = ExportConfigSchema()
        return schema.dump(config), 201


@ns.route("/configs/<int:config_id>")
@ns.param("config_id", "The export configuration identifier")
class ExportConfigResource(Resource):
    """Export configuration resource."""
    
    @ns.doc("get_export_config")
    @ns.response(200, "Success")
    @ns.response(404, "Configuration not found")
    @token_required()
    def get(self, config_id, current_user):
        """Get an export configuration by ID."""
        config = ExportConfig.query.get_or_404(config_id)
        
        schema = ExportConfigSchema()
        return schema.dump(config)
    
    @ns.doc("update_export_config")
    @ns.expect(export_config_model)
    @ns.response(200, "Configuration updated")
    @ns.response(400, "Validation error")
    @ns.response(404, "Configuration not found")
    @token_required()
    @validate_schema(ExportConfigSchema)
    def put(self, config_id, current_user, data):
        """Update an export configuration."""
        config = ExportConfig.query.get_or_404(config_id)
        
        # Extract parameters
        name = data["name"]
        export_format = data["format"]
        column_map = data["column_map"]
        
        # Initialize export service to validate column map
        export_service = ExportService()
        
        # Validate column map against Product model
        is_valid, invalid_keys = export_service.validate_column_map(column_map, Product)
        if not is_valid:
            return {
                "message": "Invalid column map",
                "invalid_keys": invalid_keys
            }, 400
        
        # Check if name is being changed and already exists
        if name != config.name:
            existing = ExportConfig.query.filter_by(name=name).first()
            if existing:
                return {"message": f"Export configuration '{name}' already exists"}, 400
        
        # Update configuration
        config.name = name
        config.format = export_format
        config.column_map = column_map
        
        db.session.commit()
        
        schema = ExportConfigSchema()
        return schema.dump(config)
    
    @ns.doc("delete_export_config")
    @ns.response(204, "Configuration deleted")
    @ns.response(404, "Configuration not found")
    @token_required()
    def delete(self, config_id, current_user):
        """Delete an export configuration."""
        config = ExportConfig.query.get_or_404(config_id)
        
        db.session.delete(config)
        db.session.commit()
        
        return "", 204 