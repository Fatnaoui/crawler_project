# Datatrove

A web crawling tool that creates WARC (Web ARChive) files from websites using wget. Perfect for archiving and analyzing web content.

## Prerequisites

- **Python 3.11** or higher
- `wget` (with WARC support)
- `uv` package manager

## Getting Started

### 1. Install Dependencies

First, make sure you have Python 3.9 installed. Then, install all project dependencies using `uv`:

```bash
uv sync
```

This will install all the required packages listed in `pyproject.toml`, including `warcio` and other dependencies.

### 2. Prepare Your Input File

Before running the crawler, you need to prepare the `crawling/file.txt` file with your target URLs. The format is simple:

1. **Put the origin website URL at the top** (the main website you want to crawl)
2. **Add sitemap URLs below it** (one URL per line)

Here's an example of how `crawling/file.txt` should look:

```
https://www.example.com/
https://www.example.com/sitemap.xml
https://www.example.com/sitemap-posts.xml
https://www.example.com/sitemap-pages.xml
```

**Tips:**
- Each URL should be on its own line
- Blank lines are ignored
- Lines starting with `#` are treated as comments
- The first URL should be the main website you want to crawl

### 3. Run the Crawler

Navigate to the `crawling` directory and run the crawl script:

```bash
cd crawling
./crawl_script.sh file.txt <prefix>
```

Replace `<prefix>` with a descriptive tag for the url website, so that we keep track of the 

**Default Settings:**
- **Depth**: 4 (crawls 4 levels deep from the seed URLs)
- **Robots**: off (doesn't respect robots.txt files)

The crawler will create WARC files in `crawl_out/<prefix>/` directory.

### 4. Customize Parameters (Optional)

If you want to change the default settings, you can set environment variables before running the script:

```bash
DEPTH=6 ROBOTS=on ./crawl_script.sh file.txt <prefix>
```

Available parameters:
- `DEPTH`: Recursion depth (default: 4)
- `ROBOTS`: Respect robots.txt - use `on` or `off` (default: off)
- `WAIT_SECS`: Delay between requests in seconds (default: 1)
- `QUOTA`: Download limit, e.g., `5G`, `500M` (default: unlimited)

## Testing Your Crawl

Once your crawl is complete, you can verify and explore the WARC files using [ReplayWeb.page](https://replayweb.page/):

1. Go to https://replayweb.page/
2. Upload your WARC file(s) from the `crawl_out/your_prefix_name/` directory
3. Browse the archived website as it was captured during the crawl

This is a great way to make sure everything worked correctly and to preview what was captured!

## Output Structure

After running the crawler, you'll find:

```
crawl_out/
└── prefix/
    ├── prefix-*.warc.gz    # Main WARC files
    ├── logs/
    │   ├── your_prefix_name.log      # Crawl log
    │   └── your_prefix_name.rejected.log  # Rejected URLs
    └── _meta/                         # Metadata WARC files
```

## Additional Tools

### Extracting URLs from Sitemaps

If you need to extract URLs from a sitemap to add to your `file.txt`, you can use the `sitemap_to_links.sh` script:

```bash
cd crawling
./sitemap_to_links.sh "https://www.example.com/sitemap.xml" output.txt
```

This will extract all URLs from the sitemap and save them to `output.txt`, which you can then append to your `file.txt` if needed.

## Notes

- The crawler stays on the same host as your seed URLs (no cross-site crawling)
- Common crawler traps (login pages, admin areas, etc.) are automatically filtered out
- The crawler is polite by default, with delays between requests
- Temporary files are automatically cleaned up after the crawl completes

Happy crawling! MTNRA 🕷️
