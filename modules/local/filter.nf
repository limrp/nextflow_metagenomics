process FILTER {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::python=3.9 conda-forge::pigz=2.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-fe7ef8839c0427047493579cb3b7618f17537a30:222df5e86a4567ed0175e9c550e3c68a744db83e-0':
        'biocontainers/mulled-v2-fe7ef8839c0427047493579cb3b7618f17537a30:222df5e86a4567ed0175e9c550e3c68a744db83e-0' }"

    input:
    tuple val(meta), path(genome)
    val(sequence_type)

    output:
    //tuple val(meta), path('*.txt'), emit: info_ch
    tuple val(meta), path ('*.fa.gz') , emit: fasta_ch
    tuple val(meta), path ('*.txt')   , emit: log_ch
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix    = task.ext.prefix    ?: "${meta.id}"
    // Define a variable named "threshold" without assigning a value to it yet.
    def threshold
    // If the variable "sequence_type" is equal to the string 'genome', execute the code inside this block.
    if (sequence_type == 'genome') {
        // If "params.genome_threshold" is not null or false, assign its value to "threshold".
        // If it is null or false, assign the default value of 1000 to "threshold".
        threshold = params.genome_threshold
    // If "sequence_type" is not 'genome' but is equal to 'gene', execute the code inside this block.
    } else if (sequence_type == 'gene') {
        // If "params.gene_threshold" is not null or false, assign its value to "threshold".
        // If it is null or false, assign the default value of 500 to "threshold".
        threshold = params.gene_threshold
    }
    """
    echo "Number of sequences before filtering:" >> "${prefix}"_number_sequences.txt
    zcat $genome | grep -c ">" >> "${prefix}"_number_sequences.txt

    pigz -cdf $genome | filter_by_length.py \\
        --input - \\
        --min_len $threshold \\
        --output "filtered_${prefix}.fa"

    pigz -nm "filtered_${prefix}.fa"

    echo "Number of sequences after filtering:" >> "${prefix}"_number_sequences.txt
    zcat "filtered_${prefix}.fa.gz" | grep -c ">" >> "${prefix}"_number_sequences.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
    END_VERSIONS
    """
}
