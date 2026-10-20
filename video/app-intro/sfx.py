"""Mixes the intro's sound effects (and the opening voice) at the cue times.

usage: python3 sfx.py <cues.json> <samples.json> <out.wav> <durationSec>
cues.json:    [[timeSec, name, gain, pitch], ...] exported by overlay.html (window.SFX_CUES)
samples.json: {name: [audio file, ...]}; repeated cues of one name cycle through its files

Every sample is brought to the same RMS first, so a cue's gain alone sets how loud it is.
"""
import json
import subprocess
import sys
import wave

import numpy as np

SR = 48000
TARGET_RMS = 0.1


def load(path):
    raw = subprocess.run(['ffmpeg', '-v', 'error', '-i', path, '-ac', '1', '-ar', str(SR), '-f', 'f32le', '-'],
                         check=True, capture_output=True).stdout
    a = np.frombuffer(raw, '<f4').astype(np.float64)
    rms = np.sqrt(np.mean(a ** 2)) or 1.0
    return a * (TARGET_RMS / rms)


def repitch(a, pitch):
    if pitch == 1:
        return a
    idx = np.arange(0, len(a) - 1, pitch)
    return np.interp(idx, np.arange(len(a)), a)


def main(cue_path, samples_path, out_path, duration):
    samples = {name: [load(f) for f in files] for name, files in json.load(open(samples_path)).items()}
    used = {}
    mix = np.zeros(int(SR * duration) + SR)
    for time, name, gain, pitch in json.load(open(cue_path)):
        variants = samples[name]
        k = used.get(name, 0)
        used[name] = k + 1
        snd = repitch(variants[k % len(variants)], pitch) * gain
        i = int(time * SR)
        mix[i:i + len(snd)] += snd[:len(mix) - i]
    mix = mix[:int(SR * duration)]
    mix *= 0.89 / max(1e-9, np.abs(mix).max())
    pcm = (mix * 32767).astype('<i2')
    with wave.open(out_path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4]))
