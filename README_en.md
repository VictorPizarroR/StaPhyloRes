# ![StaPhyloRes](docs/images/logo-black.gif)
![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)
![Run with Conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)
![Run with Docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)
![GitHub release](https://img.shields.io/github/release/VictorPizarroR/StaPhyloRes.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

# Introduction

> **❗ [Leer en Español](README.md)**.

**StaPhyloRes** is a bioinformatics pipeline that performs sequence quality analysis, assembly, detection of antibiotic resistance genes, virulence, molecular typing, phylogenetic analysis, and phenotypic antibiotic sensitivity prediction in *Staphylococcus aureus* strains.

The pipeline is built using [Nextflow](https://www.nextflow.io), a tool for running tasks across multiple compute infrastructures in a highly portable manner.

This project is part of the Master's Thesis for the Master's in Bioinformatics at the European University of Madrid.

| Process                        | Tool                                                                                               |
|---------------------------------|----------------------------------------------------------------------------------------------------|
| **Quality control of reads**    | [`FastQC`](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)                             |
| **Consolidation of quality reports** | [`MultiQC`](http://multiqc.info/)                                                                  |
| **Genome assembly**             | [`Unicycler`](https://github.com/rrwick/Unicycler)                                                  |
| **Gene annotation**             | [`Prokka`](https://github.com/tseemann/prokka)                                                      |
| **Resistance and virulence gene analysis** | [`ARIBA`](https://github.com/sanger-pathogens/ariba), [`ABRICATE`](https://github.com/tseemann/abricate), [`STARARM`](https://github.com/phac-nml/staramr) |
| **Phylogeny study**             | [`Snippy`](https://github.com/tseemann/snippy), [`IQTree`](http://www.iqtree.org/), [`Gubbins`](https://github.com/sanger-pathogens/gubbins) |
| **Phenotypic resistance prediction** | [`Mykrobe`](https://github.com/Mykrobe-tools/mykrobe)                                              |

## Workflow

The pipeline consists of the following steps:

  - **Quality control**: Analysis of raw and trimmed sequence quality.
  - **Assembly**: Assembly of reads using Unicycler.
  - **Assembly quality analysis**: Evaluation of assemblies with QUAST.
  - **Gene search**: Identification of resistance and virulence genes in both short sequences and assemblies.
  - **Annotation**: Functional annotation of assemblies.
  - **Molecular typing study**: Determination of molecular types (MLST, Spa-type, SCCmec, agr Locus).
  - **Phylogeny study**: SNP-based phylogenetic analysis and tree construction.
  - **Phenotypic resistance prediction**: Genome-based prediction of antibiotic resistance.

## Usage

> **Note**: If you're new to Nextflow and nf-core, refer to [this page](https://nf-co.re/docs/usage/installation) for Nextflow setup.

## Data Preparation

First, prepare a `samplesheet.csv` file with the R1 and R2 sequences in the following format:

```csv
sample,fastq_1,fastq_2
IDENTIFIER,XXXXXXX_XX_L002_R1_001.fastq.gz,XXXXXXX_XX_L002_R2_001.fastq.gz
```
You can use the script included in the `resourses` folder to create this samplesheet:

```bash
./Crear_CSV.bash inputdir/ samplesheet.csv
```

### **Environment Setup**

Create a **Conda** environment from the provided YML file:

```bash
conda env create -f TFM-Resvirpredictor/resourses/resvirpredictor.yml --name env_name
```

Then, activate the environment:

```bash
conda activate env_name
```

---

## **Basic Execution**

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/
```

This command will run the basic analysis, which includes:

- Quality analysis of raw sequences
- Trimming and quality analysis of trimmed sequences
- Assembly
- Quality analysis of assemblies
- Gene search for resistance and virulence in short sequences and assemblies
- MLST study for Staphylococcus aureus
- Phenotypic resistance prediction based on genomic analysis
- Consolidated report generation

### Profiles Available:

#### **CONDA**
Run with Conda:

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ -profile conda
```

#### **DOCKER**
Run with Docker:
```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ -profile docker
```

---

## **Optional and Complementary Analysi**

### Using a Custom Database

The pipeline is configured to use a custom database, `"staph_vf.fasta"`, located in the `resources` directory. To use it:

1. Verify the Abricate database path:

```bash
abricate --datadir
```

2. Copy the `staph_vf.fasta` file:

```bash
cp TFM-Resvirpredictor/resources/staph_vf.fasta /pathtobd/staph/sequences

abricate --setupdb
```

3. Run the pipeline:

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ --abricate_db true
```

---

## **Phylogeny Study**
The pipeline can obtain an optimal reference database by comparing the provided sequences with the database provided by MASH.

Download the reference database from [`here`](https://gembox.cbcb.umd.edu/mash/refseq.genomes.k21s1000.msh)

Run the pipeline with the MASH reference:

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ --phylogeny true --mash_reference pathtomashreference.msh
```

---

## **Commands**

### Input/Output Options

- `--input [string]`: Path to the CSV file with sample information.
- `--outdir [string]`: Output directory for the results.
- `--abricate_db [boolean]`: Use a custom database.
- `--gubbins [boolean]`: Alternative to Snippy for phylogenetic analysis.
- `--email [string]`: Email address to receive a summary upon pipeline completion.

### Skip Options

- `--skip_unicycler [boolean]`: Skip the execution of Unicycler.
- `--skip_ariba [boolean]`: Skip the analysis with ARIBA.
- `--skip_assemblyanalisis [boolean]`: Skip the analysis with Abricate and Staramr.
- `--skip_mykrobe [boolean]`: Skip the analysis with Mykrobe.
- `--skip_mlst [boolean]`: Skip the MLST study.

### Phylogeny Study Options

- `--phylogeny [boolean]`:Enable phylogenetic analysis. (Reference genome obtained from [here](https://gembox.cbcb.umd.edu/mash/refseq.genomes.k21s1000.msh)).
- `--mash_reference [string]`: Path to the MASH reference.

### Opciones de Solicitud Máxima de Trabajos

- `--max_cpus [integer]`: Maximum number of CPUs that can be requested for any individual job. [default: 16]
- `--max_memory [string]`: Maximum amount of memory that can be requested for any individual job. [default: 12 GB]
- `--max_time [string]`: Maximum time that can be requested for any individual job. [default: 240 hours]

### Opciones Genéricas

- `--help [boolean]`: Display the help text.

### Custom Work Directory
You can specify a custom work directory when running the pipeline using the `-work-dir` option.

```bash
nextflow run TFM-Resvirpredictor/ --input samplesheet.csv --outdir outdirpath/ -work-dir /path/to/custom/workdir
```

## **Results**
To see the results of a test run with a full-size dataset, check the [results](https://github.com/VictorPizarroR/StaPhyloRes/tree/master/results) folder on this page. 

## **Credits**

**StaPhyloRes** was developed by [Víctor Pizarro Riveros](https://github.com/VictorPizarroR) as part of his Master's Thesis in Bioinformatics at the European University of Madrid.

Special thanks to the [nf-core](https://nf-co.re) community for providing tools under the [licencia MIT](https://opensource.org/licenses/MIT).

## **Citations**

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use StaPhyloRes for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

A full list of references for the tools used in the pipeline can be found in [`CITATIONS.md`](CITATIONS.md).

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) initative, and reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> The nf-core framework for community-curated bioinformatics pipelines.
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> Nat Biotechnol. 2020 Feb 13. doi: 10.1038/s41587-020-0439-x.

In addition, references of tools and data used in this pipeline are as follows:
