---
title: "Everybody Lies — Finding Truth in Unreliable Data"
tags: "programming, softwaredevelopment, debugging, ai"
canonical_url: ""
cover_image: ""
published: false
series: "House M.D. x Software Engineering"
---

*Part of a series drawing parallels between House M.D. and software engineering in an AI-first world — Orlando Burli Junior*

If you have spent any time around *House*, you have heard the line. It is not a joke about human nature; it is a working hypothesis. Patients omit the embarrassing detail, misremember the timeline, or flat-out deny the behavior that would make the diagnosis obvious. The show treats that as a feature of the job, not a moral failing. People are unreliable narrators of their own bodies — and if you build software for long enough, you learn the same thing about systems.

In engineering, nobody is *trying* to deceive you most of the time. The lie is usually accidental: compression, abstraction, latency, fear of looking stupid, or a model optimizing for plausibility instead of correctness. The effect is the same. If you treat every signal as gospel, you will ship the wrong fix, chase ghosts, and burn weeks proving what you should have doubted on day one.

## The patient is not the system

House's most famous habit — the illegal home invasion, the trash-can archaeology, the medicine cabinet inventory — is not there for shock value alone. It is the dramatic version of a simple rule: **the story you are told is not the evidence you need.** Symptoms are filtered through memory, shame, and vocabulary. Your job is not to win an argument with the patient; it is to find the mechanism of failure.

Software has the same layered unreliability.

**Logs lie** in the boring, technical sense. They are incomplete by design: sampling drops the one line that mattered, retention deletes the window where the bug happened, async pipelines reorder events so cause and effect look swapped. A log that looks "empty" around an incident is often a policy problem, not an absence of failure. You configured a rate limiter, a budget, or a "noisy neighbor" filter, and the truth walked out the door with the bytes you threw away.

**Metrics lie** in the statistical sense. Averages hide tail risk. Dashboards show what someone chose to instrument — which is a map of past curiosity, not present reality. Green graphs can sit on top of a system that is failing for a minority of users, a minority of shards, or a minority of code paths. The metric is true *as defined*; the definition may be useless for the question you are actually asking.

**Users lie** without malice. "It worked yesterday" is sometimes true. Often it means "I do not remember changing anything that *I* consider relevant," which is compatible with a new VPN, a rotated secret, a dependency bump, or a feature flag flip three teams away. Bug reports are lossy compression of reality: one screenshot, one error string, and a narrative written under stress. Treat them as clues, not transcripts.

Organizations lie too, in the soft sense: incentives. A team may downplay risk because a launch date is immovable. A postmortem may politely avoid naming the change that broke prod because naming feels like blame. None of that requires bad people — only normal humans under pressure. Your job is the same as in medicine: separate the social story from the mechanism.

And then there is the new layer.

## The confident wrong answer

Large language models do not "lie" in the human sense; they have no intent. Practically, though, they behave like the worst kind of witness: fluent, specific, and wrong, delivered with the tone of someone who has read the manual twice. Hallucinated APIs, invented flags, plausible-but-fake citations, and stack traces that never existed — all of it *sounds* like expertise because the surface statistics of language favor coherence over contact with your repository.

That makes model output the ultimate unreliable narrator for an AI-first workflow. It is not embarrassed to omit the embarrassing detail. It will not hesitate because it is unsure; calibration and confidence are decorrelated from correctness in ways humans are still learning to model. If logs are incomplete and metrics are averaged, model output can be **complete, polished, and still fiction**.

The fix is not cynicism toward tools. It is professional skepticism toward *signals*, including the newest one.

What changes in practice is your definition of "done" for an answer. A plausible paragraph is not a finding until it survives contact with reality: `git grep`, a failing test that becomes passing, a packet capture, a query against raw events, a bisected commit range. If you would not ship a code change on vibe alone, do not ship an incident conclusion on it either. The model can accelerate reading; it cannot replace the moment where the universe says no.

## Do not trust the error message — read the mechanism

House does not debate the patient's theory of their illness; he goes looking for the physical fact that breaks the differential. In engineering, the parallel is blunt: **do not stop at the message; read the code path that emitted it.**

You have seen the HTTP 200 with an error payload. You have seen "success" in a client because retries masked a partial failure. You have seen exceptions swallowed two layers up and replaced with a generic string that sends you on a treasure hunt. The error message is a user interface for operators. Like any UI, it can be wrong, stale, or translated through layers of "helpfulness."

