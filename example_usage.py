#!/usr/bin/env python3
"""
Example usage of the download_model.py script
"""

import subprocess
import sys
from pathlib import Path

def run_example():
    """Run example downloads to demonstrate the script"""
    
    print("Hugging Face Model Downloader - Example Usage")
    print("=" * 50)
    
    # Example 1: Download a small model
    print("\n1. Downloading a small model (microsoft/DialoGPT-small):")
    print("-" * 50)
    
    cmd = [
        "python", "download_model.py", 
        "microsoft/DialoGPT-small",
        "--download-dir", "./example_models",
        "--verbose"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        print("STDOUT:", result.stdout.decode())
        if result.stderr:
            print("STDERR:", result.stderr)
        print(f"Return code: {result.returncode}")
    except subprocess.TimeoutExpired:
        print("Download timed out (this is normal for large models)")
    except Exception as e:
        print(f"Error running example: {e}")
    
    print("\n" + "=" * 50)
    print("Example completed!")
    print("\nTo use the script manually:")
    print("1. Set your HF_TOKEN environment variable or create a .env file")
    print("2. Run: python download_model.py <model_id>")
    print("3. Example: python download_model.py microsoft/DialoGPT-medium")

if __name__ == "__main__":
    run_example()
