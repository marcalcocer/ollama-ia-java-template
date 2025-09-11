#!/bin/bash

# Pull and pre-load the model
MODEL=${1:-llama3}

echo "Checking if model '$MODEL' is downloaded..."

# Check if model exists
if curl -s "http://localhost:11434/api/tags" | grep -q "\"$MODEL\""; then
    echo "✅ Model '$MODEL' already exists"
else
    echo "📥 Downloading model '$MODEL'..."
    echo "This may take several minutes depending on your internet connection..."
    
    # Pull the model
    curl -X POST "http://localhost:11434/api/pull" -d "{\"name\": \"$MODEL\"}"
    
    if [ $? -eq 0 ]; then
        echo "✅ Model '$MODEL' downloaded successfully"
    else
        echo "❌ Failed to download model '$MODEL'"
        exit 1
    fi
fi

# Pre-load the model by running a simple prompt
echo "⚡ Pre-loading model '$MODEL' into memory..."
curl -s -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"$MODEL\", \"prompt\": \"Hello\", \"stream\": false}" \
  > /dev/null 2>&1

echo "✅ Model '$MODEL' is now loaded and ready for fast responses!"