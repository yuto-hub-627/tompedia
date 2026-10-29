"""団体名とURLの一覧からQRコード画像を作り、読み取れるか確認する。

使い方:
    pip install "qrcode[pil]==7.4.2" "opencv-python-headless==4.10.0.84"
    python make_qr.py groups.json out_dir

groups.json は [["団体名", "URL"], ...] の形。
out_dir に qr01.png, qr02.png ... を一覧の順で書き出す（912×912px前後、誤り訂正M）。
"""
import json
import sys
from pathlib import Path

import qrcode


def make(groups, out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    for i, (name, url) in enumerate(groups, 1):
        q = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_M, box_size=16, border=2)
        q.add_data(url)
        q.make(fit=True)
        path = out_dir / f"qr{i:02d}.png"
        q.make_image(fill_color="#000000", back_color="white").save(path)
        paths.append(path)
    return paths


def verify(groups, paths):
    try:
        import cv2
    except ImportError:
        print("opencv がないので読み取り確認をスキップ")
        return True
    ok = True
    detectors = [cv2.QRCodeDetector()]
    if hasattr(cv2, "QRCodeDetectorAruco"):
        detectors.append(cv2.QRCodeDetectorAruco())
    for (name, url), path in zip(groups, paths):
        img = cv2.imread(str(path))
        found = ""
        for det in detectors:
            for scale in (1.0, 0.5, 0.3):
                im = cv2.resize(img, None, fx=scale, fy=scale) if scale != 1.0 else img
                found, _, _ = det.detectAndDecode(im)
                if found:
                    break
            if found:
                break
        status = "OK" if found == url else "NG"
        ok &= status == "OK"
        print(f"{status} {path.name} {name}")
    return ok


def main():
    groups = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    paths = make(groups, Path(sys.argv[2]))
    sys.exit(0 if verify(groups, paths) else 1)


if __name__ == "__main__":
    main()
