#!/bin/bash

# Show information about current models
echo "📊 Current Ollama Models"
echo "========================"

# Check if container is running
if ! docker ps | grep -q "ollama-server"; then
    echo "❌ Ollama container is not running"
    exit 1
fi

# Check if API is responding
if ! curl -f "http://localhost:11434/api/tags" > /dev/null 2>&1; then
    echo "❌ Ollama API is not responding"
    exit 1
fi

# Get model information
echo "Available models:"
echo "----------------"
curl -s "http://localhost:11434/api/tags" | \
  jq -r '.models[] | "• \(.name) (\(.details.parameter_size), \(.details.quantization_level)) - \(.size / (1024*1024*1024) | round) GB"'

echo ""
echo "Container status:"
echo "----------------"
docker ps --filter "name=ollama-server" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"