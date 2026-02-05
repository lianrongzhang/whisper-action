FROM ghcr.io/appleboy/go-whisper:1.3.0

# Install yt-dlp for downloading YouTube audio
RUN apk add --no-cache yt-dlp

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
