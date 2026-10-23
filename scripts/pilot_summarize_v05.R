# Convert the codebook v0.5 re-pilot (JSONL) to the Section 7 CSVs, check the
# codes against the speech files, and summarize the information-source module
# (Section 4b), hedging (Section 4a), and concept prevalence. Compares with the
# v0.4 pilot (same 150 speeches) in the Policy Learning in Congress project.
# Run from the project root after scripts/pilot_sample.R:
#   Rscript scripts/pilot_summarize_v05.R > output/pilot/v0.5/summary_log.txt

library(jsonlite)

pilot_dir <- file.path("output", "pilot")
out_dir   <- file.path(pilot_dir, "v0.5")
v04_dir   <- file.path("..", "00-policy-learning-congress", "output", "pilot", "v0.4")
coder_id  <- "claude-opus-5-5 (in-session, one subagent per 10-speech batch); prompt v0.5"

sample_df <- read.csv(file.path(pilot_dir, "pilot_sample.csv"), stringsAsFactors = FALSE)
meta <- sample_df[, c("speech_id", "bioGuideId", "date", "corpus", "party", "section",
                      "cell", "words", "keep_rule", "path")]

# ---- Parse JSONL --------------------------------------------------------

files <- sort(list.files(file.path(out_dir, "json"), pattern = "\\.jsonl$", full.names = TRUE))
lines <- unlist(lapply(files, readLines, encoding = "UTF-8"))
lines <- lines[nzchar(trimws(lines))]
recs  <- lapply(lines, fromJSON, simplifyVector = FALSE)

nz <- function(x) if (is.null(x) || length(x) == 0) NA else x

speeches <- do.call(rbind, lapply(recs, function(r) data.frame(
  speech_id            = r$speech_id,
  no_codable_content   = r$no_codable_content,
  bill_focus           = nz(r$bill_focus),
  bill_stance          = nz(r$bill_stance),
  speech_focus_climate = nz(r$speech_focus_climate),
  procedural_objection = nz(r$procedural_objection),
  n_sources            = nz(r$n_sources),
  n_sources_listed     = length(r$sources),
  speech_memo          = nz(r$speech_memo),
  stringsAsFactors = FALSE
)))

statements <- do.call(rbind, lapply(recs, function(r) {
  if (!length(r$statements)) return(NULL)
  do.call(rbind, lapply(r$statements, function(s) data.frame(
    speech_id   = r$speech_id,
    concept_id  = s$concept_id,
    agree       = nz(s$agree),
    intensity   = nz(s$intensity),
    hedged      = nz(s$hedged),
    conditional = nz(s$conditional),
    quote       = nz(s$quote),
    confidence  = nz(s$confidence),
    memo        = nz(s$memo),
    stringsAsFactors = FALSE
  )))
}))

sources <- do.call(rbind, lapply(recs, function(r) {
  if (!length(r$sources)) return(NULL)
  do.call(rbind, lapply(r$sources, function(s) data.frame(
    speech_id       = r$speech_id,
    source_id       = nz(s$source_id),
    source_name     = nz(s$source_name),
    source_type     = nz(s$source_type),
    specific        = nz(s$specific),
    evidence_form   = nz(s$evidence_form),
    use             = nz(s$use),
    linked_concepts = paste(unlist(s$linked_concepts), collapse = ";"),
    inserted        = nz(s$inserted),
    quote           = nz(s$quote),
    confidence      = nz(s$confidence),
    memo            = nz(s$memo),
    stringsAsFactors = FALSE
  )))
}))

stopifnot(!anyDuplicated(speeches$speech_id))
stopifnot(setequal(speeches$speech_id, meta$speech_id))

statements <- statements[statements$concept_id != "NONE", ]
statements$coder <- coder_id
sources$coder <- coder_id
speeches <- merge(meta, speeches, by = "speech_id")

write.csv(merge(meta[, c("speech_id", "bioGuideId", "date")], statements, by = "speech_id"),
          file.path(out_dir, "pilot_llm_statements_v05.csv"), row.names = FALSE)
write.csv(merge(meta[, c("speech_id", "bioGuideId", "date")], sources, by = "speech_id"),
          file.path(out_dir, "pilot_llm_sources_v05.csv"), row.names = FALSE)
write.csv(speeches[, setdiff(names(speeches), "path")],
          file.path(out_dir, "pilot_llm_speeches_v05.csv"), row.names = FALSE)

st  <- merge(statements, meta[, c("speech_id", "corpus", "party")], by = "speech_id")
src <- merge(sources,    meta[, c("speech_id", "corpus", "party")], by = "speech_id")

# ---- Validity checks ----------------------------------------------------

