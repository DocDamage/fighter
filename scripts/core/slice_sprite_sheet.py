#!/usr/bin/env python3
"""Auto-slice fighter sprite sheets into individual frame PNGs + frame map JSON."""
import os
import json
from pathlib import Path
from PIL import Image
import numpy as np

BASE = Path(__file__).parent.parent.parent
SRC = BASE / "assets" / "characters" / "sheets"
DST = BASE / "assets" / "characters" / "processed"

# Approximate row Y boundaries for each sheet (determined by visual inspection)
# These are rough guides; the script refines them automatically.
ROW_GUIDES = {
    "ryu": [0, 110, 220, 340, 460, 570, 690, 800, 968],
    "ken": [0, 110, 220, 340, 460, 570, 690, 800, 992],
    "guile": [0, 110, 220, 340, 460, 580, 700, 820, 1175],
    "chun_li": [0, 110, 220, 340, 460, 580, 700, 820, 1222],
}

# Animation names per row (top to bottom)
ROW_ANIMATIONS = {
    "ryu": [
        ["idle", "walk", "jump", "forward_jump", "crouch", "block"],
        ["st_lp", "st_mp", "st_hp", "fwd_lp", "fwd_mp", "fwd_hp"],
        ["st_lk", "st_mk", "st_hk", "fwd_lk", "fwd_mk", "fwd_hk"],
        ["cr_lp", "cr_mp", "cr_hp", "cr_lk", "cr_mk", "cr_hk"],
        ["j_lp", "j_mp", "j_hp", "j_lk", "j_mk", "j_hk", "shoryuken", "tatsumaki"],
        ["hadouken", "hadouken_proj", "shoulder_toss", "backroll"],
        ["hit", "face_hit", "cr_hit", "knockdown", "stunned", "ko"],
        ["victory1", "victory2", "time_over", "alt_palettes", "mugshots"],
    ],
    "ken": [
        ["idle", "walk", "jump", "forward_jump", "crouch", "block"],
        ["st_lp", "st_mp", "st_hp", "fwd_lp", "fwd_mp", "fwd_hp"],
        ["st_lk", "st_mk", "st_hk", "fwd_lk", "fwd_mk", "fwd_hk"],
        ["cr_lp", "cr_mp", "cr_hp", "cr_lk", "cr_mk", "cr_hk"],
        ["j_lp", "j_mp", "j_hp", "j_lk", "j_mk", "j_hk", "shoryuken", "tatsumaki"],
        ["hadouken", "hadouken_proj", "shoulder_toss", "backroll"],
        ["hit", "face_hit", "cr_hit", "knockdown", "stunned", "ko"],
        ["victory1", "victory2", "time_over", "alt_palettes", "mugshots"],
    ],
    "guile": [
        ["idle", "walk", "jump", "forward_jump", "crouch", "block"],
        ["st_lp", "st_mp", "st_hp", "fwd_lp", "fwd_mp", "fwd_hp"],
        ["st_lk", "st_mk", "st_hk", "fwd_lk", "fwd_mk", "fwd_hk"],
        ["cr_lp", "cr_mp", "cr_hp", "cr_lk", "cr_mk", "cr_hk"],
        ["j_lp", "j_mp", "j_hp", "j_lk", "j_mk", "j_hk", "flash_kick", "sonic_boom_air"],
        ["sonic_boom", "sonic_boom_proj", "backfist", "backroll"],
        ["hit", "face_hit", "cr_hit", "knockdown", "stunned", "ko"],
        ["victory1", "victory2", "time_over", "alt_palettes", "mugshots"],
    ],
    "chun_li": [
        ["idle", "walk", "jump", "forward_jump", "crouch", "block"],
        ["st_lp", "st_mp", "st_hp", "fwd_lp", "fwd_mp", "fwd_hp"],
        ["st_lk", "st_mk", "st_hk", "fwd_lk", "fwd_mk", "fwd_hk"],
        ["cr_lp", "cr_mp", "cr_hp", "cr_lk", "cr_mk", "cr_hk"],
        ["j_lp", "j_mp", "j_hp", "j_lk", "j_mk", "j_hk", "spinning_bird_kick", "hyakuretsukyaku"],
        ["kikoken", "kikoken_proj", "shoulder_toss", "backroll"],
        ["hit", "face_hit", "cr_hit", "knockdown", "stunned", "ko"],
        ["victory1", "victory2", "time_over", "alt_palettes", "mugshots"],
    ],
}


