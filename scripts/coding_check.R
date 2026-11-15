# Check the full-coding output (JSONL, one file per batch) against the batch
# manifests, the codebook's allowed values, and the speech files.
# Run from the project root: Rscript scripts/coding_check.R
#
# Reads  output/coding/batches/*.txt  and  output/coding/json/*.jsonl
# Writes output/coding/check_problems.csv  (one row per problem found)
#        output/coding/check_batches.csv   (one row per batch: status, counts)
# A batch is "ok" when every speech in its manifest has exactly one valid
# record and no problem is found. Batches with problems are re-coded or fixed
# by hand; nothing is changed by this script.

library(jsonlite)

out_dir <- file.path("output", "coding")

# ---- Allowed values (codebook v0.5 final, revised 2026-11-13) -------------
cb <- readLines(file.path("codebook", "codebook-v0.5.md"), encoding = "UTF-8")
crow <- grep("^\\| \\*\\*(DC|PC|SC)[0-9]+", cb, value = TRUE)
concepts <- unique(sub("^\\| \\*\\*((DC|PC|SC)[0-9]+).*", "\\1", crow))
source_types <- c("science", "govt_analysis", "executive", "military_security",
                  "think_tank", "advocacy", "business", "state_local",
                  "international", "courts", "congress", "media",
                  "public_opinion", "constituent", "personal", "expert_generic",
                  "other")
bill_focus <- c("waxman-markey", "lieberman-warner", "kerry-boxer",
                "mccain-lieberman", "other-captrade", "epact-2003", "epact-2005",
                "eisa-2007", "energy-bill-other", "gnd", "climate-action-now",
                "ajp", "bbb", "ira", "lower-energy-costs", "obbb", "cra-epa",
                "appropriations", "budget", "nomination", "other-bill", "none")
speech_fields <- c("speech_id", "no_codable_content", "bill_focus", "bill_stance",
                   "speech_focus_climate", "procedural_objection", "n_sources",
                   "speech_memo", "statements", "sources")
stmt_fields <- c("concept_id", "agree", "intensity", "hedged", "conditional",
                 "quote", "confidence", "memo")
src_fields <- c("source_id", "source_name", "source_type", "specific",
                "evidence_form", "use", "consensus", "linked_concepts",
                "inserted", "quote", "confidence", "memo")

# ---- Helpers ---------------------------------------------------------------
squish <- function(x) gsub("\\s+", " ", trimws(x))
read_speech <- function(path) {
  txt <- readLines(path, warn = FALSE, encoding = "UTF-8")
  squish(paste(txt[-(1:6)], collapse = " "))  # drop the 5-line header + blank line
}
n_words  <- function(q) length(strsplit(squish(q), " ")[[1]])
ellipsis <- function(q) grepl("\\.\\.\\.|\\. \\. \\.|\u2026", q)
one <- function(x) if (is.null(x) || length(x) != 1) NA else x

problems <- list()
add <- function(batch, speech_id, where, problem) {
  problems[[length(problems) + 1]] <<- data.frame(
    batch = batch, speech_id = speech_id, where = where, problem = problem,
    stringsAsFactors = FALSE)
}

check_quote <- function(batch, id, where, q, text) {
  if (is.na(one(q)) || !nzchar(q)) return(add(batch, id, where, "quote missing"))
  # A word hyphenated across a line break reads "cap- and-trade" once lines are
  # joined; a quote that restores "cap-and-trade" still counts as verbatim.
  dehyph <- function(x) gsub("- ", "-", x, fixed = TRUE)
  if (!grepl(squish(q), text, fixed = TRUE) &&
      !grepl(dehyph(squish(q)), dehyph(text), fixed = TRUE))
    add(batch, id, where, "quote not verbatim")
  if (n_words(q) > 40) add(batch, id, where, "quote over 40 words")
  if (ellipsis(q)) add(batch, id, where, "quote has an ellipsis")
}

