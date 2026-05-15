#!/usr/bin/env python3
"""Heuristically group sequential PNG frames into animations by visual similarity."""
import os
import json
import argparse
from pathlib import Path
from PIL import Image
import numpy as np


def frame_diff(img1: Image.Image, img2: Image.Image) -> float:
    """Compute normalized MSE between two images (scaled to same size)."""
    # Resize both to a standard small size for fast comparison
    size = (64, 64)
    a = np.array(img1.convert("RGB").resize(size, Image.Resampling.LANCZOS), dtype=np.float32)
    b = np.array(img2.convert("RGB").resize(size, Image.Resampling.LANCZOS), dtype=np.float32)
    mse = np.mean((a - b) ** 2)
    return mse


def group_frames(folder: Path, threshold: float = 800.0, min_group_size: int = 2) -> list:
    """
    Group consecutive frames by similarity.
    Returns list of dicts: [{"name": "anim_0", "frames": [0,1,2], "fps": 12}]
    """
    pngs = sorted(folder.glob("*.png"), key=lambda p: int(''.join(filter(str.isdigit, p.stem)) or 0))
    if not pngs:
        return []

    groups = []
    current_group = [0]
    prev_img = Image.open(pngs[0])

    for i in range(1, len(pngs)):
        curr_img = Image.open(pngs[i])
        diff = frame_diff(prev_img, curr_img)

        if diff < threshold:
            current_group.append(i)
        else:
            groups.append(current_group)
            current_group = [i]
        
        prev_img = curr_img

    if current_group:
        groups.append(current_group)

    # Merge tiny groups into neighbors
    merged = []
    for g in groups:
        if len(g) < min_group_size and merged:
            merged[-1].extend(g)
        else:
            merged.append(g)
    
    result = []
    for idx, g in enumerate(merged):
        result.append({
            "name": f"anim_{idx}",
            "frames": g,
            "fps": 12,
            "loop": len(g) > 3
        })
    
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("folder", help="Folder containing sequential PNG frames")
    parser.add_argument("--threshold", type=float, default=800.0, help="MSE threshold for grouping")
    parser.add_argument("--min-size", type=int, default=2, help="Minimum frames per group")
    parser.add_argument("--out", help="Output JSON path")
    args = parser.parse_args()

    folder = Path(args.folder)
    groups = group_frames(folder, args.threshold, args.min_size)
    
    frame_map = {}
    for g in groups:
        frame_map[g["name"]] = {
            "frames": g["frames"],
            "fps": g["fps"],
            "loop": g["loop"]
        }
    
    out_path = Path(args.out) if args.out else folder / "_heuristic_frame_map.json"
    with open(out_path, "w") as f:
        json.dump(frame_map, f, indent=2)
    
    print(f"Grouped {sum(len(g['frames']) for g in groups)} frames into {len(groups)} animations")
    print(f"Saved to {out_path}")
    for g in groups:
        print(f"  {g['name']}: frames {g['frames'][0]}-{g['frames'][-1]} ({len(g['frames'])} frames)")


if __name__ == "__main__":
    main()
