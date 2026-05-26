#!/bin/bash

# Define el directorio de entrada y el archivo de salida
input_dir="$1"
output_file="prepared_input.csv"

# Verificar si se proporcionó el directorio de entrada
if [ -z "$input_dir" ]; then
  echo "Uso: $0 <directorio_de_entrada>"
  exit 1
fi

# Comprobar si el directorio realmente existe
if [ ! -d "$input_dir" ]; then
  echo "Error: El directorio '$input_dir' no existe."
  exit 1
fi

# Crear o limpiar el archivo de salida y agregar el encabezado
echo "sample,fastq_1,fastq_2" > "$output_file"

# Declarar arreglos asociativos para guardar las rutas en memoria
declare -A r1_files
declare -A r2_files

# Buscar archivos .fastq.gz en el directorio (incluyendo subdirectorios si los hay)
while read -r file; do
    # Obtener solo el nombre del archivo (ej. C2Sau001_R1.fastq.gz)
    filename=$(basename "$file")
    
    # Extraer el ID de la muestra (todo lo que esté antes del primer guion bajo: C2Sau001)
    sample_id=$(echo "$filename" | cut -d '_' -f 1)
    
    # Identificar si es R1 o R2 basándose exactamente en tu formato
    if [[ "$filename" == *"_R1.fastq.gz"* ]]; then
        r1_files[$sample_id]="$file"
    elif [[ "$filename" == *"_R2.fastq.gz"* ]]; then
        r2_files[$sample_id]="$file"
    fi

done < <(find "$input_dir" -type f -name "*.fastq.gz")

# Emparejar las muestras por su ID y escribir las rutas completas en el CSV
for sample in "${!r1_files[@]}"; do
    if [ -n "${r2_files[$sample]}" ]; then
        echo "$sample,${r1_files[$sample]},${r2_files[$sample]}" >> "$output_file"
    else
        echo "Advertencia: Se encontró R1 para $sample pero falta su pareja R2." >&2
    fi
done | sort >> "$output_file"

echo "¡Completado! El archivo preparado con las rutas se guardó en: $output_file"