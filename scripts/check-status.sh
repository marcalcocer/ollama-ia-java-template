#!/bin/bash

# Check container status
if docker ps | grep -q "ollama-llama3"; then
    echo "✅ Ollama container is running"
    
    # Check model status
    echo "Available models:"
    docker exec ollama-llama3 ollama list
else
    echo "❌ Ollama container is not running"
    echo "Run: ./scripts/up.sh"
fi