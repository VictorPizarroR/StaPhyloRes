process GENOME_FILTER_MATCH {
    tag "$meta.id"
    label 'process_low'

    input:
    val(meta)
    path(best_complete_match_files)

    output:
    path("output/counter_complete_mash.tab"), emit: counter
    path("output/best_genome.tab"), emit: genome

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    set -euo pipefail

    output_complete_tab="output/counter_complete_mash.tab"
    output_best_genome="output/best_genome.tab"

    mkdir -p output

    # Crear archivo temporal
    counter_record_complete=\$(mktemp)

    # Consolidar los resultados en el archivo temporal
    for file in $best_complete_match_files; do
        awk -F'\\t' '{print \$1 "\\t" \$2}' "\$file" >> "\$counter_record_complete"
    done

    # Contar las ocurrencias y guardar los resultados en el archivo de salida
    echo -e "counts\\tquery-ID\\tquery-comment" > "\$output_complete_tab"
    awk -F'\\t' '{print \$1 "\\t" \$2}' "\$counter_record_complete" | sort | uniq -c | sort -nr | awk '{print \$1 "\\t" \$2 "\\t" \$3}' >> "\$output_complete_tab"

    # Obtener la referencia común más frecuente
    gfc_complete=\$(tail -n +2 "\$output_complete_tab" | head -n 1 | awk '{print \$2}' | cut -d'_' -f1-2)

    # Guardar la referencia común más frecuente en un archivo
    echo "\$gfc_complete" > "\$output_best_genome"

    # Limpiar archivo temporal
    rm "\$counter_record_complete"

    echo "Referencia común más frecuente: \$gfc_complete"
    """
    
    stub:
    """
    mkdir -p output
    touch output/counter_complete_mash.tab
    touch output/best_genome.tab
    """
}