squish <- function(x) gsub("\\s+", " ", trimws(x))
speech_text <- setNames(vapply(meta$path, function(p) {
  txt <- readLines(p, warn = FALSE, encoding = "UTF-8")
  squish(paste(txt[-(1:6)], collapse = " "))  # drop the 5-line header + blank line
}, ""), meta$speech_id)
quote_found <- function(id, q) !is.na(q) && grepl(squish(q), speech_text[[id]], fixed = TRUE)

st$quote_ok  <- mapply(quote_found, st$speech_id, st$quote)
src$quote_ok <- mapply(quote_found, src$speech_id, src$quote)
long_q   <- function(q) sapply(strsplit(squish(q), " "), length) > 40
ellipsis <- function(q) grepl("\\.\\.\\.|\\. \\. \\.|\u2026", q)
bad_sign <- with(st, (agree == 1 & intensity < 0) | (agree == 0 & intensity > 0))

coded_pairs  <- paste(st$speech_id, st$concept_id)
link_list    <- strsplit(src$linked_concepts, ";")
orphan_links <- unlist(mapply(function(id, ks) ks[nzchar(ks) & !paste(id, ks) %in% coded_pairs],
                              src$speech_id, link_list))

cat("==== Validity checks ====\n")
cat("Speeches:", nrow(speeches), "| Statements:", nrow(st), "| Sources:", nrow(src),
    "| No codable content:", sum(speeches$no_codable_content), "\n")
cat("Statement quotes not found verbatim:", sum(!st$quote_ok),
    "| > 40 words:", sum(long_q(st$quote)), "| ellipses:", sum(ellipsis(st$quote)), "\n")
cat("Source quotes not found verbatim:", sum(!src$quote_ok),
    "| > 40 words:", sum(long_q(src$quote)), "| ellipses:", sum(ellipsis(src$quote)), "\n")
cat("Intensity sign mismatches:", sum(bad_sign, na.rm = TRUE), "\n")
cat("n_sources != sources listed:", sum(speeches$n_sources != speeches$n_sources_listed, na.rm = TRUE), "\n")
cat("Linked concepts not coded as statements in the same speech:", length(orphan_links), "\n")
if (any(!st$quote_ok))  { cat("\nStatement quotes not found:\n");  print(st[!st$quote_ok, c("speech_id", "concept_id", "quote")]) }
if (any(!src$quote_ok)) { cat("\nSource quotes not found:\n");     print(src[!src$quote_ok, c("speech_id", "source_name", "quote")]) }

# ---- Information sources (Section 4b) -----------------------------------

ids_all <- speeches$speech_id
pct_speeches <- function(ids_with, ids) round(100 * mean(ids %in% ids_with), 1)
grp <- list(all = ids_all,
            CT  = ids_all[speeches$corpus == "CT"],
            IRA = ids_all[speeches$corpus == "IRA"],
            D   = ids_all[speeches$party == "D"],
            R   = ids_all[speeches$party == "R"])

cat("\n==== Information sources ====\n")
cat("Sources per speech: mean", round(nrow(src) / nrow(speeches), 2),
    "| median", median(speeches$n_sources_listed), "| max", max(speeches$n_sources_listed), "\n")
cat("% of speeches with >= 1 source:\n")
print(sapply(grp, function(ids) pct_speeches(unique(src$speech_id), ids)))

types <- c("science", "govt_analysis", "executive", "military_security", "think_tank", "advocacy",
           "business", "labor", "state_local", "international", "media", "constituent",
           "personal", "religious", "other")
type_tab <- data.frame(
  source_type = types,
  n_sources   = sapply(types, function(t) sum(src$source_type == t)),
  t(sapply(types, function(t) sapply(grp, function(ids) pct_speeches(unique(src$speech_id[src$source_type == t]), ids)))),
  pct_specific = sapply(types, function(t) round(100 * mean(src$specific[src$source_type == t] == 1), 0)),
  pct_dispute  = sapply(types, function(t) round(100 * mean(src$use[src$source_type == t] %in% c("dispute", "mixed")), 0)),
  row.names = NULL
)
names(type_tab)[3:7] <- paste0("pct_speeches_", names(grp))
type_tab$meets_5pct <- pmax(type_tab$pct_speeches_CT, type_tab$pct_speeches_IRA) >= 5
unknown_types <- setdiff(unique(src$source_type), types)
write.csv(type_tab, file.path(out_dir, "pilot_source_types_v05.csv"), row.names = FALSE)
cat("\nsource_type (% of speeches with >= 1 source of that type):\n")
print(type_tab, row.names = FALSE)
if (length(unknown_types)) cat("Unlisted source_type values:", unknown_types, "\n")

