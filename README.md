# Bioinformatics Pipeline Setup and Analysis Scripts

This repository contains two primary bash scripts for setting up the environment and executing the analysis pipeline for the Salmonella persistent infection project:

- `environment.sh`: Installs and configures the required software packages.
- `analysis.sh`: Executes the assembly pipeline with various bioinformatics tools.

## Prerequisites

- [Conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html): Ensure Conda is installed on your system for environment management.
- Ensure you have the necessary databases for some tools (e.g., `card_db.dmnd` for Diamond, `amrfinder` database).

## Files

### environment.sh

This script sets up a Conda environment named `auto` and installs various tools for bioinformatics analysis. The following tools are installed:

- **Medaka**: Tool for Oxford Nanopore sequencing data analysis.
- **Mash**: A tool for fast genome and metagenome distance estimation.
- **FastQC**: A quality control tool for high-throughput sequence data.
- **Abyss**: A de novo, parallel, paired-end sequence assembler.
- **Porechop**: Adapter trimmer for Oxford Nanopore reads.
- **Flye**: A long-read assembler for single-molecule sequencing reads.
- **Minimap2**: A fast aligner for long-read sequencing data.
- **Racon**: Consensus module for contig polishing.
- **CheckM**: Tool for assessing the quality of metagenome-assembled genomes.
- **Diamond**: Fast protein alignment tool for large sequence databases.
- **Amrfinder**: Tool for finding resistance genes.
- **Prokka**: Genome annotation tool.

To execute `environment.sh`:

`bash bash environment.sh`

This will:
1. Install the listed tools in the `auto` Conda environment.
2. Log the installed tools and their versions in `tools_version.txt`.

### analysis.sh

This script handles sequence assembly, polishing, and annotation using various tools. 
To run the assembler script:

`bash analysis.sh <input_fastq_file> <threads>`


#### analysis details
Below is a detailed breakdown of each tool, its purpose, and the parameters used:

#### 1. Porechop
- **Purpose**: Trims adapters from Oxford Nanopore `.fastq` reads to prepare for assembly.
- **Parameters**:
  - `-i ${file_name}.fastq`: Input FASTQ file.
  - `-o ${file_name}_porechop.fastq`: Output FASTQ file after trimming.
  - `-t ${threads}`: Specifies the number of threads to use.

```bash
porechop -i ${file_name}.fastq -o ${file_name}_porechop.fastq -t ${threads}
```

#### 2. Flye
- **Purpose**: Assembles long-read data into contigs.
- **Parameters**:
  - `--nano-raw ${file_name}_porechop.fastq`: Specifies input type as raw Nanopore reads.
  - `-o ${file_name}_porechop_assembly`: Output directory for the assembled contigs.
  - `--genome-size 5m`: Expected genome size.
  - `--thread ${threads}`: Number of threads to use.
  - `--iterations 0`: Number of polishing iterations to skip for faster processing.

```bash
flye --nano-raw ${file_name}_porechop.fastq -o ${file_name}_porechop_assembly --genome-size 5m --thread ${threads} --iterations 0
```

#### 3. Minimap2 & Racon (multiple rounds)
- **Purpose**: Aligns reads to the assembly (Minimap2) and refines the assembly by consensus polishing (Racon).
- **Parameters (Minimap2)**:
  - `-t ${threads}`: Number of threads.
  - `-a`: Output in SAM format.
  - `-x map-ont`: Preset for Oxford Nanopore reads.
- **Parameters (Racon)**:
  - `-m 8 -x -6 -g -8 -w 500`: Default scoring options for polishing.

The following commands are repeated for multiple rounds to improve assembly accuracy:

```bash
minimap2 -t ${threads} -a -x map-ont assembly.fasta ${file_name}_porechop.fastq > ${file_name}_mini1_racon0.sam
racon -t ${threads} -m 8 -x -6 -g -8 -w 500 ${file_name}_porechop.fastq ${file_name}_mini1_racon0.sam assembly.fasta > ${file_name}_racon1.fasta
```

