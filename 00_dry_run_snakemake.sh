#!/bin/bash

source activate parasite_microbiome

snakemake -np --configfile config/config_Brugia_malayi.yaml
snakemake -np --configfile config/config_Schistosoma_mansoni.yaml

echo Complete!

