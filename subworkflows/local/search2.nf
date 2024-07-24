process GENOME_FILTER_MATCH {
    tag "$meta.id"
    label 'process_low'

    input:
    tuple val(meta), path(best_complete_match_files)

    output:
    tuple val(meta), path("counter_complete_mash.tab"), emit: counter_complete
    tuple val(meta), path("counter_all_mash.tab"), emit: counter_all
    tuple val(meta), path("best_genome.tab"), emit: best_genome

    when:
    task.ext.when == null || task.ext.when
    
    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    set -euo pipefail

    mkdir -p output
    output_complete_tab="output/counter_complete_mash.tab"
    output_all_tab="output/counter_all_mash.tab"
    output_best_genome="output/best_genome.tab"

    # Crear archivos temporales
    counter_record_complete=\$(mktemp)
    counter_record_all=\$(mktemp)

    # Consolidar los resultados en los archivos temporales
    for file in ${best_complete_match_files[*]}; do
        cat \$file >> "\$counter_record_complete"
    done

    # Contar las ocurrencias y guardar los resultados en los archivos de salida
    echo -e "counts\tquery-ID\tquery-comment" > "\$output_complete_tab"
    awk -F'\\t' '{print \$1 "\t" \$2}' "\$counter_record_complete" | sort | uniq -c | sort -nr | awk '{print \$1 "\t" \$2 "\t" \$3}' >> "\$output_complete_tab"

    echo -e "counts\tquery-ID\tquery-comment" > "\$output_all_tab"
    awk -F'\\t' '{print \$1 "\t" \$2}' "\$counter_record_all" | sort | uniq -c | sort -nr | awk '{print \$1 "\t" \$2 "\t" \$3}' >> "\$output_all_tab"

    # Obtener la referencia común más frecuente
    gfc_complete=\$(tail -n +2 "\$output_complete_tab" | head -n 1 | awk '{print \$2}' | cut -d'_' -f1-2)

    # Guardar la referencia común más frecuente en un archivo
    echo "\$gfc_complete" > "\$output_best_genome"

    # Limpiar archivos temporales
    rm "\$counter_record_complete" "\$counter_record_all"

    echo "Referencia común más frecuente: \$gfc_complete"
    """
    
    stub:
    """
    mkdir -p output
    touch output/counter_complete_mash.tab
    touch output/counter_all_mash.tab
    touch output/best_genome.tab
    """
}