process ABRICATE_RUN {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/abricate%3A1.0.1--ha8f3691_1':
        'biocontainers/abricate:1.0.1--ha8f3691_1' }"

    // Estrategia de manejo de errores
    errorStrategy 'ignore'

    input:
    tuple val(meta), path(assembly)
    val database

    output:
    tuple val(meta), path("${meta.id}_${database}.txt"), emit: report
    tuple val(meta), path("*.tsv"), emit: summary
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    abricate \\
        --db $database \\
        $assembly \\
        $args \\
        --threads $task.cpus > ${prefix}_${database}.txt

    # Verificar si el comando anterior falló
    if [ \$? -ne 0 ]; then
        echo "ERROR: ABRICATE encontró un error al procesar ${meta.id}."
    fi

    abricate \\
        --summary \\
        ${prefix}_${database}.txt > temp_${prefix}_${database}-summary.tsv

    awk -v sample="${meta.id}" 'BEGIN {OFS="\\t"} NR==1 {print "Sample", \$0} NR>1 {print sample, \$0}' temp_${prefix}_${database}-summary.tsv > ${prefix}_${database}-summary.tsv

    rm temp_${prefix}_${database}-summary.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(echo \$(abricate --version 2>&1) | sed 's/^.*abricate //' )
    END_VERSIONS
    """
}
