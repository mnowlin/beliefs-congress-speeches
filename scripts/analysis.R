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
n_ct  <- nrow(ct)
n_ira <- nrow(ira)

# --- Coded speeches (codebook v0.5) -----------------------------------------
# LLM codes for the speeches in the three debate windows, built by
# scripts/coding_assemble.R from the raw coder output in output/coding/json/.
# set = "window" is the analysis sample; set = "validation" holds the
# human-coding speeches that fall outside the windows.
coding_dir <- file.path("output", "coding")
coded_speeches   <- read.csv(file.path(coding_dir, "llm_speeches.csv"),
                             stringsAsFactors = FALSE)
coded_statements <- read.csv(file.path(coding_dir, "llm_statements.csv"),
                             stringsAsFactors = FALSE)
coded_sources    <- read.csv(file.path(coding_dir, "llm_sources.csv"),
                             stringsAsFactors = FALSE)

win_speeches   <- coded_speeches[coded_speeches$set == "window", ]
win_statements <- coded_statements[coded_statements$set == "window", ]
win_sources    <- coded_sources[coded_sources$set == "window", ]
win_speeches$window <- factor(win_speeches$window, levels = windows$window)

n_coded          <- nrow(win_speeches)
n_coded_members  <- length(unique(win_speeches$bioGuideId))
n_statements     <- nrow(win_statements)
n_sources        <- nrow(win_sources)
n_no_statement   <- sum(win_speeches$n_statements == 0)
n_batches        <- length(unique(win_speeches$coding_batch))
n_validation     <- sum(coded_speeches$set == "validation")
n_human_coding   <- n_validation + sum(win_speeches$in_human_coding)

# Table: the coded sample by debate
tab_sample <- do.call(rbind, lapply(split(win_speeches, win_speeches$window),
  function(d) data.frame(
    Debate      = as.character(d$window[1]),
    Speeches    = nrow(d),
    Democrats   = sum(d$party == "D"),
    Republicans = sum(d$party == "R"),
    House       = sum(d$section == "House"),
    Senate      = sum(d$section == "Senate"),
    Extensions  = sum(d$section == "Extensions"),
    Members     = length(unique(d$bioGuideId)),
    `Median words` = median(d$words),
    check.names = FALSE)))
fmt_date <- function(d) paste0(format(d, "%b "), as.integer(format(d, "%d")),
                               format(d, ", %Y"))
tab_sample$Period <- paste(fmt_date(windows$start), "to", fmt_date(windows$end))[
  match(tab_sample$Debate, windows$window)]
tab_sample <- tab_sample[, c("Debate", "Period", setdiff(names(tab_sample),
                                                         c("Debate", "Period")))]
rownames(tab_sample) <- NULL

# Table: the concepts in the codebook, by belief tier
cb_lines <- readLines(file.path("codebook", "codebook-v0.5.md"), encoding = "UTF-8")
cb_rows  <- grep("^\\| \\*\\*(DC|PC|SC)[0-9]+", cb_lines, value = TRUE)
tab_concepts <- data.frame(
  ID = sub("^\\| \\*\\*((DC|PC|SC)[0-9]+).*", "\\1", cb_rows),
  Proposition = trimws(sapply(strsplit(cb_rows, "\\|"), `[`, 3)),
  stringsAsFactors = FALSE)
tab_concepts <- tab_concepts[!duplicated(tab_concepts$ID), ]
# Secondary propositions share the stem "The federal government should
# adopt/keep..." in the codebook; write each one out in full, and drop the
# codebook's bold markup.
tab_concepts$Proposition <- gsub("**", "", tab_concepts$Proposition, fixed = TRUE)
verb_first <- grepl("^\u2026(expand|invest|streamline|fund|promote|require)",
                    tab_concepts$Proposition)
tab_concepts$Proposition <- ifelse(
  verb_first,
  sub("^\u2026", "The federal government should ", tab_concepts$Proposition),
  sub("^\u2026", "The federal government should adopt or keep ",
      tab_concepts$Proposition))
tab_concepts$Tier <- c(DC = "Deep core", PC = "Policy core", SC = "Secondary")[
  substr(tab_concepts$ID, 1, 2)]
tab_concepts <- tab_concepts[, c("Tier", "ID", "Proposition")]
rownames(tab_concepts) <- NULL
n_concepts <- nrow(tab_concepts)
n_tier     <- table(tab_concepts$Tier)