def find_background_color(arr):
    """Find the most common color by sampling center and edges."""
    h, w = arr.shape[:2]
    # Sample multiple known-background points
    samples = [
        arr[0, 0],
        arr[0, w//2],
        arr[h//2, 0],
        arr[h//2, w//2],
        arr[h//4, w//4],
    ]
    colors = [tuple(c[:3]) for c in samples]
    # Return the most common
    return max(set(colors), key=colors.count)


def slice_sheet(fighter_id: str, filename: str):
    src_path = SRC / filename
    if not src_path.exists():
        print(f"SKIP: {src_path} not found")
        return

    img = Image.open(src_path).convert("RGBA")
    arr = np.array(img)
    h, w = arr.shape[:2]

    bg = find_background_color(arr)
    print(f"{fighter_id}: size={w}x{h}, bg={bg}")

    # Create mask of non-background pixels (with tolerance)
    tol = 30
    diff = np.abs(arr[:, :, :3].astype(int) - np.array(bg, dtype=int)).sum(axis=2)
    mask = diff > tol

    out_dir = DST / fighter_id
    out_dir.mkdir(parents=True, exist_ok=True)

    # Get row guides and refine them
    guides = ROW_GUIDES.get(fighter_id, [0, h])
    row_y_starts = []
    row_y_ends = []

    for i in range(len(guides) - 1):
        y0 = guides[i]
        y1 = guides[i + 1]
        # Refine: shrink from top until we find content
        while y0 < y1 and not mask[y0].any():
            y0 += 1
        # Refine: shrink from bottom until we find content
        while y1 > y0 and not mask[y1 - 1].any():
            y1 -= 1
        # Crop off text labels at top (hard crop ~25px from top of content)
        y0 = min(y1, y0 + 25)
        row_y_starts.append(y0)
        row_y_ends.append(y1)

    # Process each row
    frame_index = 0
    frame_map = {}
    anim_names = ROW_ANIMATIONS.get(fighter_id, [])

    for row_idx, (y0, y1) in enumerate(zip(row_y_starts, row_y_ends)):
        if y0 >= y1:
            continue
        row_mask = mask[y0:y1, :]
        # X projection: count non-bg pixels per column
        x_proj = row_mask.sum(axis=0)
        # Find x segments with content (allow tiny stray pixels in gaps)
        gap_threshold = 3
        in_seg = False
        x_segments = []
        x_start = 0
        for x in range(w):
            if x_proj[x] > gap_threshold and not in_seg:
                in_seg = True
                x_start = x
            elif x_proj[x] <= gap_threshold and in_seg:
                in_seg = False
                x_segments.append((x_start, x))
        if in_seg:
            x_segments.append((x_start, w))

        # Filter out tiny segments (noise, stray pixels)
        x_segments = [(xs, xe) for xs, xe in x_segments if xe - xs > 15]

        # Merge very close segments (frames with small internal gaps)
        merged = []
        for xs, xe in x_segments:
            if merged and xs - merged[-1][1] < 8:
                merged[-1] = (merged[-1][0], xe)
            else:
                merged.append((xs, xe))
        x_segments = merged

        row_anims = anim_names[row_idx] if row_idx < len(anim_names) else []

        for seg_idx, (xs, xe) in enumerate(x_segments):
            # Extract tight bounding box within this segment
            seg_mask = mask[y0:y1, xs:xe]
            ys = 0
            while ys < seg_mask.shape[0] and not seg_mask[ys].any():
                ys += 1
            ye = seg_mask.shape[0]
            while ye > ys and not seg_mask[ye - 1].any():
                ye -= 1
            if ye <= ys:
                continue

            # Add small padding
            pad = 2
            fx0 = max(0, xs - pad)
            fx1 = min(w, xe + pad)
            fy0 = max(0, y0 + ys - pad)
            fy1 = min(h, y0 + ye + pad)

            frame = img.crop((fx0, fy0, fx1, fy1))
            frame_path = out_dir / f"{fighter_id}_{frame_index:04d}.png"
            frame.save(frame_path)

            anim_name = row_anims[seg_idx] if seg_idx < len(row_anims) else f"unknown_{row_idx}_{seg_idx}"
            if anim_name not in frame_map:
                frame_map[anim_name] = []
            frame_map[anim_name].append(frame_index)

            frame_index += 1

    # Build frame_map JSON with ranges
    frame_map_json = {}
    for anim_name, indices in frame_map.items():
        if len(indices) == 1:
            frame_map_json[anim_name] = {
                "frames": [indices[0]],
                "fps": 12,
                "loop": True
            }
        else:
            frame_map_json[anim_name] = {
                "frames": indices,
                "fps": 12,
                "loop": True
            }

    map_path = out_dir / f"{fighter_id}_frame_map.json"
    with open(map_path, "w") as f:
        json.dump(frame_map_json, f, indent=2)

    print(f"{fighter_id}: {frame_index} frames saved to {out_dir}")
    print(f"Frame map: {map_path}")
    print(f"Animations: {list(frame_map_json.keys())}")


if __name__ == "__main__":
    for fid, fname in [("ryu", "ryu.gif"), ("ken", "ken.gif"), ("guile", "guile.gif"), ("chun_li", "chun_li.gif")]:
        slice_sheet(fid, fname)
    print("Done.")
