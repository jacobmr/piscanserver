#!/usr/bin/env python3
import sys

def parse_config(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    options = []
    for line in lines:
        parts = line.strip().split(' ')
        option_name = parts[0]
        default_value = None
        for part in parts:
            if part.startswith('[') and part.endswith(']'):
                default_value = part[1:-1]
                break
        if default_value is not None:
            options.append(f"{option_name} {default_value}")

    return ' '.join(options)

print(parse_config(sys.argv[1]))
