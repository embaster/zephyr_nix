#!/usr/bin/env bash

set -euo pipefail

echo "🔧 Setting up Zephyr project..."

# Check if we're in a Nix shell
if [ -z "${IN_NIX_SHELL:-}" ]; then
    echo "⚠️  Please run this script inside 'nix develop'"
    exit 1
fi

# Initialize west workspace if not already done
if [ ! -f .west/config ]; then
    echo "📥 Initializing west workspace..."
    west init -l .
else
    echo "✅ West workspace already initialized"
fi

# Update dependencies
echo "📦 Updating west dependencies..."
west update

# Source Zephyr environment
if [ -f zephyr/zephyr-env.sh ]; then
    source zephyr/zephyr-env.sh
    echo "✅ Zephyr environment sourced"
else
    echo "❌ Zephyr environment script not found"
    exit 1
fi

echo "🎉 Setup complete!"
echo ""
echo "🚀 Next steps:"
echo "  west build -b nrf52840dk_nrf52840 ."
echo "  west flash"