#!/bin/bash

# Switch to a different model without restarting the container
if [ $# -eq 0 ]; then
    echo "Usage: ./scripts/use-model.sh <model-name>"
    echo "Example: ./scripts/use-model.sh llama3:8b-instruct-q4_0"
    exit 1
fi

MODEL=$1

echo "Switching to model: $MODEL"

# Check if container is running
if ! docker ps | grep -q "ollama-server"; then
    echo "❌ Ollama container is not running"
    echo "Please start it first with: ./scripts/up.sh"
    exit 1
fi

# Check if API is responding
if ! curl -f "http://localhost:11434/api/tags" > /dev/null 2>&1; then
    echo "❌ Ollama API is not responding"
    exit 1
fi

# Setup the new model
echo "Setting up model: $MODEL"

# Check if model exists
if curl -s "http://localhost:11434/api/tags" | grep -q "\"$MODEL\""; then
    echo "✅ Model '$MODEL' already exists"
else
    echo "📥 Downloading model '$MODEL'..."
    curl -X POST "http://localhost:11434/api/pull" -d "{\"name\": \"$MODEL\"}"
    
    if [ $? -eq 0 ]; then
        echo "✅ Model '$MODEL' downloaded successfully"
    else
        echo "❌ Failed to download model '$MODEL'"
        exit 1
    fi
fi

# Pre-load the new model
echo "⚡ Pre-loading model '$MODEL' into memory..."
curl -s -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"$MODEL\", \"prompt\": \"Hello\", \"stream\": false}" \
  > /dev/null 2>&1

echo "✅ Switched to model: $MODEL"
echo "💡 Now using: $MODEL for all API requests"