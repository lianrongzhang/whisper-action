FROM ghcr.io/appleboy/go-whisper:1.3.0

# Install yt-dlp and ffmpeg for downloading and converting YouTube audio
RUN apt-get update && apt-get install -y yt-dlp ffmpeg && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
