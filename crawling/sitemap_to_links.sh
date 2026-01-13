#!/usr/bin/env bash
set -euo pipefail

# ==========================================
# sitemap_to_seeds.sh
# ==========================================
# Extract all <loc> URLs from an XML sitemap and write them to a file (one URL per line).
#
# Notes:
#   - This parser is intentionally simple: it extracts <loc>...</loc> blocks.
#   - If the sitemap is a sitemap index (sitemapindex), this will output the child sitemap URLs,
#     not the final page URLs. (For sitemapindex, you'd need recursion, which is the Python option.)
#
# Usage:
#   ./sitemap_to_links.sh <sitemap_url> file.txt
#
# Examples:
#   ./sitemap_to_links.sh "https://www.moroccophobiaa.com/sitemap.xml" file.txt
#   ./sitemap_to_inks.sh "https://example.com/sitemap.xml" file.txt
#
# Output file format:
#   - One URL per line
#   - UTF-8 text
#   - Safe to pass directly to wget:  wget --input-file=seeds.txt ...
#
# ==========================================

usage() {
  cat >&2 <<'EOF'
Usage:
  sitemap_to_seeds.sh <sitemap_url> [out_file]

Arguments:
  sitemap_url   Required. Must start with http:// or https://
  out_file      Optional. Default: seeds.txt

Examples:
  ./sitemap_to_seeds.sh "https://www.moroccophobiaa.com/sitemap.xml" seeds.txt

What the output file looks like (example):
  https://www.moroccophobiaa.com/2025/10/yasser-alzabiri.html
  https://www.moroccophobiaa.com/2025/10/moroccan-national-team.html
  https://www.moroccophobiaa.com/2024/11/qarawiyyin-university.html
EOF
}

die() {
  echo "Error: $*" >&2
  echo >&2
  usage
  exit 2
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

is_http_url() {
  [[ "${1:-}" =~ ^https?:// ]]
}

main() {
  local sitemap_url="${1:-}"
  local out_file="${2:-seeds.txt}"

  [[ -n "$sitemap_url" ]] || die "Missing required argument: <sitemap_url>"
  is_http_url "$sitemap_url" || die "sitemap_url must start with http:// or https:// (got: $sitemap_url)"

  need_cmd wget
  need_cmd tr
  need_cmd sed
  need_cmd wc
  need_cmd mkdir

  # Ensure output directory exists (if out_file includes a path)
  local out_dir
  out_dir="$(dirname "$out_file")"
  [[ "$out_dir" == "." ]] || mkdir -p "$out_dir"

  # Fetch sitemap; fail loudly on HTTP errors, timeouts, etc.
  # -q: quiet
  # -O-: write to stdout
  # --timeout/--tries: avoid hanging forever
  local xml
  if ! xml="$(wget -qO- --timeout=30 --tries=3 "$sitemap_url")"; then
    die "Failed to fetch sitemap from: $sitemap_url"
  fi

  # Extract <loc>...</loc> values:
  # 1) split on '<' to isolate tags
  # 2) pick lines starting with 'loc>'
  # 3) strip leading 'loc>' and trailing '</loc>' not needed because we split at '<'
  # 4) trim whitespace
  #
  # This produces one URL per line.
  printf '%s' "$xml" \
    | tr '<' '\n' \
    | sed -n 's/^loc>[[:space:]]*//p' \
    | sed 's/[[:space:]]*$//' \
    > "$out_file"

  # Basic sanity checks
  local count
  count="$(wc -l < "$out_file" | tr -d ' ')"

  if [[ "$count" -eq 0 ]]; then
    # Help user diagnose common cases
    echo "Warning: 0 URLs extracted." >&2
    echo "Possible reasons:" >&2
    echo "  - The URL is not a standard sitemap (<urlset>)" >&2
    echo "  - The sitemap is a sitemap index (<sitemapindex>) pointing to other sitemaps" >&2
    echo "  - The content is compressed (.gz) or blocked" >&2
    echo "Tip: Open the sitemap in a browser and check whether it contains <loc> tags." >&2
    exit 1
  fi

  # Optional: remove duplicates while preserving order (uncomment if needed)
  # awk '!seen[$0]++' "$out_file" > "${out_file}.tmp" && mv "${out_file}.tmp" "$out_file"

  echo "Wrote $count URLs to: $out_file"
}

main "$@"
