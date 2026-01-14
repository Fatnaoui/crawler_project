from trafilatura import sitemaps
from pathlib import Path
import sys

# ---------------------
# Utilization:
# python helpers/get_sitmaps.py
# this will append the sitemap links to the file.txt file

CRAWLING_DIR = Path(__file__).resolve().parents[1]
LINKS_FILE = CRAWLING_DIR / "file.txt"

if not LINKS_FILE.exists():
    print(f"File not found: {LINKS_FILE}")
    sys.exit(1)

# Read origin URL
with LINKS_FILE.open("r", encoding="utf-8") as f:
    origin_url = f.readline().strip()

if not origin_url:
    print("First line (origin URL) is empty")
    sys.exit(1)

# Ensure newline after first line
content = LINKS_FILE.read_text(encoding="utf-8")
if not content.endswith("\n"):
    LINKS_FILE.write_text(content + "\n", encoding="utf-8")

# Fetch sitemaps
mylinks = sitemaps.sitemap_search(origin_url)

# Append sitemap links
with LINKS_FILE.open("a", encoding="utf-8") as f:
    for link in mylinks:
        f.write(link + "\n")

print(f"Appended {len(mylinks)} sitemap links for {origin_url}")
