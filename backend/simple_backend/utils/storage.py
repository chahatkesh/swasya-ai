"""Storage helper functions for JSON file operations"""

import json


def load_json(file_path):
    """Load JSON data from file"""
    with open(file_path, 'r') as f:
        return json.load(f)


def save_json(file_path, data):
    """Save JSON data to file"""
    with open(file_path, 'w') as f:
        json.dump(data, f, indent=2)
