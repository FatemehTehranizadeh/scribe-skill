# Scribe AI: Automated Technical Documentation & Incident Report Generator

Scribe AI is a powerful, automated technical documentation generator designed to seamlessly convert your AI chat sessions, debugging logs, and troubleshooting conversations into professional, structured Markdown documents. 

Whether you need to generate an **Automated Incident Report**, create a **Markdown Runbook**, or compile an **AI-generated Cheat Sheet**, Scribe AI parses your session in real-time and exports directly to Confluence or GitHub Gists.

## 🚀 Key Features

*   **Automated Incident Report Generation:** Automatically extracts start times, end times, and root cause analyses to build comprehensive post-mortem incident reports.
*   **Confluence AI Integration:** Natively converts Markdown alerts into rich Confluence XML macros (`<ac:structured-macro>`). Automatically handles API auth and parent/child page hierarchies.
*   **Screenshot & Attachment Support:** Seamlessly captures image paths from your session and uploads them directly to Confluence via the Atlassian REST API.
*   **GitHub Gist Automation:** Bundles single or multiple markdown files into a unified GitHub Gist via the `gh` CLI for instant sharing.
*   **Mermaid Flowcharts:** Automatically synthesizes the entire lifecycle of a problem (birth, troubleshooting, and solution) into a visual Mermaid flowchart.
*   **Two-Pass AI Generation:** Ensures high-fidelity documentation by first dumping a raw chronological transcript, then synthesizing it into a clean, punchy, non-repetitive final document.

## 🛠️ Usage

To use Scribe AI, simply invoke the skill in your AI coding assistant (like Antigravity or OpenClaw) by typing:

```bash
/scribe
```

You can also trigger it naturally by asking: 
> *"Create an incident report for this session."*
> *"Summarize this session into a Runbook and push it to Confluence."*

### Detail Levels
Scribe AI supports three levels of detail to match your documentation needs:
1.  **Light:** A quick TL;DR focusing on the root cause and the final solution flowchart.
2.  **Full:** A comprehensive guide including failed attempts, troubleshooting steps, and exact terminal commands used.
3.  **Ultra:** An exhaustive, deep-dive into every rabbit hole, terminal command, error message, and detail encountered during the session.

## ⚙️ Configuration & Exporting

### Confluence Export
To export directly to Confluence, ensure the following environment variables are set before triggering the agent:
```bash
export CONFLUENCE_URL="https://your-domain.atlassian.net"
export CONFLUENCE_PAT="your-personal-access-token"
# Optional: Use CONFLUENCE_EMAIL for Basic Auth instead of Bearer Token
export CONFLUENCE_EMAIL="your-email@example.com"
```

### GitHub Gists
Scribe relies on the GitHub CLI (`gh`). Ensure you are authenticated:
```bash
gh auth login
```

## 🧠 Why Scribe AI?

Writing technical documentation, runbooks, and incident reports manually is time-consuming and often neglected. Scribe AI acts as your dedicated **AI Technical Scribe**, operating in the background to ensure that your hard-earned knowledge, terminal commands, and debugging processes are never lost. It is the ultimate tool for SREs, DevOps engineers, and software developers looking to automate their documentation pipeline.
