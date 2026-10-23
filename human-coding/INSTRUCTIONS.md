---
title: Instructions for Coders
subtitle: Beliefs and Information Sources in Congressional Floor Speeches (codebook v0.5)
---

# What this study is

You will read floor speeches from the *Congressional Record* (2000–2025) on climate and energy policy and record two things:

1. **Belief statements:** the speaker's own positions on a fixed list of 31 concepts (values, beliefs about the climate problem, and policy instruments).
2. **Information sources:** the external sources the speaker invokes as evidence or authority (scientists, CBO, a constituent, a newspaper, and so on).

Two coders code the same speeches independently. We compare your codes with each other and with codes produced by a language model to see whether the codebook can be applied reliably. **Disagreements are useful data.** Code what you see in the text; do not try to guess what the other coder will do.

# What is in this folder

| Item | What it is |
|---|---|
| `INSTRUCTIONS.md` / `.docx` | This document |
| `codebook/codebook-v0.5` (`.md`, `.html`, `.docx`) | The codebook. Same content in three formats; use whichever is easiest to read |
| `practice/` | 4 practice speeches (`P1`–`P4`) |
| `practice-sheet_A.xlsx`, `practice-sheet_B.xlsx` | Spreadsheets for the practice speeches |
| `speeches/` | The 54 speeches to code, numbered `01`–`54` in coding order |
| `coding-sheet_A.xlsx`, `coding-sheet_B.xlsx` | Spreadsheets for the 54 speeches. **Use only the one with your letter** |
| `manifest.csv` | Speech metadata for the project lead. You do not need it |

# Rules for independence

- **Do not discuss speeches, codes, or the codebook with the other coder** until both of you have returned your sheets. Send questions to the project lead instead (see below).
- **Do not use AI tools** (ChatGPT, Claude, Copilot, etc.) to read, summarize, or code speeches.
- **Do not look up** the speaker's votes, party positions, or other speeches. Code only from the text in front of you. The speaker's party appears in each file's header; do not use it to infer positions (codebook §3).
- Code the speeches **in numbered order**, and do not go back to change a finished speech because of something you saw later. If you think an earlier code was wrong, add a note to that speech's `speech_memo` that starts with `REVISIT:` and leave the code as it is.

# Step 1: Training (about 3 hours)

1. Read codebook **§§1–6** closely. §7 (output format) is summarized below. §§8–10 describe the study design and LLM prompt, and you can skip them.
2. Pay special attention to:
   - §3, what counts as the speaker's own position
   - §3a, inserted material
   - the **boundary anchors** for DC1, DC4, PC4, and SC4 at the end of §4
   - §4a, hedging
   - §4b, information sources
   - §5, borderline cases
3. Code the 4 practice speeches in your `practice-sheet` workbook.
4. Meet with the project lead (and the other coder) to go over the practice codes. **Practice is the only time coders discuss codes.**

# Step 2: Coding

For each speech, in order:

1. Open the speech file in `speeches/`. Each file starts with a header (speaker, date, chamber, title, and source URL). The header is not part of the speech and is not coded.
2. Read the whole speech once without coding.
3. Fill in its row on the **`speeches`** sheet. The row is already there; `order`, `file`, `speech_id`, and `coder` are pre-filled.
4. Add one row on the **`statements`** sheet for each belief statement.
5. Add one row on the **`sources`** sheet for each information source.
6. Record the minutes you spent on the speech in `minutes`, and set `done` = 1.

**Expect roughly 15–25 minutes per speech.** Speeches range from 150 to about 7,200 words (about 54,000 words in all), so plan for roughly **15–20 hours** spread over several sessions. Take a break at least every 90 minutes; coding quality drops with fatigue.

## The `speeches` sheet (codebook §6)

