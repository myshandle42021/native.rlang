#!/bin/bash

# ROL3 Database Setup - PostgreSQL
echo "🗄️ Setting up PostgreSQL for ROL3..."

# Create database and user
echo "📊 Creating ROL3 database..."

# Create user and database
psql postgres << 'PSQL_EOF'
-- Create database
DROP DATABASE IF EXISTS rol3;
CREATE DATABASE rol3;

-- Create user
DROP USER IF EXISTS rol3_user;
CREATE USER rol3_user WITH PASSWORD 'rol3_password';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE rol3 TO rol3_user;
ALTER USER rol3_user CREATEDB;
\q
PSQL_EOF

# Run schema
echo "📋 Setting up database schema..."
psql -d rol3 -f schema/database.sql

# Test connection
echo "🔌 Testing database connection..."
PGPASSWORD=rol3_password psql -h localhost -U rol3_user -d rol3 -c "SELECT 'ROL3 Database Ready!' as status;"

if [ $? -eq 0 ]; then
    echo "✅ Database setup complete!"
    echo ""
    echo "🔗 Connection string:"
    echo "DATABASE_URL=postgresql://rol3_user:rol3_password@localhost:5432/rol3"
else
    echo "❌ Database setup failed"
    exit 1
fi
