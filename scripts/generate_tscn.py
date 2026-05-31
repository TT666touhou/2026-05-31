import os
import struct
import base64
import random

def generate_tile_data():
    floor_cells = set()
    # West Room
    for x in range(-25, 26):
        for y in range(-18, 19):
            floor_cells.add((x, y))
    # East Room
    for x in range(26, 63):
        for y in range(-12, 13):
            floor_cells.add((x, y))
    # Door
    for x in range(25, 27):
        for y in range(-1, 2):
            floor_cells.add((x, y))

    wall_cells = set()
    for (x, y) in floor_cells:
        for dx in [-1, 0, 1]:
            for dy in [-1, 0, 1]:
                n = (x + dx, y + dy)
                if n not in floor_cells:
                    wall_cells.add(n)

    # Godot 4 format: int16 x, int16 y, int16 source, int16 atlas_x, int16 atlas_y, int16 alt
    # Wait, the structure in the previous dump was 12 bytes but shifted?
    # Actually, x and y might be 32-bit? No, 12 bytes total.
    # Let's write a small godot script to generate the exact base64 and print it.
    pass

if __name__ == '__main__':
    pass
