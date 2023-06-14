
Set up conda environment for snakemake
```
# setup conda env
mamba env create -n parasite_microbiome -f envs/conda_env.yaml

```

Get list of SRA files to download. Performed a manual search on ENA, and copied the curl command below to replicate on the command line. Accessed 14/06/2023

```
# create config dir
mkdir -p config

# Brugia malayi rna
curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'result=read_run&query=tax_eq(6279)%20AND%20library_strategy%3D%22RNA-Seq%22%20AND%20library_source%3D%22TRANSCRIPTOMIC%22%20AND%20instrument_platform%3D%22ILLUMINA%22%20AND%20library_layout%3D%22PAIRED%22&fields=run_accession%2Cstudy_accession%2Cexperiment_accession%2Csample_accession%2Cexperiment_title%2Ccenter_name%2Cbase_count%2Cread_count%2Ctax_id%2Clibrary_strategy%2Clibrary_selection%2Chost%2Chost_scientific_name%2Chost_status%2Cdev_stage%2Cfastq_ftp&format=tsv' "https://www.ebi.ac.uk/ena/portal/api/search" > config/samples_Brugia_malayi.tsv

# Schistosoma mansoni rna
curl -X POST -H "Content-Type: application/x-www-form-urlencoded" -d 'result=read_run&query=tax_eq(6183)%20AND%20library_strategy%3D%22RNA-Seq%22%20AND%20library_source%3D%22TRANSCRIPTOMIC%22%20AND%20instrument_platform%3D%22ILLUMINA%22%20AND%20library_layout%3D%22PAIRED%22&fields=run_accession%2Cstudy_accession%2Cexperiment_accession%2Csample_accession%2Cexperiment_title%2Ccenter_name%2Cbase_count%2Cread_count%2Ctax_id%2Clibrary_strategy%2Clibrary_selection%2Chost%2Chost_scientific_name%2Chost_status%2Cdev_stage%2Cfastq_ftp&format=tsv' "https://www.ebi.ac.uk/ena/portal/api/search" > config/samples_Schistosoma_mansoni.tsv
```

| runs  | taxon               | 
|-------|---------------------|
|  341  | Brugia malayi       |
| 25161 | Schistosoma mansoni |

```
# subset runs to include a max of 5 per experiment and exclude runs with less than 1e6 reads

# Brugiai malayi
head -n 1 config/samples_Brugia_malayi.tsv > config/samples_Brugia_malayi_subset.tsv
tail -n +2 config/samples_Brugia_malayi.tsv | cut -f 2 | sort | uniq | while read EXP; do
   awk -F "\t" '$8 > 1000000' config/samples_Brugia_malayi.tsv | grep -e "$EXP" -w | head -n 5
done >> config/samples_Brugia_malayi_subset.tsv

# Schistosoma mansoni
head -n 1 config/samples_Schistosoma_mansoni.tsv > config/samples_Schistosoma_mansoni_subset.tsv
tail -n +2 config/samples_Schistosoma_mansoni.tsv | cut -f 2 | sort | uniq | while read EXP; do
   awk -F "\t" '$8 > 1000000' config/samples_Schistosoma_mansoni.tsv | grep -e "$EXP" -w | head -n 5
done >> config/samples_Schistosoma_mansoni_subset.tsv
```

| runs | taxon               |
|------|---------------------|
|  55  | Brugia malayi       |
|  171 | Schistosoma mansoni |


Some of the Schistosoma mansoni runs were found to be empty in early trials :( Check which runs have data. Accessed 14/06/2023.
```
source activate sra-tools

head -n 1 config/samples_Brugia_malayi_subset.tsv > config/samples_Brugia_malayi_present.tsv
tail -n +2 config/samples_Brugia_malayi_subset.tsv | while read LINE; do
   ACC=$(echo -e "$LINE" | cut -f 1)
   srapath $ACC > /dev/null
   if [ $? -eq 0 ]; then
      echo -e "$LINE"
   fi
done >> config/samples_Brugia_malayi_present.tsv

head -n 1 config/samples_Schistosoma_mansoni_subset.tsv > config/samples_Schistosoma_mansoni_present.tsv
tail -n +2 config/samples_Schistosoma_mansoni_subset.tsv | while read LINE; do 
   ACC=$(echo -e "$LINE" | cut -f 1)
   srapath $ACC > /dev/null
   if [ $? -eq 0 ]; then
      echo -e "$LINE"
   fi    
done >> config/samples_Schistosoma_mansoni_present.tsv

```

| runs | taxon               |
|------|---------------------|
|  55  | Brugia malayi       |
|  166 | Schistosoma mansoni |


Run pipeline
```
# dry run
bash 00_dry_run_snakemake.sh

# run
sbatch 01_run_snakemake_Brugia_malayi.sh
sbatch 02_run_snakemake_Schistosoma_mansoni.sh

```

