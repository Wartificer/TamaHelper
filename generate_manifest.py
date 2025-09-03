#!/usr/bin/env python3
import os
import json
import hashlib
from pathlib import Path

def calculate_file_hash(filepath):
    """Calculate SHA256 hash of a file."""
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        # Read file in chunks to handle large files
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()[:10]  # Use first 10 chars for shorter hash

def calculate_combined_hash(json_file, png_file=None):
    """Calculate hash of JSON file and optional PNG file together."""
    sha256_hash = hashlib.sha256()
    
    # Always include JSON file
    with open(json_file, "rb") as f:
        # Read file in chunks to handle large files
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    
    # Include PNG file if it exists
    if png_file and png_file.exists():
        with open(png_file, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
    
    return sha256_hash.hexdigest()[:10]

def calculate_file_hash(filepath):
    """Calculate SHA256 hash of a file."""
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        # Read file in chunks to handle large files
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()[:10]  # Use first 10 chars for shorter hash

def calculate_folder_hash(folder_path):
    """Calculate hash based on all files in a folder."""
    all_files = []
    for root, dirs, files in os.walk(folder_path):
        for file in sorted(files):  # Sort for consistent hashing
            file_path = os.path.join(root, file)
            with open(file_path, 'rb') as f:
                all_files.append(f.read())
    
    # Combine all file contents and hash
    combined_content = b''.join(all_files)
    return hashlib.sha256(combined_content).hexdigest()[:10]

def generate_manifest():
    """Generate the manifest.json file."""
    data_dir = Path("data")
    manifest = {
        "characters": {},
        "scenarios": {},
        "supports": {}
    }
    
    if not data_dir.exists():
        print("Data directory not found!")
        return
    
    # Process characters (JSON files + optional PNG files)
    characters_dir = data_dir / "characters"
    if characters_dir.exists():
        for json_file in characters_dir.glob("*.json"):
            name = json_file.stem  # filename without extension
            png_file = characters_dir / f"{name}.png"
            file_hash = calculate_combined_hash(json_file, png_file)
            manifest["characters"][name] = file_hash
            png_status = "with PNG" if png_file.exists() else "JSON only"
            print(f"Character: {name} -> {file_hash} ({png_status})")
    
    # Process supports (JSON files + optional PNG files)
    supports_dir = data_dir / "supports"
    if supports_dir.exists():
        for json_file in supports_dir.glob("*.json"):
            name = json_file.stem
            png_file = supports_dir / f"{name}.png"
            file_hash = calculate_combined_hash(json_file, png_file)
            manifest["supports"][name] = file_hash
            png_status = "with PNG" if png_file.exists() else "JSON only"
            print(f"Support: {name} -> {file_hash} ({png_status})")
    
    # Process scenarios (folders with data.json)
    scenarios_dir = data_dir / "scenarios"
    if scenarios_dir.exists():
        for scenario_folder in scenarios_dir.iterdir():
            if scenario_folder.is_dir():
                data_json = scenario_folder / "data.json"
                if data_json.exists():
                    # Hash the entire folder contents
                    folder_hash = calculate_folder_hash(scenario_folder)
                    manifest["scenarios"][scenario_folder.name] = folder_hash
                    print(f"Scenario: {scenario_folder.name} -> {folder_hash}")
    
    # Write manifest
    with open("manifest.json", "w") as f:
        json.dump(manifest, f, indent=2)
    
    print(f"\nManifest generated with:")
    print(f"- {len(manifest['characters'])} characters")
    print(f"- {len(manifest['supports'])} supports")  
    print(f"- {len(manifest['scenarios'])} scenarios")

if __name__ == "__main__":
    generate_manifest()