
Set up conda environment for snakemake
```
# setup conda env
mamba env create -n parasite_microbiome -f envs/conda_env.yaml

```

Get list of SRA files to download. Performed a manual search on ENA, and copied the curl command below to replicate on the command line.
```
curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'result=read_run&query=tax_eq(6279)%20AND%20library_strategy%3D%22WGS%22%20AND%20library_source%3D%22GENOMIC%22%20AND%20instrument_platform%3D%22ILLUMINA%22&fields=run_accession%2Cexperiment_title%2Ctax_id%2Clibrary_strategy&format=tsv' "https://www.ebi.ac.uk/ena/portal/api/search" > config/samples.tsv
```

Run pipeline
```
# dry run
bash 00_dry_run_snakemake.sh

# run
sbatch 01_run_snakemake.sh
```

