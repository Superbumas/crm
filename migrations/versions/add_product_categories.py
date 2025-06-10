"""add product categories

Revision ID: add_product_categories
Revises: 
Create Date: 2024-06-09 22:30:00

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'add_product_categories'
down_revision = None  # Update this with your previous migration ID if needed
branch_labels = None
depends_on = None


def upgrade():
    # Create product_categories table
    op.create_table('product_categories',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('slug', sa.String(length=100), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('parent_id', sa.Integer(), nullable=True),
        sa.Column('external_id', sa.String(length=50), nullable=True),
        sa.Column('image_url', sa.String(length=255), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(['parent_id'], ['product_categories.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_product_categories_slug'), 'product_categories', ['slug'], unique=True)
    
    # Add category_id to products table
    op.add_column('products', sa.Column('category_id', sa.Integer(), nullable=True))
    op.create_foreign_key('fk_products_category_id', 'products', 'product_categories', ['category_id'], ['id'])


def downgrade():
    # Drop foreign key first
    op.drop_constraint('fk_products_category_id', 'products', type_='foreignkey')
    op.drop_column('products', 'category_id')
    
    # Drop the product_categories table
    op.drop_index(op.f('ix_product_categories_slug'), table_name='product_categories')
    op.drop_table('product_categories') 