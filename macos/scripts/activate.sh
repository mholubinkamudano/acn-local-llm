#!/bin/bash

# Local Llama Server

# Starts the llama.cpp with the specified model
# Uses Metal GPU for inference


# configure paths and settings
LLAMA_SERVER="$HOME/git/llama.cpp/llama-cpp-metal/bin/llama-server"
MODEL_PATH="$HOME/.models/Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf"

GPU_LAYERS=99          # offloads all layers to Metal GPU
CONTEXT_SIZE=4096      # offloads context window size
THREADS=6              # cpu threads (M3 Pro: 6 performance cores)
HOST="0.0.0.0"
PORT=8080

if [ ! -f "$MODEL_PATH" ]; then
    echo "✗ Model not found at $MODEL_PATH"
    echo "  Download it with:"
    echo "  hf download bartowski/Meta-Llama-3.1-8B-Instruct-GGUF \\"
    echo "    Meta-Llama-3.1-8B-Instruct-Q5_K_M.gguf --local-dir ~/.models"
    exit 1
fi

if [ ! -f "$LLAMA_SERVER" ]; then
    echo "✗ llama-server not found at $LLAMA_SERVER"
    echo "  Build it with:"
    echo "  cd ~/llama.cpp && cmake -B build -DGGML_METAL=ON && cmake --build build --config Release"
    exit 1
fi

echo "Starting llama.cpp server..."
echo "  Model:   $MODEL_PATH"
echo "  API:     http://$HOST:$PORT/v1"
echo "  Threads: $THREADS | GPU Layers: $GPU_LAYERS | Context: $CONTEXT_SIZE"
echo ""

$LLAMA_SERVER \
    -m "$MODEL_PATH" \
    -ngl $GPU_LAYERS \
    -c $CONTEXT_SIZE \
    -t $THREADS \
    -fa on \
    --host $HOST \
    --port $PORT