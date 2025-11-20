# Reproducing Experiments: Comparing Metrics Before/After Semantic Uncertainty

This guide shows how to reproduce experiments comparing baseline uncertainty metrics (regular entropy) with semantic uncertainty approaches.

## Prerequisites

- Docker with GPU support (nvidia-docker2)
- NVIDIA Container Toolkit
- W&B account (for logging results)

## 1. Setup Environment

```bash
cd tools_uncertainty/semantic_uncertainty

# Copy and configure environment variables
cp env.example .env
```

Edit `.env` file with your credentials:
```bash
HUGGING_FACE_HUB_TOKEN=your_token_here
WANDB_API_KEY=your_wandb_key_here
WANDB_SEM_UNC_ENTITY=your_wandb_entity_here  # Your W&B entity/username
OPENAI_API_KEY=your_key_here  # Optional, only for GPT models
XDG_CACHE_HOME=/workspace/cache
SCRATCH_DIR=/workspace/scratch
```

## 2. Build and Connect to Docker Container

```bash
# Build the Docker image
docker compose build

# Start container in interactive mode
docker compose run --rm semantic-uncertainty
```

Once inside the container, activate the conda environment:
```bash
conda activate semantic_uncertainty
```

## 3. Initialize W&B

```bash
wandb login
```

## 4. Run Complete Experiment Pipeline

This single command generates model responses, computes all uncertainty metrics (baseline + semantic), and automatically compares them:

```bash
python semantic_uncertainty/generate_answers.py \
  --num_samples=500 \
  --num_test_samples=400 \
  --model_name=Mistral-7B-Instruct-v0.1 \
  --dataset=trivia_qa \
  --entity=your_wandb_entity
```

**What this computes:**
- **Baseline metrics (before):**
  - `regular_entropy` - Naive predictive entropy
  - `cluster_assignment_entropy` - Discrete semantic entropy
  - `p_ik` - Embedding regression
  
- **Semantic uncertainty metrics (after):**
  - `semantic_entropy` - Main semantic uncertainty

**Available models:**
- `Llama-2-7b`, `Llama-2-13b`, `Llama-2-70b`
- `Llama-2-7b-chat`, `Llama-2-13b-chat`, `Llama-2-70b-chat`
- `Mistral-7B-v0.1`, `Mistral-7B-Instruct-v0.1`
- `falcon-7b`, `falcon-40b`, `falcon-7b-instruct`, `falcon-40b-instruct`

**Available datasets:**
- `trivia_qa`, `squad`, `bioasq`, `nq`, `svamp`

**Note:** The command automatically computes all metrics and runs comparison analysis. Results are logged to W&B. Check the console output for the W&B run URL.

## 4.5. Run Experiments for All Models and Datasets

For running experiments across multiple models and datasets automatically, use the batch script:

```bash
# Make sure the script is executable (if not already)
chmod +x run_experiments.sh

# Run the script inside the Docker container with entity parameter
./run_experiments.sh --entity your_wandb_entity

# Or set via environment variable
WANDB_SEM_UNC_ENTITY=your_wandb_entity ./run_experiments.sh
```

**What the script does:**
- Iterates through all models and datasets defined in the script
- Automatically generates unique experiment names with timestamps (format: `{model}_{dataset}_{timestamp}`)
- Requires `--entity` parameter or `WANDB_SEM_UNC_ENTITY` environment variable (no default)
- Continues running even if individual experiments fail
- Logs progress for each experiment

**Configure models and datasets:**

Edit `run_experiments.sh` to customize which models and datasets to run:

```bash
# Define models and datasets to run
MODELS=(
    "Mistral-7B-Instruct-v0.1"
    "Llama-2-7b-chat"
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
```

**Example output:**
```
==========================================
Running experiment: Mistral_7B_Instruct_v0_1_trivia_qa_20240101_120000_123456789
Model: Mistral-7B-Instruct-v0.1
Dataset: trivia_qa
==========================================
...
✓ Successfully completed experiment: Mistral_7B_Instruct_v0_1_trivia_qa_20240101_120000_123456789
```

**Note:** The `ENTITY` parameter is required. You must either:
- Pass it via `--entity` command-line argument: `./run_experiments.sh --entity your_wandb_entity`
- Or set it via environment variable: `WANDB_SEM_UNC_ENTITY=your_wandb_entity ./run_experiments.sh`
- Or ensure your `.env` file includes `WANDB_SEM_UNC_ENTITY=your_wandb_entity` and the environment variable is loaded

The script will exit with an error if ENTITY is not provided.

## 5. View Comparison Results

### Option A: W&B Dashboard

1. Go to your W&B project: `https://wandb.ai/your_entity/semantic_uncertainty`
2. Open your run
3. View metrics comparing all methods:
   - `AUROC` - Area under ROC curve
   - `accuracy_at_X_answer_fraction` - Accuracy at different thresholds
   - `area_under_thresholded_accuracy` - Overall calibration

### Option B: Programmatic Analysis

Inside the container, use the provided Jupyter notebook for detailed analysis:

```bash
# Open the example evaluation notebook
jupyter notebook notebooks/example_evaluation.ipynb
```

The notebook includes helper functions to:
- Load results from W&B runs
- Create comparison DataFrames
- Visualize metrics comparing all methods

**Methods compared:**
- Naive Entropy (baseline)
- Semantic entropy (semantic uncertainty approach)
- Discrete Semantic Entropy (cluster assignment entropy)
- Embedding Regression (p_ik baseline)
- p(True) (probability baseline)

