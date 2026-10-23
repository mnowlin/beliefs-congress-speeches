# Session Log — beliefs-congress-speeches Project

Paper title: **"Belief Systems and Climate Change Discourse in the US Congress"**

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

### Session 3 — 2026-10-23 (Codebook v0.5 re-pilot, final codebook, human-coding packet, MPSA abstract)

- Re-coded the 150 pilot speeches with `codebook/prompt_v0.5.txt`, in-session, one fresh subagent per 10-speech batch (15 batches; each saw only the prompt, its manifest, and its speeches). Batch 01's subagent hit the session usage limit after writing a complete file; used as written.
- Added `scripts/pilot_summarize_v05.R` (JSONL → CSVs, verbatim-quote and consistency checks, source/hedging/concept summaries, v0.4 comparison); output in `output/pilot/v0.5/`, report `output/pilot/v0.5/pilot-report-v05.md`. `jsonlite` recorded in `renv.lock`.
- Checks: 773/773 statement quotes and 478/479 source quotes verbatim; no sign or count errors.
- Sources: 81% of speeches cite ≥ 1 (mean 3.2, median 2; one 59-source Inhofe speech). Science D 47% vs R 22%, C&T 44% → IRA 27%. `other` is 25% of speeches and hides courts, polls, and congressional reports; `labor` and `religious` fail 5%.
- Hedging: 3.2% hedged (v0.4 3.9%); PC1–PC3 R 12.9% vs D 0.9%. Dictionary check weak (r = 0.14).
- Concept stability vs v0.4 (independent subagent coders): median κ 0.88; lowest DC4 0.69, DC1 0.72, PC4 0.74, SC4 0.76.
- Recommended final-v0.5 changes listed in the report §6.
- **Finalized codebook v0.5** (source types, decided by the user): split `other` into `courts`, `congress`, and `public_opinion`; added `expert_generic` for unattributed expert claims and estimates (generic appeals about the physical climate stay `science`); merged `labor` into `advocacy` and `religious` into `other`; contrarian science recorded as a note in §4b and an open issue in §10 (no new field). 17 source types. Regenerated `codebook/prompt_v0.5.txt` (codebook §§3–6 verbatim + JSON block; md5 `99c9df71…`, after the anchors below); the draft prompt used in the re-pilot stays archived in `output/pilot/v0.5/` (md5 `88bee1e9…`). Decisions noted in the report §6.
- **Boundary anchors** for DC1, DC4, PC4, and SC4 (codebook §4): verbatim pilot passages on which the v0.4 and v0.5 runs disagreed, each with its code and reason (all quotes checked against the speech text). Rule changes: DC4 codes the fiscal-restraint value on either side of a bill ("fully paid for" = agree; attacking cuts = disagree; returns on investment and cost of inaction are not DC4); PC4 includes fossil-supply restrictions and cost-as-a-constraint statements, and excludes supporters' cost concessions, cost of inaction (PC2), and non-energy savings; SC4 requires an agreement, treaty, or negotiation; DC1 needs value language, not a "market-based" label or a complaint about red tape (§5 "free-market approach" row narrowed). Prompt regenerated.
- **Human-coding packet** (`human-coding/`, built by `scripts/human_coding_setup.R`, seed 20261023): 54 speeches = the 50-speech reliability subset + 4 rule-C cap-and-trade speeches (one per party × chamber, ≤ 3,000 words; these still need LLM codes); 53,576 words; one fixed random order for both coders. 4 practice speeches (pilot speeches outside the subset). Codebook v0.5 in md/html/docx. Workbooks `coding-sheet_A/B.xlsx` (sheets: speeches, statements, sources, concepts, lists; dropdown validation) and practice sheets. Hand-written `INSTRUCTIONS.md` (+ docx): independence rules, training, field-by-field entry, quote rules, questions, return. `openxlsx` added to renv.
- **Anchor swap:** 17 of the 54 coding speeches contained codebook anchor quotes (v0.4 anchors and the new boundary anchors). Replaced every overlapping anchor (§4 tables, boundary anchors, §4a intensity example) with verified verbatim passages from pilot speeches outside the coding and practice sets, preferring passages both LLM runs coded the same way; constructed examples where none existed (DC5 disagree, a DC4 "paid for" case, a PC4 fossil-restriction case). `human_coding_setup.R` now stops if any quoted codebook passage appears in a coding speech. Prompt and packet regenerated; same 54 speeches.
- Renamed the local notes file `project-file.md` → `project-note.md` (user); `.gitignore` updated.
- Drafted the MPSA 2027 abstract (1,492 of 1,500 characters; exploratory wording; LLM–human validation only, since no human–human comparison will be done before the conference) and a 221-character overview from the wiki's theory pages and the nowlin style profile; the user edited the abstract. Both live in `project-note.md` (local only).
- **Next steps:** LLM-code all 54 human-coding speeches with the final `prompt_v0.5.txt` (the existing pilot codes used the draft prompt, and the 4 rule-C speeches have none); send the packet to coders; compute LLM–human agreement; fix the insertion filter and the speaker-split error before full coding.

### Session 2 — 2026-10-23 (Codebook v0.5: information sources and hedging)

