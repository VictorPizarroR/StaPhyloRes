process MASH_DIST {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mash:2.3--he348c14_1' :
        'staphb/mash:2.3' }"

    input:
    tuple val(meta), path(query)
    path reference

    output:
    tuple val(meta), path("*.tab"), emit: dist
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mash \\
        dist \\
        -p $task.cpus \\
        $args \\
        $reference \\
        $query > ${prefix}.tab

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mash: \$(mash --version 2>&1)
    END_VERSIONS
    """
}
