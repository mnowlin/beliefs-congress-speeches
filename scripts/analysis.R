# Analysis for "Belief Systems and Climate Change Discourse in the US Congress"
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

# --- Periods ---------------------------------------------------------------
# era: every speech, grouped by the Congresses around each debate.
#   Cap-and-trade = 106th-112th (2000-2012); IRA = 115th-118th (2018-2024,
#   incl. the Green New Deal and Build Back Better); OBBB = 119th (2025-).
# window: debate windows, from the start of each bill's legislative vehicle
#   to its final disposition (NA outside the windows).
#   Cap-and-trade: Waxman-Markey discussion draft released -> Senate
#     leadership drops the climate bill.
#   IRA: Senate adopts the FY2022 budget resolution (S.Con.Res. 14) -> signed.
#   OBBB: House adopts the FY2025 budget resolution (H.Con.Res. 14) -> signed.
# window_congress: the Congress in which each debate took place (robustness
#   check on the window dates).
# climate_rule: kept by the climate-term screen rules (A: dense, B: titled),
#   which are identical in both corpora. FALSE = kept only by rule C
#   (bill_energy): names the period's climate bill and is energy-dense, with
#   the same energy vocabulary in both corpora.
windows <- data.frame(
  window   = c("Cap-and-trade", "IRA", "OBBB"),
  start    = as.Date(c("2009-03-31", "2021-08-11", "2025-02-25")),
  end      = as.Date(c("2010-07-22", "2022-08-16", "2025-07-04")),
  congress = c(111, 117, 119)
)

speeches$date <- as.Date(speeches$date)
speeches$era <- factor(
  cut(speeches$congress, breaks = c(0, 112, 118, Inf),
      labels = windows$window),
  levels = windows$window)
speeches$window <- factor(NA, levels = windows$window)
for (i in seq_len(nrow(windows))) {
  in_w <- speeches$date >= windows$start[i] & speeches$date <= windows$end[i]
  speeches$window[in_w] <- windows$window[i]
}
speeches$in_window <- !is.na(speeches$window)
speeches$window_congress <- factor(
  windows$window[match(speeches$congress, windows$congress)],
  levels = windows$window)
speeches$climate_rule <- speeches$keep_rule %in% c("dense", "titled")

# --- Descriptives ----------------------------------------------------------
n_speeches <- nrow(speeches)
n_members  <- length(unique(speeches$bioGuideId[speeches$bioGuideId != ""]))
