#!/bin/bash

# Define the input directory and output file
input_dir="$1"
output_file="prepared_input.csv"

# Check if input directory is provided
if [ -z "$input_dir" ]; then
  echo "Usage: $0 <input_directory>"
  exit 1
fi

# Create or clear the output file and add the header
echo "sample,fastq_1,fastq_2" > "$output_file"

# Find all fastq.gz files, process them, and output to a temporary file
find "$input_dir" -name "*.fastq.gz" | while read -r file; do
  filename=$(basename "$file")
  sample_id=$(echo "$filename" | cut -d '_' -f 1)
  read_type=$(echo "$filename" | cut -d '_' -f 3)
  echo "$sample_id,$file,$read_type" >> tmp_output.csv
done

# Sort and group by sample_id to pair R1 and R2
sort -t, -k1,1 tmp_output.csv | awk -F, '{
  if ($3 == "R1") {
    r1=$2
  } else if ($3 == "R2") {
    r2=$2
    print $1 "," r1 "," r2
  }
}' >> "$output_file"

# Remove the temporary file
rm tmp_output.csv

echo "Prepared input file saved to $output_file"
