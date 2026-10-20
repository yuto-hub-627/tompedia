#!/usr/bin/env bash
# Builds the Giving Campaign (GC) version: the normal intro video plus a white end card
# (gc-card.html) that crossfades in after it. The normal video itself is left as is.
# usage: ./build-gc.sh <assetsDir> <normal.mp4> <workDir> <out.mp4>
#   assetsDir needs: labo_logo.png (とんペディア_ラボ logo), gc_post.png (Canva GC post, 1080x1350)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
assets="$(cd "$1" && pwd)"; normal="$2"; work="$3"; out="$4"
mkdir -p "$work"
FPS=30; CARD=3.5; XF=0.4
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$normal")
start=$(python3 -c "print(round($dur-$XF, 3))")   # card fades in over the last XF seconds of the video
total=$(python3 -c "print(round($start+$CARD, 3))")

echo "== card frames"
rm -rf "$work/card"
node "$here/render-overlay.mjs" "$assets" "$work/card" --page gc-card.html --opaque --fps $FPS --duration $CARD

echo "== card audio (chime as the card appears)"
python3 -I - "$work/card/sfx_cues.json" "$start" "$work/cues.json" <<'PY'
import json, sys
cues, start, out = sys.argv[1], float(sys.argv[2]), sys.argv[3]
json.dump([[round(start + t, 3), n, g, p] for t, n, g, p in json.load(open(cues))], open(out, 'w'))
PY
cat > "$work/samples.json" <<JSON
{"chime": ["$here/sfx/confirmation_004.ogg"], "sparkle": ["$here/sfx/glass_004.ogg"]}
JSON
python3 -I "$here/sfx.py" "$work/cues.json" "$work/samples.json" "$work/card_sfx.wav" "$total"

echo "== composite"
ffmpeg -v error -y -i "$normal" -framerate $FPS -i "$work/card/%05d.png" -i "$work/card_sfx.wav" -filter_complex \
  "[0:v]fps=$FPS,format=yuv420p[a];[1:v]fps=$FPS,format=yuv420p[b];[a][b]xfade=transition=fade:duration=$XF:offset=$start,format=yuv420p[v];\
[0:a]apad=whole_dur=$total[na];[2:a]volume=0.5[ca];[na][ca]amix=inputs=2:normalize=0:duration=first[aout]" \
  -map "[v]" -map "[aout]" -t "$total" -c:v libx264 -profile:v high -crf 20 -preset slow -c:a aac -b:a 160k -movflags +faststart "$out"
ffprobe -v error -show_entries format=duration,size -of compact "$out"
