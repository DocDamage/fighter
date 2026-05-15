import json
import os
from pathlib import Path

BASE = Path("assets/characters/processed")

# Frame maps based on visual inspection of contact sheets.
# Both Ryu and Ken share the same GIF sheet layout (same game, same character template).
# Ken has fewer total frames (175 vs 181) but the early frames align.

RYU_MAP = {
    "idle":       {"frames": [0, 1, 2, 3],        "fps": 8,  "loop": True},
    "walk":       {"frames": [4, 5, 6, 7, 8],     "fps": 10, "loop": True},
    "jump":       {"frames": [9, 10, 11, 12, 13], "fps": 10, "loop": False},
    "jump_fwd":   {"frames": [14, 15, 16, 17, 18, 19], "fps": 10, "loop": False},
    "crouch":     {"frames": [20, 21, 22],        "fps": 12, "loop": True},
    "block":      {"frames": [24, 25],             "fps": 12, "loop": True},
    "st_lp":      {"frames": [30, 31, 32, 33],    "fps": 12, "loop": False},
    "st_mp":      {"frames": [34, 35, 36, 37, 38],"fps": 12, "loop": False},
    "st_hp":      {"frames": [39, 40, 41, 42],    "fps": 12, "loop": False},
    "st_lk":      {"frames": [43, 44, 45, 46],    "fps": 12, "loop": False},
    "st_mk":      {"frames": [47, 48, 49, 50],    "fps": 12, "loop": False},
    "st_hk":      {"frames": [51, 52, 53, 54, 55, 56, 57, 58, 59], "fps": 12, "loop": False},
    "hitstun":    {"frames": [60, 61, 62, 63, 64, 65], "fps": 12, "loop": False},
    "cr_lp":      {"frames": [82, 83, 84],        "fps": 12, "loop": False},
    "cr_mp":      {"frames": [85, 86, 87],        "fps": 12, "loop": False},
    "cr_hp":      {"frames": [88, 89, 90],        "fps": 12, "loop": False},
    "cr_lk":      {"frames": [91, 92, 93],        "fps": 12, "loop": False},
    "cr_mk":      {"frames": [94, 95, 96],        "fps": 12, "loop": False},
    "cr_hk":      {"frames": [98, 99],             "fps": 12, "loop": False},
    "jmp_lp":     {"frames": [100, 101],           "fps": 12, "loop": False},
    "jmp_mp":     {"frames": [102, 103, 104],      "fps": 12, "loop": False},
    "jmp_hp":     {"frames": [105, 106, 107],      "fps": 12, "loop": False},
    "jmp_lk":     {"frames": [108, 109],           "fps": 12, "loop": False},
    "jmp_mk":     {"frames": [110, 111, 112],      "fps": 12, "loop": False},
    "shoryuken":  {"frames": [113, 114, 115, 116, 117, 118, 119], "fps": 12, "loop": False},
    "tatsumaki":  {"frames": [120, 121, 122, 123, 124, 125, 126], "fps": 12, "loop": False},
    "hadoken":    {"frames": [128, 129],           "fps": 12, "loop": False},
    "knockdown":  {"frames": [144, 145, 146, 147, 148], "fps": 10, "loop": False},
    "getup":      {"frames": [160, 161, 162, 163, 164, 165, 166, 167], "fps": 10, "loop": False},
    "victory":    {"frames": [174, 175],           "fps": 8,  "loop": True},
}

