# Build the human-coding packet for the codebook v0.5 reliability study.
# Run from the project root: Rscript scripts/human_coding_setup.R
#
# Writes human-coding/:
#   speeches/        the 54 speeches to code, numbered in coding order
#   practice/        4 practice speeches (pilot speeches outside the subset)
#   codebook/        codebook v0.5 (md, html, docx)
#   coding-sheet_A.xlsx, coding-sheet_B.xlsx      one workbook per coder
#   practice-sheet_A.xlsx, practice-sheet_B.xlsx
#   manifest.csv     speech metadata (not for coders)
# INSTRUCTIONS.md in human-coding/ is written by hand, not by this script.

library(openxlsx)

set.seed(20261023)

data_dir  <- "data"
out_dir   <- "human-coding"
pilot_dir <- file.path("output", "pilot")
subset_file <- file.path("..", "00-policy-learning-congress", "output", "pilot",
                         "human_coding_subset.csv")
for (d in c("speeches", "practice", "codebook")) {
  dir.create(file.path(out_dir, d), showWarnings = FALSE, recursive = TRUE)
}

# --- Speeches --------------------------------------------------------------
# 50-speech reliability subset (seed 20260929; drawn from the 150-speech
# pilot) plus 4 cap-and-trade speeches kept only by rule C (bill_energy), one
# per party x chamber, which the pilot predates. Rule-C draws are capped at
# 3,000 words to keep the coding load comparable to the subset.
pilot  <- read.csv(file.path(pilot_dir, "pilot_sample.csv"), stringsAsFactors = FALSE)
subset <- read.csv(subset_file, stringsAsFactors = FALSE)
core <- pilot[match(subset$speech_id, pilot$speech_id), ]
core$group <- "subset"

ct <- read.csv(file.path(data_dir, "cap-and-trade-congressional-record", "index.csv"),
               stringsAsFactors = FALSE)
ct$path <- file.path(data_dir, "cap-and-trade-congressional-record", ct$file)
pool <- ct[ct$keep_rule == "bill_energy" & ct$words >= 150 & ct$words <= 3000 &
             !is.na(ct$bioGuideId) & ct$bioGuideId != "" &
             ct$party %in% c("D", "R") & ct$section %in% c("House", "Senate"), ]
rule_c <- do.call(rbind, lapply(split(pool, list(pool$party, pool$section)),
                                function(p) p[sample(nrow(p), 1), ]))
rule_c$cell <- paste("CT", rule_c$party, rule_c$section, "ruleC", sep = "_")
rule_c$group <- "rule_c"

cols <- c("speech_id", "cell", "group", "member_name", "party", "section",
          "date", "record_title", "words", "keep_rule", "path")
speeches <- rbind(core[, cols], rule_c[, cols])
speeches <- speeches[sample(nrow(speeches)), ]  # coding order, same for both coders
speeches$order <- seq_len(nrow(speeches))
speeches$file <- sprintf("%02d_%s.txt", speeches$order, speeches$speech_id)

# Practice: 4 pilot speeches outside the subset, one per corpus x party,
# 300-1,200 words
rest <- pilot[!pilot$speech_id %in% subset$speech_id &
                pilot$words >= 300 & pilot$words <= 1200 &
                pilot$party %in% c("D", "R"), ]
practice <- do.call(rbind, lapply(split(rest, list(rest$corpus, rest$party)),
                                  function(p) p[sample(nrow(p), 1), ]))
practice$order <- seq_len(nrow(practice))
practice$file <- sprintf("P%d_%s.txt", practice$order, practice$speech_id)

copy_speeches <- function(df, folder) {
  unlink(list.files(file.path(out_dir, folder), full.names = TRUE))
  ok <- file.copy(df$path, file.path(out_dir, folder, df$file))
  stopifnot(all(ok))
}
copy_speeches(speeches, "speeches")
copy_speeches(practice, "practice")

manifest <- rbind(
  data.frame(set = "coding", speeches[, c("order", "file", cols)]),
  data.frame(set = "practice", group = "practice",
             practice[, c("order", "file", setdiff(cols, "group"))])
)
manifest$path <- NULL
write.csv(manifest, file.path(out_dir, "manifest.csv"), row.names = FALSE)

# --- Codebook --------------------------------------------------------------
cb <- file.path("codebook", "codebook-v0.5.md")
invisible(file.copy(cb, file.path(out_dir, "codebook", "codebook-v0.5.md"),
                    overwrite = TRUE))
