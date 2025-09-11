#!/bin/bash

# Test prompts against Ollama models
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$(dirname "$SCRIPT_DIR")/prompts"

# Default values
MODEL="llama3:latest"
PROMPT="Hello, how are you?"
PROMPT_FILE=""
OUTPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -p|--prompt)
            PROMPT="$2"
            shift 2
            ;;
        -f|--file)
            PROMPT_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -l|--list)
            echo "Available prompt files:"
            find "$PROMPTS_DIR" -name "*.txt" -exec basename {} .txt \; | sort
            exit 0
            ;;
        -h|--help)
            echo "Usage: ./scripts/prompt-test.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -m, --model MODEL    Model to use (default: llama3)"
            echo "  -p, --prompt TEXT    Prompt text to send"
            echo "  -f, --file FILE      Load prompt from file in prompts/"
            echo "  -o, --output FILE    Save output to file"
            echo "  -l, --list           List available prompt files"
            echo "  -h, --help           Show this help"
            echo ""
            echo "Examples:"
            echo "  ./scripts/prompt-test.sh -m llama3 -p \"Hello world\""
            echo "  ./scripts/prompt-test.sh -m mistral -f creative-writing"
            echo "  ./scripts/prompt-test.sh -m phi3:mini -f coding-help -o result.txt"
            exit 0
            ;;
        *)
            # Handle positional arguments (for backward compatibility)
            if [[ "$1" == -* ]]; then
                echo "❌ Unknown option: $1"
                exit 1
            else
                # If it's not an option, treat it as a prompt
                PROMPT="$1"
                shift
            fi
            ;;
    esac
done

# Load prompt from file if specified
if [ -n "$PROMPT_FILE" ]; then
    if [ -f "$PROMPTS_DIR/$PROMPT_FILE.txt" ]; then
        PROMPT=$(cat "$PROMPTS_DIR/$PROMPT_FILE.txt")
    elif [ -f "$PROMPTS_DIR/examples/$PROMPT_FILE.txt" ]; then
        PROMPT=$(cat "$PROMPTS_DIR/examples/$PROMPT_FILE.txt")
    else
        echo "❌ Prompt file not found: $PROMPT_FILE"
        echo "💡 Available files:"
        find "$PROMPTS_DIR" -name "*.txt" -exec basename {} .txt \; | sort
        exit 1
    fi
fi

# Check if Ollama is running
if ! docker ps | grep -q "ollama-server"; then
    echo "❌ Ollama container is not running"
    echo "💡 Start it with: ./scripts/up.sh"
    exit 1
fi

# Check if model exists
if ! curl -s "http://localhost:11434/api/tags" | grep -q "\"$MODEL\""; then
    echo "❌ Model '$MODEL' not found"
    echo "💡 Available models:"
    ./scripts/model-info.sh
    exit 1
fi

echo "🚀 Testing prompt with model: $MODEL"
echo "📝 Prompt: $(echo "$PROMPT" | head -1 | cut -c1-50)..."
echo "----------------------------------------"

# Send the prompt and measure time
START_TIME=$(date +%s%N)

# Escape JSON special characters in the prompt
ESCAPED_PROMPT=$(echo "$PROMPT" | sed 's/"/\\"/g' | sed 's/\\/\\\\/g')

RESPONSE=$(curl -s -X POST "http://localhost:11434/api/generate" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"$MODEL\",
    \"prompt\": \"$ESCAPED_PROMPT\",
    \"stream\": false
  }")

END_TIME=$(date +%s%N)
DURATION_MS=$((($END_TIME - $START_TIME) / 1000000))

# Parse the response
if [ $? -eq 0 ] && [ -n "$RESPONSE" ]; then
    # Extract response text
    RESPONSE_TEXT=$(echo "$RESPONSE" | grep -o '"response":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$RESPONSE_TEXT" ]; then
        echo "❌ Failed to parse response:"
        echo "$RESPONSE"
        exit 1
    fi
    
    # Extract timing information
    TOTAL_DURATION=$(echo "$RESPONSE" | grep -o '"total_duration":[0-9]*' | cut -d: -f2)
    LOAD_DURATION=$(echo "$RESPONSE" | grep -o '"load_duration":[0-9]*' | cut -d: -f2)
    EVAL_DURATION=$(echo "$RESPONSE" | grep -o '"eval_duration":[0-9]*' | cut -d: -f2)
    EVAL_COUNT=$(echo "$RESPONSE" | grep -o '"eval_count":[0-9]*' | cut -d: -f2)
    
    # Convert nanoseconds to milliseconds
    TOTAL_MS=$((${TOTAL_DURATION:-0} / 1000000))
    LOAD_MS=$((${LOAD_DURATION:-0} / 1000000))
    EVAL_MS=$((${EVAL_DURATION:-0} / 1000000))
    
    # Calculate tokens per second
    if [ -n "$EVAL_COUNT" ] && [ "$EVAL_MS" -gt 0 ]; then
        TOKENS_PER_SEC=$(echo "scale=2; $EVAL_COUNT * 1000 / $EVAL_MS" | bc)
    else
        TOKENS_PER_SEC="N/A"
    fi
    
    # Display results
    echo "✅ Response:"
    echo "$RESPONSE_TEXT"
    echo ""
    echo "📊 Performance:"
    echo "• Total time: ${TOTAL_MS}ms (curl: ${DURATION_MS}ms)"
    echo "• Load time: ${LOAD_MS}ms"
    echo "• Generation time: ${EVAL_MS}ms"
    echo "• Tokens generated: ${EVAL_COUNT}"
    echo "• Tokens/second: ${TOKENS_PER_SEC}"
    
    # Save to file if requested
    if [ -n "$OUTPUT_FILE" ]; then
        mkdir -p "$(dirname "$OUTPUT_FILE")"
        echo "# Prompt: $PROMPT" > "$OUTPUT_FILE"
        echo "# Model: $MODEL" >> "$OUTPUT_FILE"
        echo "# Timestamp: $(date)" >> "$OUTPUT_FILE"
        echo "----------------------------------------" >> "$OUTPUT_FILE"
        echo "$RESPONSE_TEXT" >> "$OUTPUT_FILE"
        echo "----------------------------------------" >> "$OUTPUT_FILE"
        echo "# Performance: Total: ${TOTAL_MS}ms, Load: ${LOAD_MS}ms, Gen: ${EVAL_MS}ms" >> "$OUTPUT_FILE"
        echo "# Tokens: ${EVAL_COUNT}, Speed: ${TOKENS_PER_SEC} tokens/sec" >> "$OUTPUT_FILE"
        echo "✅ Output saved to: $OUTPUT_FILE"
    fi
    
else
    echo "❌ Error sending prompt to Ollama"
    if [ -n "$RESPONSE" ]; then
        echo "$RESPONSE"
    else
        echo "No response received from server"
    fi
    exit 1
fi