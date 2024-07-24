#!/bin/bash

return_best_complete_match() {
    screen_file=$1
    
    # Filtrar líneas que contienen 'complete genome' y excluir 'phage', 'Phage', 'shotgun'
    awk -F'\t' '
        $6 ~ /complete genome/ && $6 !~ /phage/ && $6 !~ /Phage/ && $6 !~ /shotgun/ {
            print $0
        }
    ' "$screen_file" |
    # Ordenar por la columna 'identity' (la primera columna) en orden descendente
    sort -t $'\t' -k1,1nr |
    # Obtener la primera línea
    head -n 1 |
    # Imprimir las columnas 'query-ID' (quinta columna) y 'query-comment' (sexta columna)
    awk -F'\t' '{print $5, $6}'
}

return_best_match() {
    screen_file=$1
    
    # Ordenar por la columna 'identity' (la primera columna) en orden descendente
    sort -t $'\t' -k1,1nr "$screen_file" |
    # Obtener la primera línea
    head -n 1 |
    # Imprimir las columnas 'query-ID' (quinta columna) y 'query-comment' (sexta columna)
    awk -F'\t' '{print $5, $6}'
}

process_directory() {
    directory=$1
    output_file_complete="$directory/mash_best_complete_match.txt"
    output_file_best="$directory/mash_best_match.txt"
    
    # Limpiar los archivos de salida si ya existen
    > "$output_file_complete"
    > "$output_file_best"
    
    # Iterar sobre todos los archivos screen.tab en la carpeta
    for screen_file in "$directory"/*screen.tab; do
        best_complete_match=$(return_best_complete_match "$screen_file")
        if [ -n "$best_complete_match" ]; then
            echo -e "$screen_file\t$best_complete_match" >> "$output_file_complete"
        fi
        
        best_match=$(return_best_match "$screen_file")
        if [ -n "$best_match" ]; then
            echo -e "$screen_file\t$best_match" >> "$output_file_best"
        fi
    done
}

#process_files() {
#    files=("$@")
#    output_file_complete="mash_best_complete_match.txt"
#    output_file_best="mash_best_match.txt"

#    # Limpiar los archivos de salida si ya existen
#    > "$output_file_complete"
#    > "$output_file_best"
    
    # Iterar sobre todos los archivos screen.tab en la lista
#    for screen_file in "${files[@]}"; do
#        best_complete_match=$(return_best_complete_match "$screen_file")
#        if [ -n "$best_complete_match" ]; then
#            echo -e "$screen_file\t$best_complete_match" >> "$output_file_complete"
#        fi
        
#        best_match=$(return_best_match "$screen_file")
#        if [ -n "$best_match" ]; then
#            echo -e "$screen_file\t$best_match" >> "$output_file_best"
#        fi
#    done
#}


find_common_reference() {
    folder=$1
    output_complete_tab="$folder/counter_complete_mash.tab"
    output_all_tab="$folder/counter_all_mash.tab"
    output_best_genome="$folder/best_genome.tab"

    # Crear DataFrames vacíos
    counter_record_complete=$(mktemp)
    counter_record_all=$(mktemp)

    # Leer archivos de entrada y consolidar los resultados en los DataFrames temporales
    while IFS=$'\t' read -r file query_id query_comment; do
        echo -e "$query_id\t$query_comment" >> "$counter_record_complete"
    done < "$folder/mash_best_complete_match.txt"

    while IFS=$'\t' read -r file query_id query_comment; do
        echo -e "$query_id\t$query_comment" >> "$counter_record_all"
    done < "$folder/mash_best_match.txt"

    # Convertir los archivos temporales en DataFrames y contar las ocurrencias
    counter_df_complete=$(awk -F'\t' '{print $1 "\t" $2}' "$counter_record_complete" | sort | uniq -c | sort -nr)
    counter_df=$(awk -F'\t' '{print $1 "\t" $2}' "$counter_record_all" | sort | uniq -c | sort -nr)

    # Guardar los resultados en los archivos de salida
    echo -e "counts\tquery-ID\tquery-comment" > "$output_complete_tab"
    echo "$counter_df_complete" | awk '{print $1 "\t" $2 "\t" $3}' >> "$output_complete_tab"

    echo -e "counts\tquery-ID\tquery-comment" > "$output_all_tab"
    echo "$counter_df" | awk '{print $1 "\t" $2 "\t" $3}' >> "$output_all_tab"

    # Obtener la referencia común más frecuente
    gfc_complete=$(echo "$counter_df_complete" | head -n 1 | awk '{print $2}' | cut -d'_' -f1-2)

    # Guardar la referencia común más frecuente en un archivo
    echo "$gfc_complete" > "$output_best_genome"

    # Limpiar archivos temporales
    rm "$counter_record_complete" "$counter_record_all"

    # Mostrar la referencia común más frecuente
    echo "Referencia común más frecuente: $gfc_complete"
}

# Verificar si se proporcionó un argumento
if [ $# -ne 1 ]; then
    echo "Uso: $0 ruta/a/la/carpeta"
    exit 1
fi

# Llamada a la función con la carpeta de entrada como argumento
process_directory "$1"
find_common_reference "$1"
