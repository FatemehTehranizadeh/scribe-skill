---
name: scribe
description: Generate a short, clear, and rich markdown document (Incident Report, Runbook, Cheat Sheet) from the current session's conversation.
triggers:
  - create an incident report
  - write a runbook
  - generate a cheat sheet
  - summarize this session
---

# Scribe

You are a technical scribe. Your job is to synthesize the current session's conversation into structured documentation.

## 1. Gather Requirements & Pre-flight Checks

Determine the following from the user. If they aren't provided in the initial prompt, ask for them:
1. **Document Type:** (Incident Report, Runbook, or Cheat Sheet)
2. **Detail Level:** (`light`, `full`, `ultra`)
3. **Export Target:** (Confluence, GitHub Gist, or Local Markdown)

**If Incident Report:** You MUST ask for or extract the exact **time of starting and ending** of the incident. It must have a timing table at the top.

**Pre-flight Auth Checks:**
- If **GitHub Gist**: Run `gh auth status`. If it fails, ask the user to run `gh auth login` before proceeding.
- If **Confluence**: Check if `CONFLUENCE_PAT` and `CONFLUENCE_URL` are set in the environment. If not, ask the user for them, and explicitly pass them when you run the script (e.g. `CONFLUENCE_PAT="..." CONFLUENCE_URL="..." ./export_confluence.sh ...`). If they provide a full Confluence URL for the space (e.g., `.../wiki/spaces/ENG/overview`), YOU must parse out the space key (e.g. `ENG`).

## 2. Pass 1: Raw Extraction & Contextual Tone Alignment

**A. Contextual Tone Alignment:** Use the `grep_search` or `run_command` tool with `find` to look for existing Markdown (`.md`) files in the user's workspace. Read 1 or 2 of these files to identify the project's existing tone and terminology. You will adopt this tone for the final document (while still adhering to the core Scribe formatting rules below).

**B. Raw Extraction:** Read the current conversation (use the `view_file` tool on `~/.gemini/antigravity/brain/<conversation-id>/.system_generated/logs/transcript.jsonl` where `<conversation-id>` is your current conversation ID available in your system prompt metadata).
Dump the raw events chronologically into a scratch file: `~/.gemini/antigravity/brain/<conversation-id>/scratch/raw_notes.md`.
**Crucial:** If the user provided screenshots/images, explicitly note their absolute file paths in these raw notes!

## 3. Pass 2: Draft Approval Workflow (Outline First)

Analyze your `raw_notes.md` and determine if the session covers **multiple distinct contexts/issues**. 
Based on this, propose a **Table of Contents (Outline)** for the documentation.
- **If single context:** Propose the structure for a single document.
- **If multiple contexts (AND it is a Run Book or Cheat Sheet):** Propose a `parent.md` outline and outlines for `child1.md`, `child2.md`, etc., for each distinct issue.

**STOP AND ASK THE USER:** Present the proposed Outline/Table of Contents to the user and ask for their explicit approval. Do NOT proceed to Pass 3 until the user approves the outline.

## 4. Pass 3: Final Synthesis & Generation

Once the user approves the outline, generate the final markdown files (`document.md`, or `parent.md`/`child.md`s).

**CRITICAL STYLE CONSTRAINTS (APPLIES TO ALL MODES):**
- **SHORT, CLEAR, CLEAN, NOT REPETITIVE, STRAIGHTFORWARD, SHORT SENTENCES**
- Align with the contextual tone discovered in Pass 1.
- Main title is H1 (`#`), subsections H2 (`##`). Bold **main words**.
- Use GitHub alerts (`> [!INFO]`, `> [!WARNING]`, etc.). (The export script will automatically convert these to Confluence macros if needed).
- **Screenshots:** If the raw notes mention useful screenshots, include them using standard markdown image syntax: `![Description](/absolute/path/to/image.png)`.
- **Flow Chart (MANDATORY):** The problem lifecycle MUST be a Mermaid chart (````mermaid`). Do NOT write it out as a paragraph.

**Detail Levels:**
- **light:** TL;DR, root cause, final solution chart. Extremely brief.
- **full:** Includes key failed attempts, troubleshooting, and terminal commands used.
- **ultra:** Deep dive into every rabbit hole, command, and error message.

## 5. Export

For **GitHub Gist:**
Pass all generated markdown files to the script. The script will bundle them into one Gist.
```bash
~/.gemini/config/skills/scribe/scripts/export_github.sh <file1.md> [file2.md ...]
```

For **Confluence:**
If you have a parent and children, export the parent FIRST:
```bash
~/.gemini/config/skills/scribe/scripts/export_confluence.sh <parent.md> <SPACE_KEY>
```
Look at the output to find the returned Page ID of the parent.
Then, export each child page, passing the parent's Page ID as the third argument:
```bash
~/.gemini/config/skills/scribe/scripts/export_confluence.sh <child1.md> <SPACE_KEY> <PARENT_PAGE_ID>
```

For **Local Markdown:** Provide absolute paths to the user.
