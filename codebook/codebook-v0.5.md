---
title: Codebook — Beliefs and Information Sources in the Congressional Record
created: 2026-09-25
updated: 2026-10-23
status: v0.5 final (information-source module and certainty revision; source types revised after the v0.5 re-pilot; pre-reliability)
---

# Codebook: Beliefs and Information Sources in the Congressional Record

**Status:** v0.5 final, for human reliability coding. v0.4 was revised after the 150-speech LLM pilot (Pilot Report v0.4, in the Policy Learning in Congress project). v0.5 adds an information-source module (§4b, for RQ2) and revises speaker certainty (§4a). The source module was re-piloted on the same 150 speeches (`output/pilot/v0.5/pilot-report-v05.md`) and the `source_type` list revised from the results; human reliability testing has not been done for any part of the codebook. Anchor examples marked with a speaker name are **verbatim quotes from the pilot**; unmarked examples are constructed paraphrases.

v0.4 and earlier live in `00-policy-learning-congress/output/pilot-codebook-congressional-belief-networks.md` and are unchanged. The concept list (§4) is identical to v0.4. Concept-boundary changes proposed in Pilot Report v0.4 §6.2–6.3 (PC6/leakage, PC4 wording, PC4/PC9, PC7 "all of the above," SC13) are deferred until the reliability results are in.

**Version history**
- **v0.5 final (2026-10-23):** boundary anchors for DC1, DC4, PC4, and SC4, the concepts with the lowest re-code agreement (§4); attributed anchors throughout the codebook replaced where they came from speeches in the human reliability set; DC4's disagree anchor replaced (a "pays for itself" claim is no longer DC4); the "free-market approach" borderline rule narrowed (§5). `source_type` revised after the re-pilot (Pilot Report v0.5 §6): `other` split into `courts`, `congress`, and `public_opinion`; new `expert_generic` for unattributed expert claims and estimates; `labor` merged into `advocacy` and `religious` into `other` (both under 5% of speeches); note on dissenting ("contrarian") science. The re-pilot used the draft prompt, archived as `output/pilot/v0.5/prompt_v0.5.txt` (md5 `88bee1e99e2366dc4bbd83da14d7c80a`).
- **v0.5 draft (2026-10-23):** new §4b information sources: one row per source × speech with type, specificity, evidence form, use, and linked concepts; sources are recorded even in inserted material the speaker only introduces (§3a). `speaker_certainty` (3 levels) replaced by binary `hedged`; emphasis is measured by a hedge/booster dictionary instead of by coder judgment; "believe in X" is not a hedge (§4a). Corpus paths updated to this project's `data/`.
- **v0.4 (2026-09-28):** rules for inserted and endorsed material (§3a); regressivity rule for DC2; SC2 broadened to all carbon pricing; PC7 rewritten as a two-sided proposition about *how* to achieve energy security; emphatic certainty tightened; `bill_focus` list expanded; `procedural_objection` added; 5 new candidate concepts (‡); agree-only nodes flagged; verbatim anchor quotes added.
- **v0.3:** node set no longer tied to the 17 public-survey nodes; 6 elite-discourse candidates (†).
- **v0.2:** statement-level `intensity` and `speaker_certainty` (§4a); see the belief-certainty memo (`output/measuring-beliefs-belief-certainty-congressional-record.md`, Policy Learning in Congress project).

**Design rationale:** see `output/congressional-record-belief-networks-feasibility.md` in the Policy Learning in Congress project.

---

## 1. Purpose

Code the **climate/energy policy beliefs members of Congress express** in floor speeches so that:
1. a **speech-level belief network** (Ising model + Bayesian network) can be estimated, mirroring Nowlin (2026, *SSQ*); and
2. the same codes can be imported into **Discourse Network Analyzer / `rDNA`** to build concept × concept and actor congruence/conflict networks (Leifeld; Fisher & Leifeld, 2019); and
3. the **information sources** members cite can be identified, classified, and linked to the beliefs they are used to support (§4b; RQ2), so that belief and source salience can be compared across periods (RQ3).

Concepts are organized by ACF tier (deep core / policy core / secondary) and chosen for how members of Congress actually argue about climate and energy. They are **not** constrained to match the 17 survey nodes in Nowlin (2026). Elite–public comparisons, where made, are qualitative.

**Number of nodes.** v0.4 lists 26 concepts retained from v0.3 plus 5 **new candidates (‡)**. The † concepts from v0.3 all met the pilot prevalence criterion and are retained pending reliability. A concept stays only if it meets the prevalence and reliability criteria in §8.

**Agree-only nodes.** In the pilot, 8 concepts had < 10% disagree statements: DC4, PC2, PC5, PC9, SC9, SC10, SC11, and old PC7. For these, the analysis matrix uses a single "agree" indicator; "disagree" codes are kept in the statement file but not modeled as separate nodes unless they reach 10% in the full data.

## 2. Corpora and unit of analysis

| Item | Definition |
|---|---|
| Corpora | `data/cap-and-trade-congressional-record/` (2000–2012); `data/ira-congressional-record/` (2018–2026) |
| Document | One speech file (`speeches/{year}/{speech_id}.txt`) = one Member's turn. **Inserted material is not always removed** (see §3a). |
| Actor | The speaking Member (`bioGuideId` from `index.csv`). Party, state, chamber, and Congress come from metadata, **not** from coding. |
| Statement | A passage in which the speaker expresses a position on **one** concept. |
| Source (new in v0.5) | An external origin of information or authority that the speaker invokes (§4b). |
| Coding granularity | For each speech, code **each concept × stance combination at most once**, using the clearest passage. Code **each distinct source at most once per speech** (§4b). |

## 3. What to code, in general

- **Code the speaker's own position.** Positions attributed to others are coded only as the speaker's endorsement or rejection of them.
  - "Some of my colleagues claim climate change is a hoax. They are wrong." → PC1 **agree**.
- **Explicit or unambiguous implied stances only.** Rhetorical questions and sarcasm are coded when the intended stance is unmistakable in context; otherwise do not code. Ironic or mocking framing whose stance is unclear (e.g., "this idea of global warming" in an attack on something else) is **not** coded.
- **Do not infer from party** or from what the speaker "would" believe. Silence on a concept means **not coded**, never disagreement.
- **Deep core concepts need explicit value language.** A general appeal to principle (freedom, fairness, stewardship, fiscal restraint, separation of powers, federalism) must appear in the text. General statements of principle count even if not energy-specific (e.g., "We must strengthen our economy, not grow our government" → DC1).
- **A bill is not an instrument.** Opposition to a bill is coded to an instrument concept only when the stated reason concerns that instrument. Otherwise code only `bill_stance` (§6) plus whatever reasons are given.
  - "This bill's cap-and-trade scheme is a national energy tax on every family." → SC1 **disagree**, PC4 **agree**.
  - "This bill spends too much money." (IRA) → DC4 **agree**; no instrument code.