for (fmt in c("html", "docx")) {
  args <- c(cb, "-o", file.path(out_dir, "codebook", paste0("codebook-v0.5.", fmt)),
            "--toc", "--standalone")
  if (fmt == "html") args <- c(args, "--embed-resources",
                               "--metadata", shQuote("title=Codebook v0.5"))
  if (fmt == "docx") args <- c(args, "--reference-doc", "custom-reference-doc.docx")
  stopifnot(system2("pandoc", args) == 0)
}
# Coder instructions (INSTRUCTIONS.md is written by hand) -> docx
stopifnot(system2("pandoc", c(file.path(out_dir, "INSTRUCTIONS.md"), "-o",
                              file.path(out_dir, "INSTRUCTIONS.docx"),
                              "--reference-doc", "custom-reference-doc.docx")) == 0)

cb_lines <- readLines(cb, encoding = "UTF-8")

# Anchor check: no quoted codebook passage may appear in a coding speech, or
# coders would see the answer. Compare on letters and digits only, so line
# breaks and hyphenation do not hide a match.
squash <- function(x) gsub("[^a-z0-9]", "", tolower(x))
quotes <- unlist(regmatches(cb_lines, gregexpr('"[^"]{20,}"', cb_lines)))
quotes <- unlist(strsplit(quotes, "…"))
quotes <- squash(quotes)
quotes <- quotes[nchar(quotes) >= 40]
speech_text <- vapply(file.path(out_dir, "speeches", speeches$file), function(f)
  squash(paste(readLines(f, warn = FALSE), collapse = " ")), character(1))
leaks <- quotes[vapply(quotes, function(q) any(grepl(q, speech_text, fixed = TRUE)),
                       logical(1))]
if (length(leaks) > 0) stop("Codebook anchors found in coding speeches: ",
                            paste(substr(leaks, 1, 40), collapse = "; "))

# --- Valid values ----------------------------------------------------------
crow <- grep("^\\| \\*\\*(DC|PC|SC)[0-9]+", cb_lines, value = TRUE)
concepts <- data.frame(
  concept_id  = sub("^\\| \\*\\*((DC|PC|SC)[0-9]+).*", "\\1", crow),
  proposition = trimws(sapply(strsplit(crow, "\\|"), `[`, 3))
)
concepts <- concepts[!duplicated(concepts$concept_id), ]

source_types <- c("science", "govt_analysis", "executive", "military_security",
                  "think_tank", "advocacy", "business", "state_local",
                  "international", "courts", "congress", "media",
                  "public_opinion", "constituent", "personal", "expert_generic",
                  "other")
bill_focus <- c("waxman-markey", "lieberman-warner", "kerry-boxer",
                "mccain-lieberman", "other-captrade", "epact-2003", "epact-2005",
                "eisa-2007", "energy-bill-other", "gnd", "climate-action-now",
                "ajp", "bbb", "ira", "lower-energy-costs", "obbb", "cra-epa",
                "appropriations", "budget", "nomination", "none")
lists <- list(
  concept_id = concepts$concept_id, binary = c(0, 1),
  intensity = c(-2, -1, 1, 2), confidence = 1:3,
  bill_focus = bill_focus, bill_stance = c("support", "oppose", "mixed", "none"),
  source_type = source_types,
  evidence_form = c("quantitative", "finding", "testimony", "position"),
  use = c("support", "dispute", "mixed")
)

# --- Workbooks -------------------------------------------------------------
hdr  <- createStyle(textDecoration = "bold", fgFill = "#DDE5EE", wrapText = TRUE,
                    valign = "top", border = "bottom")
wrap <- createStyle(wrapText = TRUE, valign = "top")
lock <- createStyle(fgFill = "#F2F2F2", valign = "top")

add_dropdown <- function(wb, sheet, col, rows, list_name) {
  n <- length(lists[[list_name]])
  lc <- LETTERS[match(list_name, names(lists))]
  dataValidation(wb, sheet, cols = col, rows = rows, type = "list",
                 value = sprintf("'lists'!$%s$2:$%s$%d", lc, lc, n + 1))
}