| Column | Enter |
|---|---|
| `no_codable_content` | 1 if the speech is procedural or has no codable climate/energy content; otherwise 0. If 1, leave the other columns blank and add no statement or source rows |
| `bill_focus` | The bill or debate the speech is about (dropdown). Use `none` if no bill is in view |
| `bill_stance` | support · oppose · mixed · none, toward the bill in `bill_focus` |
| `speech_focus_climate` | 1 if climate/energy is the main subject; 0 if it is a passing mention |
| `procedural_objection` | 1 if the speaker objects mainly on procedural grounds |
| `n_sources` | Number of rows you entered on the `sources` sheet for this speech (0 if none) |
| `speech_memo` | Free text: bill name if `other`, `NEW:` concept suggestions, `DATA:` problems with the file (e.g., `DATA: speaker split` if another Member's remarks appear), `REVISIT:` notes, `Q:` questions |
| `minutes` | Minutes spent on the speech |
| `done` | 1 when finished |

## The `statements` sheet (codebook §§3–4a)

One row per **concept × stance** per speech. If the speaker states the same position several times, enter it **once** and use the clearest passage. If the speaker takes both stances on a concept, enter two rows (agree and disagree).

| Column | Enter |
|---|---|
| `speech_id` | Pick from the dropdown (it lists the 54 IDs; the ID is in the file name after the number) |
| `concept_id` | Pick from the dropdown; the `concepts` sheet lists every proposition |
| `agree` | 1 = agrees with the proposition; 0 = disagrees |
| `intensity` | −2, −1, +1, or +2. The sign must match `agree` (agree → +1/+2; disagree → −1/−2) |
| `hedged` | 1 if the speaker qualifies their own stance (§4a); otherwise 0 |
| `conditional` | 1 if the stance is conditional ("I could support a cap if China did the same"); otherwise 0 |
| `quote` | The passage that shows the stance (rules below) |
| `confidence` | How sure **you** are of this code: 1 = unsure, 2 = fairly sure, 3 = sure |
| `memo` | Optional notes, e.g., `all-of-the-above`, `constraint`, `Q:` questions |

## The `sources` sheet (codebook §4b)

One row per **source** per speech. If a source is cited several times, enter it once with every linked concept.

| Column | Enter |
|---|---|
| `speech_id` | Dropdown |
| `source_id` | S1, S2, S3… numbered within each speech |
| `source_name` | As named in the speech: "IPCC", "CBO", "a dairy farmer in Wisconsin", "scientists" |
| `source_type` | Dropdown (17 types; §4b). Includes `expert_generic` for unattributed expert claims |
| `specific` | 1 = named organization, document, or person; 0 = generic ("studies show") |
| `evidence_form` | quantitative · finding · testimony · position |
| `use` | support (the speaker relies on it) · dispute (attacks it) · mixed |
| `linked_concepts` | Concept IDs the source is used for, separated by semicolons (e.g., `PC4;DC4`). Use only concepts you also entered as statements for this speech. Leave blank if none |
| `inserted` | 1 if the source is inserted material the speaker introduces (§3a) |
| `quote` | The passage naming or invoking the source |
| `confidence` | 1–3 |
| `memo` | e.g., `hearing witness`, `via inserted editorial`, unresolved type |

## Quotes

- **Copy and paste** from the speech file. Do not retype, correct spelling, or fix line breaks. Quotes are matched to the text by computer, so they must be exact.
- One **continuous** passage, **at most 40 words**, with **no ellipses** (…). If the stance needs more than 40 words, pick the 40 that show it most clearly.
- The quote must be the speaker's own words, not inserted material (§3a), except for source rows with `inserted` = 1.

## Using the spreadsheet

- Keep the column order and headers as they are. Do not add, rename, or delete sheets or columns.
- Use the dropdowns. If Excel rejects a value, the value is not allowed; check the codebook.
- Leave rows for a speech together if you can, but order does not matter: every row carries its `speech_id`.
- The sheets work in Excel, Google Sheets, and LibreOffice. If you use Google Sheets, download as `.xlsx` when you return it.
- **Save often** and keep a backup copy.

# Questions

- When you are unsure about a code, **make your best call from the codebook**, set `confidence` = 1, and explain in `memo` starting with `Q:`. Do not leave the code out because you are unsure.
- If a question blocks you (for example, a rule you cannot apply at all), email the project lead. Answers that change how the codebook is applied will be sent to **both** coders in writing, so you keep working from the same rules.

# Returning your work

When all 54 speeches have `done` = 1:

1. Check that `n_sources` matches the number of `sources` rows for each speech.
2. Rename the file `coding-sheet_<letter>_<your initials>.xlsx`.
3. Email it to the project lead, Matthew Nowlin.

Thank you. Careful, independent coding is what makes this test meaningful.
