# Belief Systems and Climate Change Discourse in the US Congress

Manuscript and reproducible analysis examining whether belief systems can be
measured from floor speeches in the US Congress. The paper uses speeches from
three climate and energy debates (cap-and-trade, the Inflation Reduction Act,
and the One Big Beautiful Bill Act) to ask:

- **RQ1:** Can beliefs be measured as probability distributions using
  congressional floor speeches? Beliefs span the deep core (also measured by
  DW-NOMINATE), the policy core (beliefs about climate change), and secondary
  beliefs (policy instruments and specific legislation).
- **RQ2:** What information sources did members cite in these speeches?
- **RQ3:** Which beliefs and information sources were salient in each of the
  three periods, and how can the periods be compared?

## Layout

```
beliefs-congress-speeches.qmd        Manuscript source (renders to HTML, PDF, DOCX)
_quarto.yaml                         Quarto project config
_output/                             Rendered HTML/PDF/DOCX (tracked in git)
custom-reference-doc.docx            Word reference template used for the DOCX output
LOG.md                               Running session log (newest entry first)
renv.lock, renv/, .Rprofile          renv project library (R package versions)
codebook/
  codebook-v0.5.md                   Coding scheme for beliefs (concepts, intensity, hedging)
                                       and information sources (RQ2)
  prompt_v0.5.txt                    Final LLM coding prompt, generated from codebook sections 3-6
                                       (the re-pilot's draft prompt is in output/pilot/v0.5/)
scripts/
  analysis.R                         Sourced by the qmd: loads the speech corpora and
                                       DW-NOMINATE scores and builds the objects used
                                       in tables, figures, and inline R
  export-cited-refs.R                Pre-render step: trims the master .bib to cited keys
  pilot_sample.R                     Draws the 150-speech stratified pilot sample
                                       (seed 20260928) -> output/pilot/pilot_sample.csv
  pilot_summarize_v05.R              Validates and summarizes the codebook v0.5 re-pilot
  human_coding_setup.R               Builds human-coding/ (seed 20261023)
human-coding/                        Packet for the human reliability study: INSTRUCTIONS,
                                       codebook v0.5 (md/html/docx), 54 speeches + 4 practice,
                                       one coding workbook per coder (A, B), manifest.csv
output/pilot/v0.5/                   Codebook v0.5 re-pilot: batch manifests, raw JSONL
                                       codes, CSVs, summary log, pilot-report-v05.md
data/                                Speech corpora and DW-NOMINATE (NOT in git -- see below)
literature/                          Background literature (NOT in git -- local only)
```

## Reproducing the analysis

R package versions are recorded with `renv`. From the project root:

```r
renv::restore()
```

- **Manuscript:** `quarto render` → outputs to `_output/`
  (HTML, PDF, and DOCX; the DOCX uses `custom-reference-doc.docx`)
- **Analysis only:** `Rscript scripts/analysis.R`

## Data

The `data/` folder is **not tracked in git**. Restore it before rendering.
Each folder has its own `README.md` documenting how it was built.

- `data/cap-and-trade-congressional-record/` — Congressional Record floor
  speeches, debate turns, and Extensions of Remarks on climate change or
  cap-and-trade, 2000–2012 (2,331 kept speeches; `index.csv` has one row per
  speech, `speeches/{year}/` holds the text). Built from GovInfo's CREC
  collection.
- `data/ira-congressional-record/` — companion corpus, 2018–2026, covering
  climate change and the energy/climate side of Build Back Better, the IRA,
  the OBBB, and the Green New Deal (2,079 kept speeches).
- **Screening rules are the same in both corpora:** A (dense climate terms),
  B (titled), and C (names the period's climate bill and is energy-dense, with
  an identical energy vocabulary). Rule C was added to the cap-and-trade
  corpus on 2026-10-23 (cap-and-trade-era bills: Waxman-Markey, Kerry-Boxer,
  Kerry-Lieberman, Lieberman-Warner, McCain-Lieberman). `keep_rule` records
  which rule kept each speech; `climate_rule` in `scripts/analysis.R` flags
  A/B.
- `data/voteview-nominate/` — DW-NOMINATE and Nokken-Poole scores (Voteview)
  matched to every speech (`{captrade,ira}_speech_nominate.csv`, joined to
  `index.csv` on `speech_id`). `add_nominate.R` expects the two corpora to be
  sibling folders.

## Related project

This paper is connected to the Policy Learning in Congress research wiki,
which holds the theoretical background (Bayesian belief-distribution model of
policy learning) and the pilot coding of these speeches (codebook v0.4).
Findings from this paper are fed back to that wiki as sources.

## Notes

- `references.bib` and the local `.csl` are generated at render time by the
  pre-render step (`export-cited-refs.R`) from the master bibliography, so
  they are git-ignored.
- `_output/` **is tracked in git** so the rendered manuscript is available
  without re-running R/Quarto. Re-render (`quarto render`) after any change to
  `beliefs-congress-speeches.qmd` or `scripts/analysis.R` and commit the
  updated files in `_output/` alongside the source change.
- Quarto's freeze cache (`_freeze/`) is enabled (`execute: freeze: auto` in
  `_quarto.yaml`), so code chunks are only re-executed when the qmd changes.
- `LOG.md` records what changed and why for each work session; add a new
  entry at the top rather than editing manuscript prose notes into commit
  messages.
