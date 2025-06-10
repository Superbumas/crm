"""Fix WordPress fields and product categories table issues

Revision ID: fix_wordpress_categories
Revises: 2023a1b2c3d6
Create Date: 2025-06-10 22:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import text

# revision identifiers, used by Alembic.
revision = 'fix_wordpress_categories'
down_revision = '2023a1b2c3d6'  # Points to the company settings migration
branch_labels = None
depends_on = None


def upgrade():
    # 1. Add WordPress fields to company_settings table if they don't exist
    connection = op.get_bind()
    
    # Check if columns already exist to avoid errors
    inspector = sa.inspect(connection)
    existing_columns = [column['name'] for column in inspector.get_columns('company_settings')]
    
    if 'wordpress_api_url' not in existing_columns:
        op.add_column('company_settings', 
                     sa.Column('wordpress_api_url', sa.String(length=255), nullable=True))
    
    if 'wordpress_consumer_key' not in existing_columns:
        op.add_column('company_settings', 
                     sa.Column('wordpress_consumer_key', sa.String(length=255), nullable=True))
    
    if 'wordpress_consumer_secret' not in existing_columns:
        op.add_column('company_settings', 
                     sa.Column('wordpress_consumer_secret', sa.String(length=255), nullable=True))
    
    # 2. Add category_id to products table if it doesn't exist
    existing_product_columns = [column['name'] for column in inspector.get_columns('products')]
    
    if 'category_id' not in existing_product_columns:
        try:
            op.add_column('products', sa.Column('category_id', sa.Integer(), nullable=True))
            # Check if product_categories table exists before creating the foreign key
            if 'product_categories' in inspector.get_table_names():
                op.create_foreign_key('fk_products_category_id', 'products', 'product_categories', 
                                     ['category_id'], ['id'])
        except Exception as e:
            print(f"Error adding category_id column: {e}")
    
    # 3. For product_categories table, we'll check if it exists first
    if 'product_categories' not in inspector.get_table_names():
        try:
            # Create product_categories table
            op.create_table('product_categories',
                sa.Column('id', sa.Integer(), nullable=False),
                sa.Column('name', sa.String(length=100), nullable=False),
                sa.Column('slug', sa.String(length=100), nullable=False),
                sa.Column('description', sa.Text(), nullable=True),
                sa.Column('parent_id', sa.Integer(), nullable=True),
                sa.Column('external_id', sa.String(length=50), nullable=True),
                sa.Column('image_url', sa.String(length=255), nullable=True),
                sa.Column('created_at', sa.DateTime(), nullable=True),
                sa.Column('updated_at', sa.DateTime(), nullable=True),
                sa.PrimaryKeyConstraint('id')
            )
            op.create_index(op.f('ix_product_categories_slug'), 'product_categories', ['slug'], unique=True)
            
            # Add self-reference after table is created
            op.create_foreign_key('fk_product_categories_parent', 'product_categories', 
                                 'product_categories', ['parent_id'], ['id'])
        except Exception as e:
            print(f"Error creating product_categories table: {e}")


def downgrade():
    # We don't want to drop columns/tables in downgrade as it could cause data loss
    # This migration is for fixing issues, not removing functionality
    pass 