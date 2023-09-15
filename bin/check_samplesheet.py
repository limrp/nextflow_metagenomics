#!/usr/bin/env python3

import argparse
import csv
import logging
import sys
from pathlib import Path

logger = logging.getLogger(__name__)

def sniff_format(handle):
    """
    Detect the tabular format.
    """
    peek = handle.read(1024)  # Reading the first 1024 bytes
    handle.seek(0)
    sniffer = csv.Sniffer()
    dialect = sniffer.sniff(peek)
    return dialect

class RowChecker:
    def __init__(self, sample_col="sample", genome_col="genome", **kwargs):
        self._sample_col = sample_col
        self._genome_col = genome_col
        self._seen = set()
        self.modified = []

    def validate_and_transform(self, row):
        self._validate_sample(row)
        self._seen.add((row[self._sample_col], row[self._genome_col]))
        self.modified.append(row)

    def _validate_sample(self, row):
        if len(row[self._sample_col]) <= 0:
            raise AssertionError("Sample input is required.")
        row[self._sample_col] = row[self._sample_col].replace(" ", "_")

    def validate_unique_samples(self):
        if len(self._seen) != len(self.modified):
            raise AssertionError("Duplicate samples found. Sample names and genome paths must be unique.")

def check_samplesheet(file_in, file_out):
    required_columns = {"sample", "genome"}
    with file_in.open(newline="") as in_handle:
        reader = csv.DictReader(in_handle, dialect=sniff_format(in_handle))
        if not required_columns.issubset(reader.fieldnames):
            req_cols = ", ".join(required_columns)
            logger.critical(f"The sample sheet **must** contain these column headers: {req_cols}.")
            sys.exit(1)
        checker = RowChecker()
        for i, row in enumerate(reader):
            try:
                checker.validate_and_transform(row)
            except AssertionError as error:
                logger.critical(f"{str(error)} On line {i + 2}.")
                sys.exit(1)
        try:
            checker.validate_unique_samples()
        except AssertionError as error:
            logger.critical(str(error))
            sys.exit(1)
    header = list(reader.fieldnames)
    with file_out.open(mode="w", newline="") as out_handle:
        writer = csv.DictWriter(out_handle, header, delimiter=",")
        writer.writeheader()
        for row in checker.modified:
            writer.writerow(row)

def parse_args(argv=None):
    parser = argparse.ArgumentParser(
        description="Validate and transform a tabular samplesheet.",
        epilog="Example: python check_samplesheet.py --input samplesheet.csv --output samplesheet.valid.csv",
    )
    parser.add_argument(
        "-i", "--input",
        metavar="FILE_IN",
        type=Path,
        required=True,
        help="Tabular input samplesheet in CSV or TSV format.",
    )
    parser.add_argument(
        "-o", "--output",
        metavar="FILE_OUT",
        type=Path,
        required=True,
        help="Transformed output samplesheet in CSV format.",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        help="The desired log level (default WARNING).",
        choices=("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"),
        default="WARNING",
    )
    return parser.parse_args(argv)

def main(argv=None):
    args = parse_args(argv)
    logging.basicConfig(level=args.log_level, format="[%(levelname)s] %(message)s")
    if not args.input.is_file():
        logger.error(f"The given input file {args.input} was not found!")
        sys.exit(2)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    check_samplesheet(args.input, args.output)

if __name__ == "__main__":
    sys.exit(main())
