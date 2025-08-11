#!/bin/sh

# Post-create command script for devcontainer setup
# This script runs after the container is created to install necessary tools

set -e

echo "=== Running post-create setup ==="

# Install global npm packages
echo "Installing Claude Code CLI..."
npm install -g @anthropic-ai/claude-code

# Verify Claude Code installation
echo "Verifying Claude Code installation..."
claude --version && echo "Claude Code is working"

# Configure git safe directory
echo "Configuring git safe directory..."
git config --global --add safe.directory /workspace

# Set up Claude configuration directory (bind mount from .git/.config/claude)
echo "Setting up Claude configuration..."
# Ensure the bind mount directory has correct permissions
# (Docker may create it with root ownership on first run)
if [ -d /home/vscode/.claude ] && [ ! -w /home/vscode/.claude ]; then
    echo "Fixing permissions on Claude config directory..."
    sudo chown -R vscode:vscode /home/vscode/.claude
fi
# Create .claude.json with default content if it doesn't exist
# On Dev Container rebuild, Claude won't use the stored credentials
# unless the .claude.json file is present and can be parsed.
# The following file is what is created by default on first run.
if [ ! -f /home/vscode/.claude/.claude.json ]; then
    echo "Creating .claude.json with default configuration..."
    cat > /home/vscode/.claude/.claude.json << 'EOF'
{
  "numStartups": 0,
  "theme": "dark",
  "preferredNotifChannel": "auto",
  "verbose": false,
  "editorMode": "normal",
  "autoCompactEnabled": true,
  "hasSeenTasksHint": false,
  "queuedCommandUpHintCount": 0,
  "diffTool": "auto",
  "customApiKeyResponses": {
    "approved": [],
    "rejected": []
  },
  "env": {},
  "tipsHistory": {},
  "memoryUsageCount": 0,
  "promptQueueUseCount": 0,
  "todoFeatureEnabled": true,
  "messageIdleNotifThresholdMs": 60000,
  "autoConnectIde": false,
  "autoInstallIdeExtension": true,
  "autocheckpointingEnabled": true,
  "checkpointingShadowRepos": [],
  "cachedStatsigGates": {}
}
EOF
fi
# Create symlink if it doesn't exist
if [ ! -L /home/vscode/.claude.json ]; then
    echo "Creating symlink ~/.claude.json -> ~/.claude/.claude.json"
    ln -sf /home/vscode/.claude/.claude.json /home/vscode/.claude.json
fi
echo "Claude configuration ready"

echo "=== Post-create setup complete ==="

# EOF
