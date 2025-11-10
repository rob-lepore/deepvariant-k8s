nextflow.enable.dsl=2

/*
 * WGS SR variant calling with DeepVariant (CPU)
 * Author: Roberto Lepore & Gaia Corona
 * Requires Nextflow >= 21.10.6
 */

params.help = (params.help ?: false) as boolean

if (params.help) {
    log.info """
    -----------------------------------------------------------------------
    Pipeline for WGS SR alignment data using DeepVariant (CPU)
    Usage:
      nextflow run main.nf \\
        --sample_cram samples.tsv \\
        --reference_fasta /path/to/reference.fa
    samples.tsv format (tab-delimited, with header):
      sample_name\tcram_file_path
    -----------------------------------------------------------------------
    """.stripIndent()
    System.exit(0)
}

// Input validation
if (!params.sample_cram)     error "Please provide the sample cram file with --sample_cram"
if (!params.reference_fasta) error "Please provide the reference fasta with --reference_fasta"

// Channels
sample_cram = Channel
    .fromPath(params.sample_cram, checkIfExists: true)
    .splitCsv(sep: '\t', header: true)
    .map { row ->
        def sample = (row.sample_name ?: '').toString().trim()
        def cramPath = (row.cram_file_path ?: '').toString().trim()
        if (!sample)               error "samples.tsv: missing 'sample_name' in a row"
        if (!cramPath)             error "samples.tsv: missing 'cram_file_path' for sample '${sample}'"
        def cram = file(cramPath, checkIfExists: true)
        def craiA = file(cram.toString() + '.crai')
        def craiB = file(cram.toString().replaceAll(/\.cram$/, '.crai'))
        def crai = craiA.exists() ? craiA : (craiB.exists() ? craiB : null)
        if (!crai) error "Missing CRAI for ${cram} (expected ${cram}.crai or ${cram.toString().replaceAll(/\\.cram$/, '.crai')})"

        tuple(sample, cram, crai)
    }

reference_fasta     = file(params.reference_fasta, checkIfExists: true)
reference_fasta_fai = file("${params.reference_fasta}.fai", checkIfExists: true)

// Optional but recommended for CRAM:
reference_fasta_gzi = file("${params.reference_fasta}.gzi", checkIfExists: false)
// We won't require .gzi; htslib can build it if needed.

// Pair the reference files in one tuple
ref_ch = Channel.of( tuple(reference_fasta, reference_fasta_fai) )

process DEEPVARIANT {
    // container "google/deepvariant:${params.bin_version ?: '1.6.0'}"

    
    scratch true

    tag { sample_name }

    // publish each sample into results/<sample_name>/
    publishDir "results", mode: 'copy', saveAs: { fn -> "${sample_name}/${fn}" }

    input:
    tuple val(sample_name), path(cram), path(crai)        // <— include CRAI
    //tuple path(reference_fasta), path(reference_fasta_fai)

    output:
    tuple val(sample_name), path("${sample_name}.vcf.gz"), emit: vcf
    tuple val(sample_name), path("${sample_name}.g.vcf.gz"), emit: gvcf
    tuple val(sample_name), path("${sample_name}.vcf.stats.html"), emit: stats

    script:
    """
    /opt/deepvariant/bin/run_deepvariant \
      --model_type=WGS \
      --ref=${reference_fasta} \
      --reads=${cram} \
      --output_vcf=${sample_name}.vcf.gz \
      --output_gvcf=${sample_name}.g.vcf.gz \
      --vcf_stats_report=true

    # Normalize stats filename (DeepVariant writes <VCF>.stats.html)
    if [ -f "${sample_name}.vcf.gz.stats.html" ] && [ ! -f "${sample_name}.vcf.stats.html" ]; then
      mv "${sample_name}.vcf.gz.stats.html" "${sample_name}.vcf.stats.html"
    fi
    """

    stub:
    """
    touch ${sample_name}.vcf.gz
    touch ${sample_name}.g.vcf.gz
    touch ${sample_name}.vcf.stats.html
    """
}

workflow {
    // Bind BOTH channels (samples + reference)
    DEEPVARIANT(sample_cram)
}
