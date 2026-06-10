# Linkly AI CLI Reference

Command-line interface for Linkly AI — search your local documents (and, over `--remote`, your linked cloud libraries) from the terminal.

The CLI connects to the Linkly AI desktop app's MCP server (locally or over LAN), or to the `mcp.linkly.ai` cloud gateway via `--remote`, giving fast access to indexed documents without leaving the terminal.

## Prerequisites

For **local** documents, the **Linkly AI desktop app** must be running with its MCP server enabled (the CLI auto-discovers it via `~/.linkly/port`). Use LAN mode (`--endpoint` + `--token`) or Remote mode (`--remote` with a saved API key) to connect over the network. Linked **cloud** libraries reached via `--remote` do not require the desktop to be online — see below.

Remote mode reaches both your local libraries and your linked cloud libraries through the `mcp.linkly.ai` gateway. Cloud libraries are served even when the desktop tunnel is disconnected; only local / default-scope calls need the desktop online — an offline local call returns a gateway error (`-32000`) with reconnect guidance rather than a client-side abort.

## Installation

See the [CLI installation guide](https://linkly.ai/docs/en/use-cli) for platform-specific instructions.

## Commands

### list-libraries — List knowledge libraries

```bash
linkly list-libraries
```

Lists all knowledge libraries with document counts. Over `--remote` this includes both local libraries (`local://<id>`) and linked cloud libraries (`cloud://<owner>/<slug>`).

| Option   | Description                            |
| -------- | -------------------------------------- |
| `--json` | Output structured JSON (global option) |

### explore — Overview of indexed documents

```bash
linkly explore [OPTIONS]
```

Get a bird's-eye overview of all indexed documents or a specific library. Returns document type distribution, directory structure with file counts and median word counts, and top keywords with source attribution.

| Option             | Description                                                                                                                               |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `--library <name>` | Restrict overview to one library: a local name / `local://<id>`, or `cloud://<owner>/<slug>` (over `--remote`). Omit = all local content. |
| `--json`           | Output structured JSON (global option)                                                                                                    |

Examples:

```bash
linkly explore
linkly explore --library my-research
```

### find-paths — Locate folder paths

```bash
linkly find-paths --patterns <keywords> [OPTIONS]
```

Locate real folder paths in the indexed documents by fuzzy keyword matching on the file path. Returns top folder candidates with file counts so you can pick a `--path-glob` for a follow-up `linkly search` call.

| Option              | Description                                                                                                                                                     |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--patterns <list>` | Keywords (comma-separated) to substring-match against file paths. Multiple keywords are OR-matched — pass cross-language or spelling variants in a single call. |
| `--library <name>`  | Restrict to one library: a local name / `local://<id>`, or `cloud://<owner>/<slug>` (over `--remote`). Omit = all local content.                                |
| `--limit <N>`       | Maximum folder candidates, 1–50 (default: 10)                                                                                                                   |
| `--json`            | Output structured JSON (global option)                                                                                                                          |

Examples:

```bash
linkly find-paths --patterns WeChat,微信,wxid
linkly find-paths --patterns Notion,notion --library my-knowledge --limit 5
linkly find-paths --patterns Slack --json
```

**When to use:** The user names a container by a fuzzy or cross-language word ("in my WeChat files", "在我的 Notion 笔记里") and you don't yet know the on-disk path. The tool returns folder candidates — take a distinctive segment of one of them (often the leaf name) and pass it to `linkly search --path-glob "*<segment>*"`. To scope to a whole folder, the JSON output's `path_glob` field is a ready-to-use value (already glob-quoted, so a folder name with `* ? [` still matches literally) — copy it verbatim.

**When NOT to use:** Pure content queries (use `search` directly); file-type filters (use `search --type pdf` — `--path-glob` is path-pattern matching, not file-type filtering).

**Aggregation note:** This is a "find folders" tool. Files whose patterns only match the filename segment (not any directory segment) are silently dropped. If you get zero folders despite expecting matches, fall back to `linkly search` directly without `--path-glob`.

### search — Search indexed documents

```bash
linkly search <QUERY> [OPTIONS]
```

| Option                    | Description                                                                                                                                                                                                                      |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<QUERY>`                 | Search keywords or phrases (required)                                                                                                                                                                                            |
| `--limit <N>`             | Maximum results, 1–50 (default: 20)                                                                                                                                                                                              |
| `--type <types>`          | Filter by document types, comma-separated (e.g. `pdf,md`)                                                                                                                                                                        |
| `--library <name>`        | Restrict search to one library: a local name / `local://<id>`, or `cloud://<owner>/<slug>` (over `--remote`; cloud must be the two-segment `owner/slug` form). Omit = all local content.                                         |
| `--path-glob <pat>`       | Glob **substring-matched** against the file path (no leading/trailing `*` needed). `*` matches any chars including `/`, `?` one char. Full dir path `/Users/me/notes/` scopes to that dir. When unknown, run `find-paths` first. |
| `--modified-after <iso>`  | Inclusive lower bound on modification time (ISO 8601 UTC; bare date or RFC 3339)                                                                                                                                                 |
| `--modified-before <iso>` | Inclusive upper bound on modification time (same format as `--modified-after`)                                                                                                                                                   |
| `--time-sort <mode>`      | Reorder by modification time: `newest`, `oldest`, or `default`. `default` and omitting the flag are equivalent — both keep relevance order.                                                                                      |
| `--json`                  | Output structured JSON (global option)                                                                                                                                                                                           |

Examples:

```bash
linkly search "machine learning"
linkly search "API design" --limit 5
linkly search "notes" --type pdf,md,docx
linkly search "deep learning" --library my-research
linkly search "design tokens" --remote --library "cloud://blueeon/design-system"
linkly search "report" --path-glob "*2024*"
linkly search "Q3 report" --modified-after 2024-07-01 --modified-before 2024-09-30
linkly search "weekly retro" --time-sort newest --limit 5
linkly search "budget" --json
```

Read the `[meta] now=<iso>` footer (Markdown output) or top-level `_meta.now` (JSON output) of any tool response to compute relative dates ("last 7 days", "after July 1, 2024", "in 2024") rather than guessing the current date.

**Document IDs:** each search result's `doc_id` is an opaque string — pass it verbatim to `outline` / `grep` / `read`, never reshape or fabricate it. Local documents look like `local://<integer>` (older desktops return a bare integer, still accepted); cloud documents look like `cloud://<owner>/<slug>/<root-hash>/<path>`.

### outline — Get document outlines

```bash
linkly outline <IDS>...
```

| Option           | Description                                                                           |
| ---------------- | ------------------------------------------------------------------------------------- |
| `<IDS>...`       | One or more document IDs from search (required)                                       |
| `--expand <ids>` | Node IDs to expand, comma-separated (e.g. `2,3.1`); others collapse, omit to auto-fit |
| `--json`         | Output structured JSON (global option)                                                |

Examples:

```bash
linkly outline 1044
linkly outline 1044 591 302
linkly outline 1044 --expand 2,3.1
linkly outline 1044 --json
```

### grep — Locate specific lines within a document by regex

```bash
linkly grep <PATTERN> <DOC_ID> [OPTIONS]
```

| Option               | Description                                                                   |
| -------------------- | ----------------------------------------------------------------------------- |
| `<PATTERN>`          | Regular expression pattern (required)                                         |
| `<DOC_ID>`           | Document ID to search within (required, from search results)                  |
| `-C, --context`      | Lines of context before and after each match                                  |
| `-B, --before`       | Lines of context before each match                                            |
| `-A, --after`        | Lines of context after each match                                             |
| `-i`                 | Case-insensitive matching                                                     |
| `--mode`             | Output mode: `content` or `count`                                             |
| `--limit`            | Maximum matches, 1–100 (default: 20)                                          |
| `--offset`           | Number of matches to skip for pagination (default: 0)                         |
| `--fuzzy-whitespace` | Fuzzy whitespace matching: `true`/`false`, omit for auto (PDF on, others off) |
| `--json`             | Output structured JSON (global option)                                        |

Examples:

```bash
linkly grep "useState" 456
linkly grep "error|warning" 1044 -C 3
linkly grep "TODO" 591 -i --mode count
linkly grep "function\s+\w+" 1044 -A 5 --json
```

### read — Read document content

```bash
linkly read <ID> [OPTIONS]
```

| Option         | Description                            |
| -------------- | -------------------------------------- |
| `<ID>`         | Document ID from search (required)     |
| `--offset <N>` | Starting line number, 1-based          |
| `--limit <N>`  | Number of lines to read, max 500       |
| `--json`       | Output structured JSON (global option) |

Examples:

```bash
linkly read 1044
linkly read 1044 --offset 50 --limit 100
linkly read 1044 --json
```

### status — Check connection status

```bash
linkly status
linkly status --json
```

Shows CLI version, app version, MCP endpoint, indexed document count, and index status.

### doctor — Diagnose connection issues

```bash
linkly doctor
linkly doctor --remote
linkly doctor --endpoint http://192.168.1.100:60606/mcp --token <token>
linkly doctor --json
```

Runs a series of diagnostic checks based on the connection mode:

- **Local**: Port file readability → HTTP connectivity → App status
- **LAN**: HTTP connectivity → Auth token → App status
- **Remote**: Credentials → Server reachability → Auth → Tunnel status → MCP round-trip

Each check reports pass/fail with actionable advice on failures. Use this as the first step when troubleshooting any connection problem.

### mcp — Run as MCP stdio bridge

```bash
linkly mcp
linkly mcp --endpoint http://192.168.1.100:60606/mcp   # bridge to a LAN desktop instead of localhost
```

Runs the CLI as a stdio MCP server for integration with Claude Desktop, Cursor, or other MCP clients. Only local and LAN modes are supported: `--endpoint` switches the upstream desktop, while `--token` and `--remote` are not accepted.

Claude Desktop configuration (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "linkly-ai": {
      "command": "linkly",
      "args": ["mcp"]
    }
  }
}
```

### auth set-key — Save API key for remote access

```bash
linkly auth set-key <API_KEY>
```

| Option      | Description                                                                     |
| ----------- | ------------------------------------------------------------------------------- |
| `<API_KEY>` | API key from linkly.ai dashboard (format: `lkai_<32-char hex>`, 37 chars total) |

Saves the key to `~/.linkly/credentials.json` for use with `--remote`.

### self-update — Update CLI

```bash
linkly self-update
```

## Connection Options

`--endpoint` and `--token` are available on `search`, `grep`, `outline`, `read`, `status`, `doctor`, and `list-libraries` commands; `mcp` also accepts `--endpoint` for LAN bridging (but not `--token`). `--remote` is available on the same commands (not on `mcp`, `auth`, or `self-update`).

| Flag               | Scope  | Description                                                                                                                                                                            |
| ------------------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--endpoint <url>` | LAN    | Connect to a specific MCP endpoint (e.g. `http://192.168.1.100:60606/mcp`), requires `--token`                                                                                         |
| `--token <token>`  | LAN    | Bearer token for LAN authentication (required with `--endpoint`, conflicts with `--remote`)                                                                                            |
| `--remote`         | Remote | Connect via `https://mcp.linkly.ai` — reaches local + linked cloud libraries (cloud works even when the desktop tunnel is down); requires `auth set-key` (conflicts with `--endpoint`) |