When you are stuck, downgrade the stack trace from verdict to hint. Reproduce. Trace. Capture the request as it actually left the client, not as the server *claims* it received. If you can, attach a debugger or add temporary instrumentation at the boundary where truth is still cheap. The truth is rarely in the string; it is in the branch you did not know existed.

## Do not trust the metric — look at the raw distribution

A dashboard is a story told in aggregates. Aggregates are excellent for spotting drift and terrible for explaining individual failure. If your p99 looks fine while a cohort is timing out, you are not looking at the right slice — or your sampling is lying by omission.

House's equivalent is not ignoring vitals; it is refusing to let a single number close the case. You take the blood work, then you ask what the machine measured, then you ask whether the sample was contaminated. In systems, that means: drill from global to tenant, from route to shard, from "service" to process. Keep the raw events somewhere you can interrogate when the aggregates go smug.

## Cross-reference or die

The detective mindset is not paranoia; it is hygiene. You want **independent corroboration** from sources that fail for different reasons.

If logs and metrics disagree, neither wins by default — you find the seam. If a user's story and your telemetry disagree, both can be partially true: different time zones, cached assets, a canary they did not know they were on. If documentation and code disagree, the code is winning in production whether you like it or not.

"Trust but verify" is too gentle for incidents. Prefer: **assume good faith, assume lossy channels, verify anyway.**

## Building systems that are less dishonest

You cannot eliminate lying; you can reduce the *structural* incentives for it.

**Structured logging** beats clever prose in a text file. Stable fields (request id, tenant, route, outcome, latency buckets) make it possible to correlate across services without regex archaeology. Logs should be queryable contracts, not diary entries.

**Observability** — traces especially — is how you stop narrating distributed systems as a sequence of unrelated anecdotes. When a trace shows you where time went, you spend less time arguing about which team's metric is "more real." Pair traces with high-cardinality dimensions when you can afford them: tenant, build id, cell, checkout version. That is how you turn "the p99 is fine" into "this cohort is on fire" without guessing.

**Immutable audit trails** for configuration and releases turn "nobody changed anything" into a falsifiable claim. If you cannot answer *what* changed, *when*, and *by whom*, you are running a mystery novel with no last chapter.

**Feature flags and progressive delivery** do not stop mistakes, but they shrink the blast radius of being wrong — which matters when every signal in the chain is a little bit dishonest.

None of this makes the system tell the truth. It makes the system harder to misunderstand *by accident*.

## The truth is in the source code

If breaking into a patient's apartment is House's theatrical commitment to ground truth, **reading the source** is ours. Not the README that drifted, not the internal wiki that references a service renamed two years ago, not the diagram that was true at launch — the actual code executing in the environment where the bug lives.

That is not romanticism about text files; it is epistemology. The runtime does what the bytecode does. Your mental model is negotiable; the branch conditions are not.

In an AI-first workflow, this becomes even more important. Models are excellent at summarizing *patterns* in text they have seen. They are unreliable at asserting *facts* about your private system unless grounded in retrievable artifacts: the file, the diff, the trace id, the failing test. If your process lets generated text bypass the same verification bar you would apply to a junior engineer's guess, you have replaced one unreliable narrator with a faster one.

Tests, for all their own lies of omission, still have a useful role: they are executable claims about behavior. When a suggested fix contradicts a test you trust, the test is not being pedantic — it is being a witness with a different failure mode than natural language. Let them argue in CI, not in Slack.

## A harder job, not a nihilistic one

"Everybody lies" is easy to misread as cynicism. In *House*, it is closer to operational realism: people optimize their stories for comfort, speed, and self-image. Systems optimize for throughput, cost, and not waking anyone up at 3 a.m. Signals are edited by budgets, by sampling, by UX writers, by aggregation windows, and now by statistical language engines that owe you nothing.

The experienced move is not to stop listening. It is to **listen without surrendering judgment** — to treat every channel as biased, then triangulate.

So yes: the log might be lying. The dashboard might be lying. The user might be mistaken. The model might sound certain and still be wrong.

And if you forget that, you are not practicing medicine, and you are not practicing engineering.

You are practicing faith.

---

**House would probably add:** "You can trust the monitor — or you can trust me. Spoiler: the monitor's wrong half the time too."

Either way, go open the chart. And the repo.
