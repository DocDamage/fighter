#!/usr/bin/env python3
"""Convert fighter GIFs to numbered PNG frame sequences."""
import os
import sys
from pathlib import Path
from PIL import Image

BASE = Path(__file__).parent.parent.parent
SRC = BASE / "assets" / "characters" / "sheets"
DST = BASE / "assets" / "characters" / "processed"

fighters = ["ryu", "ken", "guile", "chun_li"]
mapping = {
    "ryu": "ryu.gif",
    "ken": "ken.gif",
    "guile": "guile.gif",
    "chun_li": "chun_li.gif",
}

def convert_gif(fighter_id: str, gif_name: str):
    src_path = SRC / gif_name
    if not src_path.exists():
        print(f"SKIP: {src_path} not found")
        return
    out_dir = DST / fighter_id
    out_dir.mkdir(parents=True, exist_ok=True)
    img = Image.open(src_path)
    frame = 0
    for i in range(img.n_frames):
        img.seek(i)
        # Convert to RGBA to handle transparency
        rgba = img.convert("RGBA")
        out_path = out_dir / f"{fighter_id}_{frame:04d}.png"
        rgba.save(out_path)
        frame += 1
    print(f"{fighter_id}: {frame} frames -> {out_dir}")

if __name__ == "__main__":
    for fid in fighters:
        gif = mapping.get(fid, "")
        if gif:
            convert_gif(fid, gif)
    print("Done.")
