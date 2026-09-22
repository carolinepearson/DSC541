# DSC541 Practicum in Data Science I - Graduate Student Project Proposal

## Title
AI Agent for Metadata-Driven Generation of SAS TFL Programs from TFL Designer ARS JSON Metadata

## Objective
The objective of this graduate student project is to develop and evaluate an AI-assisted software agent that can generate all table, figure, and listing (TFL) SAS programs for a clinical study containing up to 250 TFL outputs. The project will use the objective and lessons from the Gilead Data Science Symposium poster "From Metadata-Driven TFL Shells to AI-Assisted SAS Code Development" as a motivating case study: structured ARS JSON metadata must become the source of truth for the generated code, and shared global macro libraries, validated example study programs, and study title/footnote (tnf) files must be used to produce consistent, study-ready SAS programs and outputs.
The proposed agent will use TFL Designer as the authoritative metadata source by calling its API to pull ARS JSON metadata files for each of the TFL outputs. It will then use Gilead's shared global SAS macro library, anonymized ADaM datasets in an /adamdata folder, and the study-specific tnf.inc file for titles and footnotes in a /tools folder when creating SAS programs that are consistent with Gilead's study reporting standards.
Study ADaM datasets used in the testing of the agent produced SAS programs will be fully anonymized to transform all sensitive data records to protect patient privacy while preserving the standard data structure to maintain analytical integrity. The use of real anonymized ADaM datasets will be essential to ensure the agent learns from authentic clinical patterns and produces reliable, generalizable results.

## Project Scope
The project will design, implement, and evaluate an AI agent that can:

1.	Discover the complete list of up to 250 TFL outputs from the study's ARS JSON metadata inventory.
2.	Fetch and normalize the associated ARS JSON metadata from TFL Designer through an API interface.
3.	Build SAS program templates that call the Gilead shared global SAS macro library.
4.	Incorporate the study anonymized ADaM datasets in an /adamdata folder as the data source for analysis variables and program derivations. NOTE: No study data will be copied into AI. No patient level records will be uploaded, transmitted, or stored by the agent; testing will performed outside the agent by the student to run the agent produce SAS programs to evaluate the generated TFL outputs and log files.
5.	Use the study tnf.inc file as the single source for titles and footnotes.
6.	Generate a complete and consistent set of TFL SAS programs with variable naming, output structure, and macro call patterns aligned to the reporting standards used in the study.

## Proposed Research Question
Can an AI agent reliably convert ARS JSON metadata from TFL Designer into high-quality, metadata-driven SAS TFL programs for a study up to 250 outputs, while enforcing the use of the Gilead global macro library, study anonymized ADaM data sources, and the study-specific tnf.inc title/footnote source?

## Hypothesis
An AI agent that receives structured and normalized ARS JSON metadata, working examples from validated SAS code, and access to the Gilead macro library will produce an initial draft set of SAS TFL programs that is substantially more consistent, reproducible, and reviewable than hand-authored or purely free-form AI code generation. A human-in-the-loop review layer will remain necessary to ensure that final programs meet Gilead's clinical reporting quality requirements.

## System Design

### Components
The proposed system will include five core components:

1. TFL Designer Metadata Connector
   - Connects to the TFL Designer API.
   - Fetches the ARS JSON metadata files for each TFL output.
   - Normalizes metadata fields such as output ID, output title, analysis population, table/figure/listing type, row labels, analysis methods, statistic definitions, variable references, filtering conditions, and display structure.

2. Project Asset Manager
   - Maintains Gilead's directory structure for the study.
   - Identifies anonymized ADaM datasets location for dataset names and variables in the /adamdata folder.
   - Identifies the study-specific tnf.inc file location for titles and footnotes in the /tools folder.
   - Identifies the global macro library location and macro naming conventions.

3. Prompt and Code Generation Agent
   - Receives a normalized metadata record for each TFL output.
   - Produces an SAS program skeleton that aligns with the selected macro library pattern.
   - Use template rules to call the appropriate global macros, structure the output sections, and include standard annotation and documentation.

