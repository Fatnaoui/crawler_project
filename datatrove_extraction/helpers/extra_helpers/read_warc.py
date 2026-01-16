import gzip
import json
from pathlib import Path

#warc_path = Path(__file__).parent.parent.parent / "output" / "data" / "00000.jsonl.gz"
warc_path = Path(__file__).parent.parent.parent / "output" / "rejected" / "5_fineweb_qual" / "00000.jsonl.gz"

with gzip.open(warc_path, "rt", encoding="utf-8") as f:
    for i, line in enumerate(f):
        doc = json.loads(line)
        print("Reason:", doc.get("quality_reason"))
        print("Text preview:")
        print(doc.get("text", "")[:300000])
        print("-" * 80)

        if i == 3:
            break