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
include { CSVTK_CONCAT as SUMMARY_REPORT               } from '../../modules/nf-core/csvtk/concat/main'
include { CSVTK_CONCAT as SUMMARY_ARIBA                } from '../../modules/nf-core/csvtk/concat/main'

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
    ch_ariba_db = Channel.empty()

    // Dynamically resolve the expected local tarball path if the base directory is provided
    def local_tarball = params.ariba_db_dir ? "${params.ariba_db_dir}/${db_name}.tar.gz" : null

    // CHECK IF LOCAL DATABASE DIRECTORY AND THE SPECIFIC TARBALL EXIST
    if ( local_tarball && file(local_tarball).exists() ) {
        
        // Define clean explicit string for the dump operator tag
        String local_tag = "Ariba_Local_${db_name}"

        // FIX: Emit ONLY the raw file object to perfectly match ARIBA_RUN's channel input expectation
        ch_ariba_db = Channel.fromPath(local_tarball)
            .dump(tag: local_tag)

    } else {
        
        // Define clean explicit string for the dump operator tag
        String online_tag = "Ariba_Online_${db_name}"

        // Fallback to online automatic download if the localized file isn't present
        ARIBA_GETREF(db_name)
        ch_ariba_db = ARIBA_GETREF.out.db.dump(tag: online_tag)
        ch_versions = ch_versions.mix(ARIBA_GETREF.out.versions)

    }
    
    // RUN ARIBA
    ARIBA_RUN(input_reads, ch_ariba_db)

    ARIBA_RUN.out.report.collect{meta, report -> report}
        .map{ report -> [[id:"ariba-${db_name}-report"], report]}
        .set{ ch_merge_report }
    
    ARIBA_RUN.out.summary.collect{meta, summary -> summary}
        .map{ summary -> [[id:"ariba-${db_name}-summary"], summary]}
        .set{ ch_merge_summary }

    SUMMARY_REPORT(ch_merge_report, 'tsv', 'tsv', '-C "$" --lazy-quotes')

    SUMMARY_ARIBA(ch_merge_summary, 'csv', 'csv', '--lazy-quotes')

}