"""Add name column to users table

Revision ID: 2023d5e6f7g8
Create Date: 2023-05-15 14:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '2023d5e6f7g8'
down_revision = '2023c4d5e6f7'  # This should match the create_users_table migration ID
branch_labels = None
depends_on = None


def upgrade():
    # Since we're now creating the users table with the name column included,
    # this migration is no longer needed, but we'll keep it for safety
    # op.add_column('users', sa.Column('name', sa.String(length=100), nullable=True))
    # op.execute("UPDATE users SET name = username")
    # op.alter_column('users', 'name', nullable=False)
    pass


def downgrade():
    # No need to drop the column either, since we're creating the table with the column
    # op.drop_column('users', 'name')
    pass 