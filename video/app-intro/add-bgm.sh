#!/usr/bin/env bash
# Lays background music under a finished video (normal or GC version); the picture is copied as is.
# usage: ./add-bgm.sh <video.mp4> <bgm audio> <out.mp4> [bgmStartSec=0] [bgmRmsDb=-24] [delaySec=0]
#   delaySec: when the music comes in, in video time (silence before it)
#   The music is levelled to bgmRmsDb (RMS, dBFS), dipped under the opening 「とんペディア！」 shout,
#   and faded out over the last 1.5s. BGM used so far: OpenTracks (旧DOVA-SYNDROME) tracks, which
#   allow commercial use as background music without credit.
set -euo pipefail
video="$1"; bgm="$2"; out="$3"; start="${4:-0}"; target="${5:--24}"; delay="${6:-0}"
dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video")

# level the section we use to the target RMS
mean=$(ffmpeg -hide_banner -ss "$start" -t "$dur" -i "$bgm" -af volumedetect -f null - 2>&1 \
  | sed -n 's/.*mean_volume: \(-*[0-9.]*\) dB.*/\1/p')
gain=$(python3 -c "print(round($target - ($mean), 2))")

# the shout runs ~0.2-1.3s: dip the music to 40% around it
duck="if(lt(t,0.1),1,if(lt(t,0.25),1-0.6*(t-0.1)/0.15,if(lt(t,1.3),0.4,if(lt(t,1.6),0.4+0.6*(t-1.3)/0.3,1))))"
fo=$(python3 -c "print(round($dur-1.5, 3))")
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
# the video's audio is mono: copy it to both channels (a plain stereo upmix would drop it by 3 dB)
ffmpeg -v error -y -i "$video" -ss "$start" -t "$dur" -i "$bgm" -filter_complex \
  "[1:a]aformat=sample_rates=48000:channel_layouts=stereo,volume=${gain}dB,afade=t=in:d=0.05,adelay=$(python3 -c "print(int($delay*1000))"):all=1,volume='${duck}':eval=frame,afade=t=out:st=${fo}:d=1.5[m];\
[0:a]aresample=48000,pan=stereo|c0=c0|c1=c0[v];[v][m]amix=inputs=2:normalize=0:duration=first[a]" \
  -map "[a]" -c:a pcm_s16le "$tmp/mix.wav"
# bring the whole mix to ~-16 LUFS (typical for Reels) with a limiter on top
lufs=$(ffmpeg -hide_banner -i "$tmp/mix.wav" -af ebur128 -f null - 2>&1 | sed -n 's/^ *I: *\(-*[0-9.]*\) LUFS.*/\1/p' | tail -1)
lift=$(python3 -c "print(round(-16 - ($lufs), 2))")
ffmpeg -v error -y -i "$video" -i "$tmp/mix.wav" -filter_complex "[1:a]volume=${lift}dB,alimiter=limit=0.89:level=false[a]" \
  -map 0:v -map "[a]" -c:v copy -c:a aac -b:a 192k -movflags +faststart "$out"
echo "mix ${lufs} LUFS -> +${lift} dB"
echo "bgm section mean ${mean} dB -> gain ${gain} dB"
ffprobe -v error -show_entries format=duration,size -of compact "$out"