# ---- Check each batch ------------------------------------------------------
manifests <- sort(list.files(file.path(out_dir, "batches"), pattern = "\\.txt$"))
summary_rows <- list()

for (m in manifests) {
  batch <- sub("\\.txt$", "", m)
  man <- read.delim(file.path(out_dir, "batches", m), header = FALSE,
                    col.names = c("speech_id", "path"), stringsAsFactors = FALSE)
  jf <- file.path(out_dir, "json", paste0(batch, ".jsonl"))
  if (!file.exists(jf)) {
    summary_rows[[batch]] <- data.frame(batch = batch, status = "not coded",
      speeches = nrow(man), coded = 0, statements = 0, sources = 0, problems = 0)
    next
  }
  n_before <- length(problems)
  lines <- readLines(jf, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nzchar(trimws(lines))]
  recs <- lapply(seq_along(lines), function(i) tryCatch(
    fromJSON(lines[i], simplifyVector = FALSE),
    error = function(e) { add(batch, NA, paste("line", i), "invalid JSON"); NULL }))
  recs <- Filter(Negate(is.null), recs)
  ids <- vapply(recs, function(r) as.character(one(r$speech_id)), "")

  for (id in setdiff(man$speech_id, ids)) add(batch, id, "speech", "missing from output")
  for (id in setdiff(ids, man$speech_id)) add(batch, id, "speech", "not in manifest")
  for (id in unique(ids[duplicated(ids)])) add(batch, id, "speech", "coded more than once")

  n_st <- 0; n_src <- 0
  for (r in recs) {
    id <- as.character(one(r$speech_id))
    if (!id %in% man$speech_id) next
    text <- read_speech(man$path[match(id, man$speech_id)])
    for (f in setdiff(speech_fields, names(r))) add(batch, id, "speech", paste("field missing:", f))
    if (!isTRUE(one(r$no_codable_content) %in% 0:1)) add(batch, id, "speech", "no_codable_content not 0/1")
    ncc <- isTRUE(one(r$no_codable_content) == 1)
    if (!ncc) {
      if (!isTRUE(one(r$bill_focus) %in% bill_focus))
        add(batch, id, "speech", paste("bill_focus not allowed:", one(r$bill_focus)))
      if (!isTRUE(one(r$bill_stance) %in% c("support", "oppose", "mixed", "none")))
        add(batch, id, "speech", paste("bill_stance not allowed:", one(r$bill_stance)))
      for (f in c("speech_focus_climate", "procedural_objection"))
        if (!isTRUE(one(r[[f]]) %in% 0:1)) add(batch, id, "speech", paste(f, "not 0/1"))
    }
    if (!isTRUE(one(r$n_sources) == length(r$sources)))
      add(batch, id, "speech", "n_sources does not match the sources listed")

    stmts <- Filter(function(s) !identical(one(s$concept_id), "NONE"), r$statements)
    if (ncc && length(stmts) > 0) add(batch, id, "speech", "no_codable_content = 1 but statements coded")
    if (!ncc && length(stmts) == 0 && length(r$sources) == 0)
      add(batch, id, "speech", "no statements or sources but no_codable_content = 0")
    n_st <- n_st + length(stmts); n_src <- n_src + length(r$sources)

    keys <- character()
    for (s in stmts) {
      w <- paste("statement", one(s$concept_id))
      for (f in setdiff(stmt_fields, names(s))) add(batch, id, w, paste("field missing:", f))
      if (!isTRUE(one(s$concept_id) %in% concepts)) add(batch, id, w, "concept_id not in codebook")
      if (!isTRUE(one(s$agree) %in% 0:1)) add(batch, id, w, "agree not 0/1")
      if (!isTRUE(one(s$intensity) %in% c(-2, -1, 1, 2))) add(batch, id, w, "intensity not allowed")
      else if (isTRUE(one(s$agree) %in% 0:1) && (s$agree == 1) != (s$intensity > 0))
        add(batch, id, w, "intensity sign does not match agree")
      for (f in c("hedged", "conditional"))
        if (!isTRUE(one(s[[f]]) %in% 0:1)) add(batch, id, w, paste(f, "not 0/1"))
      if (!isTRUE(one(s$confidence) %in% 1:3)) add(batch, id, w, "confidence not 1-3")
      check_quote(batch, id, w, s$quote, text)
      keys <- c(keys, paste(one(s$concept_id), one(s$agree)))
    }
    for (k in unique(keys[duplicated(keys)]))
      add(batch, id, paste("statement", k), "concept x stance coded more than once")
    coded <- vapply(stmts, function(s) as.character(one(s$concept_id)), "")

    sids <- character()
    for (s in r$sources) {
      w <- paste("source", one(s$source_id))
      for (f in setdiff(src_fields, names(s))) add(batch, id, w, paste("field missing:", f))
      if (!isTRUE(one(s$source_type) %in% source_types))
        add(batch, id, w, paste("source_type not allowed:", one(s$source_type)))
      for (f in c("specific", "inserted"))
        if (!isTRUE(one(s[[f]]) %in% 0:1)) add(batch, id, w, paste(f, "not 0/1"))
      if (!isTRUE(one(s$evidence_form) %in% c("quantitative", "finding", "testimony", "position")))
        add(batch, id, w, "evidence_form not allowed")
      if (!isTRUE(one(s$use) %in% c("support", "dispute", "mixed"))) add(batch, id, w, "use not allowed")
      cons <- one(s$consensus); is_sci <- identical(one(s$source_type), "science")
      if (!isTRUE(cons %in% c("mainstream", "dissenting", "na"))) add(batch, id, w, "consensus not allowed")
      else if (is_sci && cons == "na") add(batch, id, w, "science source with consensus = na")
      else if (!is_sci && cons != "na") add(batch, id, w, "non-science source with consensus coded")
      if (identical(one(s$source_type), "expert_generic") && !isTRUE(one(s$specific) == 0))
        add(batch, id, w, "expert_generic with specific = 1")
      if (!isTRUE(one(s$confidence) %in% 1:3)) add(batch, id, w, "confidence not 1-3")
      links <- as.character(unlist(s$linked_concepts))
      for (k in setdiff(links, coded)) add(batch, id, w, paste("linked concept not coded as a statement:", k))
      check_quote(batch, id, w, s$quote, text)
      sids <- c(sids, as.character(one(s$source_id)))
    }
    if (anyDuplicated(sids)) add(batch, id, "sources", "duplicate source_id")
  }
  n_prob <- length(problems) - n_before
  summary_rows[[batch]] <- data.frame(batch = batch,
    status = if (n_prob == 0) "ok" else "problems", speeches = nrow(man),
    coded = sum(man$speech_id %in% ids), statements = n_st, sources = n_src,
    problems = n_prob)
}

batches <- do.call(rbind, summary_rows)
probs <- if (length(problems)) do.call(rbind, problems) else
  data.frame(batch = character(), speech_id = character(), where = character(),
             problem = character())
write.csv(batches, file.path(out_dir, "check_batches.csv"), row.names = FALSE)
write.csv(probs, file.path(out_dir, "check_problems.csv"), row.names = FALSE)

cat("Batches:", nrow(batches), "\n")
print(table(batches$status))
done <- batches[batches$status != "not coded", ]
cat("Speeches coded:", sum(done$coded), "of", sum(batches$speeches),
    "| statements:", sum(done$statements), "| sources:", sum(done$sources), "\n")
cat("Problems:", nrow(probs), "\n")
if (nrow(probs)) {
  print(sort(table(sub(":.*", "", probs$problem)), decreasing = TRUE))
  print(probs, row.names = FALSE, right = FALSE)
}
