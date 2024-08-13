<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-resvirpredictor_logo_dark.png">
    <img alt="nf-core/resvirpredictor" src="docs/images/nf-core-resvirpredictor_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/resvirpredictor/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/resvirpredictor/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/resvirpredictor/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/resvirpredictor/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/resvirpredictor/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/nf-core/resvirpredictor)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23resvirpredictor-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/resvirpredictor)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduccion

**nf-core/resvirpredictor** is a bioinformatics pipeline that ...

Trabajo de Fin de Máster, Máster Universitario en Bioinformática, Universidad Europea de Madrid.

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

## Herramientas
1. Read QC ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Present QC for raw reads ([`MultiQC`](http://multiqc.info/))


## Workflow

## Modo de Uso

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.



Primero, prepara una samplesheet con las secuencias R1 y R2, la cual debe ser similar a esta:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
IDENTIFICADOR,XXXXXXX_XX_L002_R1_001.fastq.gz,XXXXXXX_XX_L002_R2_001.fastq.gz
```

Puedes utilizar el script contenido en la carpeta: 
`Resources`

```bash
./Crear_CSV.bash inputdir/ samplesheet.csv
```

Cada fila representa un par de archivos fastq (paired end).

# Preparacion

Crear un entorno de CONDA a partir de archivo YML proporcionado, nombrarlo.

```bash
conda env create -f TFM-Resvirpredictor/resourses/resvirpredictor.yml --name env_name
```

Activar entorno.

## Run Basico:

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ 
```
Analisis Base:
- Analisis de calidad de secuencias raw
- Trimado
- Analisis de calidad de secuencias trimadas
- Ensamblado
- Analisis de calidad de ensamblados
- Busqueda de genes de resistencia y virulencia en secuencias cortas
- Busqueda de genes de resistencia y virulencia en ensamblados
- Estudio MLST para Staphylococcus aureus
- Prediccion de resistencia fenoticipa a travez de analisis genomico
- Informes consolidades de resultados

## Profiles disponibles:

HPC
- Optimizado para uso por slurm

Ejemplo: 

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ -profile hpc
```


# Analisis opcionales/complementarios 
## BD personalizada
El pipeline se encuentra configurado para el uso de la base de datos personalizada "staph_vf.fasta", contenida en el directorio Resources, para su uso, se requiere la sgte preparacion:

## Pasos Previos
Agregar BD personalizada a Abricate
Verificar path a base de datos de abricate:
```bash
abricate --datadir
```
crear carpeta staph en directorio de BD

Copiar archivo staph_vf.fasta a directorio

```bash
cp TFM-Resvirpredictor/resourses/staph_vf.fasta /pathtobd/staph/sequences

abricate --setupdb
```

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ --abricate_db true
```

## Estudio de filogenia
El pipeline es capaz de obtener una base de datos de referencia optima segun las secuencias entregadas al compararla con la base de datos facilitada por MASH.

## Paso Previo

1. Descargar BD desde sitio oficial https://gembox.cbcb.umd.edu/mash/refseq.genomes.k21s1000.msh

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ --filogeny true --mash_reference pathtomashreference.msh
```

## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/resvirpredictor/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/resvirpredictor/output).

## Credits

nf-core/resvirpredictor was originally written by Victor Pizarro Riveros.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#resvirpredictor` channel](https://nfcore.slack.com/channels/resvirpredictor) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/resvirpredictor for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