4. Validation and Review Layer
   - Performs static checks on SAS code structure, macro references, and variable existence assumptions.
   - Compares generated SAS code against log outputs and macro conventions.
   - Requires student review, representing a production statistical programmer role, before final code is accepted.

5. Output Repository
   - Stores generated SAS programs in the /prog folder.
   - Maintains traceability from each output's ARS metadata to its generated program and macros.

## Data and Inputs

### Source-of-Truth Inputs
The AI agent will treat the following as the project source of truth hierarchy:
1.	TFL Designer ARS JSON Metadata
   - The ARS metadata record for each output.
   - This will define the analysis context, statistic type, population, filtering conditions, output label, and display structure.
2.	Study Anonymized ADaM Datasets
   - The study's anonymized ADaM datasets in the /adamdata folder.
   - These include analysis datasets and variables that the generated SAS programs must reference.
3.	Gilead Global Macro Library
   - The shared Gilead SAS macro repository used for stable and standard TFL production.
   - The agent must use library-defined macro patterns instead of inventing ad hoc code.
4.	tnf.inc
   - The study's title and footnote source file in the /tools folder.
   - The generated programs must reference this file through the macro runner, rather than hardcoding titles and footnotes.

## Technical Approach

### Phase 1: Build the Metadata Acquisition Pipeline
The student will build an API client that can query TFL Designer and pull the ARS JSON metadata files for the full study output inventory. ARS records will then be stored in a local metadata repository and associated with output identifiers.

### Phase 2: Build the Study Asset Knowledge Layer
The student will create a project asset database that links:

   - the output ID and ARS record;
   - the output type (table, figure, listing);
   - the corresponding anonymized ADaM dataset and dataset variables;
   - the macro library standards and library usage patterns;
   - the title/footnote definitions from tnf.inc.

### Phase 3: Agent Prompt and Generation Architecture
The agent will parse an ARS JSON metadata file and produce an SAS program requested by the metadata. It will be required to:
   - maintain a consistent naming convention;
   - produce programs using Gilead macro patterns;
   - include standard title and footnote references from tnf.inc;
   - verify dataset variable existence and output assumptions;
   - generate code that follows a controlled template for TFLs.

### Phase 4: Evaluation and Validation
The project will evaluate the generated code on quality, traceability, and standardization. The student will score outputs using the following criteria:
   - Correctness of metadata mapping.
   - Ability to use shared macro library correctly.
   - Use of the study anonymized ADaM datasets instead of handwritten assumptions.
   - Correct inclusion of title and footnote definitions from tnf.inc.
   - Program readability and maintainability.
   - Reviewable structure for students representing a production statistical programmer role.

## Example Workflow
For each output:

1. The agent calls TFL Designer API and retrieves the ARS JSON metadata file.
2. The metadata parser identifies the analysis population, display structure, and method.
3. The agent retrieves the assigned output ADaM variables and datasets from the metadata.
4. The agent assembles a prompt that includes the TFL macro usage patterns, the study's tnf.inc reference, and the relevant Gilead macro guidance.
5. The agent writes the SAS program.
6. A validation layer checks the code for missing variables, macro call syntax, and required title/footnote handling.
7. The student executes the SAS program on the SAS grid and returns the resulting output files (e.g., .log, .out, .pdf). Because the AI agent has no live SAS execution environment, all iterations will follow strict human-in-the-loop and evidence-driven cycles.
8. The student reviews the deliverables for accuracy and checks for any log errors/warnings. Detailed instructions for code corrections, if any, are provided to the AI agent. These instructions must include explicit targeted corrections rather than vague instructions or assumptions. Instructions may include corrected SAS code syntax, if necessary.
9. The agent identifies and diagnoses these corrections - reading the actual log text, reading rendered .out/.pdf content directly when a rendering (not syntax) problem was suspected, and reading macro source code directly rather than trusting its own assumptions about macro behavior.
10. A targeted fix is proposed and applied, syntax-checked, and handed back for another run. 
11. This cycle is repeated with each round addressing a specific, evidence-backed issue - never a speculative change without a log, output, or source-code citation to justify it.
12. Once the student is satisfied with the SAS program and output files, the student approves the generated draft.

