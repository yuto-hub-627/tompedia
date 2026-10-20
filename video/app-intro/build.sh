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
  "intro 13 4.8 4.8"           # 18.0–22.8 シラバス検索: a syllabus page opening and scrolling (1x)
  "intro 31 2.6 2.6"           # 22.8–25.4 その他
  "intro 38 2.4 2.4"           # 25.4–27.8 数字
  "intro 42 2.2 2.2"           # 27.8–30.0 締め
)
# Feature segments shown sharp inside the phone: "bgIndex navY"
# The Figma用 recordings predate the current bottom nav, so the latest one (from intro.mp4) is pasted over
# it at navY. The 鬼仏表 recording's old nav sits where the new one goes (2236); the 時間割 recording's starts
# 42px higher, so paste it there (only white is left below it). "-" = already has the latest nav.
PHONE=("2 2194" "3 2236" "4 -")
PHONE_START=8.4   # the phone track runs continuously over the three feature scenes
XF=0.4            # crossfade length between consecutive clips (no hard cuts)

clip() { # file start srcDur outDur vf out
  local speed; speed=$(python3 -c "print($3/$4)")
  ffmpeg -v error -y -ss "$2" -t "$3" -i "$footage/$1.mp4" -an \
    -vf "setpts=PTS/${speed},fps=${FPS},$5" -t "$4" -c:v libx264 -crf 14 -preset fast -pix_fmt yuv420p "$6"
}
# clip extended by XF (same speed) so the next clip can crossfade over its tail
clip_xf() { # file start srcDur outDur extend vf out
  if [[ "$5" == 1 ]]; then
    clip "$1" "$2" "$(python3 -c "print($3*($4+$XF)/$4)")" "$(python3 -c "print($4+$XF)")" "$6" "$7"
  else
    clip "$1" "$2" "$3" "$4" "$6" "$7"
  fi
}
# crossfade a list of clips back to back; each one starts at the running sum of the outDurs
xfade_chain() { # out transition outDur... (inputs: "$work/xf_in$i.mp4")
  local out="$1" tr="$2"; shift 2
  local inputs=() filter="" prev="0:v" t=0 i=0
  for d in "$@"; do inputs+=(-i "$work/xf_in$i.mp4"); i=$((i + 1)); done
  for ((k = 1; k < i; k++)); do
    t=$(python3 -c "print($t+${!k})")
    filter+="[$prev][$k:v]xfade=transition=${tr}:duration=${XF}:offset=${t}[x$k];"; prev="x$k"
  done
  ffmpeg -v error -y "${inputs[@]}" -filter_complex "${filter%;}" -map "[$prev]" \
    -c:v libx264 -crf 12 -preset fast -pix_fmt yuv420p "$out"
}

echo "== overlay frames"
rm -rf "$work/frames"
node "$here/render-overlay.mjs" "$assets" "$work/frames" --fps $FPS --duration 30

echo "== background"
durs=()
for i in "${!BG[@]}"; do
  read -r f ss sd od <<< "${BG[$i]}"
  blur=""; for p in "${PHONE[@]}"; do [[ "${p%% *}" == "$i" ]] && blur=",gblur=sigma=14"; done
  ext=$(( i < ${#BG[@]} - 1 ? 1 : 0 ))
  clip_xf "$f" "$ss" "$sd" "$od" $ext "${cover}${blur}" "$work/xf_in$i.mp4"
  durs+=("$od")
done
xfade_chain "$work/bg.mp4" fade "${durs[@]}"

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

# 1) one continuous phone track: the feature clips crossfaded into each other, then rounded and faded in/out
durs=(); total=0
for n in "${!PHONE[@]}"; do
  read -r idx navy <<< "${PHONE[$n]}"; read -r f ss sd od <<< "${BG[$idx]}"
  ext=$(( n < ${#PHONE[@]} - 1 ? 1 : 0 ))
  clip_xf "$f" "$ss" "$sd" "$od" $ext "setsar=1" "$work/phone${n}_raw.mp4"
  nav=""; [[ "$navy" != - ]] && nav="[1:v]overlay=0:${navy},"
  ffmpeg -v error -y -i "$work/phone${n}_raw.mp4" -i "$work/navbar.png" -filter_complex \
    "[0:v]${nav}${SCREEN_CROP},scale=${PW}:${PH},setsar=1,format=yuv420p" \
    -c:v libx264 -crf 12 -preset fast "$work/xf_in$n.mp4"
  durs+=("$od"); total=$(python3 -c "print($total+$od)")
done
# features swipe to the left like pages, in step with the description card in overlay.html
xfade_chain "$work/phones.mp4" slideleft "${durs[@]}"
fo=$(python3 -c "print($total-0.35)")
ffmpeg -v error -y -i "$work/phones.mp4" -loop 1 -i "$work/mask.png" -filter_complex \
  "[0:v]format=rgba[c];[1:v]format=gray[m];[c][m]alphamerge=shortest=1,fade=t=in:st=0:d=0.35:alpha=1,fade=t=out:st=${fo}:d=0.35:alpha=1" \
  -t "$total" -c:v qtrle "$work/phones.mov"

echo "== composite"
# 2) base: 3s logo opening (last frame held for the crossfade) + 27s background
ffmpeg -v error -y -i "$assets/pop.mp4" -i "$work/bg.mp4" -filter_complex \
  "[0:v]${cover},fps=${FPS},trim=0:3,setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop_duration=${XF},format=yuv420p[a];[1:v]fps=${FPS},setpts=PTS-STARTPTS,format=yuv420p[b];[a][b]xfade=transition=fade:duration=${XF}:offset=3" \
  -c:v libx264 -crf 12 -preset fast -pix_fmt yuv420p "$work/base.mp4"
# 3) phone track under the text layer
ffmpeg -v error -y -i "$work/base.mp4" -itsoffset "$PHONE_START" -i "$work/phones.mov" \
  -filter_complex "[0:v][1:v]overlay=${PX}:${PY}:eof_action=pass:format=auto,format=yuv420p" \
  -c:v libx264 -crf 12 -preset fast "$work/with_phones.mp4"
# 4) sound effects, cued from the overlay's timeline
python3 -I "$here/sfx.py" "$work/frames/sfx_cues.json" "$work/sfx.wav" 30
# 5) text / Tonpei / veil layer on top, plus audio
ffmpeg -v error -y -i "$work/with_phones.mp4" -framerate $FPS -i "$work/frames/%05d.png" -i "$work/sfx.wav" \
  -filter_complex "[0:v][1:v]overlay=0:0:format=auto,format=yuv420p[v]" -map "[v]" -map 2:a -t 30 -r $FPS \
  -c:v libx264 -profile:v high -crf 20 -preset slow -c:a aac -b:a 160k -movflags +faststart "$out"
ffprobe -v error -show_entries format=duration,size -of compact "$out"
