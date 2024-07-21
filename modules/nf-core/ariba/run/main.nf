process ARIBA_RUN {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ariba:2.14.6--py39h67e14b5_3':
        'biocontainers/ariba:2.14.6--py39h67e14b5_3' }"

    input:
    tuple val(meta), path(reads)
    each path (db)

    output:
    tuple val(meta), path("${db.getName().replace('.tar.gz', '')}/${meta.id}-report.tsv")      , emit: report
    tuple val(meta), path("${db.getName().replace('.tar.gz', '')}/${meta.id}-summary.csv")     , emit: summary
    path "versions.yml"                                                                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def db_name = db.getName().replace('.tar.gz', '')

    """
    tar -xzvf ${db}
    mv ${db_name} ${db_name}_db
    ariba \\
        run \\
        ${db_name}_db/ \\
        ${reads} \\
        ${db_name} \\
        $args \\
        --threads $task.cpus

    ariba \\
        summary \\
        ${db_name}/summary \\
        ${db_name}/report.tsv \\
        --cluster_cols assembled,match,known_var,pct_id,ctg_cov,novel_var \\
        --col_filter n \\
        --row_filter n
    
    echo -e "Sample\\t\$(head -n 1 ${db_name}/report.tsv)" > ${db_name}/${prefix}-report_modified.tsv
    tail -n +2 ${db_name}/report.tsv | while IFS= read -r line; do
        echo -e "${meta.id}\\t\$line" >> ${db_name}/${prefix}-report_modified.tsv
    done

    echo -e "Sample\\t\$(head -n 1 ${db_name}/summary.csv)" > ${db_name}/${prefix}-summary_modified.csv
    tail -n +2 ${db_name}/summary.csv | while IFS= read -r line; do
        echo -e "${meta.id}\\t\$line" >> ${db_name}/${prefix}-summary_modified.csv
    done

    # Rename to avoid naming collisions
    mv ${db_name}/${prefix}-report_modified.tsv ${db_name}/${prefix}-report.tsv
    mv ${db_name}/${prefix}-summary_modified.csv ${db_name}/${prefix}-summary.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ariba:  \$(echo \$(ariba version 2>&1) | sed 's/^.*ARIBA version: //;s/ .*\$//')
    END_VERSIONS
    """
}
