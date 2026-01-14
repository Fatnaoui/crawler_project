# Crawling Process

This process creates WARC (Web ARChive) files from websites using wget recursion. Perfect for archiving and analyzing web content.

## Overview

The crawling script uses `wget` to recursively crawl websites and generate compressed WARC archive files. WARC files preserve the complete HTTP request/response data, making them ideal for downstream text extraction and analysis.

## Prerequisites

- `wget` with WARC support
- Bash shell

## Getting Started

### 1. Prepare Your Input File

Start by creating `file.txt` with just the origin website URL (the main website you want to crawl):

Example `file.txt`:
```
https://www.example.com/
```

**Important:** Only put the origin URL on the first line. The sitemaps will be added automatically in the next step.

### 2. Discover and Add Sitemaps Automatically

Run the helper script to automatically discover and add all sitemap URLs:

```bash
cd crawling
python helpers/get_sitmaps.py
```

This script will:
- Read the origin URL from the first line of `file.txt`
- Discover all sitemaps for that domain
- Automatically append them to `file.txt` after the origin URL

After running the script, your `file.txt` will look like:
```
https://www.example.com/
https://www.example.com/sitemap.xml
https://www.example.com/sitemap-posts.xml
https://www.example.com/sitemap-pages.xml
```

**Format Rules:**
- Each URL should be on its own line
- Blank lines are ignored
- Lines starting with `#` are treated as comments
- The first URL must be the main website origin URL

### 3. Run the Crawler

Run the crawl script from the `crawling` directory:

```bash
cd crawling
./crawl_script.sh file.txt <prefix>
```

Replace `<prefix>` with a descriptive tag for the website (e.g., `example_com`). This prefix is used to organize output files and logs.

**Default Settings:**
- **Depth**: 4 (crawls 4 levels deep from the seed URLs)
- **Robots**: off (doesn't respect robots.txt files)
- **Wait**: 1 second between requests
- **Quota**: unlimited

The crawler will create WARC files in `crawl_out/<prefix>/` directory.

### 4. Customize Parameters (Optional)

You can customize the crawling behavior using environment variables:

```bash
DEPTH=6 ROBOTS=on WAIT_SECS=2 QUOTA=5G ./crawl_script.sh file.txt <prefix>
```

**Available Parameters:**
- `DEPTH`: Recursion depth (default: 4)
- `ROBOTS`: Respect robots.txt - use `on` or `off` (default: off)
- `WAIT_SECS`: Delay between requests in seconds (default: 1)
- `RANDOM_WAIT`: Add jitter to wait times - use `0` or `1` (default: 1)
- `TIMEOUT_SECS`: Network timeout per request (default: 30)
- `TRIES`: Retry attempts per URL (default: 3)
- `MAX_REDIRECT`: Max redirects to follow (default: 10)
- `QUOTA`: Download limit, e.g., `5G`, `500M` (default: 0 = unlimited)
- `WARC_MAX_SIZE`: Rotate WARC chunks at this size (default: 1G)
- `UA`: Custom User-Agent string

## Helper Tools

### Manual Sitemap Addition (Optional)

If you prefer to manually add sitemap URLs instead of using the automatic discovery, you can edit `file.txt` directly and add sitemap URLs one per line after the origin URL.

## Output Structure

After running the crawler, you'll find:

```
crawl_out/
└── <prefix>/
    ├── <prefix>-*.warc.gz    # Main WARC files
    ├── logs/
    │   ├── <prefix>.log              # Crawl log
    │   └── <prefix>.rejected.log     # Rejected URLs
    └── _meta/                        # Metadata WARC files
```

## Verifying Your Crawl

You can verify and explore the WARC files using [ReplayWeb.page](https://replayweb.page/):

1. Go to https://replayweb.page/
2. Upload your WARC file(s) from the `crawl_out/<prefix>/` directory
3. Browse the archived website as it was captured during the crawl

This is a great way to ensure everything worked correctly and preview what was captured!

## Features

- **Host-bound crawling**: Stays on the same host as seed URLs (no cross-site crawling)
- **Crawler trap filtering**: Automatically filters out common traps (login pages, admin areas, etc.)
- **Polite crawling**: Default delays between requests to avoid overwhelming servers
- **WARC rotation**: Automatically splits large archives into manageable chunks
- **Automatic cleanup**: Temporary files are cleaned up after crawling completes
- **Comprehensive logging**: Detailed logs and rejected URL tracking

## Notes

- The crawler uses `--delete-after` by default, so downloaded mirror files are removed after WARC creation
- Metadata WARC files are automatically moved to `_meta/` subdirectory
- The script validates input and provides helpful error messages
- All WARC files are compressed with gzip (`.warc.gz`)

## Troubleshooting

**Issue**: Script permission denied
```bash
chmod +x crawl_script.sh
```

**Issue**: wget not found or no WARC support
- Ensure wget is installed with WARC support
- On Ubuntu/Debian: `sudo apt-get install wget`

**Issue**: Too many rejected URLs
- Check `logs/<prefix>.rejected.log` to see what was filtered
- Adjust `REJECT_REGEX` environment variable if needed
