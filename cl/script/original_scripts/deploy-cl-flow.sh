#!/bin/bash

# Complete DeployCL Deployment Flow Script
# Usage: ./script/deploy-cl-flow.sh [forge script arguments]
# Example: ./script/deploy-cl-flow.sh --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY

set -e  # Exit on any error

echo "=== Starting Complete DeployCL Deployment Flow ==="
echo "This will deploy all CL contracts in 5 sequential steps"
echo ""

# Store command line arguments for reuse
FORGE_ARGS="$@"

# Check if broadcast flag is present
if [[ "$*" == *"--broadcast"* ]]; then
    echo "🚀 BROADCAST MODE: Transactions will be sent to network"
else
    echo "🧪 SIMULATION MODE: Add --broadcast to deploy"
fi

echo "Arguments: $FORGE_ARGS"
echo ""

# Function to run a deployment script
run_script() {
    local script_name=$1
    local description=$2
    echo ""
    echo "=== Step: $script_name ==="
    echo "Description: $description"
    echo "Command: forge script script/${script_name}.s.sol $FORGE_ARGS"

    if forge script "script/${script_name}.s.sol" $FORGE_ARGS; then
        echo "✓ Successfully completed: $script_name"
        echo "  $description"
        sleep 2  # Short pause between steps
    else
        echo "✗ Failed to run: $script_name"
        echo "  Error occurred during: $description"
        exit 1
    fi
}

# Function to run optional/utility scripts
run_optional_script() {
    local script_name=$1
    local description=$2
    echo ""
    echo "=== Optional: $script_name ==="
    echo "Description: $description"

    if forge script "script/${script_name}.s.sol" $FORGE_ARGS; then
        echo "✓ Successfully completed optional: $script_name"
    else
        echo "⚠ Warning: Failed to run optional script: $script_name (continuing...)"
        echo "  This is non-critical, deployment can continue"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    echo "=== Checking Prerequisites ==="
    
    # Check if required files exist
    local required_files=(
        "script/constants/Local.json"
        "script/DeployCL_Step1_Core.s.sol"
        "script/DeployCL_Step2_NFT.s.sol"
        "script/DeployCL_Step3_Fees.s.sol"
        "script/DeployCL_Step4_Config.s.sol"
        "script/DeployCL_Step5_Periphery.s.sol"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo "✗ Missing required file: $file"
            echo "Please ensure all deployment files are present"
            exit 1
        fi
    done
    
    echo "✓ All required files found"
    echo ""
}

# Function to display summary
display_summary() {
    echo ""
    echo "🎉 === DeployCL Deployment Flow Complete ==="
    echo ""
    echo "Deployed contracts summary:"
    echo "├── Step 1: Core Infrastructure"
    echo "│   ├── Pool Implementation"
    echo "│   └── Pool Factory"
    echo "├── Step 2: NFT System"
    echo "│   ├── NFT Position Descriptor"
    echo "│   └── NFT Position Manager"
    echo "├── Step 3: Fee Modules"
    echo "│   ├── Dynamic Swap Fee Module"
    echo "│   ├── Unstaked Fee Module"
    echo "│   └── Protocol Fee Module"
    echo "├── Step 4: Configuration"
    echo "│   ├── Fee Module Setup"
    echo "│   └── Permission Transfers"
    echo "└── Step 5: Periphery"
    echo "    ├── Quoter V2"
    echo "    └── Swap Router"
    echo ""
    echo "📁 Deployment files location:"
    echo "├── Combined: script/constants/output/DeployCL-local.json"
    echo "├── Step 1: script/constants/output/DeployCL-Step1-local.json"
    echo "├── Step 2: script/constants/output/DeployCL-Step2-local.json"
    echo "├── Step 3: script/constants/output/DeployCL-Step3-local.json"
    echo "└── Step 5: script/constants/output/DeployCL-Step5-local.json"
    echo ""
    echo "🔗 Next steps:"
    echo "1. Deploy test tokens (if needed): ./script/DeployTestTokens.s.sol"
    echo "2. Create pools: ./script/DeployPoolWithPrice.s.sol"
    echo "3. Add liquidity: ./script/AddLiquidity5Percent.s.sol"
    echo "4. Deploy utilities: ./script/DeployPositionValueQuery.s.sol"
    echo "5. Verify contracts on block explorer"
}

# Main execution flow
main() {
    echo "Starting deployment sequence..."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Core Deployment Scripts (in sequential order)
    run_script "DeployCL_Step1_Core" "Deploy core pool infrastructure (Pool Implementation + Factory)"
    run_script "DeployCL_Step2_NFT" "Deploy NFT system (Position Descriptor + Manager)"
    run_script "DeployCL_Step3_Fees" "Deploy fee modules (Swap, Unstaked, Protocol fees)"
    run_script "DeployCL_Step4_Config" "Configure contracts and transfer permissions"
    run_script "DeployCL_Step5_Periphery" "Deploy periphery contracts (Quoter + Router)"
    
    echo ""
    echo "=== Core DeployCL Deployment Complete ==="
    echo ""
    
    # Optional utility deployments
    echo "=== Running Optional Utility Deployments ==="
    run_optional_script "DeployPositionValueQuery" "Deploy position value query utility"
    
    # Display final summary
    display_summary
}

# Handle script interruption
trap 'echo ""; echo "❌ Deployment interrupted!"; exit 1' INT TERM

# Run main function
main