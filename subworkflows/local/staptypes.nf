//
// Subworkflow Obtener Tipados moleculares comunes MLST, Spatyper, SCCmec, agr Locus y Consolidar.
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
include { SUMMARY_STAPHYLOCOCCUS_TYPE                                 } from '../../subworkflows/local/staptype_sum'
include { CSVTK_CONCAT as SUMMARY_MLST                       } from '../../modules/nf-core/csvtk/concat/main'
include { CSVTK_CONCAT as SUMMARY_SPATYPER                   } from '../../modules/nf-core/csvtk/concat/main'
include { CSVTK_CONCAT as SUMMARY_SCCMEC                     } from '../../modules/nf-core/csvtk/concat/main'
include { CSVTK_CONCAT as SUMMARY_AGRVATE                    } from '../../modules/nf-core/csvtk/concat/main'

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

    //RUN Summary por cada herramienta
    SUMMARY_MLST (
        ch_merge_mlst,
        'tsv',
        'tsv',
        '--no-header-row'
        )
    SUMMARY_MLST.out.csv
        .collect{ it[1] }
        .set { ch_mslt }
    
    SUMMARY_SPATYPER (
        ch_merge_spatyper,
        'tsv',
        'tsv',
        ''
    )
    SUMMARY_SPATYPER.out.csv
        .collect{ it[1] }
        .set { ch_spatyper }

    SUMMARY_SCCMEC (
        ch_merge_sccmec,
        'tsv',
        'tsv',
        ''
    )
    SUMMARY_SCCMEC.out.csv
        .collect{ it[1] }
        .set { ch_sccmec }

    SUMMARY_AGRVATE (
        ch_merge_agrvate,
        'tsv',
        'tsv',
        '-C "$"'
    )
    SUMMARY_AGRVATE.out.csv
        .collect{ it[1] }
        .set { ch_agr }

    // RUN Summary Consolidado
    SUMMARY_STAPHYLOCOCCUS_TYPE (
        [ id:"staptypes-report" ],        
        ch_agr, 
        ch_mslt, 
        ch_spatyper,
        ch_sccmec
    )
}