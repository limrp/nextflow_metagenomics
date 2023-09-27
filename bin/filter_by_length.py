#!/usr/bin/env python3

# *--------------------------------------------------------------------------------------------------------
# | PROGRAM NAME:
# | DATE:
# | VERSION: 2
# | CREATED BY: Lila Maciel Rodriguez Perez
# | PROJECT FILE:
# | GITHUB REPO:
# *--------------------------------------------------------------------------------------------------------
# | INFO: - This version use generators to be more memory-efficient when handling big fasta files.
# |       - This program doesn't use Biopython. That version will come later.
# *--------------------------------------------------------------------------------------------------------
# | PURPOSE: Filtering sequences by the length specified by the user
# *--------------------------------------------------------------------------------------------------------
# | USAGE:
# | - With a file:
# |   python3 filter_seqs_by_length.py --input input.fasta --min_len 100 --output output.fasta
# |   python3 filter_seqs_by_length.py -i input.fasta -m 100 -o output.fasta
# | - With standard input:
# |   cat input.fasta | python3 filter_seqs_by_length.py -i - -m 100 -o output.fasta
# |   pigz input.fasta.gz | python3 filter_seqs_by_length.py -i - -m 100 -o output.fasta
# *--------------------------------------------------------------------------------------------------------

# *-------------------------------------  Libraries ------------------------------------------------------*

import argparse

# *--------------------------------------* Defining functions *--------------------------------------------*


# Function to read and filter sequences from a FASTA file or standard input
def read_and_filter_fasta(file_object, threshold):
    seq_id = None
    seq = []

    # Iterate through each line in the file
    for line in file_object:
        line = line.strip()
        if line.startswith(">"):
            # If a sequence ID is found and a previous sequence exists
            if seq_id is not None:
                # Concatenate the individual lines of the sequence, preserving line breaks
                sequence = "\n".join(seq)
                # Check if the sequence meets the threshold and yield it
                if len(sequence.replace("\n", "")) >= threshold:
                    yield seq_id, sequence
            # Start a new sequence
            seq_id = line[1:]
            seq = []
        else:
            # Append sequence lines
            seq.append(line)

    # Check the last sequence in the file
    if seq_id is not None:
        sequence = "\n".join(seq)
        if len(sequence.replace("\n", "")) >= threshold:
            yield seq_id, sequence


# *--------------------------------------* Primary logic of the script *------------------------------------*


# Main function to parse command-line arguments and orchestrate reading, filtering, and writing sequences
def main():
    parser = argparse.ArgumentParser(
        description="Read and filter sequences in a FASTA file by length.",
        epilog="""
        Usage examples:
        - With a file:
        python3 filter_seqs_by_length.py -i input.fasta -m 100 -o output.fasta
        - With standard input:
        cat input.fasta | python3 filter_by_length.py -i - -m 100 -o out.fa
        pigz input.fasta.gz | python3 filter_by_length.py -i - -m 100 -o.fa
        """,
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument(
        "--input",
        "-i",
        type=argparse.FileType("r"),
        required=True,
        help="The input FASTA file or standard input.",
    )
    parser.add_argument(
        "--min_len",
        "-m",
        type=int,
        required=True,
        help="The minimum sequence length.",
    )
    parser.add_argument(
        "--output",
        "-o",
        type=str,
        required=True,
        help="The output FASTA file.",
    )
    args = parser.parse_args()

    # Call the read_and_filter_fasta function and get a generator of sequences
    sequences = read_and_filter_fasta(args.input, args.min_len)

    # Open the output file and write the sequences that meet the threshold
    with open(args.output, "w") as f:
        for id, seq in sequences:
            f.write(f">{id}\n{seq}\n")


# Execute the main function only if the script is run directly (not imported as a module)
if __name__ == "__main__":
    main()
