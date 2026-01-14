# Datatrove Extraction Process

This process extracts clean text content from WARC (Web ARChive) files using datatrove and Trafilatura. It processes WARC archives created by the crawling process and outputs structured JSONL files with extracted text.

## Overview

The extraction pipeline:
1. Reads WARC files from the `input/` directory
2. Extracts text content using Trafilatura (precision-focused)
3. Filters out repetitive content using GopherRepetitionFilter
4. Outputs clean text data to JSONL format

## Prerequisites

- Python 3.11 or higher
- All dependencies installed via `uv sync` (from project root)

## Getting Started

### 1. Prepare WARC Files

Place your WARC files (`.warc.gz`) in the `input/` directory:

```bash
cd datatrove_extraction
# Copy WARC files from crawling output
cp ../crawling/crawl_out/<prefix>/*/*.warc.gz input/
```

The script will automatically process all `.warc.gz` files in the `input/` directory.

### 2. Run the Extraction

Run the extraction process:

```bash
cd datatrove_extraction
python process.py
```

The process will:
- Read all WARC files from `input/`
- Extract text using Trafilatura
- Filter repetitive content
- Write results to `output/data/`
- Write rejected items to `output/Rejected/`

## Output Structure

After running the extraction, you'll find:

```
output/
├── data/              # Extracted text in JSONL format
│   └── *.jsonl       # One file per WARC processed
└── Rejected/         # Filtered repetitive content
    └── *.jsonl       # Rejected documents
```

## Configuration

The extraction process can be customized by editing `process.py`:

### Key Settings

- **Trafilatura**: Uses `favour_precision=True` for high-quality extraction
- **GopherRepetitionFilter**: Automatically filters repetitive content
- **Workers**: Currently set to 1 worker (can be increased for parallel processing)
- **Tasks**: Currently set to 1 task

### Customizing the Pipeline

You can modify `process.py` to:
- Change extraction settings (e.g., `favour_precision=False` for speed)
- Adjust filtering parameters
- Add additional filters or processors
- Change output format
- Increase parallelism (workers/tasks)

Example modification for parallel processing:
```python
executor = LocalPipelineExecutor(
    pipeline=pipeline,
    logging_dir="log",
    tasks=4,      # Process 4 WARC files in parallel
    workers=2     # 2 workers per task
)
```

## Output Format

Each JSONL file contains one JSON object per line, with extracted text and metadata:

```json
{
  "id": "unique_document_id",
  "text": "Extracted clean text content...",
  "url": "https://example.com/page",
  "metadata": {
    "title": "Page Title",
    "author": "Author Name",
    "date": "2024-01-01",
    ...
  }
}
```

## Processing Details

### Trafilatura Extractor

- **Mode**: Precision-focused (`favour_precision=True`)
- Extracts main content, title, author, date, and other metadata
- Handles various HTML structures and content types
- Removes navigation, headers, footers, and other boilerplate

### GopherRepetitionFilter

- Automatically detects and filters repetitive content
- Useful for removing duplicate or near-duplicate pages
- Rejected items are saved separately for review

## Troubleshooting

**Issue**: No WARC files found
- Ensure WARC files are in the `input/` directory
- Check file extensions are `.warc.gz`
- Verify files are not corrupted

**Issue**: Memory errors
- Reduce `tasks` and `workers` in the executor
- Process WARC files in smaller batches
- Increase system memory if possible

**Issue**: Empty output files
- Check that WARC files contain valid web content
- Verify Trafilatura can extract content from the pages
- Review logs in the `log/` directory

**Issue**: Too many rejected items
- Review files in `output/Rejected/` to understand filtering
- Adjust GopherRepetitionFilter parameters if needed
- Some websites may have high repetition rates

## Logs

The extraction process creates logs in the `log/` directory:
- Processing progress
- Errors and warnings
- Statistics about extracted content

## Integration with Crawling Process

This extraction process is designed to work with WARC files created by the crawling process:

1. **Crawling** → Creates WARC files in `crawling/crawl_out/<prefix>/`
2. **Extraction** → Processes WARC files from `input/` directory
3. **Dataset** → Final output in `output/data/` (can be moved to `crawled_dataset/`)

## Notes

- The extraction process is CPU-intensive, especially with large WARC files
- Processing time depends on WARC file size and content complexity
- Trafilatura's precision mode prioritizes quality over speed
- Rejected items are preserved for review and analysis
