#!/bin/bash
#SBATCH --partition=week
#SBATCH --output=job_run_snakemake_%j.out
#SBATCH --error=job_run_snakemake_%j.err
#SBATCH --mem=250G
#SBATCH --cpus-per-task=48

source activate parasite_microbiome

snakemake \
   --cores 48 \
   --use-conda

echo Complete!

