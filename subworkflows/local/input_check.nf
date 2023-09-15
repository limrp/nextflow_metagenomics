//
// Check input samplesheet and get fasta channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fasta_channel(it) }
        .set { genomes_ch }
    
    emit:
    genomes_ch                                // channel: [ val(meta), fasta ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, genome ]
def create_fasta_channel(LinkedHashMap row) {

    // Create empty meta map and create key id with its value
    def meta = [:]
    meta.id         = row.sample

    // Create empty list for the future tuple elements (not necessary, just useful to know the output type)
    def fasta_meta = []

    // Create a tuple with the meta map and the path to the genome file
    // 1. Checking if the provided to the genome file exists
    if (!file(row.genome).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Genome file does not exist!\n${row.genome}"
    } else {
        fasta_meta = [ meta, file(row.genome) ]
    }
    // 2. If it exists, create/fill the list with 2 elements: the meta map and the genome file

    return fasta_meta
}
