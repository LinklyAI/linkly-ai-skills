---
name: linkly-ai
description: "Search, browse, and read the user's local documents indexed by Linkly AI. This skill should be used when the user asks to 'search my documents', 'find files about a topic', 'look up my notes', 'read a local document', 'search my knowledge base', 'find PDFs about X', 'browse document outlines', 'what documents do I have about Y', 'read my local files', 'search local knowledge', or any task involving searching, browsing, or reading locally stored documents (PDF, Markdown, DOCX, TXT, HTML). Also triggered by Chinese phrases: '搜索我的文档', '查找文件', '读取本地笔记', '知识库搜索', '浏览文档大纲'. Linkly AI provides full-text search with relevance ranking, structural outlines, and paginated reading through CLI commands or MCP tools."
metadata:
  version: 0.1.1
  openclaw:
    anyBins:
      - linkly
    emoji: "\U0001F50D"
    homepage: https://linkly.ai
    os:
      - macos
      - linux
      - windows
---

# Linkly AI — Local Document Search

Linkly AI indexes documents on the user's local machine (PDF, Markdown, DOCX, TXT, HTML, etc.) and exposes them through a three-step workflow: **search → outline → read**.

## Environment Detection

Before executing any document operation, detect the available access mode:

### 1. Check for CLI (preferred)

Run `linkly --version` via Bash. If the command succeeds:

- Run `linkly status` to verify the desktop app is connected.
- If connected → use **CLI mode** for all operations.
- If not connected → inform the user: "Linkly AI desktop app is not running. Please start it and ensure MCP server is enabled."

### 2. Check for MCP tools (fallback)

If no Bash tool is available, check whether MCP tools named `search`, `outline`, and `read` (from the `linkly-ai` MCP server) are accessible in the current environment.

- If available → use **MCP mode** for all operations.

### 3. Auto-install CLI

If the CLI is not found and Bash is available, install it automatically:

- **macOS / Linux:** `curl -sSL https://updater.linkly.ai/cli/install.sh | sh`
- **Windows (PowerShell):** `irm https://updater.linkly.ai/cli/install.ps1 | iex`

After installation, run `linkly status` to verify. If the desktop app is not running, inform the user:

> Linkly AI CLI is installed, but the desktop app is not connected. Please download and start Linkly AI from [linkly.ai](https://linkly.ai), then enable the MCP server in settings.

If neither Bash nor MCP tools are available (rare — e.g., a sandboxed environment with no shell access), inform the user of the prerequisites and stop.

## Document Search Workflow

### Step 1: Search

Find documents matching a query. Always start here — never guess document IDs.

**CLI mode:**

```bash
linkly search "query keywords" --limit 10
linkly search "machine learning" --type pdf,md --limit 5
```

**MCP mode:**

Call the `search` tool with parameter `query` (required), and optionally `limit` (1–50, default 20) and `doc_types` (e.g. `["pdf", "md"]`).

**Search tips:**

- Use specific keywords rather than full sentences.
- Add `--type` / `doc_types` filter when the user mentions a specific format.
- Start with a small limit (5–10) to scan relevance before requesting more.
- Each result includes a `doc_id` — save these for subsequent steps.

### Step 2: Outline (optional but recommended)

Get structural overviews of documents before reading. This step is especially useful for long documents, as it reveals headings, sections, and line ranges.

**CLI mode:**

```bash
linkly outline <ID>
linkly outline <ID1> <ID2> <ID3>
linkly outline <ID> --json
```

Note: The `expand` parameter is only available in MCP mode. CLI always renders the full outline.

**MCP mode:**

Call the `outline` tool with `doc_ids` (list of document IDs). Optionally pass `expand` (list of node IDs like `["2", "3.1"]`) to drill into specific sections.

**When to use outline:**

- The document has `has_outline: true` in search results (typically Markdown and DOCX with headings).
- The document is long (>200 lines) and reading it all at once is impractical.
- The user wants to understand the structure before diving in.

**When to skip outline:**

- The document is short (<100 lines) — go directly to read.
- The document has `has_outline: false` (PDF, TXT, HTML) — use read with pagination instead.

### Step 3: Read

Read document content with line numbers and pagination.

**CLI mode:**

```bash
linkly read <ID>
linkly read <ID> --offset 50 --limit 100
```

**MCP mode:**

Call the `read` tool with `doc_id` (required), and optionally `offset` (1-based line number, default 1) and `limit` (max 500 lines, default 200).

**Reading strategies:**

- For short documents: read without offset/limit to get the full content.
- For long documents: use outline to identify target sections, then read specific line ranges with `offset` and `limit`.
- To paginate through a long document: advance `offset` by `limit` on each call (e.g., offset=1 limit=200, then offset=201 limit=200, etc.).

## JSON Output

When structured output is needed (e.g., for programmatic processing), append `--json` in CLI mode or pass `output_format: "json"` in MCP mode. This returns structured JSON instead of Markdown.

In CLI mode, `--json` is a global option that can be placed before or after the subcommand. The CLI wraps the response with a `status` field.

```bash
linkly search "query" --limit 5 --json
linkly outline <ID> --json
linkly read <ID> --limit 50 --json
```

## Best Practices

1. **Always search first.** Never fabricate or assume document IDs.
2. **Respect pagination.** For documents longer than 200 lines, read in chunks rather than requesting the entire file.
3. **Use outline for navigation.** On long documents with outlines, identify the relevant section before reading.
4. **Filter by type when possible.** If the user mentions "my PDFs" or "markdown notes", use the type filter.
5. **Present results clearly.** When showing search results, include the title, path, and relevance. When reading, include line numbers for reference.
6. **Handle errors gracefully.** If a document is not found or the app is disconnected, inform the user with actionable next steps.

## References

For detailed parameter specifications and return formats, consult:

- `references/cli-reference.md` — CLI installation, all commands, and options.
- `references/mcp-tools-reference.md` — MCP tool schemas, parameters, and response formats.
