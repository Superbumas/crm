"""Initial migration

Revision ID: 2023a1b2c3d4
Create Date: 2023-11-08 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '2023a1b2c3d4'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Create enum types
    order_status = sa.Enum('new', 'paid', 'packed', 'shipped', 'returned', 'cancelled', name='orderstatus')
    movement_reason_code = sa.Enum('import', 'sale', 'return', 'manual_adj', name='movementreasoncode')
    invoice_status = sa.Enum('draft', 'issued', 'paid', 'cancelled', name='invoicestatus')
    integration_type = sa.Enum('ecommerce', 'accounting', 'shipping', 'inventory', 'other', name='integrationtype')
    sync_status = sa.Enum('pending', 'in_progress', 'success', 'failed', 'partial', name='syncstatus')
    
    order_status.create(op.get_bind())
    movement_reason_code.create(op.get_bind())
    invoice_status.create(op.get_bind())
    integration_type.create(op.get_bind())
    sync_status.create(op.get_bind())
    
    # Create products table
    op.create_table('products',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('sku', sa.String(length=50), nullable=False),
        sa.Column('name', sa.String(length=200), nullable=False),
        sa.Column('description_html', sa.Text(), nullable=True),
        sa.Column('barcode', sa.String(length=50), nullable=True),
        sa.Column('quantity', sa.Integer(), nullable=True, default=0),
        sa.Column('delivery_days', sa.SmallInteger(), nullable=True),
        sa.Column('price_final', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('price_old', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('category', sa.String(length=100), nullable=True),
        sa.Column('main_image_url', sa.String(length=255), nullable=True),
        sa.Column('extra_image_urls', sa.JSON(), nullable=True),
        sa.Column('model', sa.String(length=100), nullable=True),
        sa.Column('manufacturer', sa.String(length=100), nullable=True),
        sa.Column('warranty_months', sa.SmallInteger(), nullable=True),
        sa.Column('weight_kg', sa.Numeric(precision=8, scale=3), nullable=True),
        sa.Column('parameters', sa.JSON(), nullable=True),
        sa.Column('variants', sa.JSON(), nullable=True),
        sa.Column('delivery_options', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('sku')
    )
    op.create_index(op.f('ix_products_sku'), 'products', ['sku'], unique=True)
    
    # Create orders table
    op.create_table('orders',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('order_number', sa.String(length=20), nullable=False),
        sa.Column('customer_id', sa.Integer(), nullable=True),
        sa.Column('status', sa.Enum('new', 'paid', 'packed', 'shipped', 'returned', 'cancelled', name='orderstatus'), nullable=False),
        sa.Column('total_amount', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('tax_amount', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('shipping_amount', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('discount_amount', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('shipping_name', sa.String(length=100), nullable=True),
        sa.Column('shipping_address', sa.String(length=200), nullable=True),
        sa.Column('shipping_city', sa.String(length=100), nullable=True),
        sa.Column('shipping_postal_code', sa.String(length=20), nullable=True),
        sa.Column('shipping_country', sa.String(length=100), nullable=True, default='Lithuania'),
        sa.Column('shipping_phone', sa.String(length=20), nullable=True),
        sa.Column('shipping_email', sa.String(length=120), nullable=True),
        sa.Column('payment_method', sa.String(length=50), nullable=True),
        sa.Column('payment_reference', sa.String(length=100), nullable=True),
        sa.Column('shipping_method', sa.String(length=50), nullable=True),
        sa.Column('tracking_number', sa.String(length=100), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['customer_id'], ['customers.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('order_number')
    )
    op.create_index(op.f('ix_orders_order_number'), 'orders', ['order_number'], unique=True)
    
    # Create order_items table
    op.create_table('order_items',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('order_id', sa.Integer(), nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('quantity', sa.Integer(), nullable=False, default=1),
        sa.Column('price', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('tax_rate', sa.Numeric(precision=5, scale=2), nullable=True),
        sa.Column('discount_amount', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('variant_info', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create stock_movements table
    op.create_table('stock_movements',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('qty_delta', sa.Integer(), nullable=False),
        sa.Column('reason_code', sa.Enum('import', 'sale', 'return', 'manual_adj', name='movementreasoncode'), nullable=False),
        sa.Column('note', sa.String(length=255), nullable=True),
        sa.Column('channel', sa.String(length=50), nullable=True),
        sa.Column('reference_id', sa.String(length=50), nullable=True),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create invoices table
    op.create_table('invoices',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('invoice_number', sa.String(length=20), nullable=False),
        sa.Column('order_id', sa.Integer(), nullable=True),
        sa.Column('customer_id', sa.Integer(), nullable=True),
        sa.Column('status', sa.Enum('draft', 'issued', 'paid', 'cancelled', name='invoicestatus'), nullable=False),
        sa.Column('issue_date', sa.Date(), nullable=True),
        sa.Column('due_date', sa.Date(), nullable=True),
        sa.Column('total_amount', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('tax_amount', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('subtotal_amount', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('billing_name', sa.String(length=100), nullable=True),
        sa.Column('billing_address', sa.String(length=200), nullable=True),
        sa.Column('billing_city', sa.String(length=100), nullable=True),
        sa.Column('billing_postal_code', sa.String(length=20), nullable=True),
        sa.Column('billing_country', sa.String(length=100), nullable=True, default='Lithuania'),
        sa.Column('billing_email', sa.String(length=120), nullable=True),
        sa.Column('company_code', sa.String(length=50), nullable=True),
        sa.Column('vat_code', sa.String(length=50), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('payment_details', sa.Text(), nullable=True),
        sa.Column('pdf_url', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['customer_id'], ['customers.id'], ),
        sa.ForeignKeyConstraint(['order_id'], ['orders.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('invoice_number')
    )
    op.create_index(op.f('ix_invoices_invoice_number'), 'invoices', ['invoice_number'], unique=True)
    
    # Create integration_sync_logs table
    op.create_table('integration_sync_logs',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('integration_type', sa.Enum('ecommerce', 'accounting', 'shipping', 'inventory', 'other', name='integrationtype'), nullable=False),
        sa.Column('provider_name', sa.String(length=50), nullable=False),
        sa.Column('status', sa.Enum('pending', 'in_progress', 'success', 'failed', 'partial', name='syncstatus'), nullable=False),
        sa.Column('records_processed', sa.Integer(), nullable=True, default=0),
        sa.Column('records_created', sa.Integer(), nullable=True, default=0),
        sa.Column('records_updated', sa.Integer(), nullable=True, default=0),
        sa.Column('records_failed', sa.Integer(), nullable=True, default=0),
        sa.Column('started_at', sa.DateTime(), nullable=True),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.Column('entity_type', sa.String(length=50), nullable=True),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('log_data', sa.JSON(), nullable=True),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )


def downgrade():
    # Drop tables
    op.drop_table('integration_sync_logs')
    op.drop_table('invoices')
    op.drop_table('stock_movements')
    op.drop_table('order_items')
    op.drop_table('orders')
    op.drop_table('products')
    
    # Drop enum types
    op.execute('DROP TYPE syncstatus')
    op.execute('DROP TYPE integrationtype')
    op.execute('DROP TYPE invoicestatus')
    op.execute('DROP TYPE movementreasoncode')
    op.execute('DROP TYPE orderstatus') 