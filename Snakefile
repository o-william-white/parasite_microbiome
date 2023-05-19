import pandas as pd

# set configfile
configfile: "config/config.yaml"

# configfile parameters
output_dir = config["output_dir"]
kraken_db = config["kraken_db"]
threads = config["threads"]

# read sample data
sample_data = pd.read_csv(config["samples"], sep = "\t").set_index("run_accession", drop=False)

# get list of samples from sample_data
samples = sample_data["run_accession"].tolist()

# one rule to rule them all :)
rule all:
    input:
        ## fastq-dl
        # expand(output_dir+"/fastq_dl/{sample}_1.fastq.gz", sample=samples),
        #expand(output_dir+"/fastq_dl/{sample}_2.fastq.gz", sample=samples)
        # kraken
        expand(output_dir+"/kraken/{sample}.txt",        sample=samples),
        expand(output_dir+"/kraken/{sample}_report.txt", sample=samples)

# fastq-dl
rule fastq_dl:
    params:
        ena_id = "{sample}"
    output:
        fwd = output_dir+"/fastq_dl/{sample}_1.fastq.gz",
        rev = output_dir+"/fastq_dl/{sample}_2.fastq.gz"
    log:
        output_dir+"/logs/fastq_dl/{sample}.log"
    conda:
        "envs/fastq_dl.yaml"
    threads: threads
    shell:
        """
        fastq-dl \
            --accession {params.ena_id} \
            --outdir fastq_dl \
            --provider ena \
            --cpus {threads} &> {log}
        """

# kraken
rule kraken:
    input:
        fwd = output_dir+"/fastq_dl/{sample}_1.fastq.gz",
        rev = output_dir+"/fastq_dl/{sample}_2.fastq.gz"
    output:
        out = output_dir+"/kraken/{sample}.txt",
        rep = output_dir+"/kraken/{sample}_report.txt"
    conda:
        "envs/kraken2.yaml"
    log:
        output_dir+"/logs/kraken/{sample}.log"
    threads: threads
    shell:
        """
        kraken2 \
            --db {kraken_db} \
            --paired \
            --gzip-compressed \
            --use-names \
            --threads {threads} \
            --output {output.out} \
            --report {output.rep} \
            {input.fwd} \
            {input.rev}
        """



