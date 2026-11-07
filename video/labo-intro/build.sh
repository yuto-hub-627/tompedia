#!/usr/bin/env bash
# Builds the vertical Tompedia Labo intro video (OPEN + 31.2s; 33.0s with the default 1.8s opening).
# usage: ./build.sh <assetsDir> <footageDir> <workDir> <out.mp4>
#   assetsDir: labo_logo.png wordmark.png tonpei_*.png
#              reports/r1..r8.png  (event report covers, exported from Canva)
#              photos/p1a p1b p1c p2a p2b p3 p4 p5 p6 .jpg  (missing ones render as labelled stand-ins)
#              narr/n1..n7.<any audio>  (narration N1..N7 in the storyboard; missing ones are silent)
#   footageDir: intro.mp4 (とんペディア紹介用, the app recording shown in the phone)
# Shares render-overlay.mjs and sfx.py with ../app-intro. BGM and the GC card are added afterwards with
# ../app-intro/add-bgm.sh (music starts at OPEN + 3.0, when the slogan gives way) and ../app-intro/build-gc.sh.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"; app="$here/../app-intro"
assets="$(cd "$1" && pwd)"; footage="$(cd "$2" && pwd)"; work="$3"; out="$4"
mkdir -p "$work"
W=1080; H=1920; FPS=30
OPEN=${OPEN:-1.8}   # length of the logo opening; passed to overlay.html
DURATION=$(python3 -c "print($OPEN + 31.2)")   # = the end of S.end in overlay.html
# phone screen rect in the app scene (see #bezel / #sc-app.hole in overlay.html)
PX=305; PY=430; PW=470; PH=962
SCREEN_CROP="crop=1170:2392:0:140"   # the recording below the status bar
APP_START=$(python3 -c "print($OPEN + 14.5 - 0.3)")   # app scene starts at OPEN+14.5 and fades in over 0.3s
APP_LEN=6.1

echo "== overlay frames"
rm -rf "$work/frames"
node "$app/render-overlay.mjs" "$assets" "$work/frames" --page ../labo-intro/overlay.html \
  --fps $FPS --duration $DURATION --query open=$OPEN

echo "== phone clip"
python3 -I - "$work/mask.png" $PW $PH <<'PY'
import sys
from PIL import Image, ImageDraw
out, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
m = Image.new('L', (w, h), 0)
ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), radius=46, fill=255)
m.save(out)
PY
ffmpeg -v error -y -ss 0 -t $APP_LEN -i "$footage/intro.mp4" -loop 1 -i "$work/mask.png" -filter_complex \
  "[0:v]fps=${FPS},${SCREEN_CROP},scale=${PW}:${PH},setsar=1,format=rgba[c];[1:v]format=gray[m];[c][m]alphamerge=shortest=1" \
  -t $APP_LEN -c:v qtrle "$work/phone.mov"

echo "== base"
# black canvas; the phone shows through the hole in the app scene
ffmpeg -v error -y -f lavfi -i "color=c=black:s=${W}x${H}:r=${FPS}:d=${DURATION}" -itsoffset "$APP_START" -i "$work/phone.mov" \
  -filter_complex "[0:v][1:v]overlay=${PX}:${PY}:eof_action=pass:format=auto,format=yuv420p" \
  -c:v libx264 -crf 12 -preset fast "$work/base.mp4"

echo "== audio"
# narration: trim silence at both ends, cut rumble, light denoise, even out with a compressor
mkdir -p "$work/narr"
for n in 1 2 3 4 5 6 7; do
  src=$(ls "$assets"/narr/n$n.* 2>/dev/null | head -1 || true)
  if [[ -n "$src" ]]; then
    ffmpeg -v error -y -i "$src" -ac 1 -ar 48000 -af \
      "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.1,areverse,highpass=f=80,afftdn=nf=-50,equalizer=f=250:t=q:w=1:g=-2,equalizer=f=3200:t=q:w=1:g=2,acompressor=threshold=-20dB:ratio=3:attack=5:release=120:makeup=3,afade=t=in:d=0.02" \
      "$work/narr/n$n.wav"
  else
    echo "  (no narration n$n yet: silent)"
    ffmpeg -v error -y -f lavfi -i "anullsrc=r=48000:cl=mono" -t 0.1 "$work/narr/n$n.wav"
  fi
done
# ドーン: a falling sub-bass sine under a heavy punch sample, with a short tail
python3 -I - "$here/sfx/impactPunch_heavy_000.ogg" "$work/doon.wav" <<'PY'
import subprocess, sys, wave
import numpy as np
SR = 48000
punch = np.frombuffer(subprocess.run(['ffmpeg', '-v', 'error', '-i', sys.argv[1], '-ac', '1', '-ar', str(SR), '-f', 'f32le', '-'],
                                     check=True, capture_output=True).stdout, '<f4').astype(np.float64)
t = np.arange(int(SR * 2.2)) / SR
f = 38 + 72 * np.exp(-t / 0.25)                      # 110 Hz falling to ~38 Hz
sub = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.55) * np.clip(t / 0.004, 0, 1)
out = 0.9 * sub
out[:len(punch)] += 0.8 * punch / (np.abs(punch).max() or 1)
for d, g in ((0.11, 0.35), (0.23, 0.2), (0.37, 0.1)):  # a little room
    k = int(SR * d); out[k:] += g * out[:-k] * 0.5
out *= 0.89 / np.abs(out).max()
with wave.open(sys.argv[2], 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes((out * 32767).astype('<i2').tobytes())
PY
sfx="$app/sfx"
cat > "$work/samples.json" <<JSON
{
  "n1": ["$work/narr/n1.wav"], "n2": ["$work/narr/n2.wav"], "n3": ["$work/narr/n3.wav"], "n4": ["$work/narr/n4.wav"],
  "n5": ["$work/narr/n5.wav"], "n6": ["$work/narr/n6.wav"], "n7": ["$work/narr/n7.wav"],
  "doon":    ["$work/doon.wav"],
  "pop":     ["$sfx/drop_002.ogg"],
  "whoosh":  ["$sfx/card-slide-1.ogg", "$sfx/card-slide-2.ogg"],
  "chime":   ["$sfx/confirmation_002.ogg"],
  "sparkle": ["$sfx/glass_004.ogg"]
}
JSON
python3 -I "$app/sfx.py" "$work/frames/sfx_cues.json" "$work/samples.json" "$work/sfx.wav" $DURATION

echo "== composite"
ffmpeg -v error -y -i "$work/base.mp4" -framerate $FPS -i "$work/frames/%05d.png" -i "$work/sfx.wav" \
  -filter_complex "[0:v][1:v]overlay=0:0:format=auto,format=yuv420p[v]" -map "[v]" -map 2:a -t $DURATION -r $FPS \
  -c:v libx264 -profile:v high -crf 20 -preset slow -c:a aac -b:a 160k -movflags +faststart "$out"
ffprobe -v error -show_entries format=duration,size -of compact "$out"
