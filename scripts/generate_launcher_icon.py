from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
source = root / 'assets' / 'images' / 'bazar_mark.svg'
if not source.exists():
    raise SystemExit(f'Missing brand asset: {source}')

sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

for folder, size in sizes.items():
    image = Image.new('RGBA', (size, size), '#1565C0')
    draw = ImageDraw.Draw(image)
    scale = size / 64
    draw.rounded_rectangle((0, 0, size, size), radius=18 * scale, fill='#1565C0')
    draw.polygon([(18 * scale, 25 * scale), (46 * scale, 25 * scale), (42.6 * scale, 46 * scale), (21.4 * scale, 46 * scale)], fill='white')
    draw.line([(24 * scale, 27 * scale), (24 * scale, 23 * scale), (24.5 * scale, 20 * scale), (27.6 * scale, 16.4 * scale), (32 * scale, 15 * scale), (36.4 * scale, 16.4 * scale), (39.5 * scale, 20 * scale), (40 * scale, 23 * scale), (40 * scale, 27 * scale)], fill='white', width=round(4 * scale), joint='curve')
    draw.line([(27 * scale, 34 * scale), (37 * scale, 34 * scale)], fill='#1565C0', width=round(3 * scale))
    draw.line([(32 * scale, 29 * scale), (32 * scale, 39 * scale)], fill='#1565C0', width=round(3 * scale))
    image.save(root / 'android' / 'app' / 'src' / 'main' / 'res' / folder / 'ic_launcher.png')
