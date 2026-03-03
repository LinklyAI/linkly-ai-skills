# Linkly AI CLI Reference

Command-line interface for Linkly AI — search local documents from the terminal.

The CLI connects to the Linkly AI desktop app's MCP server, giving fast access to indexed documents without leaving the terminal.

## Prerequisites

The **Linkly AI desktop app** must be running with MCP server enabled. The CLI automatically discovers the app via `~/.linkly/port`.

## Installation

### macOS / Linux

```bash
curl -sSL https://updater.linkly.ai/cli/install.sh | sh
```

### Windows (PowerShell)

```powershell
irm https://updater.linkly.ai/cli/install.ps1 | iex
```

### From Source

```bash
cargo install --git https://github.com/nicepkg/linkly-ai-cli
```

## Commands

### search — Search indexed documents

```bash
linkly search <QUERY> [OPTIONS]
```

| Option           | Description                                               |
| ---------------- | --------------------------------------------------------- |
| `<QUERY>`        | Search keywords or phrases (required)                     |
| `--limit <N>`    | Maximum results, 1–50 (default: 20)                       |
| `--type <types>` | Filter by document types, comma-separated (e.g. `pdf,md`) |
| `--json`         | Output structured JSON (global option)                    |

Examples:

```bash
linkly search "machine learning"
linkly search "API design" --limit 5
linkly search "notes" --type pdf,md,docx
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

### self-update — Update CLI

```bash
linkly self-update
```

## Global Options

| Flag               | Description                                                            |
| ------------------ | ---------------------------------------------------------------------- |
| `--endpoint <url>` | Connect to a specific MCP endpoint (e.g. `http://127.0.0.1:60606/mcp`) |
| `--json`           | Output in structured JSON format (useful for scripting)                |
| `-V, --version`    | Print version                                                          |
| `-h, --help`       | Print help                                                             |

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
