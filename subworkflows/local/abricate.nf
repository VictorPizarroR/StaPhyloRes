//
// Subworkflow Instalar BD Persolanlizada, Run Abricate, Summary y concatenar resultados.
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ABRICATE_RUN                                 } from '../../modules/nf-core/abricate/run/main'
include { CSVTK_CONCAT as SUMMARY_REPORT               } from '../../modules/nf-core/csvtk/concat/main'

/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow ABRICATE {
    take:
    input_reads // channel: trimreads from fastp
    db_name     // string:  db version to use

    main:
    ch_versions = Channel.empty()
    
    //RUN ABRICATE
    ABRICATE_RUN (input_reads, db_name)

    ABRICATE_RUN.out.summary.collect{meta, summary -> summary}
        .map{ summary -> [[id:"abricate-${db_name}-summary"], summary]}
        .set{ ch_merge_summary }

    //RUN SUMMARY CSVTK
    SUMMARY_REPORT(ch_merge_summary, 'tsv', 'tsv', '--lazy-quotes')

}