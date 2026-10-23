# Session Log — beliefs-congress-speeches Project

Paper title: **"Belief Systems and the Climate Change Discourse in the US Congress"**

This log records what has been done in each working session. Update it at the end of each session.

---

## Project Overview

Examines the feasibility of measuring belief systems from floor speeches in the US Congress, using speeches from the cap-and-trade, IRA, and OBBB debates plus DW-NOMINATE scores. Research questions: (RQ1) can beliefs (deep core, policy core, secondary) be measured as probability distributions from floor speeches; (RQ2) what information sources did members cite; (RQ3) which beliefs and information sources were salient in each period, and how do the periods compare. Target venues: MPSA (conference), *Journal of Public Policy*.

Connected to the Policy Learning in Congress wiki (`../00-policy-learning-congress`), which holds the theory and the pilot coding of these speeches (codebook v0.4).

**Key files:**
- `beliefs-congress-speeches.qmd` — main manuscript (renders to HTML, PDF, DOCX)
- `scripts/analysis.R` — data loading and analysis objects sourced by the manuscript
- `scripts/export-cited-refs.R` — pre-render step that trims the master `.bib` to cited keys
- `data/cap-and-trade-congressional-record/`, `data/ira-congressional-record/` — speech corpora
- `data/voteview-nominate/` — DW-NOMINATE scores matched to each speech
- `README.md` — project structure and reproduction instructions

---

## Session History

### Session 1 — 2026-10-23 (Project set-up)

- Copied the standard project files from the `project-files` template; renamed `template.qmd` → `beliefs-congress-speeches.qmd` and set its title; pointed `_quarto.yaml` and `scripts/export-cited-refs.R` at the new qmd.
- Fixed the template's PDF header: added `\usepackage{ulem}` so `\normalem` compiles (same fix as the cue-WTP project).
- Moved the speech data from `01-RESEARCH/03-data/` into `data/`: `cap-and-trade-congressional-record` (2000–2012, 2,133 speeches), `ira-congressional-record` (2018–2026, 2,079 speeches; includes the OBBB debate), and `voteview-nominate` (DW-NOMINATE/Nokken-Poole matched per speech; moved with the corpora because `add_nominate.R` reads them as sibling folders).
- Created `scripts/analysis.R`: reads both corpus indexes, merges the speech-level DW-NOMINATE scores, and stacks them into `speeches` (4,212 speeches, 696 members); sourced by the qmd setup chunk.
- Initialized `renv` and snapshotted the lockfile (`knitr`, `rmarkdown`; analysis is base R so far).
- Wrote `README.md` and this log; set up `.gitignore` (`/data/`, `/literature/`, `nowlin-style-profile.md`, the `beliefs-congress-speeches.md` notes file, generated bib/CSL).
- Added `wiki/overview/congressional-speeches-paper.md` to the Policy Learning in Congress wiki pointing to this project, and logged it in `wiki/log.md`.
- Rendered HTML, PDF, and DOCX; all three build cleanly.
- Note: `../00-policy-learning-congress/scripts/pilot_sample.R` still reads the corpora from `../../03-data/` and will need its `data_dir` updated if re-run.
