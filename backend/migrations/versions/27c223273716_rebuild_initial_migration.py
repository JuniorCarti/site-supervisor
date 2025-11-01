"""Rebuild initial migration

Revision ID: 27c223273716
Revises: 
Create Date: 2025-10-30 13:35:03.477248

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '27c223273716'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Recreate ENUM in lowercase to match Python model
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'userrole') THEN
                CREATE TYPE userrole AS ENUM ('admin', 'manager', 'driver');
            END IF;
        END$$;

        -- Convert all roles to lowercase for consistency
        UPDATE users SET role = LOWER(role);

        -- Change column type safely
        ALTER TABLE users ALTER COLUMN role TYPE userrole USING role::userrole;
    """)

def downgrade():
    op.execute("""
        ALTER TABLE users ALTER COLUMN role TYPE VARCHAR(50);
        DROP TYPE IF EXISTS userrole CASCADE;
    """)


    # ### end Alembic commands ###
