#!/usr/bin/env bash
# setup-modular.sh - Setup script for modular SD CLI
set -Eeuo pipefail

echo "🔧 Setting up modular SD CLI..."

# 1. Create directories
echo "Creating directory structure..."
mkdir -p lib plugins/example src/{cli,commands/bridge,plugins/example}

# 2. Make sure bin/sd is executable
chmod +x bin/sd bin/sd-launch.cjs bin/bridge.mjs bin/postinstall.mjs

# 3. Run syntax checks
echo "Checking module syntax..."
for f in lib/*.sh; do
  if [[ -f "$f" ]]; then
    bash -n "$f" && echo "✓ $f" || echo "✗ $f has syntax errors"
  fi
done

# 4. Test basic functionality
echo "Testing basic commands..."
./bin/sd --help >/dev/null && echo "✓ sd --help works" || echo "✗ sd --help failed"

# 5. Test plugin system
echo "Testing plugin system..."
if ./bin/sd example:echo "test" 2>/dev/null | grep -q "Hello from plugin"; then
  echo "✓ Plugin system working"
else
  echo "ℹ Plugin system not yet active (normal during setup)"
fi

# 6. Run full test suite
echo "Running test suite..."
npm test && echo "✓ All tests passed" || echo "✗ Some tests failed"

echo
echo "🎉 Modular SD CLI setup complete!"
echo
echo "Next steps:"
echo "  ./bin/sd --help                 # See all commands"
echo "  ./bin/sd example:echo hello     # Test plugin"
echo "  ./bin/sd deps doctor            # Check dependencies"
echo "  ./bin/sd up                     # Start full stack (needs Docker)"