build_workbook <- function(df, coder, file, n_stmt, n_src) {
  wb <- createWorkbook()
  ids <- df$speech_id

  # speeches: one row per speech, speech-level variables (codebook §6)
  addWorksheet(wb, "speeches")
  sp <- data.frame(order = df$order, file = df$file, speech_id = ids,
                   coder = coder, no_codable_content = NA, bill_focus = NA,
                   bill_stance = NA, speech_focus_climate = NA,
                   procedural_objection = NA, n_sources = NA,
                   speech_memo = NA, minutes = NA, done = NA)
  writeData(wb, "speeches", sp, headerStyle = hdr)
  r <- 2:(nrow(sp) + 1)
  addStyle(wb, "speeches", lock, rows = r, cols = 1:4, gridExpand = TRUE)
  for (cc in c(5, 8, 9, 13)) add_dropdown(wb, "speeches", cc, r, "binary")
  add_dropdown(wb, "speeches", 6, r, "bill_focus")
  add_dropdown(wb, "speeches", 7, r, "bill_stance")
  dataValidation(wb, "speeches", cols = 10, rows = r, type = "whole",
                 operator = "greaterThanOrEqual", value = 0)
  dataValidation(wb, "speeches", cols = 12, rows = r, type = "decimal",
                 operator = "greaterThanOrEqual", value = 0)
  setColWidths(wb, "speeches", 1:13,
               c(6, 44, 36, 6, 10, 18, 11, 10, 10, 9, 50, 8, 6))
  freezePane(wb, "speeches", firstActiveRow = 2, firstActiveCol = 4)

  # statements: one row per concept x stance per speech (codebook §4, §4a)
  addWorksheet(wb, "statements")
  st <- data.frame(speech_id = character(), concept_id = character(),
                   agree = integer(), intensity = integer(), hedged = integer(),
                   conditional = integer(), quote = character(),
                   confidence = integer(), memo = character())
  writeData(wb, "statements", st, headerStyle = hdr)
  r <- 2:(n_stmt + 1)
  dataValidation(wb, "statements", cols = 1, rows = r, type = "list",
                 value = sprintf("'speeches'!$C$2:$C$%d", nrow(df) + 1))
  add_dropdown(wb, "statements", 2, r, "concept_id")
  for (cc in c(3, 5, 6)) add_dropdown(wb, "statements", cc, r, "binary")
  add_dropdown(wb, "statements", 4, r, "intensity")
  add_dropdown(wb, "statements", 8, r, "confidence")
  addStyle(wb, "statements", wrap, rows = r, cols = c(7, 9), gridExpand = TRUE)
  setColWidths(wb, "statements", 1:9, c(36, 11, 7, 9, 8, 11, 70, 10, 40))
  freezePane(wb, "statements", firstActiveRow = 2)

  # sources: one row per source per speech (codebook §4b)
  addWorksheet(wb, "sources")
  so <- data.frame(speech_id = character(), source_id = character(),
                   source_name = character(), source_type = character(),
                   specific = integer(), evidence_form = character(),
                   use = character(), linked_concepts = character(),
                   inserted = integer(), quote = character(),
                   confidence = integer(), memo = character())
  writeData(wb, "sources", so, headerStyle = hdr)
  r <- 2:(n_src + 1)
  dataValidation(wb, "sources", cols = 1, rows = r, type = "list",
                 value = sprintf("'speeches'!$C$2:$C$%d", nrow(df) + 1))
  add_dropdown(wb, "sources", 4, r, "source_type")
  for (cc in c(5, 9)) add_dropdown(wb, "sources", cc, r, "binary")
  add_dropdown(wb, "sources", 6, r, "evidence_form")
  add_dropdown(wb, "sources", 7, r, "use")
  add_dropdown(wb, "sources", 11, r, "confidence")
  addStyle(wb, "sources", wrap, rows = r, cols = c(3, 10, 12), gridExpand = TRUE)
  setColWidths(wb, "sources", 1:12, c(36, 8, 28, 16, 8, 13, 9, 16, 8, 60, 10, 30))
  freezePane(wb, "sources", firstActiveRow = 2)

  # concepts: reference list of propositions
  addWorksheet(wb, "concepts")
  writeData(wb, "concepts", concepts, headerStyle = hdr)
  addStyle(wb, "concepts", wrap, rows = 2:(nrow(concepts) + 1), cols = 2)
  setColWidths(wb, "concepts", 1:2, c(11, 100))

  # lists: valid values for the dropdowns (do not edit)
  addWorksheet(wb, "lists")
  for (i in seq_along(lists)) {
    writeData(wb, "lists", data.frame(lists[[i]]) |> setNames(names(lists)[i]),
              startCol = i, headerStyle = hdr)
  }
  protectWorksheet(wb, "lists", protect = TRUE)

  saveWorkbook(wb, file, overwrite = TRUE)
}

for (coder in c("A", "B")) {
  build_workbook(speeches, coder,
                 file.path(out_dir, sprintf("coding-sheet_%s.xlsx", coder)),
                 n_stmt = 1000, n_src = 800)
  build_workbook(practice, coder,
                 file.path(out_dir, sprintf("practice-sheet_%s.xlsx", coder)),
                 n_stmt = 100, n_src = 100)
}

cat("Coding speeches:", nrow(speeches), "(", sum(speeches$group == "rule_c"),
    "rule C ); total words:", sum(speeches$words), "\n")
print(table(speeches$cell))
cat("Practice speeches:", nrow(practice), "; words:", sum(practice$words), "\n")
cat("Concepts:", nrow(concepts), "\n")
cat("R version:", R.version.string, "\n")
