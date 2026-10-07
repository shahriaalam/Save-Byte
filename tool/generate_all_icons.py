import os
import math
from PIL import Image, ImageFont, ImageDraw, ImageFilter

FONT_PATH = r'D:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf'
BASE_DIR = r'd:\Save Byte'

COLOR_TOP_LEFT = (198, 40, 40)    # #C62828
COLOR_BOTTOM_RIGHT = (139, 0, 0)  # #8B0000

def create_gradient(width, height, color1=COLOR_TOP_LEFT, color2=COLOR_BOTTOM_RIGHT):
    base = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    r1, g1, b1 = color1
    r2, g2, b2 = color2
    pixels = []
    for y in range(height):
        for x in range(width):
            t = (x / width + y / height) / 2.0
            r = int(r1 + (r2 - r1) * t)
            g = int(g1 + (g2 - g1) * t)
            b = int(b1 + (b2 - b1) * t)
            pixels.append((r, g, b, 255))
    base.putdata(pixels)
    return base

def render_cutlery_glyph(size, icon_ratio=0.52):
    font_size = int(size * icon_ratio)
    font = ImageFont.truetype(FONT_PATH, font_size)
    char = '\U000f0108'
    bbox = font.getbbox(char)
    glyph_w = bbox[2] - bbox[0]
    glyph_h = bbox[3] - bbox[1]
    
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pos_x = (size - glyph_w) / 2.0 - bbox[0]
    pos_y = (size - glyph_h) / 2.0 - bbox[1]
    draw.text((pos_x, pos_y), char, font=font, fill=(255, 255, 255, 255))
    return img

def create_full_bleed_icon(size=1024, icon_ratio=0.52):
    bg = create_gradient(size, size)
    glyph = render_cutlery_glyph(size, icon_ratio)
    return Image.alpha_composite(bg, glyph)

def create_rounded_icon(size=1024, radius_ratio=0.24, icon_ratio=0.52, padding_ratio=0.04):
    """Creates a rounded icon with soft drop shadow for legacy Android / web / desktop."""
    actual_size = int(size * (1 - padding_ratio * 2))
    pad = int(size * padding_ratio)
    
    bg = create_gradient(actual_size, actual_size)
    glyph = render_cutlery_glyph(actual_size, icon_ratio)
    comp = Image.alpha_composite(bg, glyph)
    
    # Rounded mask with antialiasing
    scale = 4
    mask = Image.new('L', (actual_size * scale, actual_size * scale), 0)
    draw = ImageDraw.Draw(mask)
    r = int(actual_size * scale * radius_ratio)
    draw.rounded_rectangle((0, 0, actual_size * scale, actual_size * scale), radius=r, fill=255)
    mask = mask.resize((actual_size, actual_size), Image.Resampling.LANCZOS)
    
    comp.putalpha(mask)
    
    # Shadow layer
    shadow_canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    s_mask = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_mask)
    s_r = int(actual_size * radius_ratio)
    s_draw.rounded_rectangle((pad, pad + int(size * 0.02), pad + actual_size, pad + actual_size + int(size * 0.02)), radius=s_r, fill=(0, 0, 0, 90))
    s_blur = s_mask.filter(ImageFilter.GaussianBlur(radius=size * 0.025))
    
    # Combine shadow and rounded icon
    result = Image.alpha_composite(s_blur, shadow_canvas)
    result.paste(comp, (pad, pad), comp)
    return result

def create_circular_icon(size=1024, icon_ratio=0.48, padding_ratio=0.04):
    """Creates a circular icon for Android round icons."""
    actual_size = int(size * (1 - padding_ratio * 2))
    pad = int(size * padding_ratio)
    
    bg = create_gradient(actual_size, actual_size)
    glyph = render_cutlery_glyph(actual_size, icon_ratio)
    comp = Image.alpha_composite(bg, glyph)
    
    scale = 4
    mask = Image.new('L', (actual_size * scale, actual_size * scale), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, actual_size * scale, actual_size * scale), fill=255)
    mask = mask.resize((actual_size, actual_size), Image.Resampling.LANCZOS)
    comp.putalpha(mask)
    
    # Soft shadow
    s_mask = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(s_mask)
    s_draw.ellipse((pad, pad + int(size * 0.02), pad + actual_size, pad + actual_size + int(size * 0.02)), fill=(0, 0, 0, 80))
    s_blur = s_mask.filter(ImageFilter.GaussianBlur(radius=size * 0.025))
    
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    result = Image.alpha_composite(result, s_blur)
    result.paste(comp, (pad, pad), comp)
    return result