- **Timing and germaneness objections are not instrument stances.** "Now is not the time to debate solar tax credits" (in an unrelated emergency bill) → code the instrument only if the speaker also objects on the merits; otherwise note in `memo`.
- **Conditional positions:** code the stance and set `conditional = 1`.
  - "I could support a cap on emissions if China and India did the same." → SC1 agree (conditional), PC6 agree.
- **Procedural speech** (unanimous consent, scheduling, tributes with no policy content) → `no_codable_content = 1`.

### 3a. Inserted and endorsed material (new in v0.4)

The pilot found letters, editorials, bill text, and Statements of Administration Policy inside speech files. Apply these rules:

| Material | Rule |
|---|---|
| Letters, articles, reports, or SAPs the speaker only **introduces** ("I include in the Record the following letters…") | Not coded. If the file contains nothing else, `no_codable_content = 1`. |
| Inserted material the speaker **summarizes or characterizes in their own words** ("this editorial shows the bill will reduce temperatures by only 0.028 degrees") | Code the speaker's own sentence only, with `confidence` ≤ 2. |
| Material the speaker **quotes within their remarks and explicitly endorses** ("I could not agree more") | Code, using the speaker's endorsing sentence as the `quote` where possible. |
| **Bill or amendment text** read by the Clerk, including an amendment the speaker offers | Not coded as a stance. Code only the speaker's own remarks about it. |
| A **letter the speaker co-signed** and submits (e.g., a caucus letter) | Code as the speaker's own position; set `memo` to `co-signed letter`. |
| **Another Member's remarks** in the same file (speaker-split error) | Not coded; flag `DATA: speaker split` in `speech_memo`. |

**Sources in inserted material (v0.5).** The rules above govern **stance** codes only. Inserted material is itself an information source: a letter, report, article, or SAP the speaker introduces into the Record is coded as a **source** (§4b) with `inserted = 1`, even when it is not coded as a stance. A speech that only inserts material is therefore `no_codable_content = 1` for stances but can still have source rows. Sources cited **inside** the inserted material (e.g., a study an inserted editorial mentions) are not coded.

## 4. Concepts

Each concept is a **proposition**. Code **agree (1)** or **disagree (0)**. A speech may contain both stances on the same concept (ambivalence); code both.

### Deep core (DC): abstract values that span policy domains

| ID | Proposition | Agree looks like | Disagree looks like |
|---|---|---|---|
| **DC1** | Government should minimize intervention; markets and individuals, not federal mandates, should make energy choices. | "We must strengthen our economy, not grow our government." (Meuser) | "voluntary programs unfortunately do not work." (Lieberman) |
| **DC2** | Policy should protect disadvantaged, low-income, or frontline communities from unfair burdens and share benefits fairly. | "Low- and middle-income households spend a greater share of their budget on energy costs than higher income households." (Fudge); "It is a regressive tax that imposes a greater burden … on the poor" (Inhofe) | Explicit rejection of equity targeting: "$3.4 billion for tree equity. Tree equity, that surely is going to bring down gas prices" (J. Smith) |
| **DC3** | We have a moral obligation to protect the environment/planet for future generations. | "we have a responsibility here, to future generations and to all of us, to try to get this right." (Kerry) | "if only Americans grow poorer, the planet will somehow grow purer." (Lee, mocking the trade-off) |
| **DC4** | Federal spending, taxes, and debt should be restrained. | "higher taxes, higher spending, and higher debt." (Ernst) | "The austere and irresponsible cuts in this bill do not align with America's values." (Pingree) |
| **DC5 †** | Major energy/climate policy should be made by Congress, not by executive agencies or the courts. | "the elected representatives of the people, Congress, should be the ones making the decision, not unelected bureaucrats" (Bunning) | "EPA already has the authority to regulate carbon pollution, and the Supreme Court has said so. Congress should let the agency do its job." (constructed; not observed outside the coding set) |
| **DC6 †** | States, not the federal government, should decide their own energy and climate policies. | "The bill overrides State energy and environmental legal authorities … So much for States rights" (Lieberman) | Overturning EPA's findings is bad "because a dozen States, such as Vermont and California, could then go forward, each with their own rules and standards." (Leahy) |

*Notes:*
- "Debt on future generations" is **DC4**, not DC3.
- **DC2 regressivity rule (v0.4):** DC2 codes the *value* (fairness to low-income or disadvantaged people), whichever side of the policy debate it is used on. "It hurts the poor most" used **against** a climate policy is DC2 **agree**, coded together with the relevant PC4 or instrument code. The network then shows DC2's link to opposition through its co-occurrence with PC4, not through a separate node. Use normal `confidence` (not 1) when the fairness language is explicit.
- DC5 is an institutional value specific to legislators (separation of powers); it is not the same as DC1 (size of government).
- DC6 is cross-party in the pilot (55% D); keep it as a candidate bridge node.
- Hierarchy and fatalism are not coded.

### Policy core (PC): beliefs about the climate/energy problem