cat("\nspecific (1 = named) share:", round(mean(src$specific == 1), 3), "\n")
cat("specific by party (share named):\n"); print(round(tapply(src$specific == 1, src$party, mean), 3))
cat("\nevidence_form:\n"); print(table(src$evidence_form, useNA = "ifany"))
cat("\nevidence_form by party (row shares):\n"); print(round(prop.table(table(src$party, src$evidence_form), 1), 3))
cat("\nuse:\n"); print(table(src$use, useNA = "ifany"))
cat("\ninserted = 1:", sum(src$inserted == 1, na.rm = TRUE), "\n")
cat("Sources with no linked concepts:", sum(!nzchar(src$linked_concepts)), "of", nrow(src), "\n")

# Source type x concept tier, from linked_concepts
links <- data.frame(source_type = rep(src$source_type, lengths(link_list)),
                    party = rep(src$party, lengths(link_list)),
                    concept = unlist(link_list), stringsAsFactors = FALSE)
links <- links[nzchar(links$concept), ]
links$tier <- substr(links$concept, 1, 2)
cat("\nLinks: source_type x concept tier:\n"); print(table(links$source_type, links$tier))
cat("\nMost-linked concepts by source_type (top 3):\n")
for (t in intersect(types, unique(links$source_type))) {
  x <- sort(table(links$concept[links$source_type == t]), decreasing = TRUE)
  cat(sprintf("  %-17s %s\n", t, paste(names(x)[1:min(3, length(x))], x[1:min(3, length(x))], sep = " ", collapse = ", ")))
}
cat("\nMost frequent source names (normalized to lower case):\n")
print(head(sort(table(tolower(squish(src$source_name))), decreasing = TRUE), 25))

# ---- Hedging (Section 4a) -----------------------------------------------

hedge_re <- paste0("\\b(may|might|could|perhaps|possibly|probably|likely|unlikely|somewhat|seemingly|",
                   "uncertain|I think|I suspect|I guess|it appears|it seems|to some extent|",
                   "as I understand it|not sure|not certain)\\b|\\bI believe\\b(?! in\\b)")
boost_re <- paste0("\\b(clearly|certainly|undeniably|undoubtedly|obviously|without question|no doubt|",
                   "beyond doubt|the fact is|it is a fact|the simple truth is|the reality is|the truth is|",
                   "make no mistake|let me be clear|let there be no mistake|everyone knows|",
                   "there is no dispute|no one disputes|there is no question|this isn't hypothetical|",
                   "it is simply|never|always|absolutely)\\b")
count_re <- function(x, re) vapply(gregexpr(re, x, perl = TRUE, ignore.case = TRUE),
                                   function(m) sum(m > 0), 0L)
# "may" is matched case-insensitively; month names are rare in quotes but
# common in speech text, so speech-level counts drop "May <digit>" dates first.
undate <- function(x) gsub("\\bMay \\d", "", x)

st$q_hedges  <- count_re(st$quote, hedge_re)
st$q_boosts  <- count_re(st$quote, boost_re)
speeches$hedges_per_1k <- round(1000 * count_re(undate(speech_text[speeches$speech_id]), hedge_re) / speeches$words, 2)
speeches$boosts_per_1k <- round(1000 * count_re(undate(speech_text[speeches$speech_id]), boost_re) / speeches$words, 2)
write.csv(speeches[, c("speech_id", "corpus", "party", "words", "hedges_per_1k", "boosts_per_1k")],
          file.path(out_dir, "pilot_dictionary_v05.csv"), row.names = FALSE)

sci <- st$concept_id %in% c("PC1", "PC2", "PC3")
cat("\n==== Hedging ====\n")
cat("hedged = 1 share of statements:", round(mean(st$hedged == 1), 3), "\n")
cat("hedged share by party:\n"); print(round(tapply(st$hedged == 1, st$party, mean), 3))
cat("hedged share, PC1-PC3, by party (n):\n")
print(round(tapply(st$hedged[sci] == 1, st$party[sci], mean), 3)); print(table(st$party[sci]))
cat("\nCoded hedged vs. dictionary hedge in the quote (rows: hedged; cols: any dictionary hedge):\n")
print(table(hedged = st$hedged, dict_hedge = st$q_hedges > 0))
hs <- tapply(st$hedged == 1, st$speech_id, mean)
cat("Speech-level correlation, share of hedged statements vs. dictionary hedges per 1k words:",
    round(cor(hs, speeches$hedges_per_1k[match(names(hs), speeches$speech_id)]), 2), "\n")
cat("\nDictionary rates per 1,000 words by party (mean):\n")
print(round(sapply(split(speeches[, c("hedges_per_1k", "boosts_per_1k")], speeches$party), colMeans), 2))
cat("\nDictionary rates per 1,000 words by corpus (mean):\n")
print(round(sapply(split(speeches[, c("hedges_per_1k", "boosts_per_1k")], speeches$corpus), colMeans), 2))

