from PIL import Image, ImageDraw, ImageFont
import os

start = 0x0400
end = 0x04FF

os.makedirs("cyrillic_chars", exist_ok=True)

font = ImageFont.truetype("/usr/share/fonts/liberation-mono-fonts/LiberationMono-Regular.ttf", 18)

for codepoint in range(start, end + 1):
	char = chr(codepoint)
	img = Image.new("RGBA", (11, 22), (0, 0, 0, 0))
	draw = ImageDraw.Draw(img)

	bbox = draw.textbbox((0, 0), char, font=font)
	w = bbox[2] - bbox[0]
	h = bbox[3] - bbox[1]

	draw.text(((11 - w) // 2, (22 - h) // 2), char, font=font, fill=(255, 255, 255, 255))
	if char.isupper():
		filename = f"W_U{char}.png"
	else:
		filename = f"W_{char}.png"
	img.save(os.path.join("cyrillic_chars", filename))
