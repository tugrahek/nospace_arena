"""Focused PNG, icon-safe-zone and listing checks using Python's standard library."""
import argparse
import configparser
import hashlib
import json
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "docs/play-store"


def read_png(path):
    data = path.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    offset, chunks, compressed = 8, {}, bytearray()
    while offset < len(data):
        size = struct.unpack_from(">I", data, offset)[0]
        kind = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + size]
        crc = struct.unpack_from(">I", data, offset + 8 + size)[0]
        assert zlib.crc32(kind + payload) & 0xffffffff == crc, (path, kind)
        chunks[kind] = payload
        if kind == b"IDAT":
            compressed.extend(payload)
        offset += size + 12
    width, height, depth, color, compression, filtering, interlace = struct.unpack(">IIBBBBB", chunks[b"IHDR"])
    assert depth == 8 and color in (2, 6) and interlace == 0
    channels = 3 if color == 2 else 4
    stride = width * channels
    raw = zlib.decompress(compressed)
    assert len(raw) == height * (stride + 1)
    rows, previous = [], bytearray(stride)
    for y in range(height):
        method = raw[y * (stride + 1)]
        row = bytearray(raw[y * (stride + 1) + 1:(y + 1) * (stride + 1)])
        for x in range(stride):
            a = row[x - channels] if x >= channels else 0
            b = previous[x]
            c = previous[x - channels] if x >= channels else 0
            if method == 0:
                break
            if method == 1:
                prediction = a
            elif method == 2:
                prediction = b
            elif method == 3:
                prediction = (a + b) // 2
            else:
                assert method == 4
                p = a + b - c
                distances = (abs(p - a), abs(p - b), abs(p - c))
                prediction = (a, b, c)[distances.index(min(distances))]
            row[x] = (row[x] + prediction) & 255
        rows.append(row)
        previous = row
    return width, height, channels, rows, chunks, data


def validate():
    report = {"status": "technical checks passed; branding/feature accepted; physical Android acceptance pending", "images": [], "listing": {}}
    images = sorted(PACKAGE.rglob("*.png"))
    assert len(images) == 14, len(images)
    for path in images:
        w, h, channels, rows, chunks, data = read_png(path)
        name = path.relative_to(PACKAGE).as_posix()
        if name.startswith("screenshots/"):
            assert (w, h, channels) == (1080, 1920, 3)
            assert 320 <= min(w, h) and max(w, h) <= min(3840, 2 * min(w, h))
        elif name.startswith("feature/"):
            assert (w, h, channels) == (1024, 500, 3)
        elif name == "icon/play-icon-512.png":
            assert (w, h, channels) == (512, 512, 4)
            assert all(row[x] == 255 for row in rows for x in range(3, len(row), 4))
            assert len(data) <= 1024 * 1024
        elif "foreground" in name or "monochrome" in name:
            assert (w, h, channels) == (432, 432, 4)
            visible = [(x, y) for y, row in enumerate(rows) for x in range(w) if row[x * 4 + 3]]
            assert visible
            # 66 dp circular safe area within the 108 dp layer, at 4 pixels per dp.
            assert all((x + .5 - 216) ** 2 + (y + .5 - 216) ** 2 <= 132 ** 2 for x, y in visible)
            if "monochrome" in name:
                assert all(rows[y][x * 4:x * 4 + 3] == b"\xff\xff\xff" for x, y in visible)
        elif name.endswith("launcher-192.png"):
            assert (w, h, channels) == (192, 192, 3)
        elif "background" in name:
            assert (w, h, channels) == (432, 432, 3)
        else:
            assert name.endswith("mask-preview.review.png") and (w, h, channels) == (864, 432, 3)
        if not name.startswith("screenshots/"):
            assert chunks.get(b"sRGB") == b"\0"
        report["images"].append({"file": name, "width": w, "height": h,
            "channels": channels, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
    listing = json.loads((PACKAGE / "listing.json").read_text(encoding="utf-8"))
    for locale in ("en", "tr"):
        counts = {key: len(listing[locale][key]) for key in ("title", "short_description", "full_description")}
        assert 0 < counts["title"] <= 30 and 0 < counts["short_description"] <= 80 and 0 < counts["full_description"] <= 4000
        report["listing"][locale] = counts
    provenance = json.loads((PACKAGE / "screenshots/capture-provenance.json").read_text())
    assert len(provenance) == 6 and all(not p["upscaled_bitmap"] and p["platform"] == "Windows" for p in provenance)
    order = json.loads((PACKAGE / "screenshots/order.json").read_text())
    for locale in ("en", "tr"):
        assert order[locale] == [f"gameplay-{locale}-02.png", f"gameplay-{locale}-01.png", f"mode-select-{locale}.png"]
        for name in order[locale]:
            assert (PACKAGE / "screenshots" / name).is_file()
            record = next(p for p in provenance if p["file"] == name)
            assert record["locale"] == locale and (record["width"], record["height"]) == (1080, 1920)
            if name.startswith("mode-select"):
                assert record["screen"] == "ModeSelect"
    icons = {"main_192x192": "launcher-192.png",
        "adaptive_foreground_432x432": "adaptive-foreground-432.png",
        "adaptive_background_432x432": "adaptive-background-432.png",
        "adaptive_monochrome_432x432": "adaptive-monochrome-432.png"}
    presets = configparser.ConfigParser(interpolation=None, strict=False)
    presets.read(ROOT / "export_presets.cfg", encoding="utf-8")
    for key, filename in icons.items():
        relative = "assets/branding/launcher/" + filename
        assert (ROOT / relative).read_bytes() == (PACKAGE / "android-launcher" / filename).read_bytes()
        assert 'source_file="res://' + relative + '"' in (ROOT / (relative + ".import")).read_text()
        for section in ("preset.0.options", "preset.1.options"):
            assert presets[section]["launcher_icons/" + key] == '"res://' + relative + '"'
    for section, export_format, signed in (("preset.0.options", "0", "true"), ("preset.1.options", "1", "false")):
        options = presets[section]
        assert options["gradle_build/export_format"] == export_format and options["package/signed"] == signed
        assert options["package/unique_name"] == '"com.tugrahek.nospace"'
        assert options["architectures/arm64-v8a"] == "true"
    assert presets["preset.1.options"]["gradle_build/min_sdk"] == '"24"'
    assert presets["preset.1.options"]["gradle_build/target_sdk"] == '"36"'
    report["screenshot_order"] = order
    report["runtime_launcher_assets"] = len(icons)
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    result = validate()
    if args.report:
        args.report.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(json.dumps({"images": len(result["images"]), "listing": result["listing"], "status": result["status"]}))
