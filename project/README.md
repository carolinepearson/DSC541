# Project Folder Inventory

This repository contains the project assets for the DSC541 AI-assisted SAS TFL programming workflow. The `project/` directory combines reference standards, example study metadata, prompt definitions, generated outputs, and study data used to support TFL generation and validation work.

## Top-Level Structure

The project folder currently includes:

- `cdisc/` — core CDISC reference documents and standards PDFs.
- `cdisc_etfl/` — example ADaM and define.xml-based TFL metadata packages used for CDISC-style case studies.
- `fda/` — FDA safety and standard safety table reference materials.
- `poster/` — project proposal, report, and supporting reference papers.
- `prompts/` — workflow prompt templates.
- `s0000000/` — generated study artifacts and output directory.
- `tfl_designer_imports/` — imported TFL design metadata and XML definitions.

## Folder Inventory

### `cdisc/`

Reference materials from CDISC:

- `ADaM Oncology Examples v1.0_Provisional.pdf`
- `ADaMIG_v1.3.pdf`
- `ADaM_OCCDS_Implementation_Guide v1.1.pdf`
- `adam_examples_final.pdf`
- `adam_tte_final_v1.pdf`

### `cdisc_etfl/`

Example analysis and TFL datasets representing CDISC-style study packages and metadata bundles.

- `adamdata/` — ADaM datasets and metadata files, including:
  - `adae.*`, `adlbc.*`, `adlbh.*`, `adlbhy.*`, `adqsadas.*`, `adqscibc.*`, `adqsnpix.*`, `adsl.*`, `adtte.*`, `advs.*`
  - `define.xml`, `define.html`, and `define-v1-updated-html.xsl`
- `ars-lb-t01_20241022/` — liver safety example package with `adlb.xpt`, `adsl.xpt`, `ars-lb-t01-ard.json`, `ars-lb-t01-ars.json`, `define.xml`, and documentation.
- `ars-lb-t02_20241022/` — second liver safety example package with `adlb.xpt`, `adsl.xpt`, JSON reports, and `define.xml`.
- `ars-vs-t01_20241022/` — vital signs example package with `adsl.xpt`, `advs.xpt`, JSON outputs, and `define.xml`.
- `fda-ae-t06_20241022/` — AE example package with `adae.xpt`, `adsl.xpt`, JSON outputs, and `define.xml`.
- `fda-ae-t07_20241022/` — AE example package with `adsl.xpt`, JSON outputs, and `define.xml`.
- `fda-ae-t09_20241022/` — AE example package with `adae.xpt`, `adsl.xpt`, JSON outputs, and `define.xml`.
- `fda-ae-t12_20241022/` — additional AE package directory.
- `fda-ae-t13_20241022/` — additional AE package directory.
- `fda-ae-t36_20241022/` — additional AE package directory.
- `fda-dm-t02_20241022/` — demographic example directory.
- `fda-ds-t04_20241022/` — disposition example directory.
- `fda-ex-t05_20241022/` — exposure example directory.

### `fda/`

FDA-related safety and methodology guidance materials.

- `sbia-stf-508-slides-beasley-20260623_0.pdf`
- `standard_safety_tables_and_figures_integrated_guide_2025.pdf`
- `Standard Safety Tables and Figures Muscle Injury Targeted Analysis Guide - 2025.pdf`
- `standard_safety_tables_and_figures_kidney_injury_targeted_analysis_guide_-_2025.pdf`

### `poster/`

Project proposal and presentation materials:

- `AI_Assisted_SAS_TFL_Programming_Report.txt`
- `Graduate_Student_Project_Proposal_AI_TFL_Agent.md`
- `reference papers/` — supporting literature referenced in the project.

### `prompts/`

Workflow prompt files used to drive SAS TFL generation:

- `initial_prompt.txt`
- `sas_tfl_program_creation_prompt.txt`

### `s0000000/`

Generated sample study directory used for demonstration outputs.

- `final/` — final project outputs and generated artifacts.

### `tfl_designer_imports/`

Imported design metadata and XML configuration files:

- `all-sdtm-spec-define.xml`

## Notes

This folder is intended to capture the study references, generated SAS outputs, and example metadata used in the AI-assisted TFL programming workflow. The project brings together standards documents, example define.xml packages, prompt templates, and output artifacts in a single workspace.
