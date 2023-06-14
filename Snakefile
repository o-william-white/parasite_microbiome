import pandas as pd

# set configfile
configfile: "config/config.yaml"

# configfile parameters
output_dir = config["output_dir"]
kraken_silva = config["kraken_silva"]
kraken_nt = config["kraken_nt"]
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
        #expand(output_dir+"/kraken_silva/{sample}.txt",           sample=samples),
        #expand(output_dir+"/kraken_silva/{sample}_report.txt",    sample=samples),
        #expand(output_dir+"/kraken_nt/{sample}.txt",        sample=samples),
        #expand(output_dir+"/kraken_nt/{sample}_report.txt", sample=samples)
        output_dir+"/kraken_silva_summary/plot_count.png",
        output_dir+"/kraken_nt_summary/plot_count.png"

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
        fwd = temp(output_dir+"/fastq_dump/{sample}_1.fastq.gz"),
        rev = temp(output_dir+"/fastq_dump/{sample}_2.fastq.gz")
    shell:
        """
        gzip -c {input.fwd} > {output.fwd}
        gzip -c {input.rev} > {output.rev}
        """

# fastp
rule fastp:
    input:
        fwd = output_dir+"/fastq_dump/{sample}_1.fastq.gz",
        rev = output_dir+"/fastq_dump/{sample}_2.fastq.gz"
    output:
        fwd = output_dir+"/fastp/{sample}_1.fastq.gz",
        rev = output_dir+"/fastp/{sample}_2.fastq.gz",
        html = output_dir+"/fastp/{sample}.html",
        json = output_dir+"/fastp/{sample}.json"
    log:
        output_dir+"/logs/fastp/{sample}.log"
    conda:
        "envs/fastp.yaml"
    threads: threads
    shell:
        """
        fastp --in1 {input.fwd} --in2 {input.rev} \
            --out1 {output.fwd} --out2 {output.rev} \
            --html {output.html} --json {output.json} \
            --disable_quality_filtering \
            --thread {threads} &> {log}
        """

# kraken with silva db
rule kraken_silva:
    input:
        fwd = output_dir+"/fastp/{sample}_1.fastq.gz",
        rev = output_dir+"/fastp/{sample}_2.fastq.gz"
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


# kraken with nt db
rule kraken_nt:
    input:
        fwd = output_dir+"/fastp/{sample}_1.fastq.gz",
        rev = output_dir+"/fastp/{sample}_2.fastq.gz"
    output:
        out = output_dir+"/kraken_nt/{sample}.txt",
        rep = output_dir+"/kraken_nt/{sample}_report.txt"
    conda:
        "envs/kraken2.yaml"
    log:
        output_dir+"/logs/kraken_nt/{sample}.log"
    threads: threads
    shell:
        """
        kraken2 \
            --db {kraken_nt} \
            --paired \
            --gzip-compressed \
            --use-names \
            --threads {threads} \
            --output {output.out} \
            --report {output.rep} \
            {input.fwd} \
            {input.rev} &> {log}
        """

# create plots for silva
rule plot_silva:
    input:
        expand(output_dir+"/kraken_silva/{sample}.txt",        sample=sample_data["run_accession"].tolist()),
        expand(output_dir+"/kraken_silva/{sample}_report.txt", sample=sample_data["run_accession"].tolist())
    output:
        output_dir+"/kraken_silva_summary/plot_count.png",
        output_dir+"/kraken_silva_summary/plot_heatmap.png",
        output_dir+"/kraken_silva_summary/table_join.txt"
    conda:
        "envs/r_env.yaml"
    log:
        output_dir+"/logs/kraken_silva_summary/log"
    shell:
        """
        Rscript scripts/summarise_kraken.R {output_dir}/kraken_silva/ {output_dir}/kraken_silva_summary/ &> {log}
        """

# create plots for nt
rule plot_nt:
    input:
        expand(output_dir+"/kraken_nt/{sample}.txt",        sample=sample_data["run_accession"].tolist()),
        expand(output_dir+"/kraken_nt/{sample}_report.txt", sample=sample_data["run_accession"].tolist())
    output:
        output_dir+"/kraken_nt_summary/plot_count.png", 
        output_dir+"/kraken_nt_summary/plot_heatmap.png",
        output_dir+"/kraken_nt_summary/table_join.txt"
    conda:
        "envs/r_env.yaml"
    log:
        output_dir+"/logs/kraken_nt_summary/log"
    shell:
        """
        Rscript scripts/summarise_kraken.R {output_dir}/kraken_nt/ {output_dir}/kraken_nt_summary/ &> {log}
        """