## Deliverables
The graduate student project will produce the following deliverables:

1.	A working AI agent prototype that can query TFL Designer ARS JSON metadata and create SAS program drafts.
2.	A metadata normalization layer that can map JSON metadata to an internal program-generation schema.
3.	A study asset registry containing the macro library, anonymized ADaM datasets, and tnf.inc integration rules.
4.	A collection of generated SAS TFL programs for up to 250 outputs.
5.	A validation report describing program quality, macro usage conformity, and gap analysis.
6.	A final project report summarizing the design, lessons learned, and recommendations for scaling this approach across Gilead studies as an AI use case.

## Success Criteria
The project will be considered successful if:

   - the agent can retrieve ARS JSON metadata for the complete set of target outputs;
   - the generated SAS programs can be traced back to the ARS metadata source file;
   - generated programs reliably use the Gilead global macro library;
   - generated programs reference study anonymized ADaM datasets in /adamdata;
   - program code correctly includes the tnf.inc title and footnote structure;
   - the output includes a reviewable and reproducible process for production statistical programmer adoption.

## Expected Outcomes
This project will be a first step toward a reusable AI-assisted clinical reporting workflow in which a human statistical programmer remains the final reviewer, while the AI agent creates the initial TFL code from ARS metadata and study files. It directly supports the vision articulated in Gilead’s 2026 Development goals and could be a potential AI use case at Gilead. This project creates a concrete research prototype for automated metadata-driven SAS TFL programming at scale.

## Proposed Student Role
The graduate student will serve as the lead developer and evaluator for the project. The role will include:
   - implementing the TFL Designer API client;
   - building the metadata normalization framework;
   - creating standard AI prompt and define agent guardrails;
   - integrating the Gilead macro library standards;
   - creating production ready SAS programs with an AI assistant;
   - running evaluation checks and documenting the generated code quality.

## Timeline
A graduate project timeline spans eight months and is sufficient for a prototype that demonstrates end-to-end generation across a representative subset of up to 250 outputs, with all remaining outputs supported by the same generation pipeline and validation workflow. The project will be co-managed by the Gilead Clinical Data Science team and the UNCW Data Science & Artificial Intelligence faculty. All students and faculty members involved in the project will sign an NDA with Gilead. No one will be granted access to resulting student work products and deliverables until they have signed Gilead’s NDA and Gilead has confirmed receipt.

## Sponsor Involvement 
If Gilead agrees to sponsor this Practicum Project, there is no fee or cost involved in being a sponsor. Optionally, Gilead may incur part or all the cost for the student team’s travel for the in-person Final Presentation if amenable, but this is not requirement for sponsorship. 
A Kickoff Meeting should occur around the first week in May 2027 via video conference. The team consists of four students with one student being designated as the formal point of contact for the Gilead team.
A Sponsor Liaison from Gilead will serve as the central point of contact for the student point of contact.
Regularly scheduled progress meetings will occur every other week to make sure the team is progressing towards their goal.
A Midpoint Team Presentation will be delivered to Gilead by October 1, 2027. The purpose of this presentation will be to demonstrate the team understands the data involved, their understanding of the business problem and to present initial models and results. Gilead team members will evaluate the presentation and identify final methodology to be used and desired deliverables.
The Final Presentation will be an executive-level presentation to Gilead team members which will occur on December 10, 2027. The presentation will be an hour long, in person at Gilead’s Raleigh NC office and is mandatory for the student team. 

## Conclusion
This project turns the objective on whether an AI-assisted software agent can generate all production TFL SAS programs for a clinical study into a concrete research and software engineering task. The key innovation is not simply asking for an AI model to write SAS programs. The innovation is building an AI assisted workflow that treats TFL Designer ARS JSON metadata as the source of truth and integrates that metadata with the study ADaM datasets, the Gilead macro library, and the study tnf.inc template to produce an auditable, scalable, and maintainable SAS TFL production process.