- Assessed feasibility of RQ1–RQ3 against the pilot results and the corpora. Keyword scan of all 4,212 speeches: ~53% name at least one candidate information source (upper bound); appeals to scientists fall from 18.5% (cap-and-trade 2009–10) to 5.6% (IRA 2021–22) and 7.6% (OBBB 2025–26), while CBO/JCT stays at 5–9%. Debate windows are small for OBBB (249 speeches; 10 members with ≥5).
- Created `codebook/codebook-v0.5.md` from v0.4 (v0.4 left unchanged in the policy-learning project):
  - New §4b information-source module: one row per source per speech with `source_type` (15 categories), `specific`, `evidence_form`, `use`, `linked_concepts`, `inserted`; sources in inserted material are recorded even when not coded as stances.
  - `speaker_certainty` (3 levels) replaced by binary `hedged`; emphasis moved to a hedge/booster dictionary computed by script; "believe in X" is not a hedge; v0.4 → v0.5 mapping given.
  - Reliability plan extended with a source re-pilot on the same 150 speeches and source detection/classification criteria.
  - Concept-boundary changes from Pilot Report v0.4 (PC6/leakage, PC4/PC9, SC13, etc.) deliberately deferred until the reliability results.
- Generated `codebook/prompt_v0.5.txt` from codebook §§3–6 plus the v0.5 JSON schema.
- Codebook §8: removed "temperature 0" (the Anthropic API rejects sampling parameters on every model as of 2026-10-21); reproducibility now rests on fixed model ID, versioned prompt, archived raw responses, a re-code stability check, and LLM–human agreement. In-session coding uses a fresh subagent per batch.
- Found that `01-in-progress/info-agendas` README/LOG document the corpora at `03-data/` (docs only, no scripts); not changed.
- Added period variables to `scripts/analysis.R`: `era` (Congresses 106–112 / 115–118 / 119, covers every speech), `window` (debate windows: cap-and-trade 2009-03-31 to 2010-07-22; IRA 2021-08-11 to 2022-08-16; OBBB 2025-02-25 to 2025-07-04; NA outside), `in_window`, `window_congress` (111th / 117th / 119th, robustness check on the window dates), and `climate_rule` (kept by the climate-term rules A/B, which are identical in both corpora's screening scripts).
- Corpus filtering finding: every cap-and-trade-window speech passes the climate rules, but only 20% of IRA-window and 19% of OBBB-window speeches do (Republicans: 8% and 6%). Restricting to A/B is exactly comparable but leaves 16 Republican speeches in the IRA window and 3 in OBBB. Extending rule C to 2000–2012 would need a new GovInfo search for cap-and-trade-era bill names (step 1 is resumable; needs `GOVINFO_API_KEY`).
- **Rebuilt the cap-and-trade corpus with rule C** (option 2): added a bill-name search to `data/cap-and-trade-congressional-record/scripts/01_search_and_fetch.py` (Waxman-Markey / ACES, Kerry-Boxer / CEJAPA, Kerry-Lieberman / American Power Act, Lieberman-Warner / Climate Security Act, McCain-Lieberman / Climate Stewardship Act) and made step 1 incremental (runs only searches missing from `records.csv`); added rule C to `02_split_and_screen.py` with the energy vocabulary copied verbatim from the IRA corpus. 291 new records; kept speeches 2,133 → 2,331 (+198 bill_energy: 129 in 2009, 30 in 2008). All 2,133 existing speeches unchanged (IDs, rules, text verified). Backups `*.bak-20261023` in the corpus folder.
- Re-ran `data/voteview-nominate/add_nominate.R`: all new speeches matched (still 12 unmatched speeches overall, non-voting delegates and one blank-party record). Backups `*.bak-20261023`.
- `scripts/pilot_sample.R` now drops cap-and-trade `bill_energy` speeches so it still reproduces the original pilot sample (verified identical).
- After the rebuild, share of D/R speeches kept by the climate rules: cap-and-trade window D 73% / R 90%; IRA D 31% / R 8%; OBBB D 31% / R 6%. Window sizes (D/R): cap-and-trade 785, IRA 387, OBBB 109.

### Session 1 — 2026-10-23 (Project set-up)

- Copied the standard project files from the `project-files` template; renamed `template.qmd` → `beliefs-congress-speeches.qmd` and set its title; pointed `_quarto.yaml` and `scripts/export-cited-refs.R` at the new qmd.
- Fixed the template's PDF header: added `\usepackage{ulem}` so `\normalem` compiles (same fix as the cue-WTP project).
- Moved the speech data from `01-RESEARCH/03-data/` into `data/`: `cap-and-trade-congressional-record` (2000–2012, 2,133 speeches), `ira-congressional-record` (2018–2026, 2,079 speeches; includes the OBBB debate), and `voteview-nominate` (DW-NOMINATE/Nokken-Poole matched per speech; moved with the corpora because `add_nominate.R` reads them as sibling folders).
- Created `scripts/analysis.R`: reads both corpus indexes, merges the speech-level DW-NOMINATE scores, and stacks them into `speeches` (4,212 speeches, 696 members); sourced by the qmd setup chunk.
- Initialized `renv` and snapshotted the lockfile (`knitr`, `rmarkdown`; analysis is base R so far).
- Wrote `README.md` and this log; set up `.gitignore` (`/data/`, `/literature/`, `nowlin-style-profile.md`, the `project-file.md` notes file, renamed from `beliefs-congress-speeches.md` to avoid confusion with the qmd, generated bib/CSL).
- Added `wiki/overview/congressional-speeches-paper.md` to the Policy Learning in Congress wiki pointing to this project, and logged it in `wiki/log.md`.
- Rendered HTML, PDF, and DOCX; all three build cleanly.
- Moved `pilot_sample.R` from `../00-policy-learning-congress/scripts/` to `scripts/` and set `data_dir <- "data"`. Verified it reproduces the existing 150-speech pilot sample exactly (same `speech_id`s, same order). It now writes to `output/pilot/pilot_sample.csv` in this project; the `path` column will be relative to this project (`data/...`) rather than `../../03-data/...`.
