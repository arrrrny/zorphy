#!/bin/bash

# Build Zorphy MCP Server
# Compiles the MCP server to a native executable

set -e

echo "🔨 Building Zorphy MCP Server..."

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Compile to native executable
dart compile exe bin/zorphy_mcp_server.dart -o bin/zorphy_mcp_server

echo "✅ Build complete!"
echo "📦 Executable: bin/zorphy_mcp_server"
echo ""
echo "To use with Claude Desktop, add to your config:"
echo ""
echo '{
  "mcpServers": {
    "zorphy": {
      "command": "'$SCRIPT_DIR/bin/zorphy_mcp_server'"
    }
  }
}'
