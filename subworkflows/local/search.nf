process GENOME_COMPLETE_MATCH {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(screen_file)
    
    output:
    tuple val(meta), path("${prefix}.best_complete_match.tab"), emit: best_complete_match

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    set -euo pipefail

    echo "Processing file: $screen_file"
    
    awk -F'\\t' '
        \$6 ~ /complete genome/ && \$6 !~ /phage/ && \$6 !~ /Phage/ && \$6 !~ /shotgun/ {
            print \$0
        }
    ' $screen_file | \
    sort -t \$'\\t' -k1,1nr | \
    head -n 1 | \
    awk -F'\\t' '{print \$5, \$6}' > ${prefix}.best_complete_match.tab || true

    if [[ ! -s ${prefix}.best_complete_match.tab ]]; then
        echo "Query-ID\tQuery-comment" > ${prefix}.best_complete_match.tab
    fi
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.best_complete_match.tab
    """
}