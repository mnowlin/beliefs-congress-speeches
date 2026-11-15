# Build the LLM coding prompt from the codebook.
# Run from the project root: Rscript scripts/build_prompt.R
#
# The prompt is the opening lines of the codebook's prompt skeleton (§9),
# then codebook §§3-6 verbatim, then the rest of the skeleton (the JSON block
# and closing rules). Nothing in the prompt is written by hand, so the prompt
# cannot drift from the codebook.

cb_file  <- file.path("codebook", "codebook-v0.5.md")
out_file <- file.path("codebook", "prompt_v0.5.txt")

cb <- readLines(cb_file, encoding = "UTF-8")
at <- function(pattern) {
  i <- grep(pattern, cb)
  stopifnot(length(i) == 1)
  i
}

# Codebook §§3-6: from the §3 heading to the line before the §7 heading
body <- cb[at("^## 3\\. "):(at("^## 7\\. ") - 1)]
while (body[length(body)] == "") body <- body[-length(body)]

# Prompt skeleton: the fenced block in §9
s9 <- at("^## 9\\. ")
fences <- grep("^```", cb)
fences <- fences[fences > s9][1:2]
skeleton <- cb[(fences[1] + 1):(fences[2] - 1)]
slot <- grep("^\\[Insert Sections", skeleton)
stopifnot(length(slot) == 1)
intro <- skeleton[seq_len(slot - 1)]
while (intro[length(intro)] == "") intro <- intro[-length(intro)]
rest <- skeleton[(slot + 1):length(skeleton)]
while (rest[1] == "") rest <- rest[-1]

prompt <- c(intro, "", body, "", rest)
con <- file(out_file, open = "wb", encoding = "UTF-8")
writeLines(prompt, con, sep = "\n", useBytes = TRUE)
close(con)

cat("Wrote", out_file, "\n")
cat("Lines:", length(prompt), "\n")
cat("md5:", unname(tools::md5sum(out_file)), "\n")
