"""Add shipment tables.

Revision ID: 384af2710d5b
Revises: initial_migration
Create Date: 2023-11-15 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '384af2710d5b'
down_revision = 'initial_migration'  # adjust if you have another migration
branch_labels = None
depends_on = None


def upgrade():
    # Create shipment status enum
    shipment_status = sa.Enum('pending', 'received', 'cancelled', name='shipmentstatus')
    shipment_status.create(op.get_bind())
    
    # Update movement reason code enum to include shipment
    # Note: This assumes MovementReasonCode enum already exists
    op.execute("ALTER TYPE movementreasoncode ADD VALUE IF NOT EXISTS 'shipment'")
    
    # Create shipments table
    op.create_table(
        'shipments',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('shipment_number', sa.String(length=50), nullable=False),
        sa.Column('supplier', sa.String(length=100), nullable=True),
        sa.Column('expected_date', sa.Date(), nullable=True),
        sa.Column('arrival_date', sa.Date(), nullable=True),
        sa.Column('status', shipment_status, nullable=False, server_default='pending'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('user_id', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('shipment_number')
    )
    
    # Create shipment_items table
    op.create_table(
        'shipment_items',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('shipment_id', sa.Integer(), nullable=False),
        sa.Column('product_id', sa.Integer(), nullable=False),
        sa.Column('quantity', sa.Integer(), nullable=False),
        sa.Column('cost_price', sa.Numeric(precision=12, scale=2), nullable=True),
        sa.Column('notes', sa.String(length=255), nullable=True),
        sa.ForeignKeyConstraint(['product_id'], ['products.id'], ),
        sa.ForeignKeyConstraint(['shipment_id'], ['shipments.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create indices
    op.create_index(op.f('ix_shipments_status'), 'shipments', ['status'], unique=False)


def downgrade():
    # Drop tables
    op.drop_table('shipment_items')
    op.drop_table('shipments')
    
    # Drop enum
    sa.Enum(name='shipmentstatus').drop(op.get_bind(), checkfirst=True)
    
    # Note: We don't remove the 'shipment' value from movementreasoncode
    # as that could break existing data 