# CLAUDE.md Guidelines

## Project Structure
This is a memory server for MCP (Multi-Client Protocol) that uses PostgreSQL with pgvector for vector similarity search.

## Commands
- `npm start`: Start server with Node.js
- `npm run dev`: Start with nodemon for development (auto-reload)
- `npm run prisma:migrate`: Initialize database (mentioned in README but not in package.json)

## Code Style
- Use ES Module imports (type: "module")
- camelCase for variables and functions
- Descriptive naming with clear purpose
- Structured error handling with try/catch and detailed logging
- JSON-RPC response format with proper error codes

## Database
- PostgreSQL with pgvector extension
- Use UUID primary keys with gen_random_uuid()
- Store JSON content with JSONB type
- Include created_at/updated_at timestamps

## PostgreSQL Connection Configuration

### Current Production Configuration (2025-08-29)
- **Host**: linuxserver.lan (remote PostgreSQL server)
- **Database**: mcp_memory_administrator
- **User**: administrator
- **Password**: Pass123qp
- **Connection URL**: `postgresql://administrator:Pass123qp@linuxserver.lan:5432/mcp_memory_administrator`

### Critical Authentication Setup
1. **Password Encryption**: PostgreSQL requires SCRAM-SHA-256 encryption for network connections
   ```sql
   SET password_encryption = 'scram-sha-256';
   ALTER USER username WITH PASSWORD 'password';
   ```

2. **Connection URL Format**:
   ```
   postgresql://username:password@host:port/database
   ```
   Example: `postgresql://administrator:Pass123qp@linuxserver.lan:5432/mcp_memory_administrator`

3. **Common Authentication Issues**:
   - Error: "password authentication failed" with "User does not have a valid SCRAM secret"
     - Solution: Set password with SCRAM-SHA-256 encryption (see above)
   - Error: "fe_sendauth: no password supplied"
     - Solution: Ensure DATABASE_URL includes password in connection string

4. **pg_hba.conf Configuration**:
   - Local connections (inside container): `trust` authentication works
   - Network connections: Requires password with SCRAM-SHA-256
   - Order matters: First matching rule is applied

### Required Database Setup
1. **Database Prerequisites**:
   - PostgreSQL server with pgvector extension
   - Database created with proper ownership
   - User with appropriate permissions

2. **Minimum Required Permissions** (Recommended for production):
   ```sql
   -- As superuser/admin, first create extension
   CREATE EXTENSION IF NOT EXISTS vector;
   
   -- Then grant minimal permissions to app user
   GRANT CREATE ON DATABASE mcp_memory_administrator TO administrator;
   GRANT USAGE ON SCHEMA public TO administrator;
   GRANT CREATE ON SCHEMA public TO administrator;
   GRANT ALL ON ALL TABLES IN SCHEMA public TO administrator;
   GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO administrator;
   ```

3. **Table Creation** (auto-created on first use, or manually):
   ```sql
   CREATE TABLE IF NOT EXISTS memories (
       id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
       type TEXT NOT NULL,
       content JSONB NOT NULL,
       source TEXT NOT NULL,
       embedding vector(384) NOT NULL,
       tags TEXT[] DEFAULT '{}',
       confidence DOUBLE PRECISION NOT NULL,
       created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
   );
   ```

### Environment Configuration
- **MCP Server Configuration** (~/.config/claude/mcp_servers.json):
  ```json
  "memory": {
    "command": "node",
    "args": ["/home/administrator/projects/mcp-memory-postgres/src/server.js"],
    "env": {
      "DATABASE_URL": "postgresql://administrator:Pass123qp@linuxserver.lan:5432/mcp_memory_administrator",
      "NODE_ENV": "production"
    }
  }
  ```

- **Optional .env file** (if not using MCP config):
  ```env
  DATABASE_URL=postgresql://administrator:Pass123qp@linuxserver.lan:5432/mcp_memory_administrator
  NODE_ENV=production
  ```

### Testing Connection
1. **Test from command line**:
   ```bash
   env PGPASSWORD='Pass123qp' psql -h linuxserver.lan -U administrator -d mcp_memory_administrator -c "SELECT 1;"
   ```

2. **Verify memories table exists**:
   ```bash
   env PGPASSWORD='Pass123qp' psql -h linuxserver.lan -U administrator -d mcp_memory_administrator -c "\dt"
   ```

3. **Check stored memories**:
   ```bash
   env PGPASSWORD='Pass123qp' psql -h linuxserver.lan -U administrator -d mcp_memory_administrator -c "SELECT id, type, source, tags, created_at FROM memories ORDER BY created_at DESC;"
   ```

### Troubleshooting

1. **Authentication Failures**:
   - Ensure password is set with SCRAM-SHA-256: `ALTER USER administrator WITH PASSWORD 'Pass123qp';`
   - Verify user exists: `\du` in psql as admin
   - Check database exists: `\l` in psql as admin

2. **Extension Issues**:
   - "permission denied to create extension": Admin/superuser must create: `CREATE EXTENSION vector;`
   - "type vector does not exist": Extension not installed in database

3. **MCP Memory Tool Issues**:
   - Tools return empty: This is normal for successful operations
   - "relation memories does not exist": Table needs to be created (see setup above)
   - Authentication errors: Check DATABASE_URL in MCP config matches actual credentials

4. **Testing MCP Memory**:
   ```javascript
   // Create a test memory
   mcp__memory__memory_create({
     type: "test",
     content: {"message": "test"},
     source: "test",
     confidence: 1
   })
   
   // List all memories (returns empty on success)
   mcp__memory__memory_list()
   
   // Search memories (returns empty on success)
   mcp__memory__memory_search({query: "test"})
   ```

### Verifying Setup
1. **Check pgvector extension**:
   ```bash
   env PGPASSWORD='Pass123qp' psql -h linuxserver.lan -U administrator -d mcp_memory_administrator -c "\dx"
   ```

2. **Verify table structure**:
   ```bash
   env PGPASSWORD='Pass123qp' psql -h linuxserver.lan -U administrator -d mcp_memory_administrator -c "\d memories"
   ```
   Should show: embedding | vector(384)

3. **Count memories**:
   ```bash
   env PGPASSWORD='Pass123qp' psql -h linuxserver.lan -U administrator -d mcp_memory_administrator -c "SELECT COUNT(*) FROM memories;"
   ```

## Security Best Practices
- **NEVER use SUPERUSER for production** - Only needed for initial extension setup
- Use minimal permissions (see Required Database Setup above)
- Store credentials in environment variables or secure config files
- Use SCRAM-SHA-256 password encryption for all users
- Regularly rotate passwords
- Consider using connection pooling for production

## Best Practices
- Use sendLogMessage() for consistent logging with levels
- Document functions with clear comments
- Include parameter descriptions in method definitions
- Validate inputs before use
- Use environment variables via dotenv for configuration
- Always verify PostgreSQL authentication is configured correctly before troubleshooting MCP connection issues
- Test database connection independently before testing MCP memory functionality
- Grant minimal required permissions to database users