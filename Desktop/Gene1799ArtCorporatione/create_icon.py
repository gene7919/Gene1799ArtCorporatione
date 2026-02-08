#!/usr/bin/env python3
"""
Gene1799 Icon Generator
Creates professional icon for the GUI application
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_gene1799_icon():
    """Create a professional Gene1799 icon"""
    
    # Create image (256x256)
    size = 256
    image = Image.new('RGB', (size, size), color='#0d1117')
    draw = ImageDraw.Draw(image)
    
    # Draw gradient-like background
    for i in range(size):
        color_value = 13 + int((51 - 13) * (i / size))
        draw.line([(0, i), (size, i)], fill=(color_value, color_value, color_value))
    
    # Draw border
    border_color = (0, 217, 255)  # Cyan
    draw.rectangle([(10, 10), (size-10, size-10)], outline=border_color, width=3)
    
    # Draw center circle
    circle_size = 120
    left = (size - circle_size) // 2
    top = (size - circle_size) // 2
    draw.ellipse(
        [(left, top), (left + circle_size, top + circle_size)],
        outline=border_color, width=2
    )
    
    # Draw inner design
    center_x = size // 2
    center_y = size // 2
    
    # Draw AI symbol (neural network nodes)
    nodes = [
        (center_x - 30, center_y - 30),
        (center_x + 30, center_y - 30),
        (center_x - 30, center_y + 30),
        (center_x + 30, center_y + 30),
        (center_x, center_y),
    ]
    
    # Draw connections (green)
    green_color = (0, 255, 65)
    for i, node1 in enumerate(nodes):
        for node2 in nodes[i+1:]:
            draw.line([node1, node2], fill=green_color, width=1)
    
    # Draw nodes (cyan)
    for node in nodes:
        draw.ellipse(
            [(node[0]-4, node[1]-4), (node[0]+4, node[1]+4)],
            fill=border_color, outline=green_color, width=1
        )
    
    # Add text (small)
    try:
        # Try to use a nice font, fallback to default
        font = ImageFont.truetype("arial.ttf", 20)
    except:
        font = ImageFont.load_default()
    
    text = "G1799"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = size - 40
    
    draw.text((text_x, text_y), text, fill=border_color, font=font)
    
    # Save as ICO
    icon_path = os.path.join(os.getcwd(), 'gene1799_icon.ico')
    image.save(icon_path, 'ICO', sizes=[(256, 256)])
    
    print(f"✓ Icon created: {icon_path}")
    return icon_path


if __name__ == '__main__':
    try:
        create_gene1799_icon()
    except ImportError:
        print("Installing PIL...")
        import subprocess
        subprocess.check_call(['pip', 'install', 'pillow', '-q'])
        create_gene1799_icon()
