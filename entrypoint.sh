#!/bin/sh

set -eu

model=${INPUT_MODEL:-"small"}

[ -d models ] || mkdir -p models

case "$model" in
  small) [ -f "models/ggml-small.bin" ] || curl -LJ https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.bin \
      --output models/ggml-small.bin
      export INPUT_MODEL=models/ggml-small.bin
    ;;
  medium) [ -f "models/ggml-medium.bin" ] || curl -LJ https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin \
      --output models/ggml-medium.bin
      export INPUT_MODEL=models/ggml-medium.bin
    ;;
  large) [ -f "models/ggml-large.bin" ] || curl -LJ https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin \
      --output models/ggml-large.bin
      export INPUT_MODEL=models/ggml-large.bin
    ;;
  large-v1) [ -f "models/ggml-large-v1.bin" ] || curl -LJ https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v1.bin \
      --output models/ggml-large-v1.bin
      export INPUT_MODEL=models/ggml-large-v1.bin
    ;;
  large-v2) [ -f "models/ggml-large-v2.bin" ] || curl -LJ https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v2.bin \
      --output models/ggml-large-v2.bin
      export INPUT_MODEL=models/ggml-large-v2.bin
    ;;
esac

# Check if video_list_file is provided
if [ -n "${INPUT_VIDEO_LIST_FILE:-}" ] && [ -f "${INPUT_VIDEO_LIST_FILE}" ]; then
  echo "Processing videos from file: ${INPUT_VIDEO_LIST_FILE}"
  
  # Extract video_ids from JSON file and process each one
  # Use grep to find video_id lines, then extract the value
  grep -o '"video_id": *"[^"]*"' "${INPUT_VIDEO_LIST_FILE}" | cut -d'"' -f4 | while read -r video_id; do
    if [ -n "$video_id" ]; then
      echo "Processing video: $video_id"
      export INPUT_YOUTUBE_URL="https://www.youtube.com/watch?v=${video_id}"
      sh -c "/bin/go-whisper $*"
    fi
  done
else
  # Original behavior: process single video
  sh -c "/bin/go-whisper $*"
fi
