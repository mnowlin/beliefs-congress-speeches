# Draw the full-coding sample: Democratic and Republican speeches inside the
# three debate windows (codebook v0.5 §2; decided 2026-11-13).
# Run from the project root: Rscript scripts/coding_sample.R
#
# Writes output/coding/:
#   coding_sample.csv   one row per speech, in coding order, with its batch
#   batches/batch_NNN.txt   speech_id <tab> path, 10 speeches per batch
#   validation_sample.csv, batches/validation_NN.txt   the human-coding
#     speeches outside the windows (coded for LLM-human agreement only)
#
# Windows, party, and paths come from scripts/analysis.R. Speeches are put in
# one fixed random order so that batches mix windows, parties, and chambers.
# The 54 human-coding speeches and the 150 pilot speeches are flagged, not
# removed: those inside the windows are coded again with the final prompt.

source(file.path("scripts", "analysis.R"))

set.seed(20261113)
batch_size <- 10
out_dir <- file.path("output", "coding")
dir.create(file.path(out_dir, "batches"), showWarnings = FALSE, recursive = TRUE)

s <- speeches[speeches$in_window & speeches$party %in% c("D", "R"), ]
stopifnot(!anyDuplicated(s$speech_id), all(file.exists(s$path)))

pilot <- read.csv(file.path("output", "pilot", "pilot_sample.csv"),
                  stringsAsFactors = FALSE)
human <- read.csv(file.path("human-coding", "manifest.csv"),
                  stringsAsFactors = FALSE)
s$in_pilot <- s$speech_id %in% pilot$speech_id
s$in_human_coding <- s$speech_id %in% human$speech_id[human$set == "coding"]

s <- s[sample(nrow(s)), ]
s$coding_order <- seq_len(nrow(s))
s$batch <- ceiling(s$coding_order / batch_size)

cols <- c("coding_order", "batch", "speech_id", "window", "corpus", "date",
          "congress", "section", "member_name", "bioGuideId", "party", "state",
          "record_title", "words", "keep_rule", "climate_rule", "in_pilot",
          "in_human_coding", "path")
write.csv(s[, cols], file.path(out_dir, "coding_sample.csv"), row.names = FALSE)

unlink(list.files(file.path(out_dir, "batches"), full.names = TRUE))
for (b in unique(s$batch)) {
  writeLines(paste(s$speech_id[s$batch == b], s$path[s$batch == b], sep = "\t"),
             file.path(out_dir, "batches", sprintf("batch_%03d.txt", b)))
}

# Validation set: the human-coding speeches that fall outside the windows.
# They are coded with the same prompt so that LLM-human agreement can be
# computed on all 54 human-coded speeches; they are not part of the analysis
# sample.
hc <- human[human$set == "coding" & !human$speech_id %in% s$speech_id, ]
v <- speeches[match(hc$speech_id, speeches$speech_id), ]
stopifnot(!anyNA(v$speech_id), all(file.exists(v$path)))
v <- v[sample(nrow(v)), ]
v$coding_order <- seq_len(nrow(v))
v$batch <- ceiling(v$coding_order / batch_size)
v$in_pilot <- v$speech_id %in% pilot$speech_id
v$in_human_coding <- TRUE
write.csv(v[, cols], file.path(out_dir, "validation_sample.csv"),
          row.names = FALSE)
for (b in unique(v$batch)) {
  writeLines(paste(v$speech_id[v$batch == b], v$path[v$batch == b], sep = "\t"),
             file.path(out_dir, "batches", sprintf("validation_%02d.txt", b)))
}
cat("Validation speeches outside the windows:", nrow(v), "; batches:",
    max(v$batch), "; words:", sum(v$words), "\n")

cat("Speeches:", nrow(s), "; batches:", max(s$batch),
    "; words:", sum(s$words), "\n")
print(table(s$window, s$party))
print(table(s$window, s$keep_rule))
cat("Words: median", median(s$words), "; max", max(s$words),
    "; over 8,000:", sum(s$words > 8000), "\n")
cat("In pilot:", sum(s$in_pilot), "; in human-coding set:",
    sum(s$in_human_coding), "\n")
cat("R version:", R.version.string, "\n")
