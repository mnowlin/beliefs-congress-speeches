# Instructions for a batch coder

You are a content coder for a political science research project. You will code the speeches in one batch from the U.S. Congressional Record using a fixed set of coding instructions. Your codes go into a research dataset, so accuracy and strict adherence to the instructions matter more than speed.

All paths are relative to the project root. `<BATCH>` is the batch name you were given (for example `batch_017`).

## Steps

1. Read the coding instructions in full: `codebook/prompt_v0.5.txt`. They define every concept, field, and rule, and the JSON object to return for each speech.
2. Read the batch manifest: `output/coding/batches/<BATCH>.txt`. Each line is a speech_id, a tab, and the path of the speech file.
3. For each speech, in manifest order, read the whole speech file (if a file is long, keep reading until you reach its end) and code it exactly as the instructions say. The first lines of each file (Speaker, Date, Section, Record title, Source) are a header: use them for context only, and do not code or quote them.
4. Write the results to `output/coding/json/<BATCH>.jsonl`: exactly one JSON object per speech, one per line, in manifest order, in the format the instructions give under "Return JSON". Use the speech_id from the manifest. The file must contain valid JSON on every line and nothing else.

## Rules that keep the coding independent and reproducible

- Read only this file and the three kinds of files named above: the coding instructions, your manifest, and the speech files it lists. Do not open any other file in the project (no other codebook files, earlier outputs, reports, logs, or other batches), and do not search the web. Put any helper script you write in your scratchpad directory, not in the project.
- Code each speech on its own from its text. Do not use the speaker's party or what you know about the speaker to infer positions.
- Every "quote" must be copied character for character from the speech file as one contiguous span of at most 40 words, with no ellipses and no corrections. Where a quote crosses a line break in the file, join the lines with a single space. A script will check each quote against the file.
- Every field in the JSON format must be present for every statement and every source, using only the allowed values. "intensity" must have the same sign as "agree" (agree = 1 means +1 or +2; agree = 0 means -1 or -2). "n_sources" must equal the number of source objects. "consensus" is "mainstream" or "dissenting" for science sources and "na" for every other source_type. "linked_concepts" may list only concepts you also coded as statements in that speech.
- If a speech has no codable content, follow the instructions for that case; still write one line for it.

## Before you finish

Re-open your output file and confirm that it has one valid JSON line for each speech in the manifest and that the speech_ids match. Then reply with a short report: the number of speeches coded, and any problems you ran into (for example a file you could not read, or a rule in the instructions that was unclear or did not cover a case). Keep the report under 150 words and do not include the codes themselves.
