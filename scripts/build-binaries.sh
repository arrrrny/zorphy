#!/bin/bash

# Build binaries for zorphy - compiles CLI and MCP server for current platform
# Usage: ./scripts/build-binaries.sh [output-dir]
# Example: ./scripts/build-binaries.sh ./dist

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

OUTPUT_DIR="${1:-$REPO_ROOT/dist}"

echo "🔨 Building zorphy binaries..."
echo "📍 Working directory: $REPO_ROOT"
echo "📁 Output directory: $OUTPUT_DIR"
echo ""

mkdir -p "$OUTPUT_DIR"

cd zorphy

dart pub get

detect_platform() {
    local os="$(uname -s)"
    local arch="$(uname -m)"
    
    case "$os" in
        Darwin*)
            case "$arch" in
                arm64) echo "macos-arm64" ;;
                x86_64) echo "macos-x64" ;;
                *) echo "macos-$arch" ;;
            esac
            ;;
        Linux*)
            case "$arch" in
                x86_64) echo "linux-x64" ;;
                aarch64) echo "linux-arm64" ;;
                *) echo "linux-$arch" ;;
            esac
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows-x64"
            ;;
        *)
            echo "$os-$arch" | tr '[:upper:]' '[:lower:]'
            ;;
    esac
}

PLATFORM=$(detect_platform)

CLI_OUTPUT="zorphy-$PLATFORM"
MCP_OUTPUT="zorphy_mcp_server-$PLATFORM"

if [[ "$PLATFORM" == "windows-"* ]]; then
    CLI_OUTPUT="$CLI_OUTPUT.exe"
    MCP_OUTPUT="$MCP_OUTPUT.exe"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Platform: $PLATFORM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "🔧 Compiling CLI binary..."
dart compile exe bin/zorphy_cli.dart -o "$OUTPUT_DIR/$CLI_OUTPUT"
echo "  ✓ CLI binary: $OUTPUT_DIR/$CLI_OUTPUT"

echo "🔧 Compiling MCP server binary..."
dart compile exe bin/zorphy_mcp_server.dart -o "$OUTPUT_DIR/$MCP_OUTPUT"
echo "  ✓ MCP server binary: $OUTPUT_DIR/$MCP_OUTPUT"

cd "$REPO_ROOT"

FILE_SIZE_CLI=$(ls -lh "$OUTPUT_DIR/$CLI_OUTPUT" | awk '{print $5}')
FILE_SIZE_MCP=$(ls -lh "$OUTPUT_DIR/$MCP_OUTPUT" | awk '{print $5}')

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Build Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📦 Binaries:"
echo "   • $CLI_OUTPUT ($FILE_SIZE_CLI)"
echo "   • $MCP_OUTPUT ($FILE_SIZE_MCP)"
echo ""
echo "📁 Location: $OUTPUT_DIR"
echo ""
