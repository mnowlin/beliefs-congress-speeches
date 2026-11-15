# Assemble the full-coding output (JSONL, one file per batch) into the three
# data files of codebook v0.5 section 7, and write the lists of cases set
# aside for review after coding.
# Run from the project root, after scripts/coding_check.R:
#   Rscript scripts/coding_assemble.R
#
# Reads  output/coding/json/*.jsonl, coding_sample.csv, validation_sample.csv
# Writes output/coding/
#   llm_statements.csv   one row per coded statement
#   llm_sources.csv      one row per source per speech
#   llm_speeches.csv     one row per speech: metadata + speech-level codes
#   review/*.csv         cases flagged during coding (see the end of the script)
#
# The raw JSONL is never changed. Two things are derived here rather than
# taken from the coder:
#   set                  "window" (the analysis sample) or "validation" (the
#                        human-coding speeches outside the debate windows)
#   no_content_derived   1 if the speech has no coded statement. Coders were
#                        not consistent about no_codable_content when a speaker
#                        only inserted a document or stated a bill stance, so
#                        the analysis uses this derived flag.

library(jsonlite)

out_dir  <- file.path("output", "coding")
rev_dir  <- file.path(out_dir, "review")
dir.create(rev_dir, showWarnings = FALSE)
coder_id <- "claude-opus-5-5 (in-session, one subagent per batch); prompt v0.5 md5 8c9ad5d7"

# ---- Metadata -------------------------------------------------------------
win <- read.csv(file.path(out_dir, "coding_sample.csv"), stringsAsFactors = FALSE)
val <- read.csv(file.path(out_dir, "validation_sample.csv"), stringsAsFactors = FALSE)
win$set <- "window"
val$set <- "validation"
meta <- rbind(win, val)
stopifnot(!anyDuplicated(meta$speech_id))

# ---- Parse JSONL ----------------------------------------------------------
files <- sort(list.files(file.path(out_dir, "json"), pattern = "\\.jsonl$",
                         full.names = TRUE))
recs <- list()
for (f in files) {
  lines <- readLines(f, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nzchar(trimws(lines))]
  for (l in lines) {
    r <- fromJSON(l, simplifyVector = FALSE)
    r$coding_batch <- sub("\\.jsonl$", "", basename(f))
    recs[[length(recs) + 1]] <- r
  }
}
ids <- vapply(recs, function(r) r$speech_id, "")
stopifnot(!anyDuplicated(ids), all(ids %in% meta$speech_id))

nz  <- function(x) if (is.null(x) || length(x) == 0) NA else x
chr <- function(x) if (is.null(x) || length(x) == 0) "" else as.character(x)

speeches <- do.call(rbind, lapply(recs, function(r) data.frame(
  speech_id            = r$speech_id,
  coding_batch         = r$coding_batch,
  no_codable_content   = nz(r$no_codable_content),
  bill_focus           = nz(r$bill_focus),
  bill_stance          = nz(r$bill_stance),
  speech_focus_climate = nz(r$speech_focus_climate),
  procedural_objection = nz(r$procedural_objection),
  n_sources            = length(r$sources),
  n_statements         = sum(vapply(r$statements, function(s)
                           !identical(s$concept_id, "NONE"), logical(1))),
  speech_memo          = chr(r$speech_memo),
  stringsAsFactors = FALSE)))
speeches$no_content_derived <- as.integer(speeches$n_statements == 0)
speeches$data_flag <- as.integer(grepl("DATA", speeches$speech_memo))
speeches$new_flag  <- as.integer(grepl("NEW:", speeches$speech_memo))

statements <- do.call(rbind, lapply(recs, function(r) {
  st <- Filter(function(s) !identical(s$concept_id, "NONE"), r$statements)
  if (!length(st)) return(NULL)
  do.call(rbind, lapply(st, function(s) data.frame(
    speech_id = r$speech_id, concept_id = s$concept_id, agree = nz(s$agree),
    intensity = nz(s$intensity), hedged = nz(s$hedged),
    conditional = nz(s$conditional), quote = chr(s$quote),
    confidence = nz(s$confidence), memo = chr(s$memo),
    stringsAsFactors = FALSE)))
}))

sources <- do.call(rbind, lapply(recs, function(r) {
  if (!length(r$sources)) return(NULL)
  do.call(rbind, lapply(r$sources, function(s) data.frame(
    speech_id = r$speech_id, source_id = chr(s$source_id),
    source_name = chr(s$source_name), source_type = chr(s$source_type),
    specific = nz(s$specific), evidence_form = chr(s$evidence_form),
    use = chr(s$use), consensus = chr(s$consensus),
    linked_concepts = paste(unlist(s$linked_concepts), collapse = ";"),
    inserted = nz(s$inserted), quote = chr(s$quote),
    confidence = nz(s$confidence), memo = chr(s$memo),
    stringsAsFactors = FALSE)))
}))

key <- meta[, c("speech_id", "bioGuideId", "date", "set")]
statements <- merge(key, statements, by = "speech_id")
sources    <- merge(key, sources, by = "speech_id")
statements$coder <- coder_id
sources$coder    <- coder_id
speeches <- merge(meta[, setdiff(names(meta), "path")], speeches, by = "speech_id")
speeches <- speeches[order(speeches$set, speeches$coding_order), ]

