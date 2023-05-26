#!/bin/bash
#SBATCH --partition=week
#SBATCH --output=job_run_snakemake_Brugia_malayi_%j.out
#SBATCH --error=job_run_snakemake_Brugia_malayi_%j.err
#SBATCH --mem=250G
#SBATCH --cpus-per-task=48

source activate parasite_microbiome

snakemake \
   --cores 48 \
   --use-conda \
   --rerun-incomplete \
   --configfile config/config_Brugia_malayi.yaml

echo Complete!