# Number formatting for inline R in the manuscript
fmt <- function(x) format(x, big.mark = ",")

# --- Analysis matrices -------------------------------------------------------
# Built from the LLM codes for the window sample. The review lists in
# output/coding/review/ are not yet applied, so source types (above all
# `science`) are as coded.
#
# speech_concept: one row per speech and concept the speech addresses.
#   position = mean intensity of the speech's statements on the concept (-2 to
#   +2; a speech can hold one agree and one disagree statement on a concept,
#   which average toward 0); hedged = any statement on the concept is hedged;
#   both_sides = the speech has an agree and a disagree statement.
concept_ids <- tab_concepts$ID
groups      <- c("window", "party")

sc_key <- paste(win_statements$speech_id, win_statements$concept_id, sep = "\r")
speech_concept <- data.frame(
  speech_id  = tapply(win_statements$speech_id, sc_key, `[`, 1),
  concept_id = tapply(win_statements$concept_id, sc_key, `[`, 1),
  position   = tapply(win_statements$intensity, sc_key, mean),
  hedged     = tapply(win_statements$hedged, sc_key, max),
  both_sides = tapply(win_statements$agree, sc_key,
                      function(a) as.integer(length(unique(a)) > 1)),
  n_statements = tapply(win_statements$intensity, sc_key, length),
  stringsAsFactors = FALSE)
rownames(speech_concept) <- NULL
speech_concept <- merge(
  speech_concept,
  win_speeches[, c("speech_id", "bioGuideId", "window", "party", "section",
                   "speech_focus_climate")],
  by = "speech_id")
speech_concept$concept_id <- factor(speech_concept$concept_id, levels = concept_ids)

# Speech x concept matrix of positions (NA = concept not addressed)
position_matrix <- matrix(
  NA_real_, nrow = nrow(win_speeches), ncol = length(concept_ids),
  dimnames = list(win_speeches$speech_id, concept_ids))
position_matrix[cbind(speech_concept$speech_id,
                      as.character(speech_concept$concept_id))] <-
  speech_concept$position

# belief_summary(): one row per concept x debate x party.
#   salience  = share of the group's speeches that address the concept
#   position  = mean speech-level position; share_agree = share with position > 0
#   dispersion = SD of speech-level positions (NA with fewer than 2 speeches)
#   hedged    = share of speeches addressing the concept with a hedged statement
# focus_only = TRUE limits the sample to speeches whose main subject is
# climate or energy (robustness check).
belief_summary <- function(focus_only = FALSE) {
  sp <- win_speeches
  sc <- speech_concept
  if (focus_only) {
    sp <- sp[sp$speech_focus_climate %in% 1, ]
    sc <- sc[sc$speech_focus_climate %in% 1, ]
  }
  denom <- as.data.frame(table(window = sp$window, party = sp$party),
                         responseName = "n_group", stringsAsFactors = FALSE)
  grid <- merge(denom, data.frame(concept_id = concept_ids), by = NULL)
  agg <- do.call(rbind, lapply(
    split(sc, list(sc$window, sc$party, sc$concept_id), drop = TRUE),
    function(d) data.frame(
      window = as.character(d$window[1]), party = d$party[1],
      concept_id = as.character(d$concept_id[1]),
      n = nrow(d), position = mean(d$position),
      share_agree = mean(d$position > 0),
      dispersion = if (nrow(d) > 1) sd(d$position) else NA_real_,
      hedged = mean(d$hedged), both_sides = mean(d$both_sides),
      stringsAsFactors = FALSE)))
  out <- merge(grid, agg, by = c("window", "party", "concept_id"), all.x = TRUE)
  out$n[is.na(out$n)] <- 0
  out$salience <- out$n / out$n_group
  out$tier <- tab_concepts$Tier[match(out$concept_id, tab_concepts$ID)]
  out$window <- factor(out$window, levels = windows$window)
  out$concept_id <- factor(out$concept_id, levels = concept_ids)
  out <- out[order(out$concept_id, out$window, out$party),
             c("tier", "concept_id", "window", "party", "n_group", "n",
               "salience", "position", "share_agree", "dispersion", "hedged",
               "both_sides")]
  rownames(out) <- NULL
  out
}
beliefs       <- belief_summary()
beliefs_focus <- belief_summary(focus_only = TRUE)

