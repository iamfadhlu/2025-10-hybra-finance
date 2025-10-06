#!/bin/bash

# Complete Deployment Flow Script
# Usage: ./script/deploy-flow.sh [network]
# Example: ./script/deploy-flow.sh --rpc-url $RPC_URL --private-key $PRIVATE_KEY

set -e  # Exit on any error

echo "=== Starting Complete Deployment Flow ==="

# Store command line arguments for reuse
FORGE_ARGS="$@"

# Function to run a deployment script
run_script() {
    local script_name=$1
    echo ""
    echo "=== Running: $script_name ==="

    if forge script "script/${script_name}.s.sol" $FORGE_ARGS; then
        echo "✓ Successfully completed: $script_name"
    else
        echo "✗ Failed to run: $script_name"
        exit 1
    fi
}

# Function to run a setup script (optional)
run_setup_script() {
    local script_name=$1
    echo ""
    echo "=== Running Setup: $script_name ==="

    if forge script "script/${script_name}.s.sol" $FORGE_ARGS; then
        echo "✓ Successfully completed setup: $script_name"
    else
        echo "⚠ Warning: Failed to run setup script: $script_name (continuing...)"
    fi
}

echo ""
echo "Starting deployment sequence..."

# Core Deployment Scripts (in order)
run_script "Deploy1_Infrastructure"
run_script "Deploy2_TokenSystem"
run_script "Deploy3a1_GaugeFactories"
run_script "Deploy3a2_GaugeManagerAndBribes"
run_script "Deploy3a3_SetupPermissions"
run_script "Deploy3b1_MinterRewards"
run_script "Deploy3b2_SetupConnections"
run_script "Deploy3c_Voting"
run_script "Deploy5_APIs"

echo ""
echo "=== Core Deployment Complete ==="
echo ""

# Optional Setup Scripts
echo "=== Running Setup Scripts ==="
run_setup_script "Set0-Permissions"
run_setup_script "Set1-Connectors"
run_setup_script "Set2-InitBribeFactory"
run_setup_script "Set3-InitMinter"
w
echo ""
echo "🎉 === Complete Deployment Flow Finished ==="
echo "All contracts deployed successfully!"
echo ""
echo "Next steps:"
echo "1. Verify all contracts on block explorer"
echo "2. Test contract interactions"
echo "3. Set up monitoring and alerting"