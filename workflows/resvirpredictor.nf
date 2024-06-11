/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQC                        } from '../modules/nf-core/fastqc/main'
include { MULTIQC                       } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap              } from 'plugin/nf-validation'
include { FASTP					        } from '../modules/nf-core/fastp/main'
include { UNICYCLER				        } from '../modules/nf-core/unicycler/main'
include { QUAST					        } from '../modules/nf-core/quast/main'
include { ABRICATE_RUN                  } from '../modules/nf-core/abricate/run/main'
include { ABRICATE_RUN as ABRICATE_VFDB             } from '../modules/nf-core/abricate/run/main'
include { ABRICATE_RUN as ABRICATE_STAPH            } from '../modules/nf-core/abricate/run/main'
include { ABRICATE_SUMMARY              } from '../modules/nf-core/abricate/summary/main'
include { ARIBA_GETREF as ARIBA_GETREF_RESFINDER		} from '../modules/nf-core/ariba/getref/main'
include { ARIBA_GETREF as ARIBA_GETREF_VFDB    			} from '../modules/nf-core/ariba/getref/main'
include { ARIBA_GETREF as ARIBA_GETREF_PLASMIDFINDER	} from '../modules/nf-core/ariba/getref/main'
include { ARIBA_GETREF as ARIBA_GETREF_CARD         	} from '../modules/nf-core/ariba/getref/main'
include { ARIBA_RUN    as ARIBA_RESFINDER		        } from '../modules/nf-core/ariba/run/main'
include { ARIBA_RUN    as ARIBA_VFDB    		        } from '../modules/nf-core/ariba/run/main'
include { ARIBA_RUN    as ARIBA_PLASMIDFINDER		    } from '../modules/nf-core/ariba/run/main'
include { ARIBA_RUN    as ARIBA_CARD        		    } from '../modules/nf-core/ariba/run/main'
include { STARAMR_SEARCH                                } from '../modules/nf-core/staramr/search/main'
include { PROKKA                        } from '../modules/nf-core/prokka/main'
include { MASH_DIST                     } from '../modules/nf-core/mash/dist/main'
include { SNIPPY_RUN			        } from '../modules/nf-core/snippy/run/main'
include { SNIPPY_CORE			        } from '../modules/nf-core/snippy/core/main'
include { MASHTREE                      } from '../modules/nf-core/mashtree/main'
include { IQTREE				        } from '../modules/nf-core/iqtree/main'
include { MLST					        } from '../modules/nf-core/mlst/main'
include { SPATYPER				        } from '../modules/nf-core/spatyper/main'
include { STAPHOPIASCCMEC		        } from '../modules/nf-core/staphopiasccmec/main'
include { AGRVATE                       } from '../modules/nf-core/agrvate/main'
include { MYKROBE_PREDICT		        } from '../modules/nf-core/mykrobe/predict/main'
include { MASH_SKETCH as SKETCH_REFERENCE               } from '../modules/nf-core/mash/sketch/main'
include { MASH_SCREEN                   } from '../modules/nf-core/mash/screen/main'
include { GUBBINS                       } from '../modules/nf-core/gubbins/main'
include { FASTQ_TRIM_FASTP_FASTQC       } from '../subworkflows/nf-core/fastq_trim_fastp_fastqc/main'
include { paramsSummaryMultiqc          } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML        } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText        } from '../subworkflows/local/utils_nfcore_resvirpredictor_pipeline'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow RESVIRPREDICTOR {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // SUBWORKFLOW: Short reads QC and trim adapters
    //
    ch_fastqc_raw_multiqc = Channel.empty()
    ch_fastqc_trim_multiqc = Channel.empty()
    ch_trim_json_multiqc = Channel.empty()
    
    FASTQ_TRIM_FASTP_FASTQC (
        ch_samplesheet,
        [],
        params.save_trimmed_fail,
        params.save_merged,
        params.skip_fastp,
        params.skip_fastqc
        )
        ch_fastqc_raw_multiqc   = FASTQ_TRIM_FASTP_FASTQC.out.fastqc_raw_zip
        ch_fastqc_trim_multiqc  = FASTQ_TRIM_FASTP_FASTQC.out.fastqc_trim_zip
        ch_trim_json_multiqc    = FASTQ_TRIM_FASTP_FASTQC.out.trim_json
        ch_trim_fastp           = FASTQ_TRIM_FASTP_FASTQC.out.reads
            FASTQ_TRIM_FASTP_FASTQC.out.reads
            .dump(tag: 'fastp')
            .map{ meta,reads -> tuple(meta,reads,[]) }
            .dump(tag: 'ch_unicycler')
            .set { ch_unicycler }
        ch_versions             = ch_versions.mix(FASTQ_TRIM_FASTP_FASTQC.out.versions)
    
    // ENSAMBALDO
    // MODULE: Run Unicycler
    //
    UNICYCLER (
        ch_unicycler
    )
    ch_assembly_read    = UNICYCLER.out.scaffolds.dump(tag: 'Unicycler')

    // ANALISIS DE CALIDAD ENSAMBLADO
    // MODULE: Run Quast
    //
    ch_assembly_read
        .collect{ it[1] }
        .map { consensus_collect -> tuple([id: "report"], consensus_collect) }
        .set { ch_to_quast }
    QUAST (
        ch_to_quast,
        [[:],[]],
        [[:],[]]
    )
    ch_quast_multiqc = QUAST.out.tsv

    // BUSQUEDA DE GENES DE RESISTENCIA/VIRULENCIA EN SECUENCIAS R1 & R2
    // MODULE: Ariba Getref and Run
    //
    ARIBA_GETREF_RESFINDER (
        "resfinder"
    )
    ch_ariba_db_resfinder           = ARIBA_GETREF_RESFINDER.out.db.dump(tag: 'Ariba_db_resfinder')

    ARIBA_RESFINDER   (
        FASTQ_TRIM_FASTP_FASTQC.out.reads,
        ch_ariba_db_resfinder
    )

    ARIBA_GETREF_VFDB (
        "vfdb_core"
    )
    ch_ariba_db_vfdb                = ARIBA_GETREF_VFDB.out.db.dump(tag: 'Ariba_db_vfdb')

    ARIBA_VFDB   (
        FASTQ_TRIM_FASTP_FASTQC.out.reads,
        ch_ariba_db_vfdb
    )

    ARIBA_GETREF_PLASMIDFINDER (
        "plasmidfinder"
    )
    ch_ariba_db_plasmidfinder       = ARIBA_GETREF_PLASMIDFINDER.out.db.dump(tag: 'Ariba_db_plasmidfinder')

    ARIBA_PLASMIDFINDER   (
        FASTQ_TRIM_FASTP_FASTQC.out.reads,
        ch_ariba_db_plasmidfinder
    )

    ARIBA_GETREF_CARD (
        "card"
    )
    ch_ariba_db_card              = ARIBA_GETREF_CARD.out.db.dump(tag: 'Ariba_db_card')

    ARIBA_CARD   (
        FASTQ_TRIM_FASTP_FASTQC.out.reads,
        ch_ariba_db_card
    )

    
    // BUSQUEDA DE GENES DE RESISTENCIA/VIRULENCIA EN ENSAMBLADOS
    // MODULE: Run Multiples databases Abricate
    //
    ABRICATE_STAPH (
        ch_assembly_read,
        "staph"
    )

    ABRICATE_VFDB (
        ch_assembly_read,
        "vfdb"
    )
    
    // IDENTIFICACION DE PLASMIDOS
    // MODULE: Run PlasmidID
    //
/*  
    PLASMIDID (
        ch_assembly_scaffolds
    )
*/    
    // ESTUDIO DE FILOGENIA
    // MODULE: Run Snippy
    //
    SNIPPY_RUN (
        ch_trim_fastp,
        params.snippy_reference
    )
    ch_snippy_fa     = SNIPPY_RUN.out.aligned_fa
    ch_snippy_output = SNIPPY_RUN.out.vcf
                        .join(ch_snippy_fa)
                        .set { ch_snippy_core }
    
    // ESTUDIO DE FILOGENIA
    // MODULE: Run Snippy
    //
    SNIPPY_CORE (
        ch_snippy_core,
        params.snippy_reference
    )
    ch_iqtree        = SNIPPY_CORE.out.aln

    // ESTUDIO DE FILOGENIA
    // MODULE: IQTree
    //
    IQTREE (
        ch_iqtree,
        []
    )

    // TIPADO MOLECULAR
    // MODULE: Run MLST
    //
    MLST (
        ch_assembly_read
    )

    // TIPIFICACION DE SECUENCIAS MULTILOCUS PARA STAPHYLOCOCCUS AUREUS
    // MODULE: Run Spatyper
    //
    SPATYPER (
        ch_assembly_read,
        [],
        []
    )

    // TIPIFICACION SCCmec
    // MODULE: Run Staphopia SCCmec
    //
    STAPHOPIASCCMEC (
        ch_assembly_read
    )

    // TIPIFICACION agr Locus
    // MODULE: Run Agrvate
    //
    AGRVATE (
        ch_assembly_read
    )

    // PREDICCION DE RESISTENCIA
    // MODULE: Run Mykrobe
    //
    MYKROBE_PREDICT (
        ch_trim_fastp,
        'staph'
    )
    
    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(storeDir: "${params.outdir}/pipeline_info", name: 'nf_core_pipeline_software_mqc_versions.yml', sort: true, newLine: true)
        .set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config                     = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config              = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true) : Channel.empty()
    ch_multiqc_logo                       = params.multiqc_logo ? Channel.fromPath(params.multiqc_logo, checkIfExists: true) : Channel.empty()
    summary_params                        = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary                   = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(methodsDescriptionText(ch_multiqc_custom_methods_description))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml', sort: false))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_fastqc_raw_multiqc.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_fastqc_trim_multiqc.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_trim_json_multiqc.collect{it[1]}.ifEmpty([]))
    ch_multiqc_files                      = ch_multiqc_files.mix(ch_quast_multiqc.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
