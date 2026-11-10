#!/usr/bin/env python3
"""Measure recorded CLI-contract screenshots; keep renderer runs separate."""
import json
from pathlib import Path
import sys
from PIL import Image, ImageChops

root = Path(sys.argv[1])


def image(name):
    return Image.open(root / f'{name}.png').convert('RGB')


def mask(im, color):
    r, g, b = ImageChops.difference(im, Image.new('RGB', im.size, color)).split()
    return ImageChops.lighter(r, ImageChops.lighter(g, b)).point(lambda v: 255 if v == 0 else 0)


base = image('01-loaded')
crop = mask(base, (22, 36, 56)).getbbox()
if crop is None:
    raise SystemExit('CLI artboard background not found; inspect screenshots')


def changes(a, b):
    diff = ImageChops.difference(image(a).crop(crop), image(b).crop(crop))
    return sum(max(pixel) != 0 for pixel in diff.getdata())


card = (84, 113, 141)
small = mask(image('08-number-small'), card).getbbox()
large = mask(image('07-number-large'), card).getbbox()
start = mask(base, card).getbbox()
trigger = mask(image('04-trigger'), card).getbbox()
if not all((small, large, start, trigger)):
    raise SystemExit('CLI card geometry missing; inspect screenshots')
report = {
    'artboard_crop': crop,
    'playing_changed_pixels': changes('01-loaded', '02-playing'),
    'paused_changed_pixels': changes('09-paused', '10-paused'),
    'resumed_changed_pixels': changes('10-paused', '11-resumed'),
    'boolean_on_green_bbox': mask(image('05-boolean-on'), (37, 182, 140)).getbbox(),
    'boolean_off_blue_bbox': mask(image('06-boolean-off'), card).getbbox(),
    'small_bbox': small, 'large_bbox': large,
    'width_ratio': (large[2]-large[0])/(small[2]-small[0]),
    'trigger_upward_pixels': start[1]-trigger[1],
    'text_review': 'read 03-text.png separately; string callback alone does not prove glyphs',
    'scope': 'same renderer and captured frames; no cross-backend pixel-equivalence claim',
}
(root / 'visual-metrics.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report, indent=2))
