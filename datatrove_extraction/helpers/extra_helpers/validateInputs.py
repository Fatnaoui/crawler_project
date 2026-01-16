from pathlib import Path

def validate_inputs():
    input_dir = Path(__file__).parent.parent.parent / "input"
    if not input_dir.exists():
        raise FileNotFoundError(f"Input directory not found: {input_dir}")
    
    warc_files = [file for file in input_dir.glob("*.warc.gz") if file.is_file()]
    if not warc_files:
        raise ValueError(f"No WARC files found in {input_dir}")
    
    # Validate output directories can be created
    output_dir = Path(__file__).parent.parent.parent / "output"
    output_dir.mkdir(parents=True, exist_ok=True)
    
    num_files = len(warc_files)
    print(f"Found {num_files} WARC files to process")

