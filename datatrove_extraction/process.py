from datatrove.pipeline.readers import WarcReader
from datatrove.pipeline.writers.jsonl import JsonlWriter
from datatrove.pipeline.extractors import Trafilatura
from datatrove.executor import LocalPipelineExecutor
from datatrove.utils.typeshelper import Languages
from datatrove.pipeline.filters import (
    GopherRepetitionFilter, 
    LanguageFilter, 
)

from helpers.GopherQualityFilter_ours import GopherQualityFilter
from helpers.C4QualityFilter_ours import C4QualityFilter
from helpers.FineWebFilter_ours import FineWebQualityFilter

OUTPUT_BASE_PATH = "output"
REJECTED_FOLDER = "Rejected"

def main():
    pipeline = [
        WarcReader(
            data_folder="input/",
            glob_pattern="*.warc.gz",
            # limit=1 
        ),
        Trafilatura(favour_precision=True),    # to use recall: favour_precision=False, favour_recall=True

        
        GopherRepetitionFilter(                # then with this one with oumaima
            exclusion_writer=JsonlWriter(
                f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/2_gopher_rep"
            ),
            languages=Languages.moroccan_arabic
        ),

        GopherQualityFilter(
            exclusion_writer=JsonlWriter(f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/3_gopher_qual")
        ),

        C4QualityFilter(
            exclusion_writer=JsonlWriter(f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/4_c4_qual/"),
        ),

        FineWebQualityFilter(
            exclusion_writer=JsonlWriter(f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/5_fineweb_qual")
        ),
        
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

    executor.run()

if __name__ == '__main__':
    main()