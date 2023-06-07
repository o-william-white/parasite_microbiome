
Set up conda environment for snakemake
```
# setup conda env
mamba env create -n parasite_microbiome -f envs/conda_env.yaml

```

Get list of SRA files to download. Performed a manual search on ENA, and copied the curl command below to replicate on the command line. Accessed 23/05/2023

```
# Brugia malayi wgs
curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'result=read_run&query=tax_eq(6279)%20AND%20library_strategy%3D%22WGS%22%20AND%20library_source%3D%22GENOMIC%22%20AND%20instrument_platform%3D%22ILLUMINA%22%20AND%20library_layout%3D%22PAIRED%22&fields=run_accession%2Cexperiment_title%2Cexperiment_accession%2Ccenter_name%2Ctax_id%2Clibrary_strategy&format=tsv' "https://www.ebi.ac.uk/ena/portal/api/search" > config/samples_Brugia_malayi.tsv

# Schistosoma mansoni wgs
curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'result=read_run&query=tax_eq(6183)%20AND%20library_strategy%3D%22WGS%22%20AND%20library_source%3D%22GENOMIC%22%20AND%20instrument_platform%3D%22ILLUMINA%22%20AND%20library_layout%3D%22PAIRED%22&fields=run_accession%2Cexperiment_title%2Cexperiment_accession%2Ccenter_name%2Ctax_id%2Clibrary_strategy&format=tsv' "https://www.ebi.ac.uk/ena/portal/api/search" > config/samples_Schistosoma_mansoni.tsv
```

| runs | taxon               | 
|------|---------------------|
|  55  | Brugia malayi       |
| 1609 | Schistosoma mansoni |

Some of the Schistosoma mansoni runs were found to be empty :( Check which runs have data. Accessed 29/05/2023.
```
source activate sra-tools
head -n 1 config/samples_Schistosoma_mansoni.tsv > config/samples_Schistosoma_mansoni_present.tsv
tail -n +2 config/samples_Schistosoma_mansoni.tsv | while read LINE; do 
   ACC=$(echo -e "$LINE" | cut -f 1)
   srapath $ACC > /dev/null
   if [ $? -eq 0 ]; then
      echo -e "$LINE"
   fi    
done >> config/samples_Schistosoma_mansoni_present.tsv

# 1547 remaining
tail -n +2 config/samples_Schistosoma_mansoni_present.tsv | wc -l
```

```
# subset Schistosoma mansoni runs
# maximum of 20 runs with the same name
head -n 1 config/samples_Schistosoma_mansoni_present.tsv > config/samples_Schistosoma_mansoni_subset.tsv 
tail -n +2 config/samples_Schistosoma_mansoni_present.tsv | cut -f 2 | sort | uniq | while read EXP; do
   grep -e "$EXP" -w config/samples_Schistosoma_mansoni_present.tsv | head -n 20
done >> config/samples_Schistosoma_mansoni_subset.tsv 

# 162 in subset
tail -n +2 config/samples_Schistosoma_mansoni_subset.tsv | wc -l
```

Run pipeline
```
# dry run
bash 00_dry_run_snakemake.sh

# run
sbatch 01_run_snakemake_Brugia_malayi.sh
sbatch 02_run_snakemake_Schistosoma_mansoni.sh

```

