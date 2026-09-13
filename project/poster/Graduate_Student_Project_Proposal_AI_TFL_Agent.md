# DSC541 Practicum in Data Science I - Graduate Student Project Proposal

## Title
AI Agent for Metadata-Driven Generation of SAS TFL Programs from TFL Designer ARS JSON Metadata

## Objective
The objective of this graduate student project is to develop and evaluate an AI-assisted software agent that can generate all SAS table, figure, and listing (TFL) programs for a clinical study containing approximately 250 TFL outputs. The project will use the objective and lessons from the report "From Metadata-Driven TFL Shells to AI-Assisted SAS Code Development" as a motivating case study: structured ARS JSON metadata must become the source of truth for the generated code, and shared macro libraries, example study data, and title/footnote libraries must be used to produce consistent, study-ready SAS outputs.

The proposed agent will use TFL Designer as the authoritative metadata source by calling its API to pull ARS JSON metadata files for each of the TFL outputs. It will then use Gilead's shared global SAS macro library, study ADaM datasets in an /adamdata folder, and the study-specific tnf.inc file for titles and footnotes in a /tools folder when creating SAS programs that are consistent with Gilead's study reporting standards.

## Project Scope
The project will design, implement, and evaluate an AI agent that can:

1. Discover the complete list of up to 250 TFL outputs from the study's ARS JSON metadata inventory.
2. Fetch and normalize the associated ARS JSON metadata from TFL Designer through an API interface.
3. Build SAS program templates that call the Gilead shared global SAS macro library.
4. Incorporate the study ADaM datasets in an /adamdata folder as the data source for analysis variables and program derivations.
5. Use the study tnf.inc file as the single source for titles and footnotes.
6. Generate a complete and consistent set of SAS table, figure, and listing programs with variable naming, output structure, and macro call patterns aligned to the reporting standards used in the study.

## Proposed Research Question
Can an AI agent reliably convert ARS JSON metadata from TFL Designer into high-quality, metadata-driven SAS TFL programs for a study up to 250 outputs, while enforcing the use of the Gilead global macro library, study ADaM data sources, and the study-specific tnf.inc title/footnote source?

## Hypothesis
An AI agent that receives structured and normalized ARS JSON metadata, working examples from validated SAS code, and access to the Gilead macro library will produce an initial draft set of SAS TFL programs that is substantially more consistent, reproducible, and reviewable than hand-authored or purely free-form AI code generation. A human-in-the-loop validation layer will remain necessary to ensure that final programs meet Gilead's clinical reporting quality requirements.

## System Design

### Components
The proposed system will include five core components:

1. TFL Designer Metadata Connector
   - Connects to the TFL Designer API.
   - Fetches the ARS JSON metadata files for each TFL output.
   - Normalizes metadata fields such as output ID, output title, analysis population, table/figure/listing type, row labels, analysis methods, statistic definitions, variable references, filtering conditions, and display structure.

2. Project Asset Manager
   - Maintains Gilead's directory structure for the study.
   - Reads the ADaM data assets in the /adamdata folder.
   - Reads the study-specific tnf.inc file for titles and footnotes in the /tools folder.
   - Identifies the global macro library location and macro naming conventions.

3. Prompt and Code Generation Agent
   - Receives a normalized metadata record for each TFL output.
   - Produces an SAS program skeleton that aligns with the selected macro library pattern.
   - Uses template rules to call the appropriate global macros, structure the output sections, and include standard annotation and documentation.

4. Validation and Review Layer
   - Performs static checks on SAS code structure, macro references, and variable existence assumptions.
   - Compares generated files against log outputs and macro conventions.
   - Allows statistical programmer review before final code is accepted.

5. Output Repository
   - Stores generated SAS programs in the /prog folder.
   - Maintains traceability from each output's ARS metadata to its generated program and macros.

## Data and Inputs

### Source-of-Truth Inputs
The AI agent will treat the following as the project source of truth hierarchy:

1. TFL Designer ARS JSON Metadata
   - The ARS metadata record for each output.
   - This will define the analysis context, statistic type, population, filtering conditions, output label, and display structure.

2. Study ADaM Data
   - The study's ADaM datasets in the /adamdata folder.
   - These include analysis datasets and variables that the generated SAS programs must reference.

3. Gilead Global Macro Library
   - The shared Gilead SAS macro repository used for stable and standard TFL production.
   - The agent must use library-defined macro patterns instead of inventing ad hoc code.

