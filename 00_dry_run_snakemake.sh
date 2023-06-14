#!/bin/bash
#SBATCH --partition=week
#SBATCH --output=job_dry_run_%j.out
#SBATCH --error=job_dry_run_%j.err
#SBATCH --mem=1G
#SBATCH --cpus-per-task=1

source activate parasite_microbiome

snakemake -np --configfile config/config_Brugia_malayi.yaml
snakemake -np --configfile config/config_Schistosoma_mansoni.yaml

echo Complete!

