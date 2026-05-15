#!/usr/bin/env python3
"""Generate .png.import files for all PNGs in a folder using a template."""
import os
import sys
import random
import string
from pathlib import Path

TEMPLATE = """[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://{uid}"
path="res://.godot/imported/{base_name}-{hash}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="res://{rel_source}"
dest_files=["res://.godot/imported/{base_name}-{hash}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/bptc_ldr=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
"""

def random_uid():
    """Generate a Godot-style uid string."""
    chars = string.ascii_lowercase + string.digits
    return ''.join(random.choices(chars, k=13))

def random_hash():
    """Generate a Godot-style import hash."""
    chars = string.hexdigits.lower()
    return ''.join(random.choices(chars, k=32))

def generate_for_folder(folder: Path):
    pngs = sorted(folder.glob("*.png"))
    if not pngs:
        print(f"No PNGs found in {folder}")
        return
    
    for png in pngs:
        import_path = png.with_suffix('.png.import')
        if import_path.exists():
            continue  # Skip existing
        
        rel_source = png.relative_to(folder.parent.parent.parent.parent).as_posix()
        base_name = png.name
        uid = random_uid()
        hash_val = random_hash()
        
        content = TEMPLATE.format(
            uid=uid,
            base_name=base_name,
            hash=hash_val,
            rel_source=rel_source
        )
        import_path.write_text(content, encoding='utf-8')
    
    print(f"Generated .import files for {len(pngs)} PNGs in {folder}")

if __name__ == "__main__":
    BASE = Path(__file__).parent.parent.parent / "assets" / "characters" / "processed"
    for name in ["ryu", "ken", "guile", "chun_li"]:
        folder = BASE / name
        if folder.exists():
            generate_for_folder(folder)
        else:
            print(f"Folder not found: {folder}")
