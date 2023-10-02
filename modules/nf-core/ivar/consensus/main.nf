process IVAR_CONSENSUS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::ivar=1.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ivar:1.4--h6b7c446_1' :
        'quay.io/biocontainers/ivar:1.4--h6b7c446_1' }"

    input:
    tuple val(meta), path(bam)
    path ref_rsva
    path ref_rsvb
    val save_mpileup

    output:
    tuple val(meta), path("*.fa")      , emit: fasta
    tuple val(meta), path("*.qual.txt"), emit: qual
    tuple val(meta), path("*.mpileup") , optional:true, emit: mpileup
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mpileup = save_mpileup ? "| tee ${prefix}.mpileup" : ""
    
    def ref
    if ("${meta.rsv_type}" == "RSVA") {
        ref = "${ref_rsva}"
    } else if ("${meta.rsv_type}" == "RSVB") {
        ref = "${ref_rsvb}"
    }

    """
    samtools \\
        mpileup \\
        --reference $ref \\
        $args2 \\
        $bam \\
        $mpileup \\
        | ivar \\
            consensus \\
            $args \\
            -p $prefix \\
            -i $prefix

    # remove leading and trailing Ns
    sed -i '/^>/! s/^N*//; /^>/! s/N*\$//' ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ivar: \$(echo \$(ivar version 2>&1) | sed 's/^.*iVar version //; s/ .*\$//')
    END_VERSIONS
    """
}
