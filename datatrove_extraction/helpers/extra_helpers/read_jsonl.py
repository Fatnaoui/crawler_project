import gzip
import json
from pathlib import Path

jsonl_path = Path(__file__).parent.parent.parent / "output" / "data" / "00000.jsonl.gz"
#jsonl_path = Path(__file__).parent.parent.parent / "output" / "rejected" / "5_fineweb_qual" / "00000.jsonl.gz"

with gzip.open(jsonl_path, "rt", encoding="utf-8") as f:
    for i, line in enumerate(f):
        doc = json.loads(line)
        print("#" * 80)
        print("Tokens:", doc.get("metadata", {}).get("token_count"))
        print("Text preview:")
        print(doc.get("text", "")[:300000])
        print("#" * 80)
        print()

        if i == 3:
            break