# source_summary(): one row per source type x debate x party.
#   salience = share of the group's speeches that cite at least one source of
#   the type (presence, not the number of sources); share_dispute = share of
#   the type's sources that the speaker disputes.
source_types <- sort(unique(win_sources$source_type))
speech_source <- unique(win_sources[, c("speech_id", "source_type")])
speech_source <- merge(
  speech_source,
  win_speeches[, c("speech_id", "window", "party", "speech_focus_climate")],
  by = "speech_id")

source_summary <- function(focus_only = FALSE) {
  sp <- win_speeches
  ss <- speech_source
  src <- merge(win_sources[, c("speech_id", "source_type", "use")],
               win_speeches[, c("speech_id", "window", "party",
                                "speech_focus_climate")], by = "speech_id")
  if (focus_only) {
    sp  <- sp[sp$speech_focus_climate %in% 1, ]
    ss  <- ss[ss$speech_focus_climate %in% 1, ]
    src <- src[src$speech_focus_climate %in% 1, ]
  }
  denom <- as.data.frame(table(window = sp$window, party = sp$party),
                         responseName = "n_group", stringsAsFactors = FALSE)
  n_sp <- as.data.frame(table(window = ss$window, party = ss$party,
                              source_type = factor(ss$source_type, source_types)),
                        responseName = "n", stringsAsFactors = FALSE)
  n_src <- as.data.frame(table(window = src$window, party = src$party,
                               source_type = factor(src$source_type, source_types)),
                         responseName = "n_sources", stringsAsFactors = FALSE)
  n_dis <- as.data.frame(table(window = src$window, party = src$party,
                               source_type = factor(src$source_type, source_types),
                               dispute = src$use == "dispute"),
                         responseName = "n_dispute", stringsAsFactors = FALSE)
  n_dis <- n_dis[n_dis$dispute == "TRUE", setdiff(names(n_dis), "dispute")]
  out <- Reduce(function(a, b) merge(a, b, all.x = TRUE),
                list(n_sp, denom, n_src, n_dis))
  out$n_dispute[is.na(out$n_dispute)] <- 0
  out$salience <- out$n / out$n_group
  out$share_dispute <- ifelse(out$n_sources > 0,
                              out$n_dispute / out$n_sources, NA_real_)
  out$window <- factor(out$window, levels = windows$window)
  out <- out[order(out$source_type, out$window, out$party),
             c("source_type", "window", "party", "n_group", "n", "salience",
               "n_sources", "share_dispute")]
  rownames(out) <- NULL
  out
}
sources_by_group       <- source_summary()
sources_by_group_focus <- source_summary(focus_only = TRUE)

# Science sources by whether they are cited for a mainstream or a dissenting
# claim: share of each group's speeches citing at least one of each kind.
sci <- unique(win_sources[win_sources$source_type == "science",
                          c("speech_id", "consensus")])
sci <- merge(sci, win_speeches[, c("speech_id", "window", "party")],
             by = "speech_id")
science_consensus <- as.data.frame(
  table(window = sci$window, party = sci$party, consensus = sci$consensus),
  responseName = "n", stringsAsFactors = FALSE)
science_consensus <- merge(
  science_consensus,
  as.data.frame(table(window = win_speeches$window, party = win_speeches$party),
                responseName = "n_group", stringsAsFactors = FALSE))
science_consensus$salience <- science_consensus$n / science_consensus$n_group

# wide(): debate x party columns for one measure, for tables in the manuscript
wide <- function(d, id, value) {
  col <- paste(d$window, d$party)
  lev <- as.vector(t(outer(windows$window, c("D", "R"), paste)))
  m <- tapply(d[[value]], list(as.character(d[[id]]), factor(col, lev)), `[`, 1)
  m[unique(as.character(d[[id]])), , drop = FALSE]
}

# --- Results: tables, figure, and inline values -------------------------------
# Used by the Results section of the manuscript. All values come from the
# matrices above (LLM codes as coded; the review lists are not applied).

