# Analysis for "Belief Systems and the Climate Change Discourse in the US Congress"
#
# Sourced by beliefs-congress-speeches.qmd (setup chunk). Builds the objects
# used by the manuscript's tables, figures, and inline R. Run from the project
# root: Rscript scripts/analysis.R

# --- Data ------------------------------------------------------------------
# Speech corpora (Congressional Record floor speeches and Extensions of
# Remarks) and DW-NOMINATE scores matched to each speech. See data/*/README.md.
data_dir <- "data"

read_corpus <- function(folder, nominate_file, label) {
  idx <- read.csv(file.path(data_dir, folder, "index.csv"),
                  stringsAsFactors = FALSE)
  nom <- read.csv(file.path(data_dir, "voteview-nominate", nominate_file),
                  stringsAsFactors = FALSE)
  nom <- nom[, c("speech_id", setdiff(names(nom), names(idx)))]
  df <- merge(idx, nom, by = "speech_id", all.x = TRUE)
  df$corpus <- label
  df$path <- file.path(data_dir, folder, df$file)
  df
}

ct  <- read_corpus("cap-and-trade-congressional-record",
                   "captrade_speech_nominate.csv", "Cap-and-trade")
ira <- read_corpus("ira-congressional-record",
                   "ira_speech_nominate.csv", "IRA/OBBB")

# The corpora have different keyword-hit columns; keep the shared ones
shared   <- intersect(names(ct), names(ira))
speeches <- rbind(ct[, shared], ira[, shared])

# --- Descriptives ----------------------------------------------------------
n_speeches <- nrow(speeches)
n_members  <- length(unique(speeches$bioGuideId[speeches$bioGuideId != ""]))
