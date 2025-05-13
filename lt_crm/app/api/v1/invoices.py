"""Invoice endpoints for API v1."""
from io import BytesIO
import os
from datetime import datetime
from flask import request, current_app, send_file
from flask_restx import Namespace, Resource, fields
from app.models.invoice import Invoice, InvoiceStatus
from app.extensions import db
from app.api.v1.utils import (
    token_required,
    get_pagination_params,
    paginate
)
from app.api.v1.schemas import InvoiceSchema
from app.api.v1 import limiter

ns = Namespace("invoices", description="Invoice operations")

# Mock PDF generator (Replace with actual PDF generation logic in a real app)
def generate_invoice_pdf(invoice):
    """Generate a PDF for an invoice."""
    # For demonstration only - in a real app, use a library like WeasyPrint or ReportLab
    # to generate a proper PDF
    from reportlab.pdfgen import canvas
    
    buffer = BytesIO()
    p = canvas.Canvas(buffer)
    
    # Add invoice details to PDF
    p.setFont("Helvetica-Bold", 18)
    p.drawString(100, 800, f"INVOICE #{invoice.invoice_number}")
    
    p.setFont("Helvetica", 12)
    p.drawString(100, 750, f"Date: {invoice.issue_date}")
    p.drawString(100, 730, f"Due Date: {invoice.due_date}")
    
    p.drawString(100, 700, f"Billing To:")
    p.drawString(120, 680, invoice.billing_name or "")
    p.drawString(120, 660, invoice.billing_address or "")
    p.drawString(120, 640, f"{invoice.billing_city or ''}, {invoice.billing_postal_code or ''}")
    p.drawString(120, 620, invoice.billing_country or "")
    
    p.drawString(100, 580, f"Company Code: {invoice.company_code or 'N/A'}")
    p.drawString(100, 560, f"VAT Code: {invoice.vat_code or 'N/A'}")
    
    p.drawString(100, 520, f"Amount: {invoice.total_amount}")
    p.drawString(100, 500, f"Tax: {invoice.tax_amount or '0.00'}")
    p.drawString(100, 480, f"Subtotal: {invoice.subtotal_amount or '0.00'}")
    
    p.drawString(100, 440, "Payment Details:")
    p.drawString(120, 420, invoice.payment_details or "N/A")
    
    p.drawString(100, 380, "Notes:")
    p.drawString(120, 360, invoice.notes or "")
    
    p.setFont("Helvetica-Bold", 12)
    p.drawString(100, 300, "Thank you for your business!")
    
    p.save()
    buffer.seek(0)
    return buffer

@ns.route("/<int:id>/pdf")
@ns.param("id", "Invoice ID")
class InvoicePDFResource(Resource):
    """Invoice PDF resource."""
    
    @ns.doc("get_invoice_pdf")
    @ns.response(200, "Success")
    @ns.response(404, "Invoice not found")
    @token_required()
    def get(self, id, current_user):
        """Get PDF for an invoice."""
        invoice = Invoice.query.get_or_404(id)
        
        # Check if PDF already exists
        if invoice.pdf_url and os.path.exists(invoice.pdf_url):
            return send_file(invoice.pdf_url, download_name=f"invoice_{invoice.invoice_number}.pdf")
        
        # Generate PDF
        pdf_buffer = generate_invoice_pdf(invoice)
        
        # Return the PDF
        return send_file(
            pdf_buffer,
            mimetype="application/pdf",
            download_name=f"invoice_{invoice.invoice_number}.pdf",
            as_attachment=True
        ) 