grp_cols <- as.vector(t(outer(windows$window, c("D", "R"), paste)))
grp_labs <- sub(" D$", " (D)", sub(" R$", " (R)", grp_cols))
wkey <- c(CT = "Cap-and-trade", IRA = "IRA", OBBB = "OBBB")
pct  <- function(x) round(100 * x)
f2   <- function(x) sprintf("%.2f", x)
f1   <- function(x) sprintf("%.1f", x)

# Inline lookups: concept/source type, debate key (CT, IRA, OBBB), party
bval <- function(concept, w, p, measure, d = beliefs)
  d[[measure]][d$concept_id == concept & d$window == wkey[[w]] & d$party == p]
sal <- function(concept, w, p) pct(bval(concept, w, p, "salience"))
agr <- function(concept, w, p) pct(bval(concept, w, p, "share_agree"))
pos <- function(concept, w, p) f2(bval(concept, w, p, "position"))
dsp <- function(concept, w, p) f2(bval(concept, w, p, "dispersion"))
hed <- function(concept, w, p) pct(bval(concept, w, p, "hedged"))
bn  <- function(concept, w, p) bval(concept, w, p, "n")
ssal <- function(type, w, p) pct(bval(type, w, p, "salience",
                                      transform(sources_by_group, concept_id = source_type)))
sdis <- function(type, w, p) pct(bval(type, w, p, "share_dispute",
                                      transform(sources_by_group, concept_id = source_type)))
scons <- function(w, p, cons) {
  x <- science_consensus$salience[science_consensus$window == wkey[[w]] &
                                    science_consensus$party == p &
                                    science_consensus$consensus == cons]
  if (length(x) == 0) 0 else pct(x)
}

# Statements joined to speech-level debate and party
stmt <- merge(win_statements[, setdiff(names(win_statements), c("window", "party"))],
              win_speeches[, c("speech_id", "window", "party")], by = "speech_id")
stmt$tier <- substr(stmt$concept_id, 1, 2)
stmt$science_concept <- stmt$concept_id %in% c("PC1", "PC2", "PC3")
grp_table <- function(x, fun = mean) {
  m <- tapply(x, list(win_speeches$window, win_speeches$party), fun)
  m
}

stmt_per_speech <- f1(mean(win_speeches$n_statements[win_speeches$n_statements > 0]))
pct_strong   <- pct(mean(abs(stmt$intensity) == 2))
n_hedged     <- sum(stmt$hedged)
pct_hedged   <- f1(100 * mean(stmt$hedged))
hedged_group <- tapply(stmt$hedged, list(stmt$window, stmt$party), function(x) f1(100 * mean(x)))
hedged_sci   <- tapply(stmt$hedged, list(stmt$science_concept, stmt$party),
                       function(x) f1(100 * mean(x)))   # rows FALSE/TRUE
n_both_sides <- sum(speech_concept$both_sides)
n_speech_concept <- nrow(speech_concept)

# Share of each group's statements in each tier
tier_share <- pct(prop.table(table(stmt$tier, factor(paste(stmt$window, stmt$party),
                                                     grp_cols)), 2))
# Share of each group's speeches that address PC1, PC2, or PC3
sci_talk <- pct(grp_table(win_speeches$speech_id %in%
  speech_concept$speech_id[speech_concept$concept_id %in% c("PC1", "PC2", "PC3")]))
# Share of each group's speeches that cite at least one source
any_src  <- pct(grp_table(win_speeches$speech_id %in% win_sources$speech_id))
pct_any_src <- pct(mean(win_speeches$speech_id %in% win_sources$speech_id))
pct_dispute <- pct(mean(win_sources$use == "dispute"))

# Concepts addressed by >= 10 speeches in each party, and how many of them the
# parties take opposite sides on (sign of the mean position)
min_n <- 10
opposite <- do.call(rbind, lapply(windows$window, function(w) {
  d <- beliefs[beliefs$window == w & beliefs$party == "D" & beliefs$n >= min_n, ]
  r <- beliefs[beliefs$window == w & beliefs$party == "R" & beliefs$n >= min_n, ]
  m <- merge(d, r, by = "concept_id")
  data.frame(window = w, n_both = nrow(m),
             n_opposite = sum(sign(m$position.x) != sign(m$position.y)))
}))
rownames(opposite) <- names(wkey)
# Correlation of the parties' concept salience within each debate
party_cor <- sapply(windows$window, function(w)
  f2(cor(beliefs$salience[beliefs$window == w & beliefs$party == "D"],
         beliefs$salience[beliefs$window == w & beliefs$party == "R"])))
