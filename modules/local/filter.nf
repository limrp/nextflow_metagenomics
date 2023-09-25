process FILTER {
    tag "$meta.id"
    label 'process_single'

    conda "conda-forge::python=3.9 conda-forge::pigz=2.6"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-fe7ef8839c0427047493579cb3b7618f17537a30:222df5e86a4567ed0175e9c550e3c68a744db83e-0':
        'biocontainers/mulled-v2-fe7ef8839c0427047493579cb3b7618f17537a30:222df5e86a4567ed0175e9c550e3c68a744db83e-0' }"

    input:
    tuple val(meta), path(genome)

    output:
    tuple val(meta), path ('*.fa'), emit: fasta_ch
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix    = task.ext.prefix    ?: "${meta.id}"
    def args      = task.ext.args ?: '--sequence_type gene'
    def threshold = args.contains("--sequence_type genome") ? params.genome_threshold :
                    args.contains("--sequence_type gene")   ? params.gene_threshold :
                    500
    """

    filter_by_length.py \\
        --input $genome \\
        --min_len $threshold \\
        --output "filtered_${prefix}.fa"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/Python //g')
    END_VERSIONS
    """
}
