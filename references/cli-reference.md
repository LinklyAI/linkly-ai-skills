# Linkly AI CLI Reference

Command-line interface for Linkly AI — search local documents from the terminal.

The CLI connects to the Linkly AI desktop app's MCP server, giving fast access to indexed documents without leaving the terminal.

## Prerequisites

The **Linkly AI desktop app** must be running with MCP server enabled. The CLI automatically discovers the app via `~/.linkly/port`.

## Installation

### Direct Download

Download the pre-built binary for your platform, extract and place it in a directory on your `PATH`.

| Platform              | CDN Download                                                                                                            | GitHub Mirror                                                                                                        |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| macOS (Apple Silicon) | [linkly-aarch64-apple-darwin.tar.gz](https://updater.linkly.ai/cli/latest/linkly-aarch64-apple-darwin.tar.gz)           | [GitHub](https://github.com/LinklyAI/linkly-ai-cli/releases/latest/download/linkly-aarch64-apple-darwin.tar.gz)      |
| macOS (Intel)         | [linkly-x86_64-apple-darwin.tar.gz](https://updater.linkly.ai/cli/latest/linkly-x86_64-apple-darwin.tar.gz)             | [GitHub](https://github.com/LinklyAI/linkly-ai-cli/releases/latest/download/linkly-x86_64-apple-darwin.tar.gz)       |
| Linux (x86_64)        | [linkly-x86_64-unknown-linux-gnu.tar.gz](https://updater.linkly.ai/cli/latest/linkly-x86_64-unknown-linux-gnu.tar.gz)   | [GitHub](https://github.com/LinklyAI/linkly-ai-cli/releases/latest/download/linkly-x86_64-unknown-linux-gnu.tar.gz)  |
| Linux (ARM64)         | [linkly-aarch64-unknown-linux-gnu.tar.gz](https://updater.linkly.ai/cli/latest/linkly-aarch64-unknown-linux-gnu.tar.gz) | [GitHub](https://github.com/LinklyAI/linkly-ai-cli/releases/latest/download/linkly-aarch64-unknown-linux-gnu.tar.gz) |
| Windows (x64)         | [linkly-x86_64-pc-windows-msvc.zip](https://updater.linkly.ai/cli/latest/linkly-x86_64-pc-windows-msvc.zip)             | [GitHub](https://github.com/LinklyAI/linkly-ai-cli/releases/latest/download/linkly-x86_64-pc-windows-msvc.zip)       |

### Install Script

macOS / Linux:

```bash
curl -sSL https://updater.linkly.ai/cli/install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://updater.linkly.ai/cli/install.ps1 | iex
```

### Homebrew (macOS / Linux)

```bash
brew tap LinklyAI/tap
brew install linkly
```

### Cargo (cross-platform)

```bash
cargo install linkly-ai-cli
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

### grep — Locate specific lines within a document by regex

```bash
linkly grep <PATTERN> <DOC_ID> [OPTIONS]
```

| Option          | Description                                                  |
| --------------- | ------------------------------------------------------------ |
| `<PATTERN>`     | Regular expression pattern (required)                        |
| `<DOC_ID>`      | Document ID to search within (required, from search results) |
| `-C, --context` | Lines of context before and after each match                 |
| `-B, --before`  | Lines of context before each match                           |
| `-A, --after`   | Lines of context after each match                            |
| `-i`            | Case-insensitive matching                                    |
| `--mode`        | Output mode: `content` or `count`                            |
| `--limit`       | Maximum matches, 1–100 (default: 20)                         |
| `--json`        | Output structured JSON (global option)                       |

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

**grep:**

```json
{
  "status": "success",
  "pattern": "useState",
  "total_matches": 5,
  "total_documents": 2,
  "results": [{ "doc_id": "456", "title": "...", "match_count": 3, "matches": [...] }]
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
