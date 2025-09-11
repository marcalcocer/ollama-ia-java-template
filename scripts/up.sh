#!/bin/bash

# Default model
DEFAULT_MODEL="llama3"
MODEL=${1:-$DEFAULT_MODEL}

# Function to start Ollama container
function start_container() {
    echo "Starting Ollama container..."
    docker-compose up -d
    
    echo "Waiting for Ollama to become ready..."
    MAX_WAIT=120
    WAIT_TIME=0
    
    while [ $WAIT_TIME -lt $MAX_WAIT ]; do
        # Check if container is running
        if ! docker ps | grep -q "ollama-server"; then
            echo "❌ Container is not running"
            docker logs ollama-server
            exit 1
        fi
        
        # Check if API is responding
        if curl -f "http://localhost:11434/api/tags" > /dev/null 2>&1; then
            echo "✅ Ollama is ready and API is responding!"
            return 0
        fi
        
        echo "⏳ Waiting for Ollama API to respond... ($((MAX_WAIT - WAIT_TIME))s remaining)"
        sleep 5
        WAIT_TIME=$((WAIT_TIME + 5))
        
        # Show logs every 30 seconds for debugging
        if [ $((WAIT_TIME % 30)) -eq 0 ]; then
            echo "📋 Container logs (last 5 lines):"
            docker logs ollama-server --tail 5
        fi
    done
    
    echo "❌ Timeout waiting for Ollama to start"
    docker logs ollama-server
    exit 1
}

# Function to setup configuration
function setup_config() {
    echo "Setting up Ollama configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    ROOT_DIR="$(dirname "$SCRIPT_DIR")"
    CONFIG_FILE="$ROOT_DIR/config/ollama-config.json"
    
    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Detect CPU cores
    CPU_CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "4")
    echo "Detected $CPU_CORES CPU cores"
    
    # Create config file
    cat > "$CONFIG_FILE" << EOF
{
  "num_parallel": 1,
  "num_ctx": 2048,
  "num_batch": 512,
  "num_thread": $CPU_CORES
}
EOF
    
    echo "Configuration created: $CONFIG_FILE"
}

# Function to pull and pre-load model
function setup_model() {
    local model=$1
    echo "Setting up model: $model"
    
    echo "Checking if model '$model' is downloaded..."
    
    # Check if model exists
    if curl -s "http://localhost:11434/api/tags" | grep -q "\"$model\""; then
        echo "✅ Model '$model' already exists"
    else
        echo "📥 Downloading model '$model'..."
        echo "This may take several minutes depending on your internet connection..."
        
        # Pull the model
        curl -X POST "http://localhost:11434/api/pull" -d "{\"name\": \"$model\"}"
        
        if [ $? -eq 0 ]; then
            echo "✅ Model '$model' downloaded successfully"
        else
            echo "❌ Failed to download model '$model'"
            exit 1
        fi
    fi
    
    # Pre-load the model by running a simple prompt
    echo "⚡ Pre-loading model '$model' into memory..."
    curl -s -X POST "http://localhost:11434/api/generate" \
      -H "Content-Type: application/json" \
      -d "{\"model\": \"$model\", \"prompt\": \"Hello\", \"stream\": false}" \
      > /dev/null 2>&1
    
    echo "✅ Model '$model' is now loaded and ready for fast responses!"
}

# Main execution
echo "🚀 Starting Ollama setup for model: $MODEL"

setup_config

start_container

setup_model "$MODEL"

echo "🎉 Ollama is running on port 11434 with model: $MODEL"
echo "💡 Usage: ./scripts/up.sh [model-name]"
echo "💡 Example: ./scripts/up.sh llama3:8b-instruct-q4_0"