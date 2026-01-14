# Crawler Project

A comprehensive web crawling and text extraction pipeline that creates WARC archives from websites and extracts clean text content for downstream processing.

## Overview

This project consists of three main processes:

1. **Crawling** - Web crawling using wget to create WARC (Web ARChive) files
2. **Datatrove Extraction** - Text extraction from WARC files using datatrove and Trafilatura
3. **Crawled Dataset** - Final processed dataset output

## Project Structure

```
crawler_project/
├── crawling/              # Web crawling process
│   ├── crawl_script.sh    # Main crawling script
│   ├── file.txt          # Input URLs file
│   ├── crawl_out/        # WARC output directory
│   └── helpers/          # Helper scripts
├── datatrove_extraction/ # Text extraction process
│   ├── process.py        # Main extraction script
│   ├── input/            # WARC input directory
│   └── output/           # Extracted text output
├── crawled_dataset/       # Final processed dataset
└── pyproject.toml        # Project dependencies
```

## Prerequisites

- **Python 3.11** or higher
- `wget` (with WARC support)
- `uv` package manager

## Installation

Install all project dependencies using `uv`:

```bash
uv sync
```

This will install all required packages listed in `pyproject.toml`, including:
- `datatrove[all]` - Text extraction pipeline
- `trafilatura` - Web content extraction
- `warcio` - WARC file handling
- `wget` - Web crawling

## Workflow

### 1. Crawling Process

The crawling process uses wget to recursively crawl websites and create WARC archive files. See the [crawling README](crawling/README.md) for detailed instructions.

**Quick Start:**
```bash
cd crawling
# 1. Put origin URL in file.txt (first line only)
echo "https://www.example.com/" > file.txt

# 2. Discover and add sitemaps automatically
python helpers/get_sitmaps.py

# 3. Run the crawler
./crawl_script.sh file.txt <prefix>
```

Output: WARC files in `crawling/crawl_out/<prefix>/`

### 2. Datatrove Extraction Process

The extraction process reads WARC files and extracts clean text content using Trafilatura, filtering out repetitive content. See the [datatrove_extraction README](datatrove_extraction/README.md) for detailed instructions.

**Quick Start:**
```bash
cd datatrove_extraction
# Place WARC files in input/ directory
python process.py
```

Output: JSONL files in `datatrove_extraction/output/data/`

### 3. Crawled Dataset

The final processed dataset is stored in the `crawled_dataset/` directory.

## Getting Help

- For crawling-specific questions, see [crawling/README.md](crawling/README.md)
- For extraction-specific questions, see [datatrove_extraction/README.md](datatrove_extraction/README.md)

## Notes

- The crawler stays on the same host as seed URLs (no cross-site crawling)
- Common crawler traps (login pages, admin areas, etc.) are automatically filtered out
- The crawler is polite by default, with delays between requests
- Text extraction uses Trafilatura with precision-focused settings
- Repetitive content is automatically filtered out during extraction

Happy crawling! 🕷️
