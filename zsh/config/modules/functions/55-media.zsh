# ===============================
# MEDIA FUNCTIONS
# ===============================

# Compress video with x264 for archival
# Converts any video to H264/AAC MP4 with quality-based encoding
if zdotfiles_has_command ffmpeg; then
  compress-video() {
    [[ $# -eq 0 ]] && { echo "Usage: compress-video <input-file>" >&2; return 1; }
    [[ ! -f "$1" ]] && { echo "File not found: $1" >&2; return 1; }
    ffmpeg -i "$1" -c:v libx264 -crf 23 -preset slow -c:a aac -b:a 128k -movflags +faststart "${1%.*}.mp4"
  }
fi
