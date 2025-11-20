#!/bin/bash
# Script to run generate_answers.py for multiple models and datasets
# This script is designed to run inside the Docker environment
#
# Usage:
#   Inside Docker container:
#     ./run_experiments.sh --entity <entity_name>
#
#   Or from host:
#     docker-compose exec semantic-uncertainty ./run_experiments.sh --entity <entity_name>
#
#   Or set via environment variable:
#     WANDB_SEM_UNC_ENTITY=<entity_name> ./run_experiments.sh
#
# The script will iterate through all models and datasets defined below,
# automatically generating experiment names with timestamps.

# Parse command-line arguments
ENTITY=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --entity)
            ENTITY="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 --entity <entity_name>"
            exit 1
            ;;
    esac
done

# Check if ENTITY is set (either from command line or environment variable)
if [ -z "$ENTITY" ]; then
    ENTITY="$WANDB_SEM_UNC_ENTITY"
fi

# Validate that ENTITY is set
if [ -z "$ENTITY" ]; then
    echo "Error: ENTITY must be set either via --entity parameter or WANDB_SEM_UNC_ENTITY environment variable"
    echo "Usage: $0 --entity <entity_name>"
    exit 1
fi

# Activate conda environment
source /opt/conda/etc/profile.d/conda.sh
conda activate semantic_uncertainty

# Create logs directory if it doesn't exist
mkdir -p /workspace/logs

# Default values
NUM_SAMPLES=500
NUM_TEST_SAMPLES=400

# Define models and datasets to run
MODELS=(
    # "Llama-2-7b"
    # "Llama-2-13b"
    # "Llama-2-70b"
    # "Llama-2-7b-chat"
    # "Llama-2-13b-chat"
    # "Llama-2-70b-chat"
    # "falcon-7b"
    # "falcon-40b"
    # "falcon-7b-instruct"
    # "falcon-40b-instruct"
    # "Mistral-7B-v0.1"
    "Mistral-7B-Instruct-v0.1"
    # Add more models as needed
)

DATASETS=(
    "trivia_qa"
    "squad"
    "bioasq"
    "nq"
    "svamp"
    # Add more datasets as needed
)

# Function to generate experiment name
generate_experiment_name() {
    local model=$1
    local dataset=$2
    # Use nanoseconds to ensure uniqueness even for rapid runs
    local timestamp=$(date +"%Y%m%d_%H%M%S_%N")
    # Clean up model name for experiment name (replace hyphens/slashes with underscores)
    local clean_model=$(echo "$model" | sed 's/[-\/]/_/g')
    echo "${clean_model}_${dataset}_${timestamp}"
}

# Run experiments
for model in "${MODELS[@]}"; do
    for dataset in "${DATASETS[@]}"; do
        experiment_name=$(generate_experiment_name "$model" "$dataset")
        log_file="/workspace/logs/${experiment_name}.log"
        
        echo "=========================================="
        echo "Running experiment: $experiment_name"
        echo "Model: $model"
        echo "Dataset: $dataset"
        echo "Log file: $log_file"
        echo "=========================================="
        
        if python semantic_uncertainty/generate_answers.py \
            --num_samples="$NUM_SAMPLES" \
            --num_test_samples="$NUM_TEST_SAMPLES" \
            --model_name="$model" \
            --dataset="$dataset" \
            --entity="$ENTITY" \
            --experiment_lot="$experiment_name" \
            2>&1 | tee "$log_file"; then
            echo "✓ Successfully completed experiment: $experiment_name"
        else
            echo "✗ Failed experiment: $experiment_name"
            echo "Continuing with next experiment..."
        fi
        echo ""
        
        # Small delay to ensure unique timestamps
        sleep 1
    done
done

echo "All experiments completed!"

