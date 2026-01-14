from datatrove.pipeline.filters import GopherRepetitionFilter, LanguageFilter
from datatrove.pipeline.readers import WarcReader
from datatrove.pipeline.writers.jsonl import JsonlWriter
from datatrove.pipeline.extractors import Trafilatura
from datatrove.executor import LocalPipelineExecutor

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

        
        GopherRepetitionFilter(
            exclusion_writer=JsonlWriter(
                f"{OUTPUT_BASE_PATH}/{REJECTED_FOLDER}/2_gopher_rep"
            )
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