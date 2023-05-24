import pandas as pd

# set configfile
configfile: "config/config.yaml"

# configfile parameters
output_dir = config["output_dir"]
kraken_silva = config["kraken_silva"]
kraken_standard = config["kraken_standard"]
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
        expand(output_dir+"/kraken_silva/{sample}.txt",           sample=samples),
        expand(output_dir+"/kraken_silva/{sample}_report.txt",    sample=samples),
        expand(output_dir+"/kraken_standard/{sample}.txt",        sample=samples),
        expand(output_dir+"/kraken_standard/{sample}_report.txt", sample=samples)

# sra-tools
rule fastq_dump:
    params:
        ena_id = "{sample}",
        outdir = output_dir+"/fastq_dump"
    output:
        fwd = temp(output_dir+"/fastq_dump/{sample}_1.fastq"),
        rev = temp(output_dir+"/fastq_dump/{sample}_2.fastq")
    log:
        output_dir+"/logs/fastq_dump/{sample}.log"
    conda:
        "envs/sra_tools.yaml"
    threads: threads
    shell:
        """
        fastq-dump \
            --outdir {params.outdir} \
            --split-3 \
            {params.ena_id} &> {log}
        """

# gzip
rule gzip:
    input:
        fwd = output_dir+"/fastq_dump/{sample}_1.fastq",
        rev = output_dir+"/fastq_dump/{sample}_2.fastq"
    output:
        fwd = output_dir+"/fastq_dump/{sample}_1.fastq.gz",
        rev = output_dir+"/fastq_dump/{sample}_2.fastq.gz"
    shell:
        """
        gzip -c {input.fwd} > {output.fwd}
        gzip -c {input.rev} > {output.rev}
        """

# kraken with silva db
rule kraken_silva:
    input:
        fwd = output_dir+"/fastq_dump/{sample}_1.fastq.gz",
        rev = output_dir+"/fastq_dump/{sample}_2.fastq.gz"
    output:
        out = output_dir+"/kraken_silva/{sample}.txt",
        rep = output_dir+"/kraken_silva/{sample}_report.txt"
    conda:
        "envs/kraken2.yaml"
    log:
        output_dir+"/logs/kraken_silva/{sample}.log"
    threads: threads
    shell:
        """
        kraken2 \
            --db {kraken_silva} \
            --paired \
            --gzip-compressed \
            --use-names \
            --threads {threads} \
            --output {output.out} \
            --report {output.rep} \
            {input.fwd} \
            {input.rev} &> {log}
        """


# kraken with standard db
rule kraken_standard:
    input:
        fwd = output_dir+"/fastq_dump/{sample}_1.fastq.gz",
        rev = output_dir+"/fastq_dump/{sample}_2.fastq.gz"
    output:
        out = output_dir+"/kraken_standard/{sample}.txt",
        rep = output_dir+"/kraken_standard/{sample}_report.txt"
    conda:
        "envs/kraken2.yaml"
    log:
        output_dir+"/logs/kraken_standard/{sample}.log"
    threads: threads
    shell:
        """
        kraken2 \
            --db {kraken_standard} \
            --paired \
            --gzip-compressed \
            --use-names \
            --threads {threads} \
            --output {output.out} \
            --report {output.rep} \
            {input.fwd} \
            {input.rev} &> {log}
        """


