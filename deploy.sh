#!/bin/bash
# MCP Memory PostgreSQL Server Deployment Script

# Load environment variables
if [ -f /home/administrator/projects/secrets/mcp-memory.env ]; then
    set -a
    source /home/administrator/projects/secrets/mcp-memory.env
    set +a
else
    echo "Warning: mcp-memory.env not found, using environment variables"
fi

# Construct DATABASE_URL if not set
if [ -z "$DATABASE_URL" ]; then
    DATABASE_URL="postgresql://${POSTGRES_USER:-administrator}:${POSTGRES_PASSWORD:-Pass123qp}@${POSTGRES_HOST:-linuxserver.lan}:${POSTGRES_PORT:-5432}/${POSTGRES_DB:-mcp_memory_administrator}"
fi

export DATABASE_URL
export NODE_ENV="${NODE_ENV:-production}"

# Change to project directory
cd /home/administrator/projects/mcp-memory-postgres

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Run the server
echo "Starting MCP Memory PostgreSQL server..."
echo "Database: $DATABASE_URL"
exec node src/server.js