names(party_cor) <- names(wkey)

# Robustness: climate/energy as the main subject of the speech
pct_focus <- pct(tapply(win_speeches$speech_focus_climate %in% 1, win_speeches$window, mean))
names(pct_focus) <- names(wkey)
bf <- merge(beliefs, beliefs_focus, by = c("concept_id", "window", "party"))
cor_focus_sal <- f2(cor(bf$salience.x, bf$salience.y))
cor_focus_pos <- f2(cor(bf$position.x, bf$position.y, use = "complete.obs"))
sf <- merge(sources_by_group, sources_by_group_focus,
            by = c("source_type", "window", "party"))
cor_focus_src <- f2(cor(sf$salience.x, sf$salience.y))

# Table: salience of each concept (% of speeches) by debate and party
tab_salience <- wide(beliefs, "concept_id", "salience")
tab_salience <- data.frame(ID = rownames(tab_salience),
                           round(100 * tab_salience), check.names = FALSE)
names(tab_salience)[-1] <- grp_labs
rownames(tab_salience) <- NULL

# Table: dispersion (SD of speech-level positions) where a group has at least
# min_n speeches on the concept; concepts with no such cell are dropped
disp <- wide(beliefs, "concept_id", "dispersion")
disp[wide(beliefs, "concept_id", "n") < min_n] <- NA
disp <- disp[rowSums(!is.na(disp)) > 0, , drop = FALSE]
tab_dispersion <- data.frame(ID = rownames(disp),
                             apply(disp, 2, function(x) ifelse(is.na(x), "", f2(x))),
                             check.names = FALSE)
names(tab_dispersion)[-1] <- grp_labs
rownames(tab_dispersion) <- NULL

# Table: share of speeches citing each source type by debate and party
source_labels <- c(
  advocacy = "Advocacy groups", business = "Business", congress = "Congress",
  constituent = "Constituents", courts = "Courts", executive = "Executive branch",
  expert_generic = "Unnamed experts", govt_analysis = "Government analysis",
  international = "International bodies", media = "Media",
  military_security = "Military and security", other = "Other",
  personal = "Personal experience", public_opinion = "Public opinion",
  science = "Science", state_local = "State and local government",
  think_tank = "Think tanks")
tab_sources <- wide(sources_by_group, "source_type", "salience")
tab_sources <- tab_sources[order(-rowMeans(tab_sources)), ]
tab_sources <- data.frame(Source = unname(source_labels[rownames(tab_sources)]),
                          round(100 * tab_sources), check.names = FALSE)
names(tab_sources)[-1] <- grp_labs
rownames(tab_sources) <- NULL

# Figure: mean position on each concept by debate and party; point area is
# proportional to salience; cells with fewer than 5 speeches are omitted
plot_positions <- function(min_speeches = 5) {
  cols <- c(D = "#2166ac", R = "#b2182b")
  pchs <- c(D = 16, R = 17)
  y <- rev(seq_along(concept_ids))
  op <- par(mfrow = c(1, 3), mar = c(4, 1, 2, 0.5), oma = c(2, 3, 0, 0),
            family = "serif")
  on.exit(par(op))
  for (w in windows$window) {
    plot(NA, xlim = c(-2, 2), ylim = c(0.5, length(y) + 0.5), yaxt = "n",
         xlab = "Mean position", ylab = "", main = w, bty = "l")
    abline(v = 0, col = "grey60", lty = 2)
    abline(h = y, col = "grey92")
    abline(h = c(25.5, 13.5), col = "grey50")
    if (w == windows$window[1])
      axis(2, at = y, labels = concept_ids, las = 1, cex.axis = 0.75, outer = FALSE)
    for (p in c("D", "R")) {
      d <- beliefs[beliefs$window == w & beliefs$party == p &
                     beliefs$n >= min_speeches, ]
      points(d$position, y[match(d$concept_id, concept_ids)], pch = pchs[[p]],
             col = adjustcolor(cols[[p]], 0.8), cex = 0.5 + 3 * sqrt(d$salience))
    }
  }
  par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
  plot.new()
  legend("bottom", legend = c("Democrats", "Republicans"), pch = pchs,
         col = cols, bty = "n", cex = 0.9, horiz = TRUE)
}
