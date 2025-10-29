#!/usr/bin/env python3
"""
Hugging Face Model Downloader

A script to download models from Hugging Face Hub with command line interface.
Supports token authentication from environment variables or .env file.
"""

import os
import sys
import argparse
import logging
from pathlib import Path

try:
    from huggingface_hub import snapshot_download, list_repo_files, hf_hub_download
    from huggingface_hub.utils import HfHubHTTPError
except ImportError:
    print("Error: huggingface_hub is not installed.")
    print("Please install it with: pip install huggingface_hub>=0.16.0 requests>=2.28.0 tqdm>=4.64.0")
    sys.exit(1)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def get_hf_token():
    """Get HuggingFace token from environment variable or .env file"""
    # First try environment variable
    hf_token = os.environ.get("HF_TOKEN")
    if hf_token:
        logger.info("Using HF_TOKEN from environment")
        return hf_token
    
    # Try to load from .env file
    env_path = Path(".env")
    if env_path.exists():
        logger.info("Looking for HF_TOKEN in .env file")
        with open(env_path) as f:
            for line in f:
                if line.startswith("HF_TOKEN="):
                    hf_token = line.strip().split("=", 1)[1]
                    logger.info("Found HF_TOKEN in .env file")
                    return hf_token
    
    logger.warning("No HF_TOKEN found in environment or .env file")
    logger.warning("Some models may require authentication. Get a token at: https://huggingface.co/settings/tokens")
    return None


def download_model(model_id, download_dir, token=None, revision="main"):
    """Download a complete model from HuggingFace Hub"""
    try:
        logger.info(f"Starting download of model: {model_id}")
        logger.info(f"Target directory: {download_dir}")
        logger.info(f"Revision: {revision}")
        
        # Create safe directory name from model_id
        safe_name = model_id.replace('/', '_').replace('\\', '_')
        model_path = Path(download_dir) / safe_name
        model_path.mkdir(parents=True, exist_ok=True)
        
        # Download the model
        downloaded_path = snapshot_download(
            repo_id=model_id,
            local_dir=str(model_path),
            token=token if token else None,
            revision=revision,
        )
        
        logger.info(f"Successfully downloaded to: {downloaded_path}")
        
        # Show download summary
        if model_path.exists():
            files = list(model_path.rglob('*'))
            file_list = [f for f in files if f.is_file()]
            file_count = len(file_list)
            
            total_size = sum(f.stat().st_size for f in file_list)
            total_size_mb = total_size / (1024 * 1024)
            
            logger.info(f"Downloaded {file_count} files ({total_size_mb:.2f} MB)")
            
            # Show first few files
            logger.info("Downloaded files:")
            for i, file in enumerate(file_list[:5]):
                size_mb = file.stat().st_size / (1024 * 1024)
                relative_path = file.relative_to(model_path)
                logger.info(f"  {relative_path}: {size_mb:.2f} MB")
            
            if file_count > 5:
                logger.info(f"  ... and {file_count - 5} more files")
        
        return str(downloaded_path)
        
    except HfHubHTTPError as e:
        if e.response.status_code == 404:
            logger.error(f"Model '{model_id}' not found. Please check the model ID.")
            logger.error("You can search for models at: https://huggingface.co/models")
            sys.exit(1)
        elif e.response.status_code == 401:
            logger.error(f"Access denied to model '{model_id}'.")
            logger.error("This model might be private. You may need a HuggingFace token.")
            logger.error("Get a token at: https://huggingface.co/settings/tokens")
            sys.exit(1)
        else:
            logger.error(f"HTTP error: {e}")
            sys.exit(1)
    except Exception as e:
        logger.error(f"Error downloading model: {e}")
        sys.exit(1)


def main():
    """Main function with command line argument parsing"""
    parser = argparse.ArgumentParser(
        description="Download models from Hugging Face Hub",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python download_model.py microsoft/DialoGPT-medium
  python download_model.py RedHatAI/Magistral-Small-2506-FP8 --download-dir ./my-models
  python download_model.py microsoft/DialoGPT-medium --revision v1.0
        """
    )
    
    parser.add_argument(
        "model_id",
        help="Hugging Face model ID (e.g., 'microsoft/DialoGPT-medium')"
    )
    
    parser.add_argument(
        "--download-dir",
        default="./models",
        help="Directory to download the model to (default: ./models)"
    )
    
    parser.add_argument(
        "--revision",
        default="main",
        help="Model revision/branch to download (default: main)"
    )
    
    parser.add_argument(
        "--token",
        help="Hugging Face token (overrides environment and .env file)"
    )
    
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose logging"
    )
    
    args = parser.parse_args()
    
    # Set logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Get token
    if args.token:
        hf_token = args.token
        logger.info("Using token from command line argument")
    else:
        hf_token = get_hf_token()
    
    # Convert download_dir to absolute path
    download_dir = Path(args.download_dir).resolve()
    
    # Download the model
    try:
        downloaded_path = download_model(
            model_id=args.model_id,
            download_dir=str(download_dir),
            token=hf_token,
            revision=args.revision
        )
        
        print("\n" + "="*60)
        print("✅ MODEL DOWNLOAD COMPLETED SUCCESSFULLY!")
        print("="*60)
        print(f"Model ID: {args.model_id}")
        print(f"Downloaded to: {downloaded_path}")
        print(f"Download directory: {download_dir}")
        print("="*60)
        
    except KeyboardInterrupt:
        logger.info("Download interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