#### 4. Medaka
- **Purpose**: Applies additional polishing based on a trained model.
- **Parameters**:
  - `-i ${file_name}_porechop.fastq`: Input FASTQ file.
  - `-d ${file_name}_racon4.fasta`: Input draft assembly for polishing.
  - `-o ${file_name}_racon4_medaka_prom`: Output directory for Medaka-polished assembly.
  - `-t ${threads}`: Number of threads.
  - `-m r941_prom_high_g303`: Model preset for R9.4.1 chemistry (for PromethION data).

```bash
medaka_consensus -i ${file_name}_porechop.fastq -d ${file_name}_racon4.fasta -o ${file_name}_racon4_medaka_prom -t ${threads} -m r941_prom_high_g303
```

#### 5. Mash & Homopolish
- **Purpose**: Performs quality checks (Mash) and homopolymer correction (Homopolish).
- **Parameters (Mash)**:
  - See [Mash documentation](https://mash.readthedocs.io/) for more details on parameters used.
  
```bash
python3 detection.py ${file_name}_racon4_medaka_prom/consensus.fasta ${threads} ${file_name}_mash_output/
```

#### 6. CheckM
- **Purpose**: Assesses assembly quality for metagenomes.
- **Parameters**:
  - `-t ${threads}`: Number of threads.
  - `-x fasta`: Specifies the file extension of input.
  
```bash
checkm lineage_wf -t ${threads} -x fasta ${file_name}_homopolish/ ${file_name}_CheckM
```

#### 7. Prodigal & Diamond
- **Purpose**: Predicts genes (Prodigal) and aligns proteins against a custom database (Diamond).
- **Parameters (Prodigal)**:
  - `-i ${file_name}_homopolish/final.fasta`: Input file for gene prediction.
  - `-o ${file_name}_prodigal/${file_name}.fasta`: Output nucleotide sequences.
  - `-a ${file_name}_prodigal/${file_name}_proteins.fasta`: Output protein sequences.
- **Parameters (Diamond)**:
  - `-d /path/to/card_db.dmnd`: Database for antibiotic resistance genes.
  - `-q ${file_name}_prodigal/${file_name}_proteins.fasta`: Query file of predicted proteins.
  - `--query-cover 96`: Query coverage threshold.

```bash
prodigal -i ${file_name}_homopolish/final.fasta -o ${file_name}_prodigal/${file_name}.fasta -a ${file_name}_prodigal/${file_name}_proteins.fasta
diamond blastp -d /path/to/card_db.dmnd -q ${file_name}_prodigal/${file_name}_proteins.fasta --query-cover 96 -o ${file_name}_prodigal_diamond.tsv
```

#### 8. Prokka
- **Purpose**: Annotates the genome.
- **Parameters**:
  - `--outdir ${file_name}_prokka/`: Output directory for Prokka annotations.

```bash
prokka ${file_name}_homopolish/final.fasta --outdir ${file_name}_prokka/
```

#### 9. Amrfinder
- **Purpose**: Identifies resistance genes in protein sequences.
- **Parameters**:
  - `-p ${file_name}_prodigal/${file_name}_proteins.fasta`: Input protein file.
  - `-o ${file_name}_amrfinder/${file_name}_amrfinder.tsv`: Output results file.

```bash
amrfinder -p ${file_name}_prodigal/${file_name}_proteins.fasta -o ${file_name}_amrfinder/${file_name}_amrfinder.tsv --threads ${threads}
```

### Output

The `assembler.sh` script generates various outputs, including:

- **Trimmed and assembled files** in FASTA format.
- **Polished assemblies** using Racon and Medaka.
- **Quality assessment** reports from CheckM.
- **Annotated genomes** from Prokka.
- **Resistance gene analysis** using Diamond and Amrfinder.

### Notes

- Paths in `assembler.sh` are hardcoded; you may need to update these paths to match your local directory structure.
- Ensure all necessary databases are accessible for Diamond and Amrfinder.

## License

This project is licensed under the GPLv3 License.
