# Ollama Java Scaffold - Simplified

A simple setup to run Ollama with Docker for Java applications.

## Quick Start

1. **Start Ollama**:
    ```bash
    chmod +x scripts/*.sh
    ./scripts/up.sh
    ```
2. **Download Model**:
    ```bash
    ./scripts/pull-model.sh
    ```

3. **Check Status**:
    ```bash
    ./scripts/check-status.sh
    ```

4. **Run Java Example**:
    ```bash
    cd examples/java-client
    javac SimpleOllamaClient.java
    java SimpleOllamaClient
    ```

## Usage

- `./scripts/up.sh` - Start Ollama container

- `./scripts/down.sh` - Stop Ollama container

- `./scripts/pull-model.sh [model-name]` - Download model (default: llama3)

- `./scripts/check-status.sh` - Check container and model status

## API Endpoint

Ollama API is available at: `http://localhost:11434/api/generate`

## Java Client

See `examples/java-client/SimpleOllamaClient.java` for a basic implementation.