## Global Options

| Flag            | Description                                             |
| --------------- | ------------------------------------------------------- |
| `--json`        | Output in structured JSON format (useful for scripting) |
| `-V, --version` | Print version                                           |
| `-h, --help`    | Print help                                              |

## JSON Output Format

`--json` is a global option that can be placed before or after the subcommand. The CLI wraps MCP server responses with a `status` field.

**search:**

```json
{
  "status": "success",
  "query": "machine learning",
  "total": 10,
  "results": [{ "doc_id": "1044", "title": "...", "relevance": 0.85, ... }]
}
```

**outline:**

```json
{
  "status": "success",
  "documents": [{ "doc_id": "1044", "title": "...", "outline_text": "...", ... }]
}
```

**grep:**

```json
{
  "status": "success",
  "pattern": "useState",
  "total_matches": 5,
  "total_documents": 1,
  "results": [{ "doc_id": "456", "title": "...", "match_count": 5, "matches": [...] }]
}
```

**read:**

```json
{
  "status": "success",
  "doc_id": "1044",
  "title": "...",
  "content": "...",
  "total_lines": 84,
  "shown_from": 1,
  "shown_to": 50
}
```

**Error:**

```json
{
  "status": "error",
  "message": "error description"
}
```

Errors from the cloud gateway also carry a JSON-RPC `code` and a `data` object (with `guidance` / `example` for recovery):

