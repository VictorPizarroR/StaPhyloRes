process SUMMARY_STAPHYLOCOCCUS_TYPE {
    tag "$meta.id"
    label 'process_low'

    input:
    val (meta)
    path (agr_report)
    path (mlst_report)
    path (spatyper_report)
    path (staphopiasccmec_report)


    output:
    path "staph_types_consolidated.tsv", emit: consolidated

    script:
    """
    set -euo pipefail

    output_file="staph_types_consolidated.tsv"

    agr_output_file="agr_group.tsv"
    tail -n +2 "${agr_report}" | awk -F'\\t' '{print \$2}' > "\$agr_output_file"

    mlst_output_file="mlst_extracted.tsv"
    awk -F'\\t' '{print \$1 "\\t" \$4}' "${mlst_report}" > "\$mlst_output_file"

    spatyper_output_file="spatyper.tsv"
    tail -n +2 "${spatyper_report}" | awk -F'\\t' '{print \$4}' > "\$spatyper_output_file"
    
    staphopiasccmec_output="staphopiasccmec_corrected.tsv"
    header=\$(head -n 1 "${staphopiasccmec_report}")
    IFS=\$'\\t' read -r -a columns <<< "\$header"

    extract_results() {
        row=(\"\$@\")
        result=()
        for i in \"\${!row[@]}\"; do
            if [[ "\${row[\$i]}" == "True" ]]; then
                result+=(\"\${columns[\$i]}\")
            fi
        done
        echo \"\${result[*]}\" | tr ' ' '-'
    }

    tail -n +2 "${staphopiasccmec_report}" | while IFS=\$'\\t' read -r -a row; do
        result=\$(extract_results "\${row[@]}")
        echo -e "\$result" >> "\$staphopiasccmec_output"
    done

    echo -e "Sample\\tmlst\\tspatyper\\tagr_group\\tscc_mec" > "\$output_file"
    paste -d'\\t' "\$mlst_output_file" "\$spatyper_output_file" "\$agr_output_file" "\$staphopiasccmec_output" >> "\$output_file"
    
    """
}