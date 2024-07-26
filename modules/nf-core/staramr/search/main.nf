process STARAMR_SEARCH {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/staramr:0.10.0--pyhdfd78af_0':
        'biocontainers/staramr:0.10.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(genome_fasta) // genome as a fasta file

    output:
    tuple val(meta), path("${meta.id}/results.xlsx")        , emit: results_xlsx
    tuple val(meta), path("${meta.id}/summary.tsv")         , emit: summary_tsv
    tuple val(meta), path("${meta.id}/${meta.id}_detailed_summary.tsv"), emit: detailed_summary_tsv
    tuple val(meta), path("${meta.id}/resfinder.tsv")       , emit: resfinder_tsv
    tuple val(meta), path("${meta.id}/plasmidfinder.tsv")   , emit: plasmidfinder_tsv
    tuple val(meta), path("${meta.id}/mlst.tsv")            , emit: mlst_tsv
    tuple val(meta), path("${meta.id}/settings.txt")        , emit: settings_txt
    tuple val(meta), path("${meta.id}/pointfinder.tsv")     , emit: pointfinder_tsv, optional: true
    path "versions.yml"                                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_gzipped = genome_fasta.getName().endsWith(".gz") ? true : false
    def genome_uncompressed_name = genome_fasta.getName().replace(".gz", "")
    """
    if [ "$is_gzipped" = "true" ]; then
        gzip -c -d $genome_fasta > $genome_uncompressed_name
    fi

    staramr \\
        search \\
        $args \\
        --pointfinder-organism 'staphylococcus_aureus' \\
        --nprocs $task.cpus \\
        -o ${prefix} \\
        $genome_uncompressed_name

    awk -v sample="${meta.id}" 'BEGIN {OFS="\\t"} NR==1 {print "Sample", \$0} NR>1 {print sample, \$0}' \\
        ${meta.id}/detailed_summary.tsv > ${meta.id}/temp_detailed_summary.tsv

    mv ${meta.id}/temp_detailed_summary.tsv ${meta.id}/${meta.id}_detailed_summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        staramr : \$(echo \$(staramr --version 2>&1) | sed 's/^.*staramr //' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}
    touch ${prefix}/results.xlsx
    touch ${prefix}/{summary,detailed_summary,resfinder,pointfinder,plasmidfinder,mlst}.tsv.gz
    touch ${prefix}/settings.txt.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        staramr : \$(echo \$(staramr --version 2>&1) | sed 's/^.*staramr //' )
    END_VERSIONS
    """
}