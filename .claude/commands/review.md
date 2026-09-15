---
allowed-tools: Bash(gh issue view:*), Bash(gh search:*), Bash(gh issue list:*), Bash(gh pr comment:*), Bash(gh pr diff:*), Bash(gh pr view:*), Bash(gh pr list:*)
description: Local code review of a pull request (prints results, does not post to GitHub unless asked)
disable-model-invocation: false
---

Review the given pull request. Output the review locally unless the user explicitly asked you to post a GitHub comment.

The deliverable is a verdict on whether this PR is sensible to merge at all. Half of PRs are wrong not because of a bug but because the thing they implement, or a decision they take, should not have been done in the first place. The PR description is the author's claim about why the change is needed and why it is shaped this way. It is evidence to test against the codebase, never a premise to accept. Finding small bugs inside the author's framing is the easy part and is not the job; CI, linters, and Bugbot already do that.

Follow these steps precisely:

1. Use an Opus agent to check if the pull request (a) is closed, (b) is a draft, or (c) already has a code review. In the third case, mention this, but proceed normally.

2. Use an Opus agent to read the pull request and return: the problem the PR claims to solve, the design decisions it takes (new concepts, new flags, new layers, new abstractions, new code paths, what it deletes), and a summary of the diff.

3. Premise review. Launch 2 parallel Opus agents that independently answer "should this exist at all, and in this shape?" Each agent gets the step-2 summary, the diff, and the relevant CLAUDE.md files, and must read the surrounding codebase rather than reason from the diff alone. Each returns a verdict of MERGE, REWORK, or CLOSE with its reasoning, by working through:
   a. Does the stated problem actually exist? Find the code, the failing behaviour, or the issue that motivates it. If the motivation is only asserted in the description, say so.
   b. Re-derive the design from scratch. Given the real problem, what is the simplest change a strong engineer would make? Compare that to the PR. Every place the PR is heavier, more general, or more layered than the from-scratch design is a finding.
   c. Is this a second way of doing something that already exists in the repo or in a dependency the repo already uses? If so the right change is usually to use or fix the existing path, not add a parallel one.
   d. Is the change at the right layer, and does it introduce a concept the codebase did not have before? New concepts need a reason stronger than convenience.
   e. Is the scope right? Flag unrequested infrastructure, speculative generality, backwards-compatibility shims, fallbacks, and anything the PR adds "just in case."
   f. What does merging commit the project to maintaining? If the answer is a design that will need to be torn out, the verdict is CLOSE or REWORK even if the code is correct.

4. Only if both premise agents return MERGE, launch 2 parallel Opus agents to scan the diff for obvious, large bugs. Avoid reading extra context beyond the changes. Focus on large bugs, and avoid small issues and nitpicks. Ignore likely false positives. Be unusually thorough. Then, for each bug found, launch a parallel Opus agent that takes the PR, issue description, and CLAUDE.md files and returns a confidence score 0-100 using this rubric (give it to the agent verbatim):
   a. 0: Not confident at all. This is a false positive that doesn't stand up to light scrutiny, or is a pre-existing issue.
   b. 25: Somewhat confident. This might be a real issue, but may also be a false positive. The agent wasn't able to verify that it's a real issue. If the issue is stylistic, it is one that was not explicitly called out in the relevant CLAUDE.md.
   c. 50: Moderately confident. The agent was able to verify this is a real issue, but it might be a nitpick or not happen very often in practice. Relative to the rest of the PR, it's not very important.
   d. 75: Highly confident. The agent double checked the issue, and verified that it is very likely it is a real issue that will be hit in practice. The existing approach in the PR is insufficient. The issue is very important and will directly impact the code's functionality, or it is an issue that is directly mentioned in the relevant CLAUDE.md.
   e. 100: Absolutely certain. The agent double checked the issue, and confirmed that it is definitely a real issue, that will happen frequently in practice. The evidence directly confirms this.
   Filter out any issues with a score less than 80.

5. If the premise agents disagree, read both arguments yourself, decide, and say which argument you rejected and why.

6. Output the review directly in the conversation. Do NOT post a GitHub comment unless the user explicitly requested it.

When writing the review output, keep in mind:

- Lead with the verdict. The reason it should or should not exist is the review; everything else is secondary.
- Keep your output brief
- Avoid emojis
- Never report findings about the PR title, description, or labels
- Link and cite relevant code, files, and URLs
- Follow the format below

Examples of false positives, for step 4:

- Pre-existing issues
- Something that looks like a bug but is not actually a bug
- Pedantic nitpicks that a senior engineer wouldn't call out
- Issues that a linter, typechecker, or compiler would catch (eg. missing or incorrect imports, type errors, broken tests, formatting issues, pedantic style issues like newlines). No need to run these build steps yourself -- it is safe to assume that they will be run separately as part of CI.
- General code quality issues (eg. lack of test coverage, general security issues, poor documentation), unless explicitly required in CLAUDE.md
- Issues that are called out in CLAUDE.md, but explicitly silenced in the code (eg. due to a lint ignore comment)
- Real issues, but on lines that the user did not modify in their pull request

Notes:

- Do not check build signal or attempt to build or typecheck the app. These will run separately, and are not relevant to your code review.
- Use `gh` to interact with Github (eg. to fetch a pull request), rather than web fetch
- Make a todo list first
- You must cite and link each finding (eg. if referring to a CLAUDE.md, you must link it)
- For the output format, follow this format precisely:

---

### Code review

**Verdict: CLOSE** (or MERGE / REWORK)

<Two to five sentences: what the PR claims to solve, whether that problem is real, what the from-scratch design would be, and where the PR departs from it. For MERGE, say in one sentence why the premise holds. For REWORK, say what shape the change should take instead.>

<For REWORK or CLOSE, list the decisions that are wrong, each with a link to the code that shows it, eg. the existing path this duplicates, or the absence of the problem it claims to fix.>

Bugs (only for MERGE, only if any scored 80+):

1. <brief description of bug> (bug due to <file and code snippet>)

<link to file and line with full sha1 + line range for context, note that you MUST provide the full sha and not use bash here, eg. https://github.com/anthropics/claude-code/blob/1d54823877c4de72b2316a64032a54afc404e619/README.md#L13-L17>

---

- When linking to code, follow the following format precisely, otherwise the Markdown preview won't render correctly: https://github.com/anthropics/claude-cli-internal/blob/c21d3c10bc8e898b7ac1a2d745bdc9bc4e423afe/package.json#L10-L15
  - Requires full git sha
  - You must provide the full sha. Commands like `https://github.com/owner/repo/blob/$(git rev-parse HEAD)/foo/bar` will not work, since your comment will be directly rendered in Markdown.
  - Repo name must match the repo you're code reviewing
  - # sign after the file name
  - Line range format is L[start]-L[end]
  - Provide at least 1 line of context before and after, centered on the line you are commenting about (eg. if you are commenting about lines 5-6, you should link to `L4-7`)

### Posting to GitHub (only when explicitly requested)

If the user explicitly asked you to post the review as a GitHub comment, then after outputting the review locally:

1. Use an Opus agent to repeat the eligibility check from step 1, to make sure the PR is still eligible.
2. Post the review as a comment on the PR using `gh pr comment`, appending this footer:

Generated with [Claude Code](https://claude.ai/code)
