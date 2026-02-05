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

# Function to download audio using yt-dlp and process with whisper
process_youtube_video() {
  youtube_url=$1
  shift
  
  echo "Downloading audio from: ${youtube_url}"
  
  # Create temporary directory for download
  temp_dir=$(mktemp -d)
  if [ -z "$temp_dir" ] || [ ! -d "$temp_dir" ]; then
    echo "Error: Failed to create temporary directory"
    return 1
  fi
  
  # Download audio using yt-dlp
  # Use best audio format and extract to mp3 with 192k quality
  # Skip problematic dash/hls formats and add User-Agent header
  if ! yt-dlp \
    -f 'bestaudio/best' \
    --extract-audio \
    --audio-format mp3 \
    --audio-quality 192K \
    --extractor-args 'youtube:skip=dash,hls' \
    --user-agent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36' \
    --no-warnings \
    -o "${temp_dir}/audio.%(ext)s" \
    "${youtube_url}"; then
    echo "Error: yt-dlp failed to download audio"
    rm -rf "${temp_dir}"
    return 1
  fi
  
  # Find the downloaded audio file
  # The file should be named audio.* based on our output template
  audio_file=$(ls "${temp_dir}"/audio.* 2>/dev/null | head -n 1)
  
  if [ -z "$audio_file" ] || [ ! -f "$audio_file" ]; then
    echo "Error: Audio file not found after download"
    rm -rf "${temp_dir}"
    return 1
  fi
  
  echo "Audio downloaded to: ${audio_file}"
  
  # Process with go-whisper using the downloaded audio file
  # Unset INPUT_YOUTUBE_URL and set INPUT_AUDIO_PATH
  unset INPUT_YOUTUBE_URL
  export INPUT_AUDIO_PATH="${audio_file}"
  
  # Call go-whisper and capture exit code
  /bin/go-whisper "$@"
  exit_code=$?
  
  # Clean up temporary directory
  rm -rf "${temp_dir}"
  
  return $exit_code
}

# Check if video_list_file is provided
if [ -n "${INPUT_VIDEO_LIST_FILE:-}" ] && [ -f "${INPUT_VIDEO_LIST_FILE}" ]; then
  echo "Processing videos from file: ${INPUT_VIDEO_LIST_FILE}"
  
  # Extract video_ids from JSON file and save to temp file
  # Use grep to find video_id lines, then extract the value
  video_ids_file=$(mktemp)
  grep -o '"video_id": *"[^"]*"' "${INPUT_VIDEO_LIST_FILE}" | cut -d'"' -f4 > "$video_ids_file"
  
  # Process each video_id
  while read -r video_id; do
    if [ -n "$video_id" ]; then
      echo "Processing video: $video_id"
      youtube_url="https://www.youtube.com/watch?v=${video_id}"
      process_youtube_video "${youtube_url}" "$@"
    fi
  done < "$video_ids_file"
  
  rm -f "$video_ids_file"
elif [ -n "${INPUT_YOUTUBE_URL:-}" ]; then
  # Download with yt-dlp and process
  process_youtube_video "${INPUT_YOUTUBE_URL}" "$@"
else
  # Original behavior: process audio file directly
  /bin/go-whisper "$@"
fi