| ID | Proposition | Agree | Disagree |
|---|---|---|---|
| **PC1** | Climate change is happening and is substantially human-caused. | "There is no doubt that human-induced emissions are warming the planet." (Lieberman) | "It isn't global warming, it is global cooling." (Inhofe) |
| **PC2** | Climate change poses serious risks or harms, now or in the future. | "Climate change is a clear and present danger." (Pingree) | "there is a lot of hysteria out here. The hysteria out here is not well founded." (Inhofe) |
| **PC3** | Climate science is reliable and there is a scientific consensus. | "In fact, scientific consensus has clearly been established" (Matheson) | "the so-called consensus on manmade global warming is not holding up." (Inhofe) |
| **PC4** | Climate/clean-energy policy imposes unacceptable economic costs (energy prices, jobs, competitiveness). | "This bill will cost you money. It will make your gasoline more expensive." (Enzi) | "these new emission requirements did not place an undue burden on companies or raise costs for consumers." (Carper) |
| **PC5** | Clean energy / climate action creates economic opportunity (jobs, manufacturing, investment). | "A new energy direction for our country will create jobs and grow our economy." (Durbin) | "This cap-and-trade proposal will fail to do that when America needs them most. We will lose jobs." (G. Davis) |
| **PC6** | US action is futile or unfair unless major emitters (China, India, developing countries) also act. | "what the United States does unilaterally is not going to have any impact" (Sessions) | "Many here in the US will try to use another country's failure or inaction as an excuse for not doing anything. But it is just that, an excuse." (McCain) |
| **PC7** (revised) | Energy security is best achieved through clean energy and efficiency rather than expanded fossil production. | "Real security means tackling the climate crisis head-on--building a clean energy future here at home" (Markey) | "endanger our own energy security to meet these arbitrary net zero deadlines." (Cornyn); a coal phase-out "will make us more dependent. It stops the use of coal in this country." (Foxx) |
| **PC8 †** | Clean-energy policy strengthens US economic and strategic competitiveness against China. | "gut the clean energy tax credits … it will be a total surrender to China on clean energy." (Wyden) | "Pouring government subsidies into green pet projects … would mean handing a massive windfall to Chinese producers" (McConnell) |
| **PC9 †** | The clean-energy transition threatens the reliability of the electric grid. | "If the grid becomes too reliant on intermittent green energy sources, we will begin to see manufacturers shutter their operations." (Latta) | "Renewables and storage make the grid more resilient." (not observed in pilot) |

