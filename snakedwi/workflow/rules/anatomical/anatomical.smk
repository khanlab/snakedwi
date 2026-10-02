def get_t1_input(wildcards):
    reference_session = config["reference_t1w_session"]
    if reference_session is None:
        candidates = expand(
            input_path["T1w"],
            zip,
            **filter_list(input_zip_lists["T1w"], wildcards),
        )
        if not candidates:
            raise ValueError(
                f"No T1w image found for subject {wildcards.subject}"
            )
        return candidates[0]

    reference_wildcards = {
        "subject": wildcards.subject,
        "session": reference_session,
    }
    candidates = expand(
        input_path["T1w_reference"],
        zip,
        **filter_list(input_zip_lists["T1w_reference"], reference_wildcards),
    )
    if len(candidates) != 1:
        raise ValueError(
            f"Expected exactly one T1w image for subject {wildcards.subject} "
            f"in session {reference_session}, found {len(candidates)}"
        )
    return candidates[0]


rule import_t1:
    input:
        nii=get_t1_input,
    output:
        nii=bids(
            root=work,
            datatype="anat",
            suffix="T1w.nii.gz",
            **subj_wildcards,
        ),
    group:
        "subj"
    shell:
        "cp {input.nii} {output.nii}"


def get_input_for_synthstrip(wildcards):
    if config["gradcorrect_coeffs"] and not config["gradcorrect_skip_t1w"]:
        return bids(
            root=work,
            datatype="anat",
            desc="gradcorrect",
            suffix="T1w.nii.gz",
            **subj_wildcards,
        )
    else:
        return bids(
            root=work,
            datatype="anat",
            suffix="T1w.nii.gz",
            **subj_wildcards,
        )


rule synthstrip_t1:
    input:
        t1=get_input_for_synthstrip,
    output:
        mask=temp(
            bids(
                root=work,
                datatype="anat",
                desc="nofixhdrbrain",
                suffix="mask.nii.gz",
                **subj_wildcards,
            )
        ),
    group:
        "subj"
    container:
        config["singularity"]["synthstrip"]
    threads: 8
    shadow:
        "minimal"
    shell:
        "python3 /freesurfer/mri_synthstrip -i {input.t1} -m {output.mask}"


rule fixheader_synthstrip:
    input:
        t1=rules.import_t1.output.nii,
        mask=rules.synthstrip_t1.output.mask,
    output:
        mask=bids(
            root=root,
            datatype="anat",
            desc="brain",
            suffix="mask.nii.gz",
            **subj_wildcards,
        ),
    group:
        "subj"
    container:
        config["singularity"]["itksnap"]
    shell:
        "c3d {input.t1} {input.mask} -copy-transform -o {output.mask}"


rule n4_t1_withmask:
    input:
        t1=rules.import_t1.output.nii,
        mask=rules.fixheader_synthstrip.output.mask,
    output:
        t1=bids(
            root=root,
            datatype="anat",
            desc="preproc",
            suffix="T1w.nii.gz",
            **subj_wildcards,
        ),
    threads: 8
    container:
        config["singularity"]["ants"]
    group:
        "subj"
    shell:
        "ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads} "
        "N4BiasFieldCorrection -d 3 -i {input.t1} -x {input.mask} -o {output}"
