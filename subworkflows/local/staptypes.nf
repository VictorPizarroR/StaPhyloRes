//
// Subworkflow Obtener Tipados moleculares comunes MLST, Spatyper, SCCmec y agr Locus
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



include { MLST					        } from '../../modules/nf-core/mlst/main'
include { SPATYPER				        } from '../../modules/nf-core/spatyper/main'
include { STAPHOPIASCCMEC		        } from '../../modules/nf-core/staphopiasccmec/main'
include { AGRVATE                       } from '../../modules/nf-core/agrvate/main'
include { CSVTK_CONCAT as SUMMARY_CONCAT_MLST                       } from '../../modules/nf-core/csvtk/concat/main'
include { CSVTK_CONCAT as SUMMARY_CONCAT_SPATYPER                   } from '../../modules/nf-core/csvtk/concat/main'
include { CSVTK_CONCAT as SUMMARY_CONCAT_SCCMEC                     } from '../../modules/nf-core/csvtk/concat/main'
include { CSVTK_CONCAT as SUMMARY_CONCAT_AGRVATE                    } from '../../modules/nf-core/csvtk/concat/main'

/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow STAPTYPES {
    take:
    fasta // channel: assemblyreads from unicycler

    main:
    ch_versions = Channel.empty()
    
    //RUN MLST
    MLST (fasta)

    MLST.out.tsv.collect{meta, tsv -> tsv}
        .map{ tsv -> [[id:'mlst-report'], tsv]}
        .set{ ch_merge_mlst }

    //RUN Spatyper
    SPATYPER (fasta,[],[])

    SPATYPER.out.tsv.collect{meta, tsv -> tsv}
        .map{ tsv -> [[id:'spatyper-report'], tsv]}
        .set{ ch_merge_spatyper }

    //RUN Staphopia SCCmec
    STAPHOPIASCCMEC (fasta)

    STAPHOPIASCCMEC.out.tsv.collect{meta, tsv -> tsv}
        .map{ tsv -> [[id:'staphopiasccmec-report'], tsv]}
        .set{ ch_merge_sccmec }

    //RUN Agrvate
    AGRVATE (fasta)

    AGRVATE.out.summary.collect{meta, summary -> summary}
        .map{ summary -> [[id:'agrvate-report'], summary]}
        .set{ ch_merge_agrvate }

    //Merge Results
    SUMMARY_CONCAT_MLST (
        ch_merge_mlst,
        'tsv',
        'tsv',
        '--no-header-row'
        )
    
    SUMMARY_CONCAT_SPATYPER (
        ch_merge_spatyper,
        'tsv',
        'tsv',
        ''
    )

    SUMMARY_CONCAT_SCCMEC (
        ch_merge_sccmec,
        'tsv',
        'tsv',
        ''
    )

    SUMMARY_CONCAT_AGRVATE (
        ch_merge_agrvate,
        'tsv',
        'tsv',
        '-C "$"'
    )
}