# Ken layout is identical for the first ~130 frames but diverges after.
# Ken only has 175 frames (0-174), so victory must use 173-174.
KEN_MAP = {
    "idle":       {"frames": [0, 1, 2, 3],        "fps": 8,  "loop": True},
    "walk":       {"frames": [4, 5, 6, 7, 8],     "fps": 10, "loop": True},
    "jump":       {"frames": [9, 10, 11, 12, 13], "fps": 10, "loop": False},
    "jump_fwd":   {"frames": [14, 15, 16, 17, 18, 19], "fps": 10, "loop": False},
    "crouch":     {"frames": [20, 21, 22],        "fps": 12, "loop": True},
    "block":      {"frames": [24, 25],             "fps": 12, "loop": True},
    "st_lp":      {"frames": [30, 31, 32, 33],    "fps": 12, "loop": False},
    "st_mp":      {"frames": [34, 35, 36, 37, 38],"fps": 12, "loop": False},
    "st_hp":      {"frames": [39, 40, 41, 42],    "fps": 12, "loop": False},
    "st_lk":      {"frames": [43, 44, 45, 46],    "fps": 12, "loop": False},
    "st_mk":      {"frames": [47, 48, 49, 50],    "fps": 12, "loop": False},
    "st_hk":      {"frames": [51, 52, 53, 54, 55, 56, 57, 58, 59], "fps": 12, "loop": False},
    "hitstun":    {"frames": [60, 61, 62, 63, 64, 65], "fps": 12, "loop": False},
    "cr_lp":      {"frames": [82, 83, 84],        "fps": 12, "loop": False},
    "cr_mp":      {"frames": [85, 86, 87],        "fps": 12, "loop": False},
    "cr_hp":      {"frames": [88, 89, 90],        "fps": 12, "loop": False},
    "cr_lk":      {"frames": [91, 92, 93],        "fps": 12, "loop": False},
    "cr_mk":      {"frames": [94, 95, 96],        "fps": 12, "loop": False},
    "cr_hk":      {"frames": [98, 99],             "fps": 12, "loop": False},
    "jmp_lp":     {"frames": [100, 101],           "fps": 12, "loop": False},
    "jmp_mp":     {"frames": [102, 103, 104],      "fps": 12, "loop": False},
    "jmp_hp":     {"frames": [105, 106, 107],      "fps": 12, "loop": False},
    "jmp_lk":     {"frames": [108, 109],           "fps": 12, "loop": False},
    "jmp_mk":     {"frames": [110, 111, 112],      "fps": 12, "loop": False},
    # Ken's special frames are slightly different; 113-119 covers his Hadoken+Shoryuken startup
    "shoryuken":  {"frames": [113, 114, 115, 116, 117, 118, 119], "fps": 12, "loop": False},
    "tatsumaki":  {"frames": [120, 121, 122, 123, 124, 125, 126], "fps": 12, "loop": False},
    "hadoken":    {"frames": [113, 114],           "fps": 12, "loop": False},
    "knockdown":  {"frames": [144, 145, 146, 147, 148], "fps": 10, "loop": False},
    "getup":      {"frames": [160, 161, 162, 163, 164, 165, 166, 167], "fps": 10, "loop": False},
    "victory":    {"frames": [173, 174],           "fps": 8,  "loop": True},
}

def validate_and_save(fighter_id: str, anim_map: dict):
    folder = BASE / fighter_id
    frame_files = sorted([f for f in folder.iterdir() if f.suffix == '.png' and f.stem.startswith(fighter_id)])
    total_frames = len(frame_files)
    
    print(f"\n=== {fighter_id.upper()} ===")
    print(f"Total PNG frames: {total_frames}")
    
    # Filter out invalid frame references and warn
    cleaned_map = {}
    for anim_name, data in anim_map.items():
        valid_frames = []
        for fi in data["frames"]:
            if fi < total_frames:
                valid_frames.append(fi)
            else:
                print(f"  WARNING: {anim_name} dropped frame {fi} (out of range, max={total_frames-1})")
        if valid_frames:
            cleaned_map[anim_name] = {
                "frames": valid_frames,
                "fps": data["fps"],
                "loop": data["loop"]
            }
    
    # Check coverage
    used_frames = set()
    for data in cleaned_map.values():
        used_frames.update(data["frames"])
    unused = set(range(total_frames)) - used_frames
    print(f"Animations: {len(cleaned_map)}, Used frames: {len(used_frames)}, Unused: {len(unused)}")
    
    # Save frame map
    with open(folder / f"{fighter_id}_frame_map.json", 'w') as f:
        json.dump(cleaned_map, f, indent=2)
    
    print(f"Saved: {folder / f'{fighter_id}_frame_map.json'}")

if __name__ == "__main__":
    validate_and_save("ryu", RYU_MAP)
    validate_and_save("ken", KEN_MAP)
