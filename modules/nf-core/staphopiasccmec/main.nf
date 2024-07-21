process STAPHOPIASCCMEC {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/staphopia-sccmec:1.0.0--hdfd78af_0' :
        'biocontainers/staphopia-sccmec:1.0.0--hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.tsv"), emit: tsv
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    staphopia-sccmec --assembly $fasta $args > ${prefix}.tsv

    echo -e "Sample\\t\$(head -n 1 ${prefix}.tsv)" > ${prefix}_modified.tsv
    tail -n +2 ${prefix}.tsv | while IFS= read -r line; do
        echo -e "${meta.id}\\t\$line" >> ${prefix}_modified.tsv
    done

    mv ${prefix}_modified.tsv ${prefix}.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        staphopiasccmec: \$(staphopia-sccmec --version 2>&1 | sed 's/^.*staphopia-sccmec //')
    END_VERSIONS
    """
}
