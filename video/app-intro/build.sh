#!/usr/bin/env bash
# Builds the 30s vertical app intro video.
# usage: ./build.sh <assetsDir> <workDir> <out.mp4> [appFootage.mp4 "start:dur start:dur ..."]
#   assetsDir needs: icon.png wordmark.png tonpei_point.png tonpei_trouble.png pop.mp4 screens/*
#   Without appFootage, a placeholder background is made from screens/*.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
assets="$(cd "$1" && pwd)"; work="$2"; out="$3"; footage="${4:-}"; segments="${5:-}"
mkdir -p "$work"
W=1080; H=1920; FPS=30
cover="scale=${W}:${H}:force_original_aspect_ratio=increase,crop=${W}:${H},setsar=1,fps=${FPS}"

echo "== overlay frames"
rm -rf "$work/frames"
node "$here/render-overlay.mjs" "$assets" "$work/frames" --fps $FPS --duration 30

echo "== background (27s)"
if [[ -n "$footage" ]]; then
  # cut the requested segments of the app screen recording and join them
  i=0; list="$work/segs.txt"; : > "$list"
  for seg in $segments; do
    ss="${seg%%:*}"; d="${seg##*:}"
    ffmpeg -v error -y -ss "$ss" -t "$d" -i "$footage" -an -vf "$cover" -c:v libx264 -crf 16 -preset fast "$work/seg$i.mp4"
    echo "file 'seg$i.mp4'" >> "$list"; i=$((i+1))
  done
  ffmpeg -v error -y -f concat -safe 0 -i "$list" -t 27 -c copy "$work/bg.mp4"
else
  i=0; list="$work/segs.txt"; : > "$list"
  for img in "$assets"/screens/*; do
    ffmpeg -v error -y -loop 1 -t 4.5 -i "$img" \
      -vf "scale=${W}:-2,crop=${W}:${H}:0:'min(ih-${H},t/4.5*(ih-${H}))',setsar=1,fps=${FPS}" \
      -c:v libx264 -crf 16 -preset fast -pix_fmt yuv420p "$work/seg$i.mp4"
    echo "file 'seg$i.mp4'" >> "$list"; i=$((i+1))
  done
  ffmpeg -v error -y -f concat -safe 0 -i "$list" -t 27 -c copy "$work/bg.mp4"
fi

echo "== composite"
ffmpeg -v error -y \
  -i "$assets/pop.mp4" -i "$work/bg.mp4" -framerate $FPS -i "$work/frames/%05d.png" \
  -filter_complex "[0:v]${cover},trim=0:3,setpts=PTS-STARTPTS[a];[1:v]${cover},trim=0:27,setpts=PTS-STARTPTS[b];[a][b]concat=n=2:v=1[base];[base][2:v]overlay=0:0:format=auto,format=yuv420p[v]" \
  -map "[v]" -t 30 -r $FPS -c:v libx264 -profile:v high -crf 20 -preset slow -movflags +faststart "$out"
ffprobe -v error -show_entries format=duration,size -of compact "$out"