*Notes:*
- **PC7 rewrite (v0.4):** In the pilot, old PC7 ("energy security should be a priority") had 0% disagreement, but the two parties meant opposite things by it. PC7 is now a two-sided proposition about **the path** to security. A generic appeal to security or independence that names no path is **not coded**. Security through **both** paths ("all of the above") → code agree and disagree (ambivalence) with `memo = all-of-the-above`. Pilot codes for old PC7 must be recoded before analysis.
- PC6 (futility: others won't act) and PC8 (competition over industries and supply chains) are distinct China arguments; code both if both are made.
- PC9 is agree-only and entirely Republican in the pilot; keep as a candidate but expect it to act as a partisan marker.
- PC4 and PC9 co-occur mainly in Republican GND/IRA-era speeches; test distinctness in the reliability study.

### Policy core candidates (‡, new in v0.4)

| ID | Proposition | Agree | Disagree |
|---|---|---|---|
| **PC10 ‡** | Fossil-fuel interests are deliberately manufacturing doubt or blocking climate action. | "This web of denial, paid for by the fossil fuel industry, has stymied Congress for a decade." (Whitehouse) | Explicit rejection of the claim (rare). |
| **PC11 ‡** | Natural gas is a climate solution (cleaner fuel that lowers emissions). | "How about we embrace clean-burning American natural gas" (Roy, answering "what are we going to do?" about climate change) | "natural gas production and use become part of the climate problem" without methane controls (Carper) |
| **PC12 ‡** | Climate policy costs fall unfairly on particular regions or States. | "This bill is nothing more than the economic colonization of the heartland by the coastal States" (G. Davis); "I remain concerned that this energy bill will result in unfair regional wealth transfers." (Matheson) | Explicit claim that burdens are fairly shared (rare). |

*Note:* PC10 is a belief about the politics of the problem rather than the problem itself; it appeared in 5 Democratic speeches in the pilot. PC12 is distinct from DC2 (fairness to people) and DC6 (state authority).

### Secondary (SC): policy instruments

Code a stance on the **instrument class**, whether or not the speech names a specific bill.

| ID | Proposition: "The federal government should adopt/keep…" | Includes |
|---|---|---|
| **SC1** | …a cap-and-trade / emissions-trading system. | Waxman-Markey, Lieberman-Warner, Kerry-Boxer caps; "cap-and-tax" framing = **disagree**; tradable CAFE or GHG credits |
| **SC2** (broadened) | …a carbon tax, carbon fee, or **unspecified price on carbon**. | Carbon fee-and-dividend; border carbon adjustments; "put a price on carbon" when no cap is named |
| **SC3** | …EPA regulation of greenhouse gases. | Endangerment finding, Clean Power Plan, power-plant/vehicle/methane GHG rules, Clean Air Act authority |
| **SC4** | …participation in international climate agreements. | Kyoto, Copenhagen, Paris, Kigali; rejoining/withdrawing (withdraw = **disagree**) |
| **SC5** | …clean-energy tax credits and subsidies. | PTC/ITC, IRA credits (45Y, 48E, 45X, 30D, 25D, 45Q, 45V, 45U), EV credits, DOE loans and grants for deployment; OBBB repeal = **disagree** |
| **SC6** | …clean-energy mandates and performance standards. | Renewable/clean electricity standards, CEPP, efficiency and building codes, CAFE, EV mandates, lifecycle fuel GHG standards |
| **SC7** | …expand domestic fossil-fuel production and infrastructure. | Drilling, federal leasing, pipelines, LNG exports, coal, coal-to-liquids; "all of the above" = agree |
| **SC8** | …expand nuclear energy. | New reactors, SMRs, licensing reform, waste storage for nuclear expansion |
| **SC9** | …invest in energy innovation/technology R&D (incl. carbon capture) as a climate strategy. | ARPA-E, DOE R&D, CCS/DAC, "innovation not regulation" |
| **SC10 †** | …streamline permitting and environmental review for energy infrastructure. | NEPA reform, transmission siting, "permitting reform"; note clean vs. fossil in `memo` |
| **SC11 †** | …fund climate adaptation and disaster resilience. | Resilience grants, flood/wildfire mitigation, adaptation funding linked to climate |
| **SC12 ‡** | …promote natural and land-based carbon sinks. | Forest carbon, reforestation, climate-smart agriculture, cover crops, blue carbon |
| **SC13 ‡** | …require or allow climate-risk disclosure and climate/ESG considerations in finance. | SEC climate disclosure, ESG in pension investment (DOL rule); opposing ESG rules = **disagree** |

*Notes:* SC10 is cross-party (clean vs. fossil projects). SC11 is coded only when resilience spending is linked to climate or extreme weather. SC12 excludes forest management framed only as wildfire prevention (that is SC11). SC2 was the weakest node in v0.3 (3%); broadening it to unspecified carbon pricing is intended to raise prevalence.

### Boundary anchors: DC1, DC4, PC4, SC4 (v0.5 final)

These four concepts had the lowest re-code agreement in the v0.5 re-pilot (κ 0.69–0.76; Pilot Report v0.5 §5). The anchors below are verbatim passages from pilot speeches, mostly ones on which the two LLM runs disagreed, with the code each should receive. Like every attributed anchor in this codebook, they come from pilot speeches **outside** the human reliability set; the few constructed examples fill gaps where no such passage exists. "Not coded" means not coded **for this concept**; other codes may apply.

**DC1 (limited government).** Code the *value*: government should step back and leave choices to markets and individuals. Complaints about a particular regulation, and labels for an instrument, are not the value.

| Passage | Code | Why |
|---|---|---|
| "Making someone dependent on government is not helping them; it is hurting them." (Tuberville, in a welfare passage) | DC1 agree | General principle; counts even outside energy (§3) |
| "allow consumers and the market to determine the cars and engine technology needed" (Allen, on EPA vehicle rules) | DC1 agree (+ SC3 disagree) | States that markets and consumers, not government, should decide |
| "we decided in the House we were going to allow a free-market approach to handle this rather than have the United States EPA regulate emissions in this country." (Boccieri) | DC1 agree (+ SC3 disagree) | Prefers markets **over** government direction, not just a label |
| "sticking a fork in these inflation- causing laws and burdensome regulations" (Ernst) | Not coded | Attack on regulation, no general principle; code SC3 or PC4 if the target or cost is named |
| "like myself, who support a market-based carbon cap- and-trade system" (Snowe) | Not coded (SC1 agree) | "Market-based" labels the instrument; no stated preference for markets over government |
| "voluntary programs unfortunately do not work." (Lieberman) | DC1 disagree | Rejects leaving the choice to voluntary action |

**DC4 (fiscal restraint).** Like DC2, DC4 codes the *value*, whichever side of a bill it is used on. A supporter who says a bill is "paid for" or "reduces the deficit" is appealing to fiscal restraint: DC4 **agree**. DC4 **disagree** is reserved for rejecting restraint (attacking cuts or austerity, or saying deficits do not matter). Claims about the economic returns of spending, or the cost of climate damage, are not DC4. A climate policy called a "tax" because it raises energy prices is PC4 (+ SC1), not DC4, unless the speaker also appeals to lower taxes, spending, or debt as such.

| Passage | Code | Why |
|---|---|---|
| "the reckless tax-and-spending spree is not helping the American people at all" (Cornyn) | DC4 agree | Appeal to restraining taxes and spending |
| "This bill is fully paid for and reduces the deficit." (constructed; a supporter) | DC4 agree | Fiscal restraint invoked in **support** of a bill |
| "It will balloon the deficit" (Markey, on the OBBB) | DC4 agree | Fiscal restraint is not a partisan code: a Democrat opposing a bill on deficit grounds |
| "We should oppose the nuclear industry's latest effort to raid the public purse." (Boxer) | DC4 agree (+ SC8 disagree) | Subsidies opposed on fiscal grounds |
| "The austere and irresponsible cuts in this bill do not align with America's values." (Pingree) | DC4 disagree | Rejects spending restraint |
| "it is proof that investing in America pays off." (Huffman) | Not coded (PC5 agree) | A claim about returns, not about restraint |

**PC4 (economic costs of climate policy).** "Climate/clean-energy policy" includes restrictions on fossil-fuel supply adopted for climate reasons (LNG export pauses, leasing limits). Agree when the speaker says such policy raises costs or harms jobs or competitiveness, or treats economic cost as a limit on climate action. Disagree when the speaker says the policy lowers costs, saves money, or does not raise prices. Not coded: costs conceded by a supporter without calling them unacceptable; the cost of climate damage (PC2); savings outside energy (health care, drug prices); questions raised without a stance.

| Passage | Code | Why |
|---|---|---|
| "Pausing LNG export approvals will raise prices here at home." (constructed) | PC4 agree | Fossil supply restriction framed as raising prices |
| "We need smart energy policies that will strengthen our economy without bankrupting American families." (Cornyn) | PC4 agree, `intensity` +1 | Cost as a limit on climate action; `memo = constraint` |
| "bring us fuel economy so we can save money at the gas pumps" (Durbin) | PC4 disagree (+ SC6 agree) | The policy saves consumers money |
| "If we pass this resolution, it is not a case of hurting the economy. Quite the opposite." (Leahy) | PC4 disagree | Rejects the claim that climate policy hurts the economy |
| "But it's going to cost everybody more. It just does." (Woolsey, a supporter) | Not coded | Cost conceded, not called unacceptable; note in `memo` |
| "the cost of inaction was as high and as dangerous as it is in this moment." (E. B. Johnson) | Not coded (PC2 agree) | Cost of climate damage, not of policy |
| "whether the bill adequately protected the economy" (Specter) | Not coded | A question raised, no stance taken |

**SC4 (international agreements).** Code SC4 only when the speech refers to an **agreement, treaty, or negotiation**, named (Kyoto, UNFCCC, Copenhagen, Paris, Glasgow/COP, Kigali) or explicit ("an international agreement," "our treaty obligations"). A general call for global cooperation with no agreement in view is not SC4 (consider PC6 disagree if the point is that the US should act with others).

| Passage | Code | Why |
|---|---|---|
| "160-some nations signed onto an agreement to try to restrain greenhouse gases" (Kerry, praising it) | SC4 agree | Endorses the agreement (UNFCCC) |
| "the United States meets its obligations by accurately reporting its total annual greenhouse gas emissions" (Snowe) | SC4 agree | Treaty reporting obligations |
| "President Biden is eager to put a show on in Glasgow and impress world leaders with dubious commitments that he can't keep" (Cornyn) | SC4 disagree | Dismisses the COP commitments |
| "I believe we must urgently address this looming issue--in partnership with the rest of the world" (Cantwell) | Not coded | Global cooperation, no agreement named in the speech |

## 4a. Intensity and hedging

Code both for **every** statement, in addition to `agree`.

**`intensity`**: strength of the stance, on the same proposition.

| Value | Meaning | Example (PC2) |
|---|---|---|
| −2 | Strong disagreement | "We cannot continue to bow to the Ashtoreth of climate alarmism" (Lee) |
| −1 | Disagreement | "The purpose of the Clean Air Act was to reduce substances toxic to humans, not substances that are not directly harmful to us." (Bunning) |
| +1 | Agreement | "climate change will impact all of these areas, and more." (Tonko) |
| +2 | Strong agreement | "No one in America will be immune from global warming." (Blumenauer) |

`intensity` sign must match `agree` (agree = 1 → +1/+2; agree = 0 → −1/−2). Intensity captures **how far** the position is from neutral, not how sure the speaker sounds.

**`hedged`** (0/1, replaces `speaker_certainty` in v0.5): does the **speaker** qualify their own stance or present it as tentative? This is not the coder's `confidence`.

| Value | Meaning | Markers |
|---|---|---|
| 1 = hedged | Stance qualified or tentative | *may, might, could, possibly, perhaps, I think, I believe, I suspect, it appears, it seems, likely, probably, as I understand it, to some extent, some scientists say*; "I don't know"; "we can't be sure"; explicit acknowledgement of uncertainty about the speaker's own stance |
| 0 = not hedged | Stance stated without qualification, whether plainly or emphatically | All other statements |

**Why the change.** Under v0.3, 73% of statements were coded emphatic; under the tightened v0.4 rule, 90% were coded neutral (Pilot Report v0.4 §6.1). Neither split carried much information, and the emphatic level mostly recorded whether a listed booster word was present. The partisan signal is in hedging (Republican statements on PC1–PC3: 12% hedged vs. 4% for Democrats). Coders now make only the hedged/not-hedged judgment. **Emphasis is measured by dictionary** (below), not by coder judgment.

Rules:
- **Content ≠ certainty.** "The science is simply not settled" = PC3 disagree, `hedged` = 0 (a confident claim that the science is uncertain). "Some say the planet may be warming, but I doubt it" = PC1 disagree, `hedged` = 0; the hedge belongs to the position the speaker rejects.
- **Hedges must qualify the speaker's own stance.** Modal verbs describing future events ("prices could rise 40 percent") are predictions, not hedges, unless the speaker signals doubt about the claim ("prices could perhaps rise, though I'm not certain").
- `conditional = 1` statements are usually `hedged` = 1 unless the condition is itself stated emphatically.
- **"I believe" + clause** ("I believe this bill will raise prices") is a hedge (1) unless paired with a booster ("I firmly believe" = 0). **"Believe in X"** ("We believe in the science," "I believe in American energy") is an endorsement, **not** a hedge (0).
- Code from the passage in `quote`; if the speech elsewhere hedges the same stance, note it in `memo`.
- **v0.4 compatibility:** v0.4 `speaker_certainty` 1 → `hedged` 1; 2 or 3 → `hedged` 0.

**Dictionary measures (computed by script, not coded).** Hedge and booster counts are computed on each statement's `quote` and on the full speech text (per 1,000 words). They serve as the emphasis measure and as a check on `hedged`.

| List | Terms (case-insensitive; the list is open-ended and versioned in the script) |
|---|---|
| Hedges | may, might, could, perhaps, possibly, probably, likely, unlikely, I think, I believe (not "believe in"), I suspect, I guess, it appears, it seems, seemingly, somewhat, to some extent, as I understand it, not sure, not certain, uncertain |
| Boosters | clearly, certainly, undeniably, undoubtedly, obviously, without question, no doubt, beyond doubt, the fact is, it is a fact, the simple truth is, the reality is, the truth is, make no mistake, let me be clear, let there be no mistake, everyone knows, there is no dispute, no one disputes, there is no question, this isn't hypothetical, it is simply, never, always, absolutely |

The dictionary will mis-score some passages ("may" as a month, "could" in a prediction), which is why it is a speech-level measure and a check rather than the statement-level code.

## 4b. Information sources (new in v0.5)

Code the **external sources of information or authority** the speaker invokes. A source is anything outside the speaker's own reasoning that is offered as evidence, expertise, or testimony: a scientific body, an agency analysis, a study, a news report, a business, a constituent, the speaker's own first-hand observation.

### What counts

| Code it | Do not code it |
|---|---|
| A named source: "The IPCC concluded…", "CBO estimates…", "According to the Heritage Foundation…" | The bill itself, its text, or its sponsors' summary of it |
| An unnamed but explicit appeal to a source: "Scientists tell us…", "Studies show…", "Economists agree…" | Other **Members of Congress** and their floor remarks (debate opponents are not information sources). Exceptions: a committee **report** or hearing record (`congress`) and a hearing **witness** (code the witness by affiliation) |
| Testimony and experience: a constituent's story, a local business owner, the speaker's own visit ("I stood on the melting permafrost in Alaska") | Generic common knowledge with no appeal to a source ("Gas prices are high"); claims about what "the American people" want with no poll or survey cited |
| Inserted letters, reports, articles, or SAPs the speaker introduces (§3a; `inserted = 1`) | Sources cited **inside** inserted material |
| A source the speaker **attacks** or discredits ("The so-called experts at the IPCC have been wrong before") | The speaker's own party or the President as a **political** opponent or ally ("the President's radical agenda"); code the executive only when it is cited as a source of information or analysis ("the Administration's own analysis shows") |

### Fields (one row per source per speech)

| Field | Values | Notes |
|---|---|---|
| `source_name` | Free text, as named in the speech | "IPCC", "Congressional Budget Office", "a dairy farmer in Wisconsin", "scientists". Normalized to a source list after coding. |
| `source_type` | See table below | One type per source. |
| `specific` | 1 = a named organization, document, or person; 0 = generic or unnamed ("scientists," "studies," "experts," "people back home") | Generic appeals are a distinct rhetorical move and are expected to differ by party. |
| `evidence_form` | `quantitative` · `finding` · `testimony` · `position` | What the speaker takes from the source (below). |
| `use` | `support` · `dispute` · `mixed` | Does the speaker rely on the source (`support`) or discredit it (`dispute`)? |
| `linked_concepts` | List of concept IDs from §4, or empty | The concepts this source is used to support or undermine **in this speech**. Use only concepts also coded as statements in the same speech. Empty if the source supports only a `bill_stance` or a point outside the concept list. |
| `inserted` | 0/1 | 1 = inserted material the speaker introduces (§3a). |
| `quote` | Verbatim, ≤ 40 words, no ellipses | The clearest passage naming or invoking the source. |
| `confidence` | 1–3 | Coder's confidence. |
| `memo` | Free text | E.g., `hearing witness`, `via inserted editorial`, unresolved type. |

**`source_type`**

| Code | Includes | Examples |
|---|---|---|
| `science` | Scientific assessment bodies, academies, universities, peer-reviewed research, federal **science** agencies acting as science (NOAA, NASA, USGCRP / National Climate Assessment, national labs' research), and generic appeals to "scientists" or "the science" | IPCC; National Academy of Sciences; "a study in *Nature*"; "97 percent of climate scientists" |
| `govt_analysis` | Nonpartisan or agency **economic, budget, and policy analysis** | CBO; JCT; GAO; CRS; EIA; Treasury revenue estimates; EPA or DOE regulatory impact analyses; CEA |
| `executive` | The President, executive officials, or SAPs cited as a source of information or official position (not as a political target) | "Secretary Chu told us…"; "the Statement of Administration Policy says…" |
| `military_security` | Defense and intelligence sources | DoD; Joint Chiefs; CNA Military Advisory Board; retired generals; intelligence assessments |
| `think_tank` | Policy research organizations | Heritage; AEI; Cato; Brookings; Resources for the Future; Rhodium Group; Energy Innovation; Tax Foundation; Princeton REPEAT |
| `advocacy` | Environmental, consumer, taxpayer, civil-rights, and other advocacy groups; **labor unions** and worker organizations | Sierra Club; EDF; NRDC; Americans for Prosperity; National Taxpayers Union; AFL-CIO; United Mine Workers; BlueGreen Alliance |
| `business` | Firms, utilities, trade associations, industry analysts, investors | U.S. Chamber of Commerce; NAM; API; Edison Electric Institute; "Ford Motor Company"; Wood Mackenzie |
| `state_local` | Governors, state agencies, public utility commissions, mayors, regional grid operators | California Air Resources Board; ERCOT; PJM; "my State's Governor" |
| `international` | Foreign governments, international organizations other than the IPCC | IEA; UN; World Bank; "the Chinese Government announced" |
| `courts` | Court rulings, opinions, and legal findings, federal or state | *Massachusetts v. EPA*; *West Virginia v. EPA*; "a Federal judge blocked the rule" |
| `congress` | Congressional **documents** and institutional positions, not Members' floor remarks: committee and staff reports, hearing records cited as a body of evidence, and earlier resolutions or votes cited as the position of Congress | Energy and Commerce Committee report; "in 12 hearings we heard from…"; Byrd-Hagel resolution (95–0). CRS → `govt_analysis` |
| `media` | News reports, editorials, op-eds, broadcast | *Wall Street Journal* editorial; AP report; "60 Minutes" |
| `public_opinion` | Polls, surveys, and measured public opinion | Gallup; Pew; "a recent poll shows 70 percent of Americans…" |
| `constituent` | Constituents, local businesses, farmers, and residents speaking as individuals; letters and calls from home | "a family in Toledo wrote to me"; "farmers in my district tell me" |
| `personal` | The speaker's own first-hand observation or experience | Site visits; "I have seen the flooding in my district" |
| `expert_generic` | **Unattributed** expert claims and estimates whose source type cannot be identified; always `specific = 0` | "economists say"; "experts agree"; "some estimates put the cost at…"; "studies show this bill will cost jobs" |
| `other` | None of the above, including religious leaders and bodies; describe in `memo` | Pope Francis; U.S. Conference of Catholic Bishops; historical figures |

Rules for `source_type`:
- **Classify by what the source is, not by its politics.** Heritage and Brookings are both `think_tank`.
- An agency can fall into different types depending on what is cited: NOAA temperature records → `science`; EPA's cost estimate for a rule → `govt_analysis`; EPA as a regulator being attacked → not a source (and possibly SC3 disagree).
- A hearing witness → the witness's affiliation (an EIA administrator testifying → `govt_analysis`), `memo = hearing witness`. The hearing record cited as a whole → `congress`.
- **Unattributed claims.** Use `expert_generic` only when the speaker invokes expertise or an estimate without saying what kind of source it is. If the kind is clear, code that type with `specific = 0`: "scientists say" or "the science" → `science`; "the Administration's estimates" → `executive`; "industry analysts" → `business`. Generic appeals about the physical climate ("studies show the oceans are warming") → `science`; about the economic or policy effects of a bill ("studies show this will cost jobs") → `expert_generic`.
- **Dissenting ("contrarian") science.** Scientists and studies that dispute the mainstream consensus are coded `science`, like any other scientific source. `use` records the speaker's stance toward the source, not the source's relation to the consensus: a speaker relying on a dissenting scientist is `science`, `use = support`. Contrarian science is therefore **not** separately identified in v0.5 (see §10).
- If the speaker cites a source **through** another source ("the *Post* reports a new NOAA study"), code the original source (`science`) and note the conduit in `memo`.

**`evidence_form`**

| Value | Meaning | Example |
|---|---|---|
| `quantitative` | A number, estimate, or projection taken from the source | "CBO says this will cost $1.2 trillion"; "EIA projects prices will rise 20 percent" |
| `finding` | A qualitative conclusion or assessment | "The National Climate Assessment found that warming is already harming agriculture" |
| `testimony` | A personal account, story, or observation | "A farmer in my district told me his diesel costs doubled" |
| `position` | The source's stance, endorsement, or opposition, with no evidence offered | "The Chamber of Commerce opposes this bill"; letters of support |

### Rules

- **One row per source per speech.** If the speaker cites the same source several times, code it once, listing every linked concept and using the clearest quote. If the same source is both relied on and attacked, `use = mixed`.
- **Distinct sources:** "CBO" and "JCT" are two sources; "scientists" and "the IPCC" in the same speech are two sources (one generic, one specific).
- **Lists of endorsers** ("This bill is supported by the Sierra Club, the AFL-CIO, and the Chamber") → one row per organization, each `evidence_form = position`. If the list is longer than five, code one row with the most frequent `source_type`, `source_name = "list: <n> organizations"`, and note the types in `memo`.
- **Linking to concepts.** Link a source only to concepts the speaker uses it for. "CBO says the bill reduces the deficit" → DC4 (disagree side) if DC4 is coded; a source cited for a raw cost figure in a PC4 argument → PC4.
- **Silence is not a code.** A speech with no sources has no source rows; this is recorded by the speech-level `n_sources = 0`.


## 5. Borderline cases

| Situation | Rule |
|---|---|
| "National energy tax" said of cap-and-trade | SC1 disagree + PC4 agree (not SC2) |
| "Put a price on carbon" with no instrument named | SC2 agree |
| Praising the IRA as a whole | `bill_stance` = support; code only concepts whose reasons are given (e.g., PC5, SC5) |
| "Green New Deal/Scam" attacks | `bill_stance` for GND; code instruments/costs only if specified ("100 percent renewables" → SC6 disagree) |
| "All-of-the-above energy" | SC7 agree; PC7 agree **and** disagree only if security is the stated purpose; add named sources (SC8, SC5) if specified |
| Opposing EPA rules as overreach | SC3 disagree. Add DC5 agree if the argument is that Congress, not the agency, should decide; add DC1 agree only if a general limited-government principle is stated |
| Agency (e.g., Treasury) implementing a law beyond congressional intent | DC5 agree |
| China mentioned | PC6 if the point is that US action is futile without China; PC8 if the point is competition over industries or supply chains; code both if both are made |
| Gas prices blamed on the administration (no climate policy named) | PC4 agree only if tied to climate/clean-energy policy; otherwise not coded |
| "US forests absorb our emissions, so we are not a net contributor" | PC6 agree if framed as others being responsible; SC12 agree if a sink policy is proposed; memo |
| Forest management framed as wildfire/climate protection | SC11 |
| Cap-and-trade supported as a "free-market approach" | SC1 agree; add DC1 agree only if the speaker states a preference for markets over government direction. The label alone ("market-based") is not DC1 (see boundary anchors, §4) |
| Statements on hydro, geothermal, biofuels | SC5/SC6 depending on instrument; note in `memo` |
| A long quotation of a constituent letter read aloud | See §3a |

## 6. Speech-level variables (not network nodes)

| Variable | Values | Use |
|---|---|---|
| `bill_focus` | **Cap-and-trade era:** waxman-markey · lieberman-warner · kerry-boxer · mccain-lieberman · other-captrade · epact-2003 · epact-2005 · eisa-2007 · energy-bill-other. **IRA era:** gnd · climate-action-now (H.R. 9) · ajp (American Jobs Plan / infrastructure) · bbb · ira · lower-energy-costs (H.R. 1) · obbb. **Any era:** cra-epa (CRA or rider on EPA/agency climate rules) · appropriations · budget · nomination · none | Debate context |
| `bill_stance` | support · oppose · mixed · none | Validation against roll-call votes |
| `no_codable_content` | 0/1 | Exclusion |
| `speech_focus_climate` | 0/1: is climate/energy the main subject (vs. a passing mention)? | Sensitivity analysis |
| `procedural_objection` (new) | 0/1: does the speaker object mainly on procedural grounds (regular order, amendment tree, reconciliation, jurisdiction)? | Separates procedural from substantive opposition |
| `speech_memo` (new) | Free text | Bill name if `other`, `NEW:` concept suggestions, `DATA:` flags |
| `n_sources` (v0.5) | Integer: number of source rows coded for the speech | Check that "no sources" was a decision, not an omission |

## 7. Output format

Three files keyed by `speech_id`.

**Statements**, one row per coded statement (DNA-compatible):

```
speech_id, bioGuideId, date, concept_id, agree, intensity, hedged, conditional, quote, coder, confidence, memo
```

- `quote`: verbatim, ≤ 40 words, the clearest passage. **No ellipses**; if the clearest passage is longer, choose a shorter contiguous span.
- `intensity`: −2, −1, +1, +2 (§4a).
- `hedged`: 0/1 (§4a); the speaker's displayed tentativeness.
- `confidence`: 1–3, the **coder's** confidence in the code.
- One row per speech with `concept_id = NONE` if `no_codable_content = 1`.

**Sources** (v0.5), one row per source per speech (§4b):

```
speech_id, bioGuideId, date, source_id, source_name, source_type, specific, evidence_form, use, linked_concepts, inserted, quote, coder, confidence, memo
```

- `source_id`: S1, S2, … within the speech.
- `linked_concepts`: semicolon-separated concept IDs (e.g., `PC4;DC4`), or empty.
- `quote`: same rules as for statements; checked against the speech file by script.

**Speeches:** speech-level variables (§6).

**Derived analysis matrix:** speech × concept with a signed 3-level variable (−1 disagree, 0 not coded, +1 agree) for two-sided concepts, and a binary agree indicator for agree-only concepts (§1). Speeches coding both stances on a concept are set to 0 in the signed version and flagged. **Source matrices:** speech × `source_type` (presence), and source × concept (counts from `linked_concepts`) for a bipartite source–belief network.

## 8. Source re-pilot and reliability study (next phase)

**Step 0: source re-pilot (v0.5).** Before reliability testing, LLM-code the same 150 pilot speeches (`output/pilot/pilot_sample.csv`; drawn by `scripts/pilot_sample.R`) with the v0.5 prompt, so the source module can be checked for prevalence and workable categories. The v0.4 statement codes give a baseline: `hedged` should reproduce the v0.4 hedged share (3.9%) and the partisan gap on PC1–PC3.

**Sample for reliability:** the 50-speech subset in `human_coding_subset.csv` (6 per corpus × party × chamber cell, 1 Extension per corpus; seed 20260929), in the Policy Learning in Congress project's `output/pilot/`.

**Coding:**
1. **Human–human:** two coders independently code the 50 speeches with v0.5 → Krippendorff's α per concept, for `intensity` and `hedged`, and for the source fields.
2. **LLM:** re-code the 50 (and ideally all 150) with v0.5, one independent request per speech, logging the model ID, prompt version, date, and raw JSON output.
3. **LLM–human:** α per concept, per stance, and per source field; review disagreements.

**LLM reproducibility.** Sampling cannot be fixed: as of 2026-10-21 the Anthropic API rejects `temperature`, `top_p`, and `top_k` on every model, so re-running the same prompt will not return identical codes. Reproducibility therefore rests on (a) the fixed model ID and versioned prompt file, (b) archiving every raw response, (c) a re-code stability check (code a subset twice; report κ), and (d) LLM–human agreement as the validity evidence. Coding can run through the API (scripted; logged) or in-session; in-session runs use a fresh subagent per batch that sees only the prompt file and the speech files, so batches do not influence one another.

**Source agreement** is measured in two steps: (a) **detection**, by matching sources across coders on speech + normalized `source_name` (F1 and α on presence); (b) **classification**, α for `source_type`, `specific`, `evidence_form`, and `use` on the matched sources, and agreement on `linked_concepts`.

**Decision criteria:**

| Check | Target | If missed |
|---|---|---|
| Concept prevalence (either stance) | ≥ 5–10% of speeches in at least one corpus | Merge or drop (applies to †/‡ candidates and core concepts). v0.4: 30 of 31 passed; SC13 failed. |
| Distinctness of related pairs (DC1/DC5, PC6/PC8, PC4/PC9, DC2/PC12) | Separable (α per concept; not near-perfect co-occurrence) | Merge the pair |
| Human–human α | ≥ 0.67 (tentative), ≥ 0.80 (good) | Revise definitions and borderline rules |
| LLM–human α | Comparable to human–human | Revise the prompt; add anchors; human-code that concept |
| Disagree stance observed | ≥ 10% for two-sided treatment | Treat as agree-only |
| `bill_stance` vs. roll-call vote | High agreement | Check attribution rules |
| α for `intensity` and `hedged` | ≥ 0.67 | Drop the statement-level code; rely on the dictionary and on measures B/C in the belief-certainty memo |
| `hedged` vs. dictionary hedge rate | Positive association at the speech level | Review the hedge rules and the dictionary list |
| Source prevalence by `source_type` | ≥ 5% of speeches in at least one period | Merge into a neighboring type (as done for `labor` → `advocacy` and `religious` → `other` after the re-pilot) |
| Source detection F1 (human–human) | ≥ 0.80 | Tighten §4b "what counts," especially generic appeals and testimony |
| α for `source_type`, `evidence_form`, `use` | ≥ 0.67 | Collapse categories (e.g., `evidence_form` → evidence vs. position) |
| Agreement on `linked_concepts` | ≥ 0.67 on matched sources | Code source–concept links at speech level only (co-occurrence) |

## 9. LLM prompt skeleton (v0.5)

The full prompt is `codebook/prompt_v0.5.txt` (final; md5 `99c9df718d03ba342379e03b7900db4e`), generated from §§3, 3a, 4, 4a, 4b, 5, and 6 verbatim plus the JSON block below. The draft prompt used in the re-pilot is archived in `output/pilot/v0.5/`.

```
You are coding a U.S. Congressional Record floor speech for (1) the speaker's
own stated positions on climate and energy policy and (2) the information
sources the speaker invokes.

[Insert Sections 3, 3a, 4, 4a, 4b, 5, and 6 of the codebook verbatim]

Return JSON:
{"speech_id": "...",
 "no_codable_content": 0|1,
 "bill_focus": "...", "bill_stance": "...", "speech_focus_climate": 0|1,
 "procedural_objection": 0|1, "n_sources": 0, "speech_memo": "",
 "statements": [
   {"concept_id": "PC1", "agree": 1, "intensity": -2|-1|1|2,
    "hedged": 0|1, "conditional": 0,
    "quote": "<verbatim contiguous span, <=40 words, no ellipses>",
    "confidence": 1-3, "memo": ""}
 ],
 "sources": [
   {"source_id": "S1", "source_name": "...", "source_type": "science|govt_analysis|executive|military_security|think_tank|advocacy|business|state_local|international|courts|congress|media|public_opinion|constituent|personal|expert_generic|other",
    "specific": 0|1, "evidence_form": "quantitative|finding|testimony|position",
    "use": "support|dispute|mixed", "linked_concepts": ["PC4"], "inserted": 0|1,
    "quote": "<verbatim contiguous span, <=40 words, no ellipses>",
    "confidence": 1-3, "memo": ""}
 ]}

Code each concept x stance at most once and each source at most once.
Do not infer positions from party. If a stance is not explicitly or
unambiguously expressed, do not code it. Code only the speaker's own words
for stances (Section 3a); code inserted material as sources with inserted = 1.
n_sources must equal the length of "sources".

SPEECH:
<header + text>
```

## 10. Open issues

- **Boundary anchors (v0.5 final):** check whether the DC1, DC4, PC4, and SC4 anchors raise agreement in the human study; DC4's "value on either side" rule and PC4's "cost as a constraint" rule are the main changes to watch.
- **Sources:** Is the 17-category `source_type` list too fine for reliable coding? After the re-pilot, `labor` and `religious` were merged and `courts`, `congress`, `public_opinion`, and `expert_generic` added. Further merge candidates if α is low: `executive` into `govt_analysis`; `think_tank` and `military_security` (each ≥ 5% in only one period).
- **Sources:** Contrarian science. In the re-pilot, Republican `science` citations mixed mainstream bodies with dissenting scientists (e.g., one Inhofe speech cites dozens), so the partisan gap in science citation understates the difference in *which* science is cited. Options: add a `consensus` field (mainstream / dissenting / not applicable) for `science` sources, or classify dissent after coding from the normalized `source_name` list. Decide before full coding if RQ2 needs the distinction.
- **Sources (new):** Should generic appeals ("scientists say," "studies show") be treated as sources or as a rhetorical feature of the statement? v0.5 codes them as sources with `specific = 0` so either analysis is possible.
- **Sources (new):** The corpus files cut most inserted material (`inserted_words` > 0 in only 0.5% of speeches); the full text is in `raw-records/`. Decide whether inserted documents should be restored for source coding.
- Does `hedged` carry enough variation, or should certainty be measured only by dispersion across speeches (measure B) and model variance (measure C)?
- Do the ‡ candidates (PC10, PC11, PC12, SC12, SC13) meet prevalence and reliability criteria in the full data?
- Concept-boundary changes deferred from Pilot Report v0.4 §6.2–6.3: PC6 vs. leakage, PC4 wording, PC4/PC9 merge, PC7 "all of the above," DC2 equity targeting, SC13 drop, `bill_focus` additions.
- Can DC1–DC6 be coded reliably, or will deep core nodes need external measures (DW-NOMINATE, LCV scores)?
- Does the IRA-corpus rule C (`bill_energy`) inflate SC7/PC7? In the pilot, several `bill_energy` speeches were mostly about other topics; compare against a `dense`/`titled`-only subsample.
- Data pipeline: fix the insertion filter (letters, SAPs, Clerk-read text) and the speaker-split error before full coding (Pilot Report v0.3 §6).

## Related documents (Policy Learning in Congress project)
- `output/pilot-codebook-congressional-belief-networks.md` (v0.4)
- `output/pilot/v0.4/pilot-report-v04.md`
- `output/measuring-beliefs-belief-certainty-congressional-record.md`
- `output/belief-network-feasibility-after-pilot.md`
