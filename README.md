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

# Introduccion

nf-core/resvirpredictor es un pipeline de bioinformática desarrollado para la caracterización molecular de cepas de Staphylococcus aureus en pacientes con enfermedad invasora. Este pipeline permite realizar análisis de calidad de secuencias, ensamblaje, búsqueda de genes de resistencia y virulencia, estudio de tipificación molecular, análisis filogenético y predicción fenotípica de resistencia a antibióticos.

Este trabajo forma parte del Trabajo de Fin de Máster del Máster Universitario en Bioinformática de la Universidad Europea de Madrid.

<!-- TODO nf-core:
   Complete this sentence with a 2-3 sentence summary of what types of data the pipeline ingests, a brief overview of the
   major pipeline sections and the types of output it produces. You're giving an overview to someone new
   to nf-core here, in 15-20 seconds. For an example, see https://github.com/nf-core/rnaseq/blob/master/README.md#introduction
-->

<!-- TODO nf-core: Include a figure that guides the user through the major workflow steps. Many nf-core
     workflows use the "tube map" design for that. See https://nf-co.re/docs/contributing/design_guidelines#examples for examples.   -->
<!-- TODO nf-core: Fill in short bullet-pointed list of the default steps in the pipeline -->

# Herramientas
1. Control de calidad de lecturas ([`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/))
2. Consolidación de informes de calidad ([`MultiQC`](http://multiqc.info/))
3. Ensamblaje de genomas ([`Unicycler`](https://github.com/rrwick/Unicycler))
4. Anotación de genes ([`Prokka`](https://github.com/tseemann/prokka))
5. Análisis de genes de resistencia y virulencia ([`ARIBA`](https://github.com/sanger-pathogens/ariba), [`ABRICATE`](https://github.com/tseemann/abricate)), ([`STARARM`](https://github.com/phac-nml/staramr))
6. Estudio de filogenia ([Snippy](https://github.com/tseemann/snippy), [IQTree](http://www.iqtree.org/), [Gubbins](https://github.com/sanger-pathogens/gubbins))
7. Predicción de resistencia fenotípica ([Mykrobe](https://github.com/Mykrobe-tools/mykrobe))


# Workflow

El pipeline se compone de los siguientes pasos:

  - Control de calidad: Análisis de calidad de secuencias raw y trimadas.
  - Ensamblaje: Ensamblaje de las lecturas utilizando Unicycler.
  - Análisis de calidad del ensamblaje: Evaluación de los ensamblados con QUAST.
  - Búsqueda de genes: Identificación de genes de resistencia y virulencia tanto en secuencias cortas como en ensamblados.
  - Anotación: Anotación funcional de los ensamblados.
  - Estudio de tipificación molecular: Determinación de tipificaciones moleculares (MLST, Spa-type, SCCmec, agr Locus).
  - Estudio de filogenia: Análisis filogenético basado en SNPs y construcción de árboles filogenéticos.
  - Predicción de resistencia fenotípica: Predicción de la resistencia a antibióticos basada en el genoma.

## Modo de Uso

> [!NOTE]
> Nota: Si eres nuevo en Nextflow y nf-core, consulta [esta página](https://nf-co.re/docs/usage/installation) para configurar Nextflow. Asegúrate de [probar tu configuración](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) con  `-profile test` antes de ejecutar el pipeline con datos reales.



## Preparación de los Datos

Primero, prepara una samplesheet con las secuencias R1 y R2, que debe tener el siguiente formato:

samplesheet.csv:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
IDENTIFICADOR,XXXXXXX_XX_L002_R1_001.fastq.gz,XXXXXXX_XX_L002_R2_001.fastq.gz
```

Puedes utilizar el script incluido en la carpeta: `resourses` para crear esta samplesheet:

```bash
./Crear_CSV.bash inputdir/ samplesheet.csv
```

Cada fila representa un par de archivos fastq (paired end).

## Preparación del Entorno

Crear un entorno de CONDA a partir de archivo YML proporcionado, nombrarlo.

```bash
conda env create -f TFM-Resvirpredictor/resourses/environmetariba.yml --name env_name
```

Luego, activa el entorno:
```bash
conda activate env_name
```

# Ejecución Básica:

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ 
```
Este comando ejecutará el análisis base, que incluye:
- Análisis de calidad de secuencias raw
- Trimado y análisis de calidad de secuencias trimadas
- Ensamblaje
- Análisis de calidad de ensamblados
- Búsqueda de genes de resistencia y virulencia en secuencias cortas y ensamblados
- Estudio MLST para Staphylococcus aureus
- Predicción de resistencia fenotípica basada en el análisis genómico
- Generación de informes consolidados

# Profiles disponibles:
  CONDA

  Ejemplo de ejecución con conda:

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ -profile conda
```

#  Análisis Opcionales y Complementarios
## Uso de una Base de Datos Personalizada
El pipeline está configurado para utilizar una base de datos personalizada, "staph_vf.fasta", contenida en el directorio `resourses`. Para usarla, sigue estos pasos:

## Pasos Previos
Agregar BD personalizada a Abricate
1. Verifica el path a la base de datos de Abricate:
```bash
abricate --datadir
```
2. Crea una carpeta `staph` en el directorio de la base de datos y copia el archivo `staph_vf.fasta` en ella:

Copiar archivo staph_vf.fasta a directorio

```bash
cp TFM-Resvirpredictor/resourses/staph_vf.fasta /pathtobd/staph/sequences

abricate --setupdb
```
3. Ejecuta el pipeline especificando el uso de la base de datos personalizada:

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ --abricate_db true
```

## Estudio de filogenia
  El pipeline puede obtener una base de datos de referencia óptima comparando las secuencias entregadas con la base de datos facilitada por MASH.

## Paso Previo
  1. Descarga la base de datos de referencia desde el sitio oficial: 
```bash
https://gembox.cbcb.umd.edu/mash/refseq.genomes.k21s1000.msh
```

2. Ejecuta el pipeline con la referencia de MASH:
```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ --filogeny true --mash_reference pathtomashreference.msh
```
# Comandos
## Input/Output Options

  `--input [string]`
    Ruta a un archivo separado por comas que contiene información sobre las muestras en el experimento.

  `--outdir [string]`
    Directorio de salida donde se guardarán los resultados. Debes utilizar rutas absolutas para el almacenamiento en infraestructuras en la nube.

  `--abricate_db [boolean]`
    Utiliza una base de datos personalizada previamente configurada en un entorno conda bajo el nombre "staph".

  `--gubbins [boolean]`
    Alternativa a Snippy para el análisis filogenético.

  `--email [string]`
    Dirección de correo electrónico para recibir un resumen de la finalización del pipeline.

## Skip Options

  `--skip_unicycler [boolean]`
    Omite la ejecución de Unicycler.

  `--skip_ariba [boolean]`
    Omite el análisis con ARIBA.

  `--skip_assemblyanalisis [boolean]`
    Omite el análisis con Abricate y Staramr.

  `--skip_mykrobe [boolean]`
    Omite el análisis con Mykrobe.

  `--skip_mlst [boolean]`
    Omite el estudio MLST.

## Opciones para Estudio de Filogenia

  `--phylogeny [boolean]`
    Si el valor es verdadero, debes especificar la ruta completa a tu archivo de referencia MASH, obtenido de [aquí](https://gembox.cbcb.umd.edu/mash/refseq.genomes.k21s1000.msh).

  `--mash_reference [string]`
    Ruta al archivo de genoma .msh.

## Opciones de Solicitud Máxima de Trabajos

  `--max_cpus [integer]`
    Número máximo de CPUs que se pueden solicitar para cualquier trabajo individual. [default: 16]

  `--max_memory [string]`
    Cantidad máxima de memoria que se puede solicitar para cualquier trabajo individual. [default: 12.GB]

  `--max_time [string]`
    Tiempo máximo que se puede solicitar para cualquier trabajo individual. [default: 240.h]

## Opciones Genéricas

  `--help [boolean]`
    Muestra el texto de ayuda.


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
