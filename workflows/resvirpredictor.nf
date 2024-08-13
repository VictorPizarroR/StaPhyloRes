/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MULTIQC                                   } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap                          } from 'plugin/nf-validation'
include { UNICYCLER				                    } from '../modules/nf-core/unicycler/main'
include { QUAST					                    } from '../modules/nf-core/quast/main'
include { STARAMR_SEARCH                            } from '../modules/nf-core/staramr/search/main'
include { CSVTK_CONCAT as SUMMARY_STARAMR           } from '../modules/nf-core/csvtk/concat/main'
include { PROKKA                                    } from '../modules/nf-core/prokka/main'
include { MASH_DIST                                 } from '../modules/nf-core/mash/dist/main'
include { SNIPPY_RUN			                    } from '../modules/nf-core/snippy/run/main'
include { SNIPPY_CORE			                    } from '../modules/nf-core/snippy/core/main'
include { MASHTREE                                  } from '../modules/nf-core/mashtree/main'
include { IQTREE				                    } from '../modules/nf-core/iqtree/main'
include { MYKROBE_PREDICT		                    } from '../modules/nf-core/mykrobe/predict/main'
include { CSVTK_CONCAT as SUMMARY_MYKROBE           } from '../modules/nf-core/csvtk/concat/main'
include { MASH_SCREEN                               } from '../modules/nf-core/mash/screen/main'
include { GUBBINS                                   } from '../modules/nf-core/gubbins/main'
include { NCBIGENOMEDOWNLOAD                        } from '../modules/nf-core/ncbigenomedownload/main'
include { FASTQ_TRIM_FASTP_FASTQC                   } from '../subworkflows/nf-core/fastq_trim_fastp_fastqc/main'
include { STAPTYPES                                 } from '../subworkflows/local/staptypes'
include { ARIBA as ARIBA_RESFINDER                  } from '../subworkflows/local/ariba'
include { ARIBA as ARIBA_VFDB                       } from '../subworkflows/local/ariba'
include { ARIBA as ARIBA_PLASMIDFINDER              } from '../subworkflows/local/ariba'
include { ARIBA as ARIBA_CARD                       } from '../subworkflows/local/ariba'
include { ABRICATE as ABRICATE_VFDB                 } from '../subworkflows/local/abricate'
include { ABRICATE as ABRICATE_STAPH                } from '../subworkflows/local/abricate'
include { ABRICATE as ABRICATE_RESFINDER            } from '../subworkflows/local/abricate'
include { GENOME_COMPLETE_MATCH                     } from '../subworkflows/local/search'
include { GENOME_FILTER_MATCH                       } from '../subworkflows/local/search2'
include { paramsSummaryMultiqc                      } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML                    } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText                    } from '../subworkflows/local/utils_nfcore_resvirpredictor_pipeline'
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
    // SUBWORKFLOW: Obtener bases de datos Ariba, Run y Consolidar.
    //
    ARIBA_RESFINDER (
        ch_trim_fastp,
        'resfinder'
    )

    ARIBA_PLASMIDFINDER (
        ch_trim_fastp,
        'plasmidfinder'
    )

    ARIBA_CARD (
        ch_trim_fastp,
        'card'
    )

    ARIBA_VFDB (
        ch_trim_fastp,
        'vfdb_core'
    )
    
    // BUSQUEDA DE GENES DE RESISTENCIA/VIRULENCIA EN ENSAMBLADOS
    // MODULE: Run Multiples databases Abricate
    //
    if (params.abricate_db) {
        ABRICATE_STAPH (
            ch_assembly_read,
            "staph"
            )
    }

    ABRICATE_VFDB (
        ch_assembly_read,
        "vfdb"
    )

    ABRICATE_RESFINDER (
        ch_assembly_read,
        "resfinder"
    )

    // MODULE: Run Multiples databases Staramr Search
    //
    STARAMR_SEARCH (
        ch_assembly_read
    )

    STARAMR_SEARCH.out.detailed_summary_tsv.collect{meta, tsv -> tsv}.map{ tsv -> [[id:'staramr-summary'], tsv]}.set{ ch_merge_staramr }

    SUMMARY_STARAMR (
        ch_merge_staramr,
        'tsv',
        'tsv',
        ''
    )

    // ANOTACION
    // MODULE: Prokka
    //
    PROKKA (
        ch_assembly_read,
        [],
        []
    )

    // BUSQUEDA DE GENOMA DE REFERENCIA
    // MODULE: Run Mash Screen
    //
    if (params.filogeny) {
        MASH_SCREEN (
            ch_assembly_read,
            params.mash_reference
            )
    

        ch_mash        = MASH_SCREEN.out.screen
            ch_mash
                .collect{ it[1] }
                .set { ch_to_genome }

        GENOME_COMPLETE_MATCH (
            ch_mash
        )

        ch_filter_genome    = GENOME_COMPLETE_MATCH.out.match
            ch_filter_genome
                .collect{ it[1] }
                .set { ch_to_genome }

        GENOME_FILTER_MATCH (
            [ id:"refseq" ],
            ch_to_genome
        )

        ch_common_genome    = GENOME_FILTER_MATCH.out.genome
            ch_common_genome
                .map { file -> file.text.trim() }
                .set { ch_final_genome }

        // DESCARGA DE BASE DE DATOS DE REFERENCIA
        // MODULE: Run ncbi-genome-download
        //
        NCBIGENOMEDOWNLOAD (
            [ id:"refseq" ],
            ch_final_genome,
            [],
            'bacteria'
        )
        ch_refseq           = NCBIGENOMEDOWNLOAD.out.gbk
            ch_refseq
                .collect{ it[1] }
                .set { ch_to_snippy }

    /*
        // BUSQUEDA DE DISTANCIAS SEGUN GENOMA DE REFERENCIA
        // MODULE: Run Mash Dist
        //
        MASH_DIST (
            ch_assembly_read,
            params.mash_reference
        )
    */
        // ESTUDIO DE FILOGENIA
        // MODULE: Run Snippy
        //
        SNIPPY_RUN (
            ch_trim_fastp,
            ch_to_snippy
        )

        // PREPARACION DE CHANNELS
        SNIPPY_RUN.out.vcf.collect{meta, vcf -> vcf}.map{ vcf -> [[id:'snp-core'], vcf]}.set{ ch_merge_vcf }
        SNIPPY_RUN.out.aligned_fa.collect{meta, aligned_fa -> aligned_fa}.map{ aligned_fa -> [[id:'snp-core'], aligned_fa]}.set{ ch_merge_aligned_fa }
        ch_merge_vcf.join( ch_merge_aligned_fa ).set{ ch_snippy_core }

        // ESTUDIO DE FILOGENIA MEDIANTE SNP
        // MODULE: Run Snippy Core
        //
        SNIPPY_CORE (
            ch_snippy_core,
            ch_to_snippy
        )
        ch_iqtree        = SNIPPY_CORE.out.aln
            ch_iqtree
                .collect{ it[1] }
                .set { ch_to_gubbins }

        // ESTUDIO DE FILOGENIA MEDIANTE SNP
        // MODULE: IQTree
        //
        IQTREE (
            ch_iqtree,
            []
        )

        // ESTUDIO DE DISTANCIA ENTRE ENSAMBLADOS
        // MODULE: IQTree
        //
        ch_assembly_read
            .collect{ it[1] }
            .map { consensus_collect -> tuple([id: "aligments"], consensus_collect) }
            .set { ch_to_mashtree }
    
        MASHTREE (
            ch_to_mashtree
        )

        // ESTUDIO DE FILOGENIA MEDIANTE SNP
        // MODULE: Gubbins
        //
        if (params.gubbins) {
                GUBBINS(
                    ch_to_gubbins
                    )
        }
    }
    // ESTUDIO MLST PARA STAPHYLOCOCCUS AUREUS
    // SUBWORKFLOW: Obtener Tipados moleculares comunes MLST, Spa-type, SCCmec, agr Locus y Consolidar Tipados.
    //
    STAPTYPES (
        ch_assembly_read
    )

    // PREDICCION DE RESISTENCIA
    // MODULE: Run Mykrobe
    //
    MYKROBE_PREDICT (
        ch_trim_fastp,
        'staph'
    )

    MYKROBE_PREDICT.out.csv.collect{meta, csv -> csv}.map{ csv -> [[id:'mykrobe-report'], csv]}.set{ ch_merge_mykrobe }
    
    SUMMARY_MYKROBE (
        ch_merge_mykrobe,
        'csv',
        'csv',
        ''
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
