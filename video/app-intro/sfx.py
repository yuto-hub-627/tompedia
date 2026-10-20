"""Synthesizes the intro's sound effects and mixes them at the cue times.

usage: python3 sfx.py <cues.json> <out.wav> <durationSec>
cues.json: [[timeSec, name, gain, pitch], ...] exported by overlay.html (window.SFX_CUES)
"""
import json
import sys
import wave

import numpy as np

SR = 48000
rng = np.random.default_rng(7)


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def sweep(f0, f1, dur, curve=1.0):
    t = t_axis(dur)
    f = f0 + (f1 - f0) * (t / dur) ** curve
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def pop(p):
    dur = 0.12
    t = t_axis(dur)
    return sweep(820 * p, 260 * p, dur, 0.5) * np.exp(-t / 0.028)


def boing(p):
    dur = 0.28
    t = t_axis(dur)
    base = sweep(170 * p, 430 * p, dur, 0.7)
    wobble = 1 + 0.05 * np.sin(2 * np.pi * 18 * t)
    env = np.minimum(t / 0.006, 1) * np.exp(-t / 0.09)
    return base * wobble * env * 0.8


def whoosh(p):
    dur = 0.42
    t = t_axis(dur)
    noise = rng.standard_normal(len(t))
    # one-pole low-pass whose cutoff sweeps up then down
    cutoff = 300 + 3200 * np.sin(np.pi * t / dur) ** 2 * p
    a = np.exp(-2 * np.pi * cutoff / SR)
    out = np.empty_like(noise)
    y = 0.0
    for i, x in enumerate(noise):
        y = a[i] * y + (1 - a[i]) * x
        out[i] = y
    return out * np.sin(np.pi * t / dur) ** 2 * 0.8


def bell(freqs, decay, p):
    dur = decay * 4
    t = t_axis(dur)
    env = np.minimum(t / 0.004, 1)
    return sum(np.sin(2 * np.pi * f * p * t) * np.exp(-t / (decay / (k + 1))) / (k + 1)
               for k, f in enumerate(freqs)) * env


def chime(p):
    # two-note "ta-da": the second note enters 80ms after the first
    low, high = bell([1046.5, 2093, 3136], 0.35, p), bell([1568, 3136], 0.3, p)
    gap = int(0.08 * SR)
    out = np.zeros(max(len(low), gap + len(high)))
    out[:len(low)] += low * 0.55
    out[gap:gap + len(high)] += high * 0.45
    return out


def ding(p):
    return bell([1760, 2637], 0.12, p) * 0.5


def tick(p):
    dur = 0.018
    t = t_axis(dur)
    return np.sin(2 * np.pi * 2400 * p * t) * np.exp(-t / 0.004)


SOUNDS = {'pop': pop, 'boing': boing, 'whoosh': whoosh, 'chime': chime, 'ding': ding, 'tick': tick}


def main(cue_path, out_path, duration):
    mix = np.zeros(int(SR * duration) + SR)
    for time, name, gain, pitch in json.load(open(cue_path)):
        snd = SOUNDS[name](pitch) * gain
        i = int(time * SR)
        mix[i:i + len(snd)] += snd[:len(mix) - i]
    mix = mix[:int(SR * duration)]
    mix *= 0.8 / max(1e-9, np.abs(mix).max())
    pcm = (mix * 32767).astype('<i2')
    with wave.open(out_path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2], float(sys.argv[3]))
