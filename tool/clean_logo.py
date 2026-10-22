import sys
from PIL import Image, ImageDraw, ImageChops
src, dst, radius = sys.argv[1], sys.argv[2], int(sys.argv[3])
im = Image.open(src).convert('RGBA')
w, h = im.size
# Contour du logo (carré arrondi) mesuré sur le fichier : x 8→713, y 3→668.
box = (7, 2, 713, 668)
S = 4
big = Image.new('L', (w * S, h * S), 0)
ImageDraw.Draw(big).rounded_rectangle([c * S for c in box], radius=radius * S, fill=255)
shape = big.resize((w, h), Image.LANCZOS)
# On ne garde en plus que les pixels non clairs près du bord (le damier est clair).
px = im.load()
light = Image.new('L', (w, h), 255)
lp = light.load()
for y in range(h):
    for x in range(w):
        r, g, b, _ = px[x, y]
        if min(r, g, b) > 120 and max(r, g, b) - min(r, g, b) < 35:
            lp[x, y] = 0
inner = Image.new('L', (w, h), 0)
ImageDraw.Draw(inner).rounded_rectangle([box[0]+10, box[1]+10, box[2]-10, box[3]-10], radius=radius-10, fill=255)
keep_light = ImageChops.lighter(light, inner)  # le blanc du texte reste intact
im.putalpha(ImageChops.multiply(shape, keep_light))
im.save(dst, optimize=True)
