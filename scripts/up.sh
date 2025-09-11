#!/bin/bash

# Start Ollama container
echo "Starting Ollama container..."
docker-compose up -d

echo "Waiting for Ollama to become ready..."
MAX_WAIT=120
WAIT_TIME=0

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    # Check if container is running
    if ! docker ps | grep -q "ollama-llama3"; then
        echo "❌ Container is not running"
        docker logs ollama-llama3
        exit 1
    fi
    
    # Check if API is responding (from host perspective)
    if curl -f "http://localhost:11434/api/tags" > /dev/null 2>&1; then
        echo "✅ Ollama is ready and API is responding!"
        break
    fi
    
    echo "⏳ Waiting for Ollama API to respond... ($((MAX_WAIT - WAIT_TIME))s remaining)"
    sleep 5
    WAIT_TIME=$((WAIT_TIME + 5))
    
    # Show logs every 30 seconds for debugging
    if [ $((WAIT_TIME % 30)) -eq 0 ]; then
        echo "📋 Container logs (last 5 lines):"
        docker logs ollama-llama3 --tail 5
    fi
done

if [ $WAIT_TIME -ge $MAX_WAIT ]; then
    echo "❌ Timeout waiting for Ollama to start"
    echo "Full container logs:"
    docker logs ollama-llama3
    exit 1
fi

# Pre-load the model after Ollama is ready
echo "Pre-loading model for faster response times..."
./scripts/pull-model.sh

echo "Ollama is running on port 11434 and ready for fast requests!"