def generate_all():
    print('Generating master assets...')
    master_full = create_full_bleed_icon(1024, icon_ratio=0.52)
    master_rounded = create_rounded_icon(1024, radius_ratio=0.24, icon_ratio=0.52)
    master_circular = create_circular_icon(1024, icon_ratio=0.48)
    
    # Master PNG in assets
    assets_dir = os.path.join(BASE_DIR, 'assets', 'images')
    os.makedirs(assets_dir, exist_ok=True)
    master_full.save(os.path.join(assets_dir, 'app_logo.png'), format='PNG')
    master_rounded.save(os.path.join(assets_dir, 'app_logo_rounded.png'), format='PNG')
    print('Saved master logo images to assets/images/')
    
    # -------------------------------------------------------------
    # 1. iOS App Icons (Must be RGB, no alpha)
    # -------------------------------------------------------------
    ios_dir = os.path.join(BASE_DIR, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    ios_sizes = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }
    
    # iOS uses full bleed RGB without alpha
    master_ios = master_full.convert('RGB')
    for filename, sz in ios_sizes.items():
        resized = master_ios.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(os.path.join(ios_dir, filename), format='PNG')
    print(f'Generated {len(ios_sizes)} iOS icons.')

    # -------------------------------------------------------------
    # 2. Android Icons
    # -------------------------------------------------------------
    android_res = os.path.join(BASE_DIR, 'android', 'app', 'src', 'main', 'res')
    android_densities = {
        'mipmap-mdpi': (48, 108),
        'mipmap-hdpi': (72, 162),
        'mipmap-xhdpi': (96, 216),
        'mipmap-xxhdpi': (144, 324),
        'mipmap-xxxhdpi': (192, 432),
    }
    
    for folder, (launcher_sz, adaptive_sz) in android_densities.items():
        folder_path = os.path.join(android_res, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        # Legacy ic_launcher.png (rounded squircle)
        sq = master_rounded.resize((launcher_sz, launcher_sz), Image.Resampling.LANCZOS)
        sq.save(os.path.join(folder_path, 'ic_launcher.png'), format='PNG')
        
        # Legacy ic_launcher_round.png (circular)
        cir = master_circular.resize((launcher_sz, launcher_sz), Image.Resampling.LANCZOS)
        cir.save(os.path.join(folder_path, 'ic_launcher_round.png'), format='PNG')
        
        # Adaptive foreground layer (108dp canvas, cutlery centered ~42%)
        fg = render_cutlery_glyph(adaptive_sz, icon_ratio=0.40)
        fg.save(os.path.join(folder_path, 'ic_launcher_foreground.png'), format='PNG')
    
    print('Generated Android mipmap icons & adaptive foregrounds.')

    # Adaptive XMLs
    # drawable/ic_launcher_background.xml
    drawable_dir = os.path.join(android_res, 'drawable')
    os.makedirs(drawable_dir, exist_ok=True)
    with open(os.path.join(drawable_dir, 'ic_launcher_background.xml'), 'w', encoding='utf-8') as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="rectangle">
    <gradient
        android:type="linear"
        android:angle="315"
        android:startColor="#C62828"
        android:endColor="#8B0000" />
</shape>
''')

    # mipmap-anydpi-v26/ic_launcher.xml
    v26_dir = os.path.join(android_res, 'mipmap-anydpi-v26')
    os.makedirs(v26_dir, exist_ok=True)
    with open(os.path.join(v26_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')
    with open(os.path.join(v26_dir, 'ic_launcher_round.xml'), 'w', encoding='utf-8') as f:
        f.write('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''')
    print('Generated Android adaptive XML drawables.')

    # -------------------------------------------------------------
    # 3. Web Icons
    # -------------------------------------------------------------
    web_dir = os.path.join(BASE_DIR, 'web')
    web_icons_dir = os.path.join(web_dir, 'icons')
    os.makedirs(web_icons_dir, exist_ok=True)
    
    # Favicon: 48x48 rounded
    fav = master_rounded.resize((48, 48), Image.Resampling.LANCZOS)
    fav.save(os.path.join(web_dir, 'favicon.png'), format='PNG')
    
    # Standard PWA icons (rounded squircle)
    master_rounded.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-192.png'), format='PNG')
    master_rounded.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, 'Icon-512.png'), format='PNG')
    
    # Maskable PWA icons (full bleed, icon ratio ~0.46 for safe area)
    maskable_192 = create_full_bleed_icon(192, icon_ratio=0.46)
    maskable_512 = create_full_bleed_icon(512, icon_ratio=0.46)
    maskable_192.save(os.path.join(web_icons_dir, 'Icon-maskable-192.png'), format='PNG')
    maskable_512.save(os.path.join(web_icons_dir, 'Icon-maskable-512.png'), format='PNG')
    print('Generated Web icons and favicon.')

    # -------------------------------------------------------------
    # 4. Windows .ico
    # -------------------------------------------------------------
    win_res_dir = os.path.join(BASE_DIR, 'windows', 'runner', 'resources')
    os.makedirs(win_res_dir, exist_ok=True)
    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    master_rounded.save(os.path.join(win_res_dir, 'app_icon.ico'), format='ICO', sizes=ico_sizes)
    print('Generated Windows app_icon.ico.')

if __name__ == '__main__':
    generate_all()
    print('All platform icons successfully generated!')
