from PIL import Image, ImageDraw, ImageFont
import math
import os

def make_icon(size=1024, dark=True):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    
    # Фон
    bg = (13, 17, 40, 255) if dark else (238, 242, 255, 255)
    d.rounded_rectangle([0, 0, size, size], radius=size//5, fill=bg)
    
    cx, cy = size // 2, size // 2
    
    # Орбиты
    orbit_col = (140, 80, 32, 140)
    rw, rh = int(size * 0.42), int(size * 0.13)
    
    for angle in [-30, 30]:
        tmp = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        td = ImageDraw.Draw(tmp)
        td.ellipse([cx-rw, cy-rh, cx+rw, cy+rh], outline=orbit_col, width=max(2, size//150))
        tmp = tmp.rotate(angle, center=(cx, cy))
        img = Image.alpha_composite(img, tmp)
    
    d = ImageDraw.Draw(img)
    
    # Планеты
    pr1 = max(8, size // 55)
    pr2 = max(6, size // 70)
    planet_col = (245, 134, 46, 255)
    
    # планета сверху
    px1 = cx
    py1 = cy - int(size * 0.32)
    d.ellipse([px1-pr1, py1-pr1, px1+pr1, py1+pr1], fill=planet_col)
    
    # планета справа
    px2 = cx + int(size * 0.38)
    py2 = cy + int(size * 0.04)
    d.ellipse([px2-pr2, py2-pr2, px2+pr2, py2+pr2], fill=planet_col)
    
    # Буква A
    a_col = (255, 255, 255, 255) if dark else (26, 26, 46, 255)
    font_size = int(size * 0.52)
    
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", font_size)
        except:
            font = ImageFont.load_default()
    
    bbox = d.textbbox((0, 0), 'A', font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = cx - tw // 2
    ty = cy - th // 2 - int(size * 0.02)
    d.text((tx, ty), 'A', font=font, fill=a_col)
    
    return img

# Установи Pillow если нет
os.system('pip install Pillow')

from PIL import Image, ImageDraw, ImageFont

# Тёмная иконка
dark_icon = make_icon(1024, dark=True)
dark_icon.save('assets/icon/icon.png')
print('✅ icon.png создан')

# Foreground для adaptive icon
fg = make_icon(1024, dark=True)
fg.save('assets/icon/icon_fg.png')
print('✅ icon_fg.png создан')

print('Готово!')