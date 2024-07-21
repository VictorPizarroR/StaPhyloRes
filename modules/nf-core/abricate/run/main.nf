process ABRICATE_RUN {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/abricate%3A1.0.1--ha8f3691_1':
        'biocontainers/abricate:1.0.1--ha8f3691_1' }"

    input:
    tuple val(meta), path(assembly)
    val database

    output:
    tuple val(meta), path("${meta.id}_${database}.txt"), emit: report
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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        abricate: \$(echo \$(abricate --version 2>&1) | sed 's/^.*abricate //' )
    END_VERSIONS
    """
}
