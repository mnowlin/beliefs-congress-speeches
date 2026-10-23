# Draw the 150-speech stratified pilot sample for codebook v0.3 (Section 8).
# Run from the project root: Rscript scripts/pilot_sample.R
# Base R only.

set.seed(20260928)

data_dir <- "data"
out_dir  <- file.path("output", "pilot")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

read_corpus <- function(folder, label) {
  df <- read.csv(file.path(data_dir, folder, "index.csv"), stringsAsFactors = FALSE)
  df$corpus <- label
  df$path <- file.path(data_dir, folder, df$file)
  df
}

ct  <- read_corpus("cap-and-trade-congressional-record", "CT")
# The pilot was drawn before rule C (bill_energy) was added to the 2000-2012
# corpus on 2026-10-23; drop those speeches to reproduce the original sample
ct  <- ct[ct$keep_rule != "bill_energy", ]
ira <- read_corpus("ira-congressional-record", "IRA")
# Corpora have different keyword-hit columns; keep the shared ones
shared <- intersect(names(ct), names(ira))
idx <- rbind(ct[, shared], ira[, shared])

# Eligibility: >= 150 words, identified member
idx <- idx[idx$words >= 150 & !is.na(idx$bioGuideId) & idx$bioGuideId != "", ]

# Largest-remainder proportional allocation
alloc <- function(counts, n) {
  raw <- n * counts / sum(counts)
  a <- floor(raw)
  r <- n - sum(a)
  if (r > 0) {
    top <- order(raw - a, decreasing = TRUE)[seq_len(r)]
    a[top] <- a[top] + 1
  }
  a
}

member_n <- integer(0)  # speeches drawn per member (cap = 2 across the sample)
cap <- 2

draw <- function(pool, n) {
  pool <- pool[sample(nrow(pool)), , drop = FALSE]
  keep <- integer(0)
  for (i in seq_len(nrow(pool))) {
    if (length(keep) == n) break
    id <- pool$bioGuideId[i]
    k <- if (is.na(member_n[id])) 0L else member_n[id]
    if (k < cap) {
      keep <- c(keep, i)
      member_n[id] <<- k + 1L
    }
  }
  pool[keep, , drop = FALSE]
}

# Draw within a cell, allocating proportionally across keep_rule;
# any shortfall in a keep_rule stratum is filled from the rest of the cell.
draw_cell <- function(cell, n) {
  tab <- table(cell$keep_rule)
  a <- alloc(as.numeric(tab), n)
  names(a) <- names(tab)
  out <- do.call(rbind, lapply(names(a), function(k) draw(cell[cell$keep_rule == k, ], a[[k]])))
  short <- n - nrow(out)
  if (short > 0) {
    rest <- cell[!cell$speech_id %in% out$speech_id, ]
    out <- rbind(out, draw(rest, short))
  }
  out
}

cells <- expand.grid(section = c("House", "Senate"), party = c("D", "R"),
                     corpus = c("CT", "IRA"), stringsAsFactors = FALSE)

sample_list <- list()
for (j in seq_len(nrow(cells))) {
  cl <- cells[j, ]
  pool <- idx[idx$corpus == cl$corpus & idx$party == cl$party & idx$section == cl$section, ]
  s <- draw_cell(pool, 18)
  s$cell <- paste(cl$corpus, cl$party, cl$section, sep = "_")
  sample_list[[j]] <- s
}

# Extensions of Remarks: 3 per corpus, any party
for (cp in c("CT", "IRA")) {
  pool <- idx[idx$corpus == cp & idx$section == "Extensions", ]
  s <- draw(pool, 3)
  s$cell <- paste(cp, "Extensions", sep = "_")
  sample_list[[length(sample_list) + 1]] <- s
}

pilot <- do.call(rbind, sample_list)
pilot$pilot_order <- sample(nrow(pilot))  # random coding order
pilot <- pilot[order(pilot$pilot_order), ]

write.csv(pilot, file.path(out_dir, "pilot_sample.csv"), row.names = FALSE)

cat("Drew", nrow(pilot), "speeches\n")
print(table(pilot$cell))
print(table(pilot$corpus, pilot$keep_rule))
cat("Max speeches per member:", max(table(pilot$bioGuideId)), "\n")
cat("R version:", R.version.string, "\n")