# ---- Concept prevalence (Section 8 criterion) ---------------------------

concepts <- c(paste0("DC", 1:6), paste0("PC", 1:12), paste0("SC", 1:13))
pct_has  <- function(k, ids) pct_speeches(unique(st$speech_id[st$concept_id == k]), ids)
prev <- data.frame(
  concept      = concepts,
  n_stmts      = sapply(concepts, function(k) sum(st$concept_id == k)),
  pct_all      = sapply(concepts, pct_has, ids = grp$all),
  pct_CT       = sapply(concepts, pct_has, ids = grp$CT),
  pct_IRA      = sapply(concepts, pct_has, ids = grp$IRA),
  pct_D        = sapply(concepts, function(k) round(100 * mean(st$party[st$concept_id == k] == "D"), 0)),
  pct_disagree = sapply(concepts, function(k) round(100 * mean(st$agree[st$concept_id == k] == 0), 0)),
  pct_hedged   = sapply(concepts, function(k) round(100 * mean(st$hedged[st$concept_id == k] == 1), 0)),
  row.names = NULL
)
prev$meets_5pct <- pmax(prev$pct_CT, prev$pct_IRA) >= 5
write.csv(prev, file.path(out_dir, "pilot_concept_prevalence_v05.csv"), row.names = FALSE)
cat("\n==== Concept prevalence (% of speeches with >= 1 statement) ====\n")
print(prev, row.names = FALSE)
codable <- speeches$no_codable_content == 0
cat("\nStatements per codable speech:", round(nrow(st) / sum(codable), 2), "\n")
cat("bill_focus = none:", sum(speeches$bill_focus == "none", na.rm = TRUE), "\n")

# ---- Comparison with v0.4 -----------------------------------------------
# The concept definitions are identical in v0.4 and v0.5, so presence agreement
# is a re-code stability check (different subagent coders, same model), not
# inter-coder reliability.

v4 <- read.csv(file.path(v04_dir, "pilot_llm_statements_v04.csv"), stringsAsFactors = FALSE)
v4 <- v4[v4$concept_id != "NONE", ]
v4 <- merge(v4, meta[, c("speech_id", "party")], by = "speech_id")
kappa <- function(x, y) {
  lev <- sort(unique(c(x, y)))
  tb <- table(factor(x, lev), factor(y, lev)); n <- sum(tb)
  po <- sum(diag(tb)) / n; pe <- sum(rowSums(tb) * colSums(tb)) / n^2
  if (pe == 1) NA else (po - pe) / (1 - pe)
}
present <- function(d, k) ids_all %in% unique(d$speech_id[d$concept_id == k])
signed  <- function(d, k) sapply(ids_all, function(i) {
  a <- d$agree[d$speech_id == i & d$concept_id == k]
  if (!length(a)) 0L else if (length(unique(a)) > 1) 0L else if (a[1] == 1) 1L else -1L
})
cmp <- data.frame(concept = concepts,
                  pct_all_v04 = sapply(concepts, function(k) pct_speeches(unique(v4$speech_id[v4$concept_id == k]), ids_all)),
                  pct_all_v05 = prev$pct_all,
                  kappa_presence = sapply(concepts, function(k) round(kappa(present(v4, k), present(st, k)), 2)),
                  kappa_signed   = sapply(concepts, function(k) round(kappa(signed(v4, k), signed(st, k)), 2)),
                  row.names = NULL)
write.csv(cmp, file.path(out_dir, "v04_v05_comparison.csv"), row.names = FALSE)

v4_sci <- v4$concept_id %in% c("PC1", "PC2", "PC3")
cat("\n==== v0.4 vs v0.5 ====\n")
cat("Statements:", nrow(v4), "->", nrow(st), "\n")
cat("Hedged share (v0.4 speaker_certainty = 1 vs. v0.5 hedged = 1):",
    round(mean(v4$speaker_certainty == 1), 3), "->", round(mean(st$hedged == 1), 3), "\n")
cat("Hedged share on PC1-PC3 by party, v0.4:\n")
print(round(tapply(v4$speaker_certainty[v4_sci] == 1, v4$party[v4_sci], mean), 3))
cat("Hedged share on PC1-PC3 by party, v0.5:\n")
print(round(tapply(st$hedged[sci] == 1, st$party[sci], mean), 3))
cat("\nConcept presence/stance agreement with v0.4 (kappa):\n")
print(cmp, row.names = FALSE)
cat("\nMedian kappa (presence):", median(cmp$kappa_presence, na.rm = TRUE),
    "| Median kappa (signed):", median(cmp$kappa_signed, na.rm = TRUE), "\n")

cat("\nCoder:", coder_id, "\nR version:", R.version.string, "\n")
