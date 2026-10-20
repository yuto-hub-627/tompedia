#!/usr/bin/env bash
# Builds the 30s vertical app intro video.
# usage: ./build.sh <assetsDir> <footageDir> <workDir> <out.mp4>
#   assetsDir:  icon.png wordmark.png tonpei_point.png tonpei_trouble.png pop.mp4
#   footageDir: intro.mp4 (とんペディア紹介用) timetable.mp4 kibutsu.mp4 syllabus.mp4 (Figma用 recordings)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
assets="$(cd "$1" && pwd)"; footage="$(cd "$2" && pwd)"; work="$3"; out="$4"
mkdir -p "$work"
W=1080; H=1920; FPS=30
cover="scale=${W}:${H}:force_original_aspect_ratio=increase,crop=${W}:${H},setsar=1"
# phone screen rect inside the overlay's bezel (see .bezel / #veil.hole in overlay.html)
PX=210; PY=170; PW=660; PH=1162
# part of the 1170x2532 recordings shown in the phone: no status bar, no bottom nav
SCREEN_CROP="crop=1170:2060:0:140"

# Edit list: "file start srcDur outDur" — srcDur is sped up/slowed to fit outDur.
# Background behind the veil, 27s after the 3s logo opening.
BG=(
  "intro 0 4 4"            # 3.0–7.0  あるある: home screen
  "intro 6 2 2"            # 7.0–9.0  解決: timetable
  "timetable 7.6 4.5 4.5"  # 9.0–13.5 時間割
  "kibutsu 18.5 7 4.5"     # 13.5–18.0 鬼仏表: results -> detail
  "syllabus 3.2 6 4"       # 18.0–22.0 シラバス検索: form -> results -> detail
  "intro 31 2.8 2.8"       # 22.0–24.8 その他
  "intro 38 2.8 2.8"       # 24.8–27.6 数字
  "intro 42 2.4 2.4"       # 27.6–30.0 締め
)
# Feature segments shown sharp inside the phone: "bgIndex startSec(in final video)"
PHONE=("2 9.0" "3 13.5" "4 18.0")

clip() { # file start srcDur outDur vf out
  local speed; speed=$(python3 -c "print($3/$4)")
  ffmpeg -v error -y -ss "$2" -t "$3" -i "$footage/$1.mp4" -an \
    -vf "setpts=PTS/${speed},fps=${FPS},$5" -t "$4" -c:v libx264 -crf 14 -preset fast -pix_fmt yuv420p "$6"
}

echo "== overlay frames"
rm -rf "$work/frames"
node "$here/render-overlay.mjs" "$assets" "$work/frames" --fps $FPS --duration 30

echo "== background"
: > "$work/bg.txt"
for i in "${!BG[@]}"; do
  read -r f ss sd od <<< "${BG[$i]}"
  blur=""; for p in "${PHONE[@]}"; do [[ "${p%% *}" == "$i" ]] && blur=",gblur=sigma=14"; done
  clip "$f" "$ss" "$sd" "$od" "${cover}${blur}" "$work/bg$i.mp4"
  echo "file 'bg$i.mp4'" >> "$work/bg.txt"
done
ffmpeg -v error -y -f concat -safe 0 -i "$work/bg.txt" -c copy "$work/bg.mp4"

echo "== phone clips"
python3 -I - "$work/mask.png" $PW $PH <<'PY'
import sys
from PIL import Image, ImageDraw
out, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
m = Image.new('L', (w, h), 0)
ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), radius=54, fill=255)
m.save(out)
PY
# 1) phone clips with rounded corners and alpha fades (RGBA .mov)
phone_inputs=(); chain=""; prev="0:v"; n=0
for p in "${PHONE[@]}"; do
  read -r idx at <<< "$p"; read -r f ss sd od <<< "${BG[$idx]}"
  clip "$f" "$ss" "$sd" "$od" "${SCREEN_CROP},scale=${PW}:${PH},setsar=1" "$work/phone$n.mp4"
  fo=$(python3 -c "print($od-0.22)")
  ffmpeg -v error -y -i "$work/phone$n.mp4" -i "$work/mask.png" -filter_complex \
    "[0:v]format=rgba[c];[1:v]format=gray[m];[c][m]alphamerge,fade=t=in:st=0:d=0.22:alpha=1,fade=t=out:st=${fo}:d=0.22:alpha=1" \
    -c:v qtrle "$work/phone$n.mov"
  phone_inputs+=(-itsoffset "$at" -i "$work/phone$n.mov")
  chain+="[$prev][$((n + 1)):v]overlay=${PX}:${PY}:eof_action=pass:format=auto[v$((n + 1))];"
  prev="v$((n + 1))"; n=$((n + 1))
done

echo "== composite"
# 2) base: 3s logo opening + 27s background
ffmpeg -v error -y -i "$assets/pop.mp4" -i "$work/bg.mp4" -filter_complex \
  "[0:v]${cover},fps=${FPS},trim=0:3,setpts=PTS-STARTPTS[a];[1:v]fps=${FPS},setpts=PTS-STARTPTS[b];[a][b]concat=n=2:v=1,format=yuv420p" \
  -c:v libx264 -crf 12 -preset fast "$work/base.mp4"
# 3) phones under the text layer
ffmpeg -v error -y -i "$work/base.mp4" "${phone_inputs[@]}" -filter_complex "${chain%;}" -map "[$prev]" \
  -c:v libx264 -crf 12 -preset fast -pix_fmt yuv420p "$work/with_phones.mp4"
# 4) text / Tonpei / veil layer on top
ffmpeg -v error -y -i "$work/with_phones.mp4" -framerate $FPS -i "$work/frames/%05d.png" \
  -filter_complex "[0:v][1:v]overlay=0:0:format=auto,format=yuv420p[v]" -map "[v]" -t 30 -r $FPS \
  -c:v libx264 -profile:v high -crf 20 -preset slow -movflags +faststart "$out"
ffprobe -v error -show_entries format=duration,size -of compact "$out"
