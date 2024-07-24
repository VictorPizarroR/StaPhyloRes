#!/usr/bin/env nextflow

process GENOME {
    tag "$meta.id"
    label 'process_low'

    input:
    val(meta)
    path(file_list)

    output:
    path("best_genome.tab"), emit: genome

    script:
    """
    return_best_complete_match() {
        screen_file=\$1

        awk -F'\\t' '
            \$6 ~ /complete genome/ && \$6 !~ /phage/ && \$6 !~ /Phage/ && \$6 !~ /shotgun/ {
                print \$0
            }
        ' "\$screen_file" |
        sort -t \$'\\t' -k1,1nr |
        head -n 1 |
        awk -F'\\t' '{print \$5, \$6}'
    }

    return_best_match() {
        screen_file=\$1

        sort -t \$'\\t' -k1,1nr "\$screen_file" |
        head -n 1 |
        awk -F'\\t' '{print \$5, \$6}'
    }

    process_files() {
        output_file_complete="./mash_best_complete_match.txt"
        output_file_best="./mash_best_match.txt"

        > "\$output_file_complete"
        > "\$output_file_best"

        while IFS= read -r screen_file; do
            if [ -f "\$screen_file" ]; then
                best_complete_match=\$(return_best_complete_match "\$screen_file")
                if [ -n "\$best_complete_match" ]; then
                    echo -e "\$screen_file\\t\$best_complete_match" >> "\$output_file_complete"
                fi

                best_match=\$(return_best_match "\$screen_file")
                if [ -n "\$best_match" ]; then
                    echo -e "\$screen_file\\t\$best_match" >> "\$output_file_best"
                fi
            else
                echo "Archivo no encontrado: \$screen_file"
            fi
        done < "\$1"
    }

    find_common_reference() {
        output_complete_tab="./counter_complete_mash.tab"
        output_all_tab="./counter_all_mash.tab"
        output_best_genome="./best_genome.tab"

        counter_record_complete=\$(mktemp)
        counter_record_all=\$(mktemp)

        while IFS=\$'\\t' read -r file query_id query_comment; do
            echo -e "\$query_id\\t\$query_comment" >> "\$counter_record_complete"
        done < "./mash_best_complete_match.txt"

        while IFS=\$'\\t' read -r file query_id query_comment; do
            echo -e "\$query_id\\t\$query_comment" >> "\$counter_record_all"
        done < "./mash_best_match.txt"

        counter_df_complete=\$(awk -F'\\t' '{print \$1 "\\t" \$2}' "\$counter_record_complete" | sort | uniq -c | sort -nr)
        counter_df=\$(awk -F'\\t' '{print \$1 "\\t" \$2}' "\$counter_record_all" | sort | uniq -c | sort -nr)

        echo -e "counts\\tquery-ID\\tquery-comment" > "\$output_complete_tab"
        echo "\$counter_df_complete" | awk '{print \$1 "\\t" \$2 "\\t" \$3}' >> "\$output_complete_tab"

        echo -e "counts\\tquery-ID\\tquery-comment" > "\$output_all_tab"
        echo "\$counter_df" | awk '{print \$1 "\\t" \$2 "\\t" \$3}' >> "\$output_all_tab"

        gfc_complete=\$(echo "\$counter_df_complete" | head -n 1 | awk '{print \$2}' | cut -d'_' -f1-2)

        echo "\$gfc_complete" > "\$output_best_genome"

        rm "\$counter_record_complete" "\$counter_record_all"

        echo "Referencia común más frecuente: \$gfc_complete"
    }

    if [ -z "\$1" ]; then
        echo "Uso: \$0 archivo_de_lista.txt"
        exit 1
    fi

    process_files "\$1"
    find_common_reference
    """
}