write.csv(statements, file.path(out_dir, "llm_statements.csv"), row.names = FALSE)
write.csv(sources,    file.path(out_dir, "llm_sources.csv"),    row.names = FALSE)
write.csv(speeches,   file.path(out_dir, "llm_speeches.csv"),   row.names = FALSE)

# ---- Review lists ---------------------------------------------------------
# Cases set aside during coding. Each list is for a human decision; nothing is
# recoded here.
has <- function(pattern, ...) grepl(pattern, paste(...), ignore.case = TRUE)
src_cols <- c("speech_id", "set", "date", "source_id", "source_name",
              "source_type", "consensus", "use", "evidence_form",
              "linked_concepts", "confidence", "quote", "memo")
st_cols  <- c("speech_id", "set", "date", "concept_id", "agree", "intensity",
              "confidence", "quote", "memo")

# 1. Science sources not linked to PC1-PC3: candidates for reclassification
#    (university economic studies, health associations, law journals).
sci <- sources[sources$source_type == "science", ]
sci$links_pc123 <- grepl("(^|;)PC[123](;|$)", sci$linked_concepts)
sci$new_source_type <- ""   # to be filled in by hand
write.csv(sci[!sci$links_pc123, c(src_cols, "new_source_type")],
          file.path(rev_dir, "science_not_climate.csv"), row.names = FALSE)

# 2. Consensus cases the rule did not settle: every dissenting source, plus
#    1970s cooling predictions and the "Climategate" emails however coded.
cons <- sources[sources$consensus == "dissenting" |
                  has("cooling|ice age|climategate|climate-gate|east anglia|hacked|leaked",
                      sources$source_name, sources$quote, sources$memo), ]
write.csv(cons[, src_cols], file.path(rev_dir, "consensus_review.csv"),
          row.names = FALSE)

# 3. Methane fee / waste emissions charge: coded SC2, SC3, or not at all.
meth_st <- statements[has("methane|waste emissions charge|natural gas tax",
                          statements$quote, statements$memo), ]
write.csv(meth_st[, st_cols], file.path(rev_dir, "methane_fee_statements.csv"),
          row.names = FALSE)
meth_sp <- speeches[has("methane fee|methane emissions|waste emissions charge|natural gas tax",
                        speeches$speech_memo), ]
write.csv(meth_sp[, c("speech_id", "set", "date", "member_name", "speech_memo")],
          file.path(rev_dir, "methane_fee_speech_memos.csv"), row.names = FALSE)

# 4. Sources whose type the coder marked as unresolved, and everything typed
#    "other" (individual economists, former officials, historical figures).
unres <- sources[sources$source_type == "other" |
                   has("unresolved|unclear|could be|could also|arguabl|alternative|does not fit|doesn't fit|no clear",
                       sources$memo), ]
write.csv(unres[, src_cols], file.path(rev_dir, "source_type_unresolved.csv"),
          row.names = FALSE)

# 5. Speech-level flags from speech_memo.
sp_cols <- c("speech_id", "set", "coding_batch", "date", "member_name", "party",
             "window", "words", "bill_focus", "bill_stance", "n_statements",
             "n_sources", "speech_memo")
write.csv(speeches[speeches$data_flag == 1, sp_cols],
          file.path(rev_dir, "data_flags.csv"), row.names = FALSE)
write.csv(speeches[speeches$new_flag == 1, sp_cols],
          file.path(rev_dir, "new_concept_flags.csv"), row.names = FALSE)

# 6. bill_focus inferred rather than stated, and cra-epa rider speeches (where
#    bill_stance records the stance on the rider).
infer <- speeches[has("infer|not named|never names|unnamed|does not name|doesn't name|from the date|from context|by context",
                      speeches$speech_memo), ]
write.csv(infer[, sp_cols], file.path(rev_dir, "bill_focus_inferred.csv"),
          row.names = FALSE)
write.csv(speeches[speeches$bill_focus %in% "cra-epa", sp_cols],
          file.path(rev_dir, "cra_epa_speeches.csv"), row.names = FALSE)

# 7. Speeches where the coder's no_codable_content disagrees with the derived
#    flag (no statements coded).
mis <- speeches[speeches$no_codable_content != speeches$no_content_derived, ]
write.csv(mis[, c(sp_cols, "no_codable_content", "no_content_derived")],
          file.path(rev_dir, "no_content_mismatch.csv"), row.names = FALSE)

# ---- Summary --------------------------------------------------------------
cat("Speeches coded:", nrow(speeches), "of", nrow(meta), "\n")
print(table(set = speeches$set))
cat("Statements:", nrow(statements), "| Sources:", nrow(sources), "\n")
cat("No coded statements (no_content_derived):", sum(speeches$no_content_derived),
    "| coder's no_codable_content:", sum(speeches$no_codable_content), "\n")
cat("\nReview lists (rows):\n")
for (f in sort(list.files(rev_dir, pattern = "\\.csv$"))) {
  cat(sprintf("  %-34s %d\n", f, nrow(read.csv(file.path(rev_dir, f)))))
}
cat("\nR version:", R.version.string, "\n")
