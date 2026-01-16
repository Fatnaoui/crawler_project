from datatrove.pipeline.readers import WarcReader
from datatrove.pipeline.writers.jsonl import JsonlWriter
from datatrove.pipeline.extractors import Trafilatura
from datatrove.executor import LocalPipelineExecutor
from datatrove.utils.typeshelper import Languages
from datatrove.pipeline.filters import (
    GopherRepetitionFilter, 
    LanguageFilter, 
)

from helpers.filters.GopherQualityFilter_ours import GopherQualityFilter
from helpers.filters.C4QualityFilter_ours import C4QualityFilter
from helpers.filters.FineWebFilter_ours import FineWebQualityFilter
from helpers.filters.ArabicNormalizationFilter import ArabicNormalizationFilter
from helpers.extra_helpers.validateInputs import validate_inputs
from pathlib import Path

try:
    validate_inputs()
except (FileNotFoundError, ValueError) as e:
    print(f"Validation error: {e}")

OUTPUT_BASE_PATH = Path(__file__).parent / "output"
REJECTED_FOLDER = "Rejected"
input_path=Path(__file__).parent / "input"

def main():
    pipeline = [
        WarcReader(
            data_folder=str(input_path),
            glob_pattern="*.warc.gz",
            limit=3
        ),
        Trafilatura(favour_precision=True, timeout=30),    # to use recall: favour_precision=False, favour_recall=True

        ArabicNormalizationFilter(
            exclusion_writer=JsonlWriter(f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/1_arabic_norm"),
        ),
        
        GopherRepetitionFilter(                # then with this one with oumaima
            exclusion_writer=JsonlWriter(
                f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/2_gopher_rep"
            ),
            language=Languages.moroccan_arabic
        ),

        GopherQualityFilter(
            exclusion_writer=JsonlWriter(f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/3_gopher_qual")
        ),

        C4QualityFilter(
            exclusion_writer=JsonlWriter(f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/4_c4_qual"),
        ),

        # FineWebQualityFilter(
        #     exclusion_writer=JsonlWriter(f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/5_fineweb_qual")
        # ),
        
        JsonlWriter(
            output_folder=f"{OUTPUT_BASE_PATH}/data",
        )
    ]

    executor = LocalPipelineExecutor(
        pipeline=pipeline,
        logging_dir="log",
        tasks=1,
        workers=1
    )

    try:
        executor.run()
    except Exception as e:
        print(f"Pipeline error: {e}")
        # Log error details
        import traceback
        traceback.print_exc()
        raise

if __name__ == '__main__':
    main()