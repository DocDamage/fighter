import json
import os
import shutil
from pathlib import Path
from PIL import Image
import numpy as np

BASE = Path("assets/characters/processed")
MIN_PIECE_WIDTH = 25
MAX_SINGLE_WIDTH = 70

def detect_bg_color(img):
    """Detect background color from corners."""
    arr = np.array(img)
    if arr.shape[2] == 4:
        corners = [tuple(arr[0, 0, :3]), tuple(arr[0, -1, :3]),
                   tuple(arr[-1, 0, :3]), tuple(arr[-1, -1, :3])]
    else:
        corners = [tuple(arr[0, 0]), tuple(arr[0, -1]),
                   tuple(arr[-1, 0]), tuple(arr[-1, -1])]
    from collections import Counter
    c = Counter(corners)
    return c.most_common(1)[0][0]

def is_bg_pixel(pixel, bg_color, tolerance=12):
    if len(pixel) == 4 and pixel[3] == 0:
        return True
    return all(abs(int(pixel[i]) - int(bg_color[i])) <= tolerance for i in range(3))

def find_split_points(arr, bg_color, expected_count):
    """Find optimal split points using x-projection valleys."""
    h, w = arr.shape[:2]
    
    # Compute x-projection
    projection = np.zeros(w, dtype=int)
    for x in range(w):
        for y in range(h):
            if not is_bg_pixel(arr[y, x], bg_color):
                projection[x] += 1
    
    # Smooth projection slightly
    smoothed = projection.copy()
    for x in range(1, w - 1):
        smoothed[x] = int((projection[x-1] + projection[x] + projection[x+1]) / 3)
    
    # Find all local minima
    minima = []
    for x in range(2, w - 2):
        if smoothed[x] <= smoothed[x-1] and smoothed[x] <= smoothed[x+1]:
            if smoothed[x] < smoothed[x-2] * 0.6 or smoothed[x] < 3:
                minima.append((x, smoothed[x]))
    
    # Sort by depth (shallower first - less confident splits)
    minima.sort(key=lambda m: m[1])
    
    # We need (expected_count - 1) splits
    # Select the deepest valleys that give us good piece sizes
    best_splits = []
    
    for x, depth in minima:
        # Check if this split creates pieces that are too small
        would_create_small = False
        for existing in best_splits + [0, w]:
            if abs(x - existing) < MIN_PIECE_WIDTH:
                would_create_small = True
                break
        if not would_create_small:
            best_splits.append(x)
        if len(best_splits) >= expected_count - 1:
            break
    
    best_splits.sort()
    return [0] + best_splits + [w]

def split_frame(img, expected_count=2):
    """Split a merged frame into individual poses."""
    arr = np.array(img)
    h, w = arr.shape[:2]
    bg_color = detect_bg_color(img)
    
    split_points = find_split_points(arr, bg_color, expected_count)
    
    pieces = []
    for i in range(len(split_points) - 1):
        x1 = split_points[i]
        x2 = split_points[i + 1]
        
        if x2 - x1 < 20:
            continue
        
        crop = img.crop((x1, 0, x2, h))
        crop_arr = np.array(crop)
        
        # Trim vertical whitespace
        top, bottom = 0, h
        for y in range(h):
            if any(not is_bg_pixel(crop_arr[y, x], bg_color) for x in range(crop.width)):
                top = y
                break
        for y in range(h - 1, -1, -1):
            if any(not is_bg_pixel(crop_arr[y, x], bg_color) for x in range(crop.width)):
                bottom = y + 1
                break
        
        if bottom > top:
            crop = crop.crop((0, top, crop.width, bottom))
        
        if crop.width >= 20 and crop.height >= 20:
            pieces.append(crop)
    
    return pieces

