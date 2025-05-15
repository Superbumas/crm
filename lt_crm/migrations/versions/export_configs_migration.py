"""Create export_configs table.

Revision ID: 20230515_export_configs
Revises: # To be filled based on the previous migration
Create Date: 2025-05-15 11:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '20230515_export_configs'
down_revision = None  # Update this to the previous migration ID
branch_labels = None
depends_on = None


def upgrade():
    """Upgrade database schema to include export_configs table."""
    # Create enum type for export formats
    op.create_table(
        'export_configs',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('format', sa.Enum('CSV', 'XLSX', 'XML', name='exportformat'), nullable=False),
        sa.Column('column_map', sa.JSON(), nullable=False),
        sa.Column('created_by_id', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['created_by_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    
    # Create an index on the name column for faster lookups
    op.create_index(op.f('ix_export_configs_name'), 'export_configs', ['name'], unique=True)


def downgrade():
    """Downgrade database schema by removing export_configs table."""
    op.drop_index(op.f('ix_export_configs_name'), table_name='export_configs')
    op.drop_table('export_configs')
    op.execute('DROP TYPE exportformat') 