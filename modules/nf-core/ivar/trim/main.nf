process IVAR_TRIM {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::ivar=1.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ivar:1.4--h6b7c446_1' :
        'quay.io/biocontainers/ivar:1.4--h6b7c446_1' }"

    input:
    tuple val(meta), path(bam)
    tuple val(meta), path(bai)
    path rsva_primer_bed
    path rsvb_primer_bed

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path('*.log'), emit: log
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    def bed
    if ("${meta.rsv_type}" == "RSVA") {
        bed = "${rsva_primer_bed}"
    } else if ("${meta.rsv_type}" == "RSVB") {
        bed = "${rsvb_primer_bed}"
    }

    """
    ivar trim \\
        $args \\
        -i $bam \\
        -b $bed \\
        -p $prefix \\
        > ${prefix}.ivar.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ivar: \$(echo \$(ivar version 2>&1) | sed 's/^.*iVar version //; s/ .*\$//')
    END_VERSIONS
    """
}
