from functools import lru_cache
import json
from pathlib import Path
from snakebids import (
    bids,
    generate_inputs,
    filter_list,
    get_wildcard_constraints,
)
import subprocess as sp

# from snakeboost import PipEnv
from lib.check_subj_dwi_metadata import check_subj_dwi_metadata


# Filter pybids_inputs based on output_spaces
# If 'T1w' is not in output_spaces, remove T1w from pybids_inputs
pybids_inputs_filtered = config["pybids_inputs"].copy()
if "T1w" not in config.get("output_spaces", ["T1w"]):
    pybids_inputs_filtered.pop("T1w", None)
    pybids_inputs_filtered.pop("T1w_reference", None)

# writes inputs_config.yml and updates config dict
inputs = generate_inputs(
    bids_dir=config["bids_dir"],
    pybids_inputs=pybids_inputs_filtered,
    derivatives=config["derivatives"],
    participant_label=config["participant_label"],
    exclude_participant_label=config["exclude_participant_label"],
    pybids_database_dir=config.get("pybids_db_dir"),
    use_bids_inputs=True,
)


# this adds constraints to the bids naming
wildcard_constraints:
    **get_wildcard_constraints(config["pybids_inputs"]),


# ---- end snakebids boilerplate ------------------------------------------------


report: "../report/workflow.rst"


input_wildcards = inputs.input_wildcards
subj_wildcards = inputs.subj_wildcards
input_zip_lists = inputs.input_zip_lists
input_path = inputs.input_path

# if no acquisiton, run or direction specified for diffusion image add acquisition wildcard to input_wildcards and add 'notspecified' for acquisition in corresponding images in input_zip_lists
if not any(
    [item in ["acq", "run", "dir"] for item in list(input_wildcards["dwi"].keys())]
):
    input_wildcards["dwi"]["acq"] = "{acquisition}"
    input_zip_lists["dwi"]["acquisition"] = ["notspecified"] * len(
        input_zip_lists["dwi"]["subject"]
    )

root = os.path.join(config["root"], "snakedwi")
work = os.path.join(config["root"], "work")
qc = os.path.join(config["root"], "qc")
# setup pipenvs - all my python rules use the script: directive, so will be some work to use snakeboost for this..
# dwi_env = PipEnv(
#            root=Path('work'),
#            requirements=['workflow/pipenvs/snakedwi.txt'],
# )


# create a subj_zip_list bids_input var to loop over subjects/sessions where
# *all* the pybids inputs are present (e.g. T1w and dwi both present)
#
# does this by performing a set intersection of the (subject+session only) zip lists for different modalities

subj_set_intersection = None
subj_set_union = None  # union not really used except for finding set union - intersection (skipped subjects)
subj_zip_list = None

for bidsinput in pybids_inputs_filtered.keys():
    if bidsinput == "T1w_reference":
        continue
    zipl = inputs.input_zip_lists[bidsinput]
    if "session" in zipl:
        # has session, so we have to zip, then use set to remove duplicates
        subj_set = set(zip(zipl["subject"], zipl["session"]))
    else:
        # does not have session, so we can remove duplicates easily by using set
        subj_set = set(zipl["subject"])

    subj_set_intersection = (
        subj_set
        if subj_set_intersection == None
        else subj_set.intersection(subj_set_intersection)
    )
    subj_set_union = (
        subj_set if subj_set_union == None else subj_set.union(subj_set_union)
    )


subj_set_difference = subj_set_union - subj_set_intersection
if "session" in zipl:
    (subzip, seszip) = zip(*list(subj_set_intersection))  # zip it up again
    subj_zip_list = {
        "subject": subzip,
        "session": seszip,
    }  # create the new subj_zip_list

    if len(subj_set_difference) > 0:
        (msubzip, mseszip) = zip(*list(subj_set_difference))  # zip it up again
    else:
        msubzip = []
        mseszip = []
    missing_subj_zip_list = {
        "subject": msubzip,
        "session": mseszip,
    }
else:
    subj_zip_list = {"subject": list(subj_set_intersection)}
    missing_subj_zip_list = {"subject": list(subj_set_difference)}
# ------------------------------------------------------------------------------
# if len(subj_set_difference) > 0:
#    print(f'Skipping following (subjects/sessions) since they are missing one of the required bids inputs: {subj_set_difference}')
#    print(subj_zip_list)