def is_junk_frame(img):
    """Detect junk frames like text fragments."""
    arr = np.array(img)
    h, w = arr.shape[:2]
    
    # Very wide and short
    if w > 120 and h < w * 0.4:
        return True
    
    bg_color = detect_bg_color(img)
    total = w * h
    bg_count = sum(1 for y in range(h) for x in range(w) if is_bg_pixel(arr[y, x], bg_color))
    
    # Mostly background with text
    if bg_count / total > 0.90 and w > 100:
        return True
    
    return False

def process_fighter(fighter_id: str):
    folder = BASE / fighter_id
    if not folder.exists():
        print(f"Folder not found: {folder}")
        return
    
    out_folder = BASE / f"{fighter_id}_split"
    if out_folder.exists():
        shutil.rmtree(out_folder)
    out_folder.mkdir(parents=True)
    
    files = sorted([f for f in folder.iterdir() if f.suffix == '.png' and f.stem.startswith(fighter_id)])
    
    frame_idx = 0
    stats = {"split": 0, "single": 0, "junk": 0, "total_in": 0}
    
    for f in files:
        stats["total_in"] += 1
        
        with Image.open(f) as img:
            img = img.copy()  # Detach from file
        
        if is_junk_frame(img):
            stats["junk"] += 1
            continue
        
        if img.width > MAX_SINGLE_WIDTH:
            # Estimate how many sprites based on width
            expected = max(2, round(img.width / 50))
            pieces = split_frame(img, expected)
            
            if len(pieces) >= 2:
                stats["split"] += 1
                for piece in pieces:
                    piece.save(out_folder / f"{fighter_id}_{frame_idx:04d}.png")
                    frame_idx += 1
                print(f"  Split {f.name} ({img.width}px) -> {len(pieces)} frames")
            else:
                # Failed to split, keep as-is
                img.save(out_folder / f"{fighter_id}_{frame_idx:04d}.png")
                frame_idx += 1
                stats["single"] += 1
        else:
            img.save(out_folder / f"{fighter_id}_{frame_idx:04d}.png")
            frame_idx += 1
            stats["single"] += 1
    
    print(f"\n{fighter_id}: {stats['total_in']} in -> {frame_idx} out")
    print(f"  Split: {stats['split']}, Single: {stats['single']}, Junk: {stats['junk']}")
    
    # Replace old folder with new
    backup = BASE / f"{fighter_id}_old"
    if backup.exists():
        shutil.rmtree(backup)
    shutil.move(folder, backup)
    shutil.move(out_folder, folder)
    
    # Generate basic frame map
    generate_frame_map(fighter_id, frame_idx)

def generate_frame_map(fighter_id: str, total_frames: int):
    folder = BASE / fighter_id
    
    # Load all frames to classify by size
    anim_groups = {
        "idle": [],
        "walk": [],
        "jump": [],
        "crouch": [],
        "block": [],
        "attack": [],
        "hit": [],
        "knockdown": [],
        "special": [],
        "unknown": [],
    }
    
    for i in range(total_frames):
        fname = folder / f"{fighter_id}_{i:04d}.png"
        if not fname.exists():
            continue
        with Image.open(fname) as img:
            w, h = img.size
        
        aspect = w / h if h > 0 else 1
        
        if h < 55:
            anim_groups["crouch"].append(i)
        elif h > 105:
            anim_groups["jump"].append(i)
        elif aspect > 1.4 and w > 60:
            anim_groups["attack"].append(i)
        elif 70 <= h <= 100 and 30 <= w <= 65:
            anim_groups["idle"].append(i)
        else:
            anim_groups["unknown"].append(i)
    
    frame_map = {}
    for name, indices in anim_groups.items():
        if indices:
            frame_map[name] = {
                "frames": indices,
                "fps": 10 if name == "idle" else 12,
                "loop": name in ["idle", "walk"]
            }
    
    with open(folder / f"{fighter_id}_frame_map.json", 'w') as f:
        json.dump(frame_map, f, indent=2)
    
    print(f"  Frame map: {len(frame_map)} animations, {total_frames} frames")

if __name__ == "__main__":
    for fid in ["ryu", "ken"]:
        print(f"\n=== Processing {fid} ===")
        process_fighter(fid)
