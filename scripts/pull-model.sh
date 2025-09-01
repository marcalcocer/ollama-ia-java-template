#!/bin/bash

# Pull the model if not already downloaded
MODEL=${1:-llama3}

echo "Checking if model '$MODEL' is downloaded..."

# Check if model exists
if docker exec ollama-llama3 ollama list | grep -q "$MODEL"; then
    echo "Model '$MODEL' already exists"
else
    echo "Downloading model '$MODEL'..."
    docker exec ollama-llama3 ollama pull "$MODEL"
    echo "Model '$MODEL' downloaded successfully"
fi