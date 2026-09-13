# Project Folder Inventory

This repository folder contains the main project artifacts for the DSC541 AI-assisted SAS TFL programming workflow. The `project/` folder is organized into reference material, compliance guidance, poster materials, prompt examples, generated SAS artifacts, and imported TFL design metadata.

## Top-Level Structure

The project directory contains the following major folders:

- `cdisc/` — CDISC reference documents and standards resources.
- `fda/` — FDA safety and standard safety table guidance PDFs.
- `poster/` — Poster and presentation materials, including the project proposal, generated report, abstract, and supporting reference papers.
- `prompts/` — Input prompts used to drive the TFL generation workflow.
- `s0000000/` — Generated study data and SAS programming artifacts.
- `tfl_designer_imports/` — Import metadata for TFL design and analysis metadata.

## Folder Inventory

### `cdisc/`

Reference and standards materials from CDISC:

- `ADaM Oncology Examples v1.0_Provisional.pdf`
- `ADaMIG_v1.3.pdf`
- `adam_examples_final.pdf`
- `ADaM_OCCDS_Implementation_Guide v1.1.pdf`
- `adam_tte_final_v1.pdf`

### `fda/`

FDA and related safety guidance materials:

- `sbia-stf-508-slides-beasley-20260623_0.pdf`
- `Standard Safety Tables and Figures Muscle Injury Targeted Analysis Guide - 2025.pdf`
- `standard_safety_tables_and_figures_integrated_guide_2025.pdf`
- `standard_safety_tables_and_figures_kidney_injury_targeted_analysis_guide_-_2025.pdf`

### `poster/`

Poster and project writing deliverables:

- `AI_Assisted_SAS_TFL_Programming_Report.txt`
- `AI_Assisted_TFL_Automation_Summary.docx`
- `DSC541 Practicum in Data Science I - Graduate Student Project Proposal.docx`
- `DSS Poster Abstract.docx`
- `Graduate_Student_Project_Proposal_AI_TFL_Agent.md`
- `reference papers/` — supporting literature PDFs for the poster and project narrative.

### `prompts/`

Prompt template files for the workflow:

- `initial_prompt.txt`
- `sas_tfl_program_creation_prompt.txt`

### `s0000000/`

Generated study and run artifacts created under a sample study id `s0000000`.

- `final/`
  - `draft1/`
    - `adamdata/` — ADaM data sets (`adae.sas7bdat`, `adpc.sas7bdat`, `adsl.sas7bdat`, `adtte.sas7bdat`)
    - `adamprog/` — generated ADaM SAS programs (`adae.sas`, `adpc.sas`, `adsl.sas`, `adtte.sas`)
    - `docs/` — shell and metadata documentation files (`DSS TFL Shells_Tables.json`, `DSS TFL Shells_Tables.xml`, `DSS TFL Shells.json`, `m_safety.xlsx`, `tnf.xlsx`, `TOC.xlsx`, `s0000000_final_project_summary.docx`)
    - `prog/` — TFL SAS outputs and logs (`t-aebrief.sas`, `t-demog.sas`, `t-disp.sas`, `t-os.sas`, `t-pkpc.sas`, `t-s-aebrief.sas`, `t-s-demog.sas`, `t-s-disp.sas`, and corresponding `.log`, `.out`, `.pdf` outputs)
    - `tools/` — support macros and data conversion utilities (`formats.sas7bcat`, `init.inc`, `m_safety.sas7bdat`, `metadata.txt`, `mk-safety.sas`, `std-safetyfmt.sas`, `taskfmt.sas`, `tnf.inc`, `tnfconvert.sas`, `toc.txt`, `val_report.sas`, `val_report.sas7bdat`)
    - `validation/` — validation SAS file (`v-mk-safety.sas`)
    - `vdata/` — validation and comparison data sets (`t_pkpc_orig.sas7bdat`, `t_pkpc.sas7bdat`, `t_s_aebrief.sas7bdat`, `t_s_demog.sas7bdat`, `t_s_disp.sas7bdat`, `v_t_aebrief.sas7bdat`, `v_t_demog.sas7bdat`, `v_t_disp.sas7bdat`, `v_t_os.sas7bdat`)

### `tfl_designer_imports/`

Imported design and metadata templates:

- `all-sdtm-spec-define.xml`
- `gilead_adam_metadata_onc.xlsx`

## Notes

This folder is intended as a project-documentation and artifact collection area for the generated demonstration study. The artifact set combines source references, model prompts, output generation specs, and SAS programming outputs in one workspace.