```json
{
  "status": "error",
  "code": -32000,
  "message": "Desktop is offline",
  "data": { "guidance": "Reconnect the MCP Connector in Desktop settings." }
}
```

## Shell Composition Tips

The CLI outputs plain text or structured JSON, making it composable with standard Unix tools for more precise text processing. Note: a cloud `doc_id` embeds the file path and can contain spaces, so iterate doc_ids with `while IFS= read -r id` rather than `xargs` (which splits on whitespace).

**Extract doc IDs and batch outline:**

```bash
linkly search "architecture" --json | jq -r '.results[].doc_id' \
  | while IFS= read -r id; do linkly outline "$id"; done
```

**Chain search → grep for two-stage filtering:**

```bash
# First narrow by semantics, then filter by exact keyword
linkly search "deployment" --json \
  | jq -r '.results[].doc_id' \
  | while IFS= read -r id; do linkly grep "docker\|kubernetes" "$id"; done
```

**Aggregate outline output into a single file:**

```bash
linkly search "API design" --json \
  | jq -r '.results[].doc_id' \
  | while IFS= read -r id; do linkly outline "$id"; done \
  > combined-outlines.txt
```

**Use `grep` on CLI output for further filtering:**

```bash
linkly search "security" | grep -i "auth\|token\|jwt"
```

When using `--json`, pipe through `jq` to extract specific fields before passing to the next command. This keeps token usage low and gives you precise control over what the Agent reads.
