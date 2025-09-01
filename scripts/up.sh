#!/bin/bash

# Start Ollama container
echo "Starting Ollama container..."
docker-compose up -d

echo "Waiting for Ollama to start..."
sleep 5

echo "Ollama is running on port $OLLAMA_PORT"