4. tnf.inc
   - The study's title and footnote source file in the /tools folder.
   - The generated programs must reference this file through the macro runner, rather than hardcoding titles and footnotes.

## Technical Approach

### Phase 1: Build the Metadata Acquisition Pipeline
The student will build an API client that can query TFL Designer and pull the ARS JSON metadata files for the full study output inventory. ARS records will then be stored in a local metadata repository and associated with output identifiers.

### Phase 2: Build the Study Asset Knowledge Layer
The student will create a project asset database that links:

- the output ID and ARS record;
- the output type (table, figure, listing);
- the corresponding ADaM dataset and dataset variables;
- the macro library standards and library usage patterns;
- the title/footnote definitions from tnf.inc.

### Phase 3: Agent Prompt and Generation Architecture
The agent will parse an ARS JSON metadata file and produce an SAS program requested by the metadata. It will be required to:

- maintain a consistent naming convention;
- produce programs using Gilead macro patterns;
- include standard title and footnote references from tnf.inc;
- verify dataset variable existence and output assumptions;
- generate code that follows a controlled template for tables, figures, and listings.

### Phase 4: Evaluation and Validation
The project will evaluate the generated code on quality, traceability, and standardization. The student will score outputs using the following criteria:

- Correctness of metadata mapping.
- Ability to use shared macro library correctly.
- Use of the study ADaM datasets instead of handwritten assumptions.
- Correct inclusion of title and footnote definitions from tnf.inc.
- Program readability and maintainability.
- Reviewable structure for statistical programmers.

## Example Workflow
For each output:

1. The agent calls TFL Designer API and retrieves the ARS JSON metadata file.
2. The metadata parser identifies the analysis population, display structure, and method.
3. The agent retrieves the study variables and dataset structure from /adamdata.
4. The agent assembles a prompt that includes the TFL macro usage patterns, the study's tnf.inc reference, and the relevant Gilead macro guidance.
5. The agent writes the SAS program.
6. A validation layer checks the code for missing variables, macro call syntax, and required title/footnote handling.
7. The statistical programmer reviews and approves the generated draft.

## Deliverables
The graduate student project will produce the following deliverables:

1. A working AI agent prototype that can query TFL Designer ARS JSON metadata and create SAS program drafts.
2. A metadata normalization layer that can map JSON metadata to an internal program-generation schema.
3. A study asset registry containing the macro library, ADaM datasets, and tnf.inc integration rules.
4. A collection of generated SAS TFL programs for approximately 250 outputs.
5. A validation report describing program quality, macro usage conformity, and gap analysis.
6. A final project report summarizing the design, lessons learned, and recommendations for scaling this approach across all Gilead studies.

## Success Criteria
The project will be considered successful if:

- the agent can retrieve ARS JSON metadata for the complete set of target outputs;
- the generated SAS programs can be traced back to the ARS metadata source file;
- generated programs reliably use the Gilead global macro library;
- generated programs reference study ADaM data in /adamdata;
- program code correctly includes the tnf.inc title and footnote structure;
- the output includes a reviewable and reproducible process for human validation.

## Expected Outcomes
This project will be a first step toward a reusable AI-assisted clinical reporting workflow in which a human programmer remains the final reviewer, while the AI agent creates the initial TFL code from ARS metadata and study assets. It directly supports the vision articulated in the report and creates a concrete research prototype for automated metadata-driven SAS TFL programming at scale.

## Proposed Student Role
The graduate student will serve as the lead developer and evaluator for the project. The role will include:

- implementing the TFL Designer API client;
- building the metadata normalization framework;
- integrating the Gilead macro library standards;
- creating SAS program generation templates;
- running evaluation checks and documenting the generated code quality.

## Timeline
A graduate project timeline of the 16 month graduate academic program is sufficient for a prototype that demonstrates end-to-end generation across a representative subset of approximately 250 outputs, with all remaining outputs supported by the same generation pipeline and validation workflow.

## Conclusion
This project turns the objective in the AI-Assisted SAS TFL Programming Report into a concrete research and software engineering task. The key innovation is not simply asking an AI model to write SAS programs. The innovation is building an agentic workflow that treats TFL Designer ARS JSON metadata as the source of truth and integrates that metadata with the study ADaM data, the Gilead macro library, and the study tnf.inc template to produce an auditable, scalable, and maintainable SAS TFL production process.
