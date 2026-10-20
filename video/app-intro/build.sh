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
PX=250; PY=165; PW=580; PH=1186
# part of the 1170x2532 recordings shown in the phone: everything below the status bar
SCREEN_CROP="crop=1170:2392:0:140"

# Edit list: "file start srcDur outDur" — srcDur is sped up/slowed to fit outDur.
# Background behind the veil, 27s after the 3s logo opening.
BG=(
  "intro 0 3.6 3.6"            # 3.0–6.6   あるある: home screen
  "intro 6 1.8 1.8"            # 6.6–8.4   解決: timetable
  "timetable 7.6 4.08 4.8"     # 8.4–13.2  時間割 (0.85x)
  "kibutsu 20.5 4.32 4.8"      # 13.2–18.0 鬼仏表: results -> detail (0.9x)
  "syllabus 3.6 4.0 4.8"       # 18.0–22.8 シラバス検索: form -> results -> detail (0.83x)
  "intro 31 2.6 2.6"           # 22.8–25.4 その他
  "intro 38 2.4 2.4"           # 25.4–27.8 数字
  "intro 42 2.2 2.2"           # 27.8–30.0 締め
)
# Feature segments shown sharp inside the phone: "bgIndex startSec(in final video) navMode"
# The Figma用 recordings predate the current bottom nav, so the latest one (from intro.mp4) is pasted over it.
#   value = y to paste the new nav at. The 鬼仏表/シラバス検索 recordings' old nav sits where the new one
#   goes (2236); the 時間割 recording's starts 42px higher, so paste it there (only white is left below it)
PHONE=("2 8.4 2194" "3 13.2 2236" "4 18.0 2236")

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
# latest bottom nav (ホーム/トピックス/時間割/イベント/アカウント, nothing selected) from intro.mp4 at 8s:
# shadow + white bar from y=2236 down; the round 時間割 button spans y 2238-2399
NAV_Y=2236
ffmpeg -v error -y -ss 8 -i "$footage/intro.mp4" -frames:v 1 -vf "crop=1170:2532-${NAV_Y}:0:${NAV_Y}" "$work/navbar.png"

# 1) phone clips with rounded corners and alpha fades (RGBA .mov)
phone_inputs=(); chain=""; prev="0:v"; n=0
for p in "${PHONE[@]}"; do
  read -r idx at navy <<< "$p"; read -r f ss sd od <<< "${BG[$idx]}"
  clip "$f" "$ss" "$sd" "$od" "setsar=1" "$work/phone${n}_raw.mp4"
  ffmpeg -v error -y -i "$work/phone${n}_raw.mp4" -i "$work/navbar.png" -filter_complex \
    "[0:v][1:v]overlay=0:${navy},${SCREEN_CROP},scale=${PW}:${PH},setsar=1,format=yuv420p" \
    -c:v libx264 -crf 14 -preset fast "$work/phone$n.mp4"
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
# 4) sound effects, cued from the overlay's timeline
python3 -I "$here/sfx.py" "$work/frames/sfx_cues.json" "$work/sfx.wav" 30
# 5) text / Tonpei / veil layer on top, plus audio
ffmpeg -v error -y -i "$work/with_phones.mp4" -framerate $FPS -i "$work/frames/%05d.png" -i "$work/sfx.wav" \
  -filter_complex "[0:v][1:v]overlay=0:0:format=auto,format=yuv420p[v]" -map "[v]" -map 2:a -t 30 -r $FPS \
  -c:v libx264 -profile:v high -crf 20 -preset slow -c:a aac -b:a 160k -movflags +faststart "$out"
ffprobe -v error -show_entries format=duration,size -of compact "$out"
