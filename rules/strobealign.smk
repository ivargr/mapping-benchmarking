
# seperate rule so that indexing time is not included in benchmark
# index depends on reads, but output file name is not deterministic, so create a checkpoint file that
# depends on the reads
rule strobealign_index:
    input:
        ref=f"data/{reference_genome}/reference.fa",
        reads=get_input_reads
    output:
        touch(f"data/{reference_genome}/{{config}}/strobealign-index-created")
    conda:
        "../envs/strobealign.yml"
    shell:
        "strobealign --create-index {input.ref} {input.reads}"


rule strobealign_map:
  input:
    reads=get_input_reads,
    ref=f"data/{reference_genome}/reference.fa",
    checkpoint_index_is_created=f"data/{reference_genome}/{{config}}/strobealign-index-created"
  output:
      f"data/{reference_genome}/{{config}}/strobealign/{{n_threads}}/without_readgroup.bam"
  conda:
      "../envs/strobealign.yml"
  threads: lambda wildcards: int(wildcards.n_threads)
  benchmark:
      f"data/{reference_genome}/{{config}}/strobealign/{{n_threads}}/benchmark.csv"
  shell:
      "mkdir -p $(dirname {output}) && "
      "strobealign -t {wildcards.n_threads} --use-index {input.ref} {input.reads} | "
      "samtools view -o {output} -"



# have this as separate rule to not be includeded in benchmark time
rule add_read_group_to_strobealign:
    input:
        f"data/{reference_genome}/{{config}}/strobealign/{{n_threads}}/without_readgroup.bam"
        #f"data/{parameters.until('n_threads')(method='strobealign')}/without_readgroup.bam"
    output:
        f"data/{reference_genome}/{{config}}/strobealign/{{n_threads}}/mapped.bam"
        #f"data/{parameters.until('n_threads')(method='strobealign')}/mapped.bam"
    conda:
        "../envs/samtools.yml"
    shell:
        "samtools addreplacerg -r 'ID:sample\\tSM:sample' -O bam -o {output} {input}"