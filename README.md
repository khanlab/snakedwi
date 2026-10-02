# snakedwi

[![Documentation Status](https://readthedocs.org/projects/snakedwi/badge/?version=latest)](https://snakedwi.readthedocs.io/en/latest/?badge=latest)

BIDS app and Snakemake workflow for diffusion-weighted imaging (DWI) pre-processing.

## Overview

snakedwi is a comprehensive workflow for preprocessing diffusion MRI data following the BIDS (Brain Imaging Data Structure) standard. The workflow includes:

- **Denoising** - Optional MP-PCA denoising
- **Susceptibility distortion correction (SDC)** - Multiple methods including TOPUP, SynthSR, SDCFlows, and SynB0
- **Eddy current correction** - FSL's eddy with optional GPU acceleration and slice-to-volume correction
- **Brain masking** - Multiple methods including BET, SyN registration, and SynthStrip
- **Gradient non-linearity correction** - Optional scanner-specific correction
- **Registration to T1w** - Rigid and deformable registration options
- **Quality control** - Automatic QC reports with eddy_quad

## Installation

### Prerequisites

- [pixi](https://pixi.sh/) - A fast package manager

### Install with pixi

1. Clone the repository:
```bash
git clone https://github.com/khanlab/snakedwi.git
cd snakedwi
```

2. Install dependencies with pixi:
```bash
pixi install
```

This will install snakedwi and all its dependencies in an isolated environment.

## Usage

### Basic Usage

Run the workflow with Apptainer (recommended for using containerized tools):

```bash
pixi run snakedwi /path/to/bids/dir /path/to/output/dir participant --use-apptainer
```

### Dry Run

To see what the workflow will do without running it:

```bash
pixi run snakedwi /path/to/bids/dir /path/to/output/dir participant --use-apptainer -np
```

### Running with Multiple Cores

To use all available cores:

```bash
pixi run snakedwi /path/to/bids/dir /path/to/output/dir participant --use-apptainer --cores all
```

### Common Options

- `--use-apptainer`: Use Apptainer/Singularity containers for tool dependencies
- `--participant_label`: Process specific subject(s), e.g., `--participant_label 001 002`
- `--sdc_method`: Choose susceptibility distortion correction method (`optimal`, `topup`, `synthsr`, `sdcflow`, `synb0`, `none`)
- `--masking_method`: Brain masking method (`b0_BET`, `b0_SyN`, `b0_synthstrip`)
- `--reference-t1w-session`: Use the T1w from the specified BIDS session as the anatomical reference (also used by DWI-to-T1w registration); omitted by default.
- `--cores`: Number of cores to use (e.g., `--cores 8` or `--cores all`)
- `-np`: Dry-run mode (show what will be executed without running)

### Example with Options

```bash
pixi run snakedwi /path/to/bids/dir /path/to/output/dir participant \
  --use-apptainer \
  --participant_label 001 \
  --reference-t1w-session clinical \
  --sdc_method topup \
  --masking_method b0_synthstrip \
  --cores 8
```

The reference session must contain exactly one T1w image per selected subject. Without
this option, snakedwi retains its existing T1w selection. The selected T1w is used
throughout anatomical preprocessing and template/segmentation processing as well as
DWI registration. The DWI session identity remains unchanged in output filenames.

## Input Data Requirements

Your input data must be organized according to the [BIDS specification](https://bids.neuroimaging.io/), specifically:

- DWI data in `sub-*/dwi/` with `.nii.gz` images and corresponding `.json` sidecar files
- Optional T1w anatomical images in `sub-*/anat/`
- Metadata including `PhaseEncodingDirection` in JSON files

## Output

Processed DWI data will be saved in the specified output directory following the BIDS derivatives format, including:

- Preprocessed DWI images
- Brain masks
- QC reports
- Transformation matrices
- Processing metadata

## Documentation

For detailed documentation, visit: [https://snakedwi.readthedocs.io](https://snakedwi.readthedocs.io)

## Development

### Running Tests

To run the test suite:

```bash
pixi run test_all
```

### Code Formatting

To format code:

```bash
pixi run quality_fix
```

To check code quality:

```bash
pixi run quality_check
```

## Citation

If you use snakedwi in your research, please cite:

```
Khan, A. R. (2024). snakedwi: BIDS app and Snakemake workflow for DWI pre-processing.
https://github.com/khanlab/snakedwi
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: Report bugs or request features at [GitHub Issues](https://github.com/khanlab/snakedwi/issues)
- **Documentation**: [https://snakedwi.readthedocs.io](https://snakedwi.readthedocs.io)
- **Repository**: [https://github.com/khanlab/snakedwi](https://github.com/khanlab/snakedwi)

## Acknowledgments

snakedwi is developed and maintained by the Khan Lab at Western University.
