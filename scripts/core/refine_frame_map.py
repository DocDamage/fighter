#!/usr/bin/env python3
"""Refine auto-sliced frames by splitting merged frames and rebuilding frame map."""
import os
import json
import shutil
from pathlib import Path
from PIL import Image
import numpy as np

BASE = Path(__file__).parent.parent.parent
DST = BASE / "assets" / "characters" / "processed"

# Known approximate frame widths for SSF2 sprites
TYPICAL_FRAME_WIDTH = 55
MERGE_THRESHOLD = 120


def split_merged_frame(img: Image.Image, bg_tol=30):
    """Split a merged frame into individual sprites using x-projection."""
    arr = np.array(img.convert("RGBA"))
    h, w = arr.shape[:2]

    # Find background color from edges
    bg = np.median(arr[[0, h-1], :, :3].reshape(-1, 3), axis=0).astype(int)

    # Mask non-background
    diff = np.abs(arr[:, :, :3].astype(int) - bg).sum(axis=2)
    mask = diff > bg_tol

    # X projection with small threshold
    x_proj = mask.sum(axis=0)
    gap_thresh = 2

    segments = []
    in_seg = False
    x_start = 0
    for x in range(w):
        if x_proj[x] > gap_thresh and not in_seg:
            in_seg = True
            x_start = x
        elif x_proj[x] <= gap_thresh and in_seg:
            in_seg = False
            segments.append((x_start, x))
    if in_seg:
        segments.append((x_start, w))

    # Filter tiny segments and merge very close ones
    segments = [s for s in segments if s[1] - s[0] > 15]
    merged = []
    for s in segments:
        if merged and s[0] - merged[-1][1] < 5:
            merged[-1] = (merged[-1][0], s[1])
        else:
            merged.append(s)
    segments = merged

    # Extract each segment with tight y-bounds
    frames = []
    for xs, xe in segments:
        seg_mask = mask[:, xs:xe]
        ys = 0
        while ys < h and not seg_mask[ys].any():
            ys += 1
        ye = h
        while ye > ys and not seg_mask[ye - 1].any():
            ye -= 1
        if ye > ys:
            # Add small padding
            pad = 2
            fx0 = max(0, xs - pad)
            fx1 = min(w, xe + pad)
            fy0 = max(0, ys - pad)
            fy1 = min(h, ye + pad)
            frames.append(img.crop((fx0, fy0, fx1, fy1)))

    return frames


def refine_fighter(fighter_id: str):
    fighter_dir = DST / fighter_id
    frame_map_path = fighter_dir / f"{fighter_id}_frame_map.json"

    with open(frame_map_path) as f:
        old_map = json.load(f)

    # Read old frames in order
    old_frames = []
    old_frame_files = sorted(fighter_dir.glob(f"{fighter_id}_*.png"))
    for p in old_frame_files:
        if "_frame_map" in p.name:
            continue
        idx = int(p.stem.split("_")[-1])
        img = Image.open(p)
        old_frames.append((idx, img.copy()))
        img.close()

    # Build new frame list by splitting merged frames
    new_frames = []
    split_info = []  # (old_idx, [new_indices...])

    for old_idx, img in old_frames:
        w, h = img.size
        if w > MERGE_THRESHOLD:
            sub_frames = split_merged_frame(img)
            if len(sub_frames) > 1:
                start = len(new_frames)
                new_frames.extend(sub_frames)
                split_info.append((old_idx, list(range(start, len(new_frames)))))
            else:
                split_info.append((old_idx, [len(new_frames)]))
                new_frames.append(img)
        else:
            split_info.append((old_idx, [len(new_frames)]))
            new_frames.append(img)

    print(f"{fighter_id}: {len(old_frames)} old frames -> {len(new_frames)} new frames")

    # Clear old frames and save new ones
    for p in old_frame_files:
        if "_frame_map" not in p.name:
            p.unlink()

    for i, frame in enumerate(new_frames):
        frame.save(fighter_dir / f"{fighter_id}_{i:04d}.png")

    # Build mapping from old index to new indices
    old_to_new = {}
    for old_idx, new_indices in split_info:
        old_to_new[old_idx] = new_indices

    # Rebuild frame map
    new_map = {}
    for anim_name, anim_data in old_map.items():
        old_indices = anim_data.get("frames", [])
        fps = anim_data.get("fps", 12)
        loop = anim_data.get("loop", True)

        new_indices = []
        for idx in old_indices:
            new_indices.extend(old_to_new.get(idx, [idx]))

        if new_indices:
            new_map[anim_name] = {
                "frames": new_indices,
                "fps": fps,
                "loop": loop
            }

    with open(frame_map_path, "w") as f:
        json.dump(new_map, f, indent=2)

    print(f"{fighter_id}: frame map rebuilt with {len(new_map)} animations")
    for name, info in new_map.items():
        print(f"  {name}: {len(info['frames'])} frames")


if __name__ == "__main__":
    for fid in ["ryu", "ken"]:
        refine_fighter(fid)
    print("Done.")
