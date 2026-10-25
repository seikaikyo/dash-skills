---
name: humanizer-en
description: Rewrites already-written English text so it reads like a person wrote it and drops the tells of AI generation. Use when the user asks to rewrite, tighten, or de-AI an existing piece of English writing (email, README, PR description, blog post, docs, customer message), or says things like "this sounds very AI", "make this sound human", "clean up this draft". This is a rewrite tool, not a checker: symbol-level issues (em dashes, emoji) are handled by hooks, so focus on filler, formulaic structure, rhythm, and tone. For Traditional Chinese text use humanizer-zh-tw instead.
---

# humanizer-en

Rewrite a piece of English so it reads like a person wrote it. Keep the meaning and every fact, strip the tells that mark it as AI-generated.

## When to use

The user has existing English text and wants it to read more naturally, or says it "sounds AI", or asks you to tighten or de-AI a draft. For Traditional Chinese, use humanizer-zh-tw.

This is a rewrite tool, not a checker. Em dashes, emoji, and decorative symbols are caught by existing hooks, so do not spend effort on the symbol layer here. Work on what a reader notices but a linter misses: filler, formula, flat rhythm, and a tone that is too eager or too corporate.

## How to rewrite

1. Read the whole piece and get what it is actually saying.
2. Find the AI tells (see the lists below).
3. Rewrite: keep the meaning and all the facts, cut the filler, break the formula, vary sentence length.
4. Return the rewritten text. If the user wants it, add a line or two on what you changed.

Do not change the meaning, do not add claims the original did not make, and leave quotes and code untouched. Keep names, numbers, and proper nouns as they are.

## Words to cut

Swap these for plain language:

- Inflated verbs and nouns: delve, leverage, utilize, foster, underscore, boast, navigate (figurative), unlock, elevate, robust, seamless, pivotal, crucial, vital.
- Vague attribution: "experts say", "studies show", "it is widely regarded", "industry reports indicate".
- Transition padding: furthermore, moreover, additionally, in conclusion, that said, it is important to note that, it is worth noting that.
- Empty closers: "I hope this helps", "let me know if you have any questions", "feel free to reach out".
- Hedges that dodge a position: arguably, it could be said, one might argue, perhaps consider.

## Patterns to break

- Rule of three: "innovative, inspiring, and insightful". Use two items, or four or more, or just say the thing.
- Negative parallelism: "not only X but also Y". State it directly.
- Hollow participial endings: "ensuring success", "highlighting the importance of", "paving the way for". Cut them or replace with something concrete.
- Copula avoidance: "serves as a", "acts as a". Use "is".
- The tidy summary sentence that restates the paragraph with no new information. End on the last real point instead.

## Rhythm and voice

- Lead with the point, backed by a specific detail, not with a windup about what you did.
- Short sentences. Do not stack three clauses with three turns in one line.
- Trust the reader: cut the sentence that explains the sentence you just wrote.
- Prefer concrete numbers over "significantly" or "substantially".
- Drop the self-presentation at the end and the "happy to help" sign-off.

## English docs conventions

When the text is technical documentation, keep these consistent (sourced from our own docs guidelines):

- Placeholders: use meaningful snake_case (`your_access_token_here`) or an obvious fake number sequence (`1234567890123`). Avoid `<TOKEN>`, `xxx`, `your-token`.
- Data sizes and units: a space before an uppercase unit (`64 KB`, `200 ms`); bare seconds like `30s` are the exception.
- Headings: sentence case for page titles ("Configure environment variables"), title case for nav labels.

## Quick self-check

Read it back once:

- Three sentences in a row the same length? Break one.
- Paragraph ending on a pretty empty line? Change the landing.
- Any "furthermore" or "moreover"? Usually deletes clean.
- A three-item list that sounds like a template? Make it two or four.
- Reads like a press release or an encyclopedia? Add one concrete point.

## Output

By default return only the rewritten text so the user can use it straight away. If they ask what changed, list the main edits in a line or two, not a long explanation.
