"""Settings models for the application."""
from lt_crm.app.extensions import db
from lt_crm.app.models.base import TimestampMixin
from sqlalchemy.exc import SQLAlchemyError
from flask import current_app

class CompanySettings(TimestampMixin, db.Model):
    """Model for storing company settings."""
    
    __tablename__ = "company_settings"
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    address = db.Column(db.String(200), nullable=True)
    city = db.Column(db.String(100), nullable=True)
    postal_code = db.Column(db.String(20), nullable=True)
    country = db.Column(db.String(100), default="Lietuva")
    phone = db.Column(db.String(20), nullable=True)
    email = db.Column(db.String(120), nullable=True)
    company_code = db.Column(db.String(50), nullable=True)
    vat_code = db.Column(db.String(50), nullable=True)
    bank_name = db.Column(db.String(100), nullable=True)
    bank_account = db.Column(db.String(50), nullable=True)
    bank_swift = db.Column(db.String(20), nullable=True)
    
    @classmethod
    def get_instance(cls):
        """Get the company settings instance or create a default one if none exists."""
        try:
            settings = cls.query.first()
            if not settings:
                # Create default settings from app config
                company_info = current_app.config.get("COMPANY_INFO", {})
                settings = cls(
                    name=company_info.get("name", "My Company"),
                    address=company_info.get("address", ""),
                    city=company_info.get("city", ""),
                    postal_code=company_info.get("postal_code", ""),
                    country=company_info.get("country", "Lietuva"),
                    phone=company_info.get("phone", ""),
                    email=company_info.get("email", ""),
                    company_code=company_info.get("company_code", ""),
                    vat_code=company_info.get("vat_code", ""),
                    bank_name=company_info.get("bank_name", ""),
                    bank_account=company_info.get("bank_account", ""),
                    bank_swift=company_info.get("bank_swift", "")
                )
                db.session.add(settings)
                db.session.commit()
                current_app.logger.info("Created default company settings")
            return settings
        except SQLAlchemyError as e:
            current_app.logger.error(f"Database error in get_instance: {str(e)}")
            db.session.rollback()
            # Return a default object without persisting it
            return cls(name="Default Company")
        except Exception as e:
            current_app.logger.error(f"Unexpected error in get_instance: {str(e)}")
            # Return a default object without persisting it
            return cls(name="Default Company")
            
    def to_dict(self):
        """Convert the company settings to a dictionary."""
        return {
            "name": self.name,
            "address": self.address,
            "city": self.city,
            "postal_code": self.postal_code,
            "country": self.country,
            "phone": self.phone,
            "email": self.email,
            "company_code": self.company_code,
            "vat_code": self.vat_code,
            "bank_name": self.bank_name,
            "bank_account": self.bank_account,
            "bank_swift": self.bank_swift
        } 