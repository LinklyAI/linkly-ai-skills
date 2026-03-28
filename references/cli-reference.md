# Linkly AI CLI Reference

Command-line interface for Linkly AI — search local documents from the terminal.

The CLI connects to the Linkly AI desktop app's MCP server, giving fast access to indexed documents without leaving the terminal.

## Prerequisites

The **Linkly AI desktop app** must be running with MCP server enabled. By default, the CLI automatically discovers the app via `~/.linkly/port`. Alternatively, use LAN mode (`--endpoint` + `--token`) or Remote mode (`--remote` with a saved API key).

## Installation

See the [CLI installation guide](https://linkly.ai/docs/en/use-cli) for platform-specific instructions.

## Commands

### list-libraries — List knowledge libraries

```bash
linkly list-libraries
```

Lists all knowledge libraries configured in the desktop app with document counts.

| Option   | Description                            |
| -------- | -------------------------------------- |
| `--json` | Output structured JSON (global option) |

### search — Search indexed documents

```bash
linkly search <QUERY> [OPTIONS]
```

| Option              | Description                                                                                           |
| ------------------- | ----------------------------------------------------------------------------------------------------- |
| `<QUERY>`           | Search keywords or phrases (required)                                                                 |
| `--limit <N>`       | Maximum results, 1–50 (default: 20)                                                                   |
| `--type <types>`    | Filter by document types, comma-separated (e.g. `pdf,md`)                                             |
| `--library <name>`  | Restrict search to a specific library by name                                                         |
| `--path-glob <pat>` | SQLite GLOB pattern to filter by file path. `*` matches any chars including `/`, `?` matches one char |
| `--json`            | Output structured JSON (global option)                                                                |

Examples:

```bash
linkly search "machine learning"
linkly search "API design" --limit 5
linkly search "notes" --type pdf,md,docx
linkly search "deep learning" --library my-research
linkly search "report" --path-glob "*2024*"
linkly search "budget" --json
```

### outline — Get document outlines

```bash
linkly outline <IDS>...
```

| Option     | Description                                     |
| ---------- | ----------------------------------------------- |
| `<IDS>...` | One or more document IDs from search (required) |
| `--json`   | Output structured JSON (global option)          |

Examples:

```bash
linkly outline 1044
linkly outline 1044 591 302
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
```

Runs the CLI as a stdio MCP server for integration with Claude Desktop, Cursor, or other MCP clients.

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

`--endpoint` and `--token` are available on `search`, `grep`, `outline`, `read`, `status`, `doctor`, and `list-libraries` commands. `--remote` is available on the same commands (not on `mcp`, `auth`, or `self-update`).

| Flag               | Scope  | Description                                                                                       |
| ------------------ | ------ | ------------------------------------------------------------------------------------------------- |
| `--endpoint <url>` | LAN    | Connect to a specific MCP endpoint (e.g. `http://192.168.1.100:60606/mcp`), requires `--token`    |
| `--token <token>`  | LAN    | Bearer token for LAN authentication (required with `--endpoint`, conflicts with `--remote`)       |
| `--remote`         | Remote | Connect via `https://mcp.linkly.ai` tunnel (conflicts with `--endpoint`, requires `auth set-key`) |

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

## Shell Composition Tips

The CLI outputs plain text or structured JSON, making it composable with standard Unix tools for more precise text processing.

**Extract doc IDs and batch outline:**

```bash
linkly search "architecture" --json | jq -r '.results[].doc_id' | xargs linkly outline
```

**Chain search → grep for two-stage filtering:**

```bash
# First narrow by semantics, then filter by exact keyword
linkly search "deployment" --json \
  | jq -r '.results[].doc_id' \
  | xargs -I{} linkly grep "docker\|kubernetes" {}
```

**Aggregate outline output into a single file:**

```bash
linkly search "API design" --json \
  | jq -r '.results[].doc_id' \
  | while read id; do linkly outline "$id"; done \
  > combined-outlines.txt
```

**Count document types in search results:**

```bash
linkly search "" --json | jq '.results[].type' | sort | uniq -c | sort -rn
```

**Use `grep` on CLI output for further filtering:**

```bash
linkly search "security" | grep -i "auth\|token\|jwt"
```

When using `--json`, pipe through `jq` to extract specific fields before passing to the next command. This keeps token usage low and gives you precise control over what the Agent reads.
