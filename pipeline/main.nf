nextflow.enable.dsl=2

/*
 * WGS SR variant calling with DeepVariant (CPU) 
 * Author: Roberto Lepore & Gaia Corona
 * This pipeline relies on Nextflow and it works using Nextflow version >= 21.10.6.5660 
 */


// Help message
params.help = params.help ?: false

if (params.help) {
    log.info """
    -----------------------------------------------------------------------
    Pipeline for WGS SR alignment data using DeepVariant (CPU)
    Usage:
    nextflow run main.nf \\
        --sample_cram samples.tsv \\
        --reference_fasta /path/to/reference.fa
    -----------------------------------------------------------------------
    Required:
    --sample_cram      PATH    Path to tab-delimited file with sample name and CRAM absolute path 
    --reference_fasta   PATH    Reference genome to which the reads are aligned
    """.stripIndent()
    exit 0
}



// Input validation
if (!params.sample_cram) {
    error "Please provide the sample cram file with --sample_cram"
}
if (!params.reference_fasta) {
    error "Please provide the reference fasta with --reference_fasta"
}


// Input channels
sample_cram = Channel
    .fromPath(params.sample_cram, checkIfExists: true)
    .splitCsv(sep: "\t", header: ["sample_name", "cram_file_path"])
    .map { row -> tuple(row.sample_name, row.cram_file_path) }


// Input files existance
reference_fasta = file(params.reference_fasta, checkIfExists: true)
reference_fasta_fai = file("${reference_fasta}.fai", checkIfExists: true)



process DEEPVARIANT {
    scratch true
    publishDir "results/$sample_name", mode: "copy"

    input:
    tuple val(sample_name), val(cram_file_path)

    output:
    tuple val(sample_name), path("${sample_name}.vcf.gz"), emit: vcf
    tuple val(sample_name), path("${sample_name}.g.vcf.gz"), emit: gvcf
    tuple val(sample_name), path("${sample_name}.vcf.stats.html"), emit: stats

    script:
    """
    /opt/deepvariant/bin/run_deepvariant \
        --model_type=WGS \ 
        --ref=${reference_fasta} \
        --reads=${cram_file_path}/${sample_name}.cram \
        --output_vcf=${sample_name}.vcf.gz \
        --output_gvcf=${sample_name}.g.vcf.gz \
        --vcf_stats_report=true 
    """
    
    stub:
    """
    touch ${sample_name}.vcg.gz
    touch ${sample_name}.g.vcf.gz
    touch ${sample_name}.vcf.stats.html
    """

}


workflow {
    DEEPVARIANT(sample_cram)
}