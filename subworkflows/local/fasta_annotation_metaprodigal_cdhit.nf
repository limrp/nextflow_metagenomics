//
// Subworkflow for the annotation of a metagenome using Metaprodigal and CD-HIT
//

include {       PRODIGAL       } from '../../modules/nf-core/prodigal/main.nf'
include {      CDHIT_CDHIT     } from '../../modules/nf-core/cdhit/cdhit/main.nf'
include { FILTER as FILTER_one } from '../../modules/local/filter.nf'
include { FILTER as FILTER_two } from '../../modules/local/filter.nf'

workflow FASTA_ANNOTATION_METAPRODIGAL_CDHIT {
    take:
    ch_metagenome // channel in which each element is a tuple: [ val(meta), [ genome ]]

    main:

    // Starting empty channel to store all the softwares' versions
    ch_versions = Channel.empty()

    // 1. Filtering out contigs shorter than 500 bp (default)
    FILTER_one( ch_metagenome, 'genome' )
    ch_versions = ch_versions.mix(FILTER_one.out.versions.first())

    // 2. Annotation the ORF's using METAPRODIGAL
    PRODIGAL( FILTER_one.out.fasta_ch, 'gff' )
    ch_versions = ch_versions.mix( PRODIGAL.out.versions.first() )

    // 3. Filtering out gene sequences shorter than 100 bp (default)
    FILTER_two( PRODIGAL.out.nucleotide_fasta, 'gene' )
    ch_versions = ch_versions.mix( FILTER_two.out.versions.first() )

    // 4. Clustering gene sequences with CDHIT
    CDHIT_CDHIT( FILTER_two.out.fasta_ch )
    ch_versions = ch_versions.mix( CDHIT_CDHIT.out.versions.first() )

    emit:
    fasta                  = FILTER_one.out.fasta_ch
    logs                   = FILTER_one.out.log_ch
    nucleotide_fasta_orf   = PRODIGAL.out.nucleotide_fasta
    fasta2                 = FILTER_two.out.fasta_ch
    logs2                  = FILTER_two.out.log_ch
    fasta_cdhit            = CDHIT_CDHIT.out.fasta

    versions             = ch_versions                        // channel: [ versions.yml ]
}

