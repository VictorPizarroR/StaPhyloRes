//
// Subworkflow Obtener bases de datos Ariba, Run y Consolidar.
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { ARIBA_GETREF              } from '../../modules/nf-core/ariba/getref/main'
include { ARIBA_RUN                 } from '../../modules/nf-core/ariba/run/main'
include { CSVTK_CONCAT as CSVTK_CONCAT_REPORT                 } from '../../modules/nf-core/csvtk/concat/main'
include { CSVTK_CONCAT as CSVTK_CONCAT_SUMMARY                } from '../../modules/nf-core/csvtk/concat/main'

/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow ARIBA {
    take:
    input_reads // channel: trimreads from fastp
    db_name     // string:  db version to use

    main:
    ch_versions = Channel.empty()

    //OBTENER BASE DE DATOS
    ARIBA_GETREF(db_name)

    ch_ariba_db                = ARIBA_GETREF.out.db.dump(tag: 'Ariba_db') 
    
    //RUN ARIBA
    ARIBA_RUN(input_reads, ch_ariba_db)

    ARIBA_RUN.out.report.collect{meta, report -> report}
        .map{ report -> [[id:"ariba-${db_name}-report"], report]}
        .set{ ch_merge_report }
    
    ARIBA_RUN.out.summary.collect{meta, summary -> summary}
        .map{ summary -> [[id:"ariba-${db_name}-summary"], summary]}
        .set{ ch_merge_summary }

    CSVTK_CONCAT_REPORT(ch_merge_report, 'tsv', 'tsv', '-C "$" --lazy-quotes')

    CSVTK_CONCAT_SUMMARY(ch_merge_summary, 'csv', 'csv', '--lazy-quotes')

}
