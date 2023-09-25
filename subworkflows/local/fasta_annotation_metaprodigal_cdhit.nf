//
// Subworkflow for the annotation of a metagenome using Metaprodigal and CD-HIT
//

include { GUNZIP as GUNZIP_one        } from '../../modules/nf-core/gunzip/main.nf'
include { GUNZIP as GUNZIP_two        } from '../../modules/nf-core/gunzip/main.nf'
include { GUNZIP as GUNZIP_compress   } from '../../modules/nf-core/gunzip/main.nf'
include { PRODIGAL                    } from '../../modules/nf-core/prodigal/main.nf'
include { CDHIT_CDHIT                 } from '../../modules/nf-core/cdhit/cdhit/main.nf'
include { FILTER as FILTER_one        } from '../../modules/local/filter.nf'
include { FILTER as FILTER_two        } from '../../modules/local/filter.nf'

workflow FASTA_ANNOTATION_METAPRODIGAL_CDHIT {
    take:
    ch_metagenome // channel in which each element is a tuple: [ val(meta), [ genome ]]

    main:
    // Starting empty channel to store all the softwares' versions
    ch_versions = Channel.empty()

    // 0. Decompress FASTA files, if necessary.
    ch_metagenome
        .filter { meta, genome_file -> genome_file.toString().endsWith('.gz') }
        .set { compressed_files_ch }

    ch_metagenome
        .filter { meta, genome_file -> !genome_file.toString().endsWith('.gz') }
        .set { uncompressed_files_ch }

    GUNZIP_one( compressed_files_ch )
    ch_versions = ch_versions.mix( GUNZIP_one.out.versions.first() )

    // 1. Filtering out contigs shorter than 500 bp (default)
    FILTER_one( GUNZIP_one.out.gunzip.mix( uncompressed_files_ch ) )
    ch_versions = ch_versions.mix( FILTER_one.out.versions.first() )

    // 1.5. Compress all FASTA files to use as input for PRODIGAL
    GUNZIP_compress( FILTER_one.out.fasta_ch )
    ch_versions = ch_versions.mix( GUNZIP_compress.out.versions.first() )

    // 2. Annotation the ORF's using METAPRODIGAL
    PRODIGAL( GUNZIP_compress.out.gunzip, 'gff' )
    ch_versions = ch_versions.mix( PRODIGAL.out.versions.first() )

    // 2.5. Decompress the PRODIGAL output to use as input for the FILTER module
    GUNZIP_two( PRODIGAL.out.nucleotide_fasta ) // *.fna.gz => *.fna
    ch_versions = ch_versions.mix( GUNZIP_two.out.versions.first() )

    // 3. Filtering out gene sequences shorter than 100 bp (default)
    FILTER_two( GUNZIP_two.out.gunzip )
    ch_versions = ch_versions.mix( FILTER_two.out.versions.first() )

    // 4. Clustering gene sequences with CDHIT
    CDHIT_CDHIT( FILTER_two.out.fasta_ch )
    ch_versions = ch_versions.mix( CDHIT_CDHIT.out.versions.first() )

    emit:
    fasta_cdhit = CDHIT_CDHIT.out.fasta
    versions    = ch_versions           // channel: [ versions.yml ]
}
