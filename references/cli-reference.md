# Linkly AI CLI Reference

Command-line interface for Linkly AI — search your local documents (and, over `--remote`, your linked cloud libraries) from the terminal.

The CLI connects to the Linkly AI desktop app's MCP server (locally or over LAN), or to the `mcp.linkly.ai` cloud gateway via `--remote`, giving fast access to indexed documents without leaving the terminal.

## Prerequisites

For **local** documents, the **Linkly AI desktop app** must be running with its MCP server enabled (the CLI auto-discovers it via `~/.linkly/port`). Use LAN mode (`--endpoint` + `--token`) or Remote mode (`--remote` with a saved API key) to connect over the network. Linked **cloud** libraries reached via `--remote` do not require the desktop to be online — see below.

Remote mode reaches both your local libraries and your linked cloud libraries through the `mcp.linkly.ai` gateway. Linked cloud libraries are served even when the desktop tunnel is disconnected; local / default-scope calls additionally need the desktop online and its tunnel connected. Reaching **local** content over the tunnel is a Pro feature — on a Free plan those calls return `-32000` telling you the tunnel requires Pro, while linked cloud libraries stay available on all plans.

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
| `--type <types>`          | Filter by document type name, comma-separated — `pdf`, `docx`, `pptx`, `epub`, `md`, `txt`, `html`, `image`, `audio`, `video` (e.g. `pdf,md`). Type name, not extension.                                                         |
| `--library <name>`        | Restrict search to one library: a local name / `local://<id>`, or `cloud://<owner>/<slug>` (over `--remote`; cloud must be the two-segment `owner/slug` form). Omit = all local content.                                         |
| `--path-glob <pat>`       | Glob **substring-matched** against the file path (no leading/trailing `*` needed). `*` matches any chars including `/`, `?` one char. Full dir path `/Users/me/notes/` scopes to that dir. When unknown, run `find-paths` first. |
| `--modified-after <iso>`  | Inclusive lower bound on modification time (ISO 8601 UTC; bare date or RFC 3339)                                                                                                                                                 |
| `--modified-before <iso>` | Inclusive upper bound on modification time (same format as `--modified-after`)                                                                                                                                                   |
| `--time-sort <mode>`      | Reorder by modification time: `newest`, `oldest`, or `default`. `default` and omitting the flag are equivalent — both keep relevance order.                                                                                      |
| `--scope <scope>`         | `folder` (default) searches all indexed content; `notes` restricts results to the user's local Markdown card notes and **ignores `--library` and `--path-glob`**.                                                                |
| `--tags <tags>`           | Comma-separated note tags; returns only documents carrying **all** of them (AND). Leading `#` is stripped and ASCII lowercased. Most useful with `--scope notes`.                                                                |
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
linkly search "standup recording" --type audio,video
linkly search "quarterly planning" --scope notes
linkly search "meeting" --scope notes --tags work
linkly search "budget" --json
```

Read the `[meta] now=<iso>` footer (Markdown output) or top-level `_meta.now` (JSON output) of any tool response to compute relative dates ("last 7 days", "after July 1, 2024", "in 2024") rather than guessing the current date.

**Document IDs:** each search result's `doc_id` is an opaque string — pass it verbatim to `outline` / `grep` / `read`, never reshape or fabricate it. Local documents look like `local://<integer>` (older desktops return a bare integer, still accepted); cloud documents look like `cloud://<owner>/<slug>/<root-hash>/<path>`.

### outline — Get document outlines

```bash
linkly outline <IDS>...
```

| Option           | Description                                                                                         |
| ---------------- | --------------------------------------------------------------------------------------------------- |
| `<IDS>...`       | One or more document IDs from search (required). Pass `-` to read the IDs from stdin, one per line. |
| `--expand <ids>` | Node IDs to expand, comma-separated (e.g. `2,3.1`); others collapse, omit to auto-fit               |
| `--json`         | Output structured JSON (global option)                                                              |

Examples:

```bash
linkly outline 1044
linkly outline 1044 591 302
linkly outline 1044 --expand 2,3.1
linkly outline 1044 --json
```

### grep — Locate specific lines within a document by regex

```bash
linkly grep <PATTERN> <DOC_IDS>... [OPTIONS]
```

| Option               | Description                                                                                              |
| -------------------- | -------------------------------------------------------------------------------------------------------- |
| `<PATTERN>`          | Regular expression pattern (required)                                                                    |
| `<DOC_IDS>...`       | One or more document IDs to search within (required). Pass `-` to read the IDs from stdin, one per line. |
| `-C, --context`      | Lines of context before and after each match                                                             |
| `-B, --before`       | Lines of context before each match                                                                       |
| `-A, --after`        | Lines of context after each match                                                                        |
| `-i`                 | Case-insensitive matching                                                                                |
| `--mode`             | Output mode: `content` or `count`                                                                        |
| `--limit`            | Maximum matches, 1–100 (default: 20)                                                                     |
| `--offset`           | Number of matches to skip for pagination (default: 0)                                                    |
| `--fuzzy-whitespace` | Fuzzy whitespace matching: `true`/`false`, omit for auto (PDF on, others off)                            |
| `--json`             | Output structured JSON (global option)                                                                   |

Examples:

```bash
linkly grep "useState" 456
linkly grep "error|warning" 1044 -C 3
linkly grep "TODO" 591 -i --mode count
linkly grep "function\s+\w+" 1044 -A 5 --json
```

### read — Read document content

```bash
linkly read <IDS>... [OPTIONS]
```

| Option                  | Description                                                                                                                                                                                                                                                                                                                     |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<IDS>...`              | One or more document IDs from search (required). Pass `-` to read the IDs from stdin, one per line.                                                                                                                                                                                                                             |
| `--offset <N>`          | Starting line number, 1-based                                                                                                                                                                                                                                                                                                   |
| `--limit <N>`           | Number of lines to read, max 500                                                                                                                                                                                                                                                                                                |
| `--image-text <detail>` | Detail for the referenced-images block: `none` (mapping only), `abstract` (default — plus excerpt and word count), `full` (plus inline OCR text; 2000 chars per image, 20000 total, over-budget images degrade to `abstract`). Cloud documents never inline full text — `full` degrades to `abstract` with a per-image pointer. |
| `--json`                | Output structured JSON (global option)                                                                                                                                                                                                                                                                                          |

Examples:

```bash
linkly read 1044
linkly read 1044 --offset 50 --limit 100
linkly read 1044 --image-text full
linkly read 1044 --json
```

### list — Enumerate a container

```bash
linkly list --scope folder --path <DIR> [OPTIONS]
linkly list --scope library --library <REF> [OPTIONS]
linkly list --scope notes [OPTIONS]
```

Lists and paginates the contents of a container. Does **no** full-text matching and applies no ranking — reach for it when the user names a container, and for `search` when they name a topic. To find notes by content use `linkly search --scope notes`.

Three scopes: `folder` (a disk directory, or every watched root when `--path` is omitted), `library` (one library — `local://<id>`, a plain name, or `cloud://owner/slug`), and `notes` (the local Markdown card notes). **Requires Desktop 0.11.0+** for `folder` / `library`; on a local or LAN connection an older Desktop makes the CLI bail with a version error naming what is missing.

| Option                     | Description                                                                                                                                                                                                       |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--scope <scope>`          | **Required.** `folder`, `library`, or `notes`. Validated by the desktop rather than the CLI, so scopes added by a newer desktop work without upgrading the CLI.                                                   |
| `--library <ref>`          | Which library to list. **Required with `--scope library`**; rejected on other scopes. See `linkly list-libraries`.                                                                                                |
| `--path <dir>`             | Directory to list. Absolute for `--scope folder` and for a local library; a **relative** prefix from the library root for a cloud library. An address, not a glob — run `linkly find-paths` if the name is fuzzy. |
| `--type <types>`           | Comma-separated document types (`pdf,md,docx,…`). `folder` / `library` only.                                                                                                                                      |
| `--modified-after <date>`  | Inclusive lower bound on file modification time (ISO 8601 UTC). `folder` / `library` only.                                                                                                                        |
| `--modified-before <date>` | Inclusive upper bound, same format. `folder` / `library` only.                                                                                                                                                    |
| `--tags <tags>`            | Comma-separated tags; returns only items carrying **all** of them (AND). `notes` only.                                                                                                                            |
| `--limit <N>`              | Maximum items (default 50, max 200; capped at 50 while snippets are on)                                                                                                                                           |
| `--offset <N>`             | Pagination offset in sort order (default 0). Use `has_more` to decide whether to fetch the next page.                                                                                                             |
| `--sort <order>`           | `recent` (default, newest first), `oldest`, or `name` (basename A → Z). Cloud libraries reject `name`.                                                                                                            |
| `--snippet`                | Attach per-item snippets where the scope defaults to off (`folder` / `library`, taken from the indexed abstract). Caps `--limit` at 50.                                                                           |
| `--no-snippet`             | Omit per-item snippets; allows limits above 50. This is the notes-side counterpart, where snippets are on by default.                                                                                             |
| `--json`                   | Output structured JSON (global option). The CLI prints Markdown for **every** scope unless this is set — the MCP tool's JSON-by-default for notes does not apply here.                                            |

Examples:

```bash
linkly list --scope folder --path /Users/me/Documents/reports
linkly list --scope folder --path /Users/me/notes --type md --modified-after 2026-01-01
linkly list --scope folder --limit 200 --no-snippet          # every watched root
linkly list --scope library --library my-research --snippet
linkly list --scope library --library cloud://alice/handbook --path guides/ --remote
linkly list --scope notes
linkly list --scope notes --tags project,urgent
linkly list --scope notes --sort name --limit 100 --no-snippet
```

`--sort` chooses which slice survives `--limit`, so it is a correctness choice, not cosmetics: with `has_more` true you are holding the newest / oldest / A→Z head, never a random sample.

A `folder` or local `library` listing given an explicit `--path` may also point at that directory's README (`README.md` → `README.txt` → `index.md` → `_index.md` → `<foldername>.md`, agent instruction files excluded). It is a pointer, not the content — `linkly read` it only when the folder's purpose actually matters.

Note listings carry `available_tags` — the tags actually in use across all notes (top 50 by usage). Reuse those values rather than inventing new ones. Each note item also carries `note_id` and `version`, which together are the handle needed by `note-save --mode edit`; a note written moments ago shows up with `indexed: false` and a null `doc_id` until indexing catches up.

### note-save — Create or rewrite a note

```bash
linkly note-save --mode create --content "..." [--tags <tags>]
linkly note-save --mode edit --note-id <uuid> --base-version <version> --tags <tags> --content "..."

# Long bodies are easier to pipe in than to quote:
some-command | linkly note-save --mode create --content - --tags research
```

**This is the only write command.** It creates or rewrites one of the user's local Markdown notes.

With `--remote` the write still lands on the Desktop machine — the tunnel forwards to it, and notes are never stored in the cloud. So `note-save --remote` needs that Desktop online (which over the tunnel also means Pro), and there is no cloud library to target or to fall back on when it is offline. There is no delete command; deletion is user-only in the app UI.

| Option                  | Description                                                                                                                                                                        |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--mode <mode>`         | **Required.** `create` writes a new note; `edit` rewrites an existing one. `edit` requires `--note-id` and `--base-version`.                                                       |
| `--content <markdown>`  | **Required.** Body without YAML front matter. Restricted Markdown subset — see below. Pass `-` to read the body from stdin, which avoids shell-quoting a long note.                |
| `--note-id <uuid>`      | Note UUID. Required for `edit`; on `create` an already-existing id is rejected as `NOTE_DUPLICATE_ID`.                                                                             |
| `--base-version <hash>` | The note's current version (sha256 of the raw file), from `linkly list --scope notes`. Required for `edit`. A stale value returns `NOTE_VERSION_CONFLICT` with the actual version. |
| `--tags <tags>`         | Comma-separated. Optional on both modes; only **adds** tags (the server appends the missing `#tokens` to the body). Remove a tag by deleting its `#token` from the content.        |

**Content whitelist.** Allowed: paragraphs, line breaks, bold, strikethrough, ordered and unordered lists, plain text. Rejected with `NOTE_INVALID_INPUT`: headings, italics, blockquotes, inline code, code blocks, links, images, raw HTML, thematic breaks, tables, task lists, footnotes. Inline `#tags` in the body **are** the note's tags — the body is the source of truth; remove a tag by deleting its `#token` from the content.

**Tag policy.** Do not add tags on your own initiative; pass only tags the user explicitly asked for.

**Never write YAML front matter** — the server owns all metadata (`note_id`, timestamps, source, tags).

Error codes: `NOTE_INVALID_INPUT`, `NOTE_NOT_FOUND`, `NOTE_DUPLICATE_ID`, `NOTE_VERSION_CONFLICT`, `NOTE_OUTSIDE_ROOT`, `NOTE_PARSE_ERROR`, `NOTE_IO_ERROR`.

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
linkly mcp --remote                                    # bridge through the cloud gateway (local + cloud libraries)
```

Runs the CLI as a stdio MCP server for integration with Claude Desktop, Cursor, or other MCP clients. The bridge is a transparent passthrough — whatever tools the upstream exposes are forwarded as-is.

**Choose the upstream deliberately, because it decides what the MCP client can reach:**

- default (no flag) — the local desktop. Local content only; `cloud://` references are rejected.
- `--endpoint <url>` — a desktop on the LAN. Same content boundary as local.
- `--remote` — the `mcp.linkly.ai` gateway. Reaches local content (through the desktop tunnel) **and** linked cloud libraries. Requires `linkly auth set-key` first.

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

### auth — Manage credentials

```bash
linkly auth set-key <API_KEY>
linkly auth status
linkly auth logout
```

| Command   | Description                                                                                                                                |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `set-key` | Save an API key from the linkly.ai dashboard (format: `lkai_<32-char hex>`, 37 chars total) to `~/.linkly/credentials.json` for `--remote` |
| `status`  | Show which key is in use, whether it is valid, and the account's plan                                                                      |
| `logout`  | Remove the stored credentials                                                                                                              |

Linkly AI CLI authenticates with an API key rather than a browser sign-in, so it works in headless and agent environments.

### completions — Shell completion script

```bash
linkly completions <SHELL>
```

Prints a completion script to stdout. Supported shells: `bash`, `zsh`, `fish`, `powershell`, `elvish`.

| Shell      | Install                                                             |
| ---------- | ------------------------------------------------------------------- |
| bash       | `linkly completions bash > /usr/local/etc/bash_completion.d/linkly` |
| zsh        | `linkly completions zsh > "${fpath[1]}/_linkly"`                    |
| fish       | `linkly completions fish > ~/.config/fish/completions/linkly.fish`  |
| powershell | `linkly completions powershell \| Out-String \| Invoke-Expression`  |
| elvish     | `linkly completions elvish > ~/.config/elvish/lib/linkly.elv`       |

Open a new shell afterwards. For zsh, `compinit` must already be running (it is under oh-my-zsh); a bare zsh needs `autoload -Uz compinit && compinit` in `~/.zshrc` first.

The script is **static**: it completes subcommands, flags, and fixed value sets (`--image-text`, `--mode`, `--sort`, `--time-sort`). It never starts a process or contacts the desktop app, so it can't stall your prompt and works with Linkly AI closed. Values that are open-ended — `--scope`, `--library`, `--tags`, document IDs — complete to nothing rather than falling back to filenames.

### self-update — Update CLI

```bash
linkly self-update
```

## Connection Options

`--endpoint` and `--token` are available on the document commands (`search`, `grep`, `outline`, `read`, `list`, `note-save`, `list-libraries`, `explore`, `find-paths`) plus `status` and `doctor`; `mcp` accepts `--endpoint` for LAN bridging (but not `--token`). `--remote` is available on those same commands and on `mcp`; it is not accepted by `auth` or `self-update`.

| Flag               | Scope  | Description                                                                                                                                                                            |
| ------------------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--endpoint <url>` | LAN    | Connect to a specific MCP endpoint (e.g. `http://192.168.1.100:60606/mcp`), requires `--token`                                                                                         |
| `--token <token>`  | LAN    | Bearer token for LAN authentication (required with `--endpoint`, conflicts with `--remote`)                                                                                            |
| `--remote`         | Remote | Connect via `https://mcp.linkly.ai` — reaches local + linked cloud libraries (cloud works even when the desktop tunnel is down); requires `auth set-key` (conflicts with `--endpoint`) |

`--remote` changes **how you reach your Desktop**, not where the data lives: the gateway forwards to that machine over the tunnel. Linked cloud libraries are the one exception — the gateway serves those itself, so they stay available while the Desktop is offline. Notes are the opposite extreme: they exist only on the Desktop, so `list --scope notes` and `note-save` over `--remote` fail outright when it is unreachable, with nothing to retry against.

## Exit Codes

By default the CLI keeps the conventional two-value contract:

| Code | Meaning                      |
| ---- | ---------------------------- |
| `0`  | The command ran successfully |
| `1`  | The command failed           |

Note that "ran successfully" includes finding nothing — a search with no hits still exits `0`.

### `--exit-code`

Pass `--exit-code` (a global flag) to tell "found nothing" apart from "failed":

| Code | Meaning                                                                        |
| ---- | ------------------------------------------------------------------------------ |
| `0`  | The command ran and produced at least one result                               |
| `1`  | The command ran successfully but found nothing (no search hits, no matches)    |
| `2`  | The command failed (connection, authentication, invalid arguments, tool error) |

```bash
# Only runs the second command when there really was a hit:
linkly search "quarterly report" --exit-code && open-report

# Tell "nothing found" apart from "Linkly is broken":
linkly search "$q" --exit-code
case $? in
  0) echo "found" ;;
  1) echo "nothing matched" ;;
  2) echo "linkly failed" ;;
esac
```

The flag is opt-in because it changes what `1` means: without it, `1` is "failed" (the historical behaviour existing scripts test for); with it, `1` is "matched nothing" and failures move to `2`.

**Applies to** `search`, `grep`, `find-paths` and `list` — the commands that can legitimately match nothing. Every other command exits `0` on success either way.

## Global Options

| Flag            | Description                                                                        |
| --------------- | ---------------------------------------------------------------------------------- |
| `--json`        | Output in structured JSON format (useful for scripting)                            |
| `--exit-code`   | Distinguish "no results" (`1`) from "failed" (`2`) — see [Exit Codes](#exit-codes) |
| `-V, --version` | Print version                                                                      |
| `-h, --help`    | Print help                                                                         |

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

`read`, `outline` and `grep` all take **several document IDs**, and `-` reads the IDs from stdin (one per line). So a `search` result feeds straight into the next command — no shell loop.

**Outline everything a search found:**

```bash
linkly search "architecture" --json | jq -r '.results[].doc_id' | linkly outline -
```

**Chain search → grep for two-stage filtering:**

```bash
# First narrow by semantics, then filter by exact keyword
linkly search "deployment" --json \
  | jq -r '.results[].doc_id' \
  | linkly grep "docker\|kubernetes" -
```

**Aggregate into a file:**

```bash
linkly search "API design" --json | jq -r '.results[].doc_id' \
  | linkly outline - > combined-outlines.txt
```

**Read several documents as JSON Lines:**

```bash
# One JSON object per line — one document each. A single ID still prints
# a single object, so this is safe to use either way.
linkly search "onboarding" --json | jq -r '.results[].doc_id' \
  | linkly read - --json \
  | jq -r '"\(.title): \(.total_lines) lines"'
```

**Use `grep` on CLI output for further filtering:**

```bash
linkly search "security" | grep -i "auth\|token\|jwt"
```

Notes on batching:

- **`-` cannot be mixed with IDs on the command line** — pass either `-` alone or the IDs directly.
- **Partial failures don't abort the batch.** Unreadable documents are reported on stderr and the rest still print on stdout, so a downstream parser sees only good records. If _every_ ID fails, the command fails.
- **`--exit-code` treats the batch as a whole**: `grep` exits 0 when at least one document matched, 1 when none did — the same thing `grep pattern *.txt` reports.
- A cloud `doc_id` embeds the file path and can contain spaces. Piping through `-` is line-based and handles that; `xargs` (which splits on whitespace) does not.

When using `--json`, pipe through `jq` to extract specific fields before passing to the next command. This keeps token usage low and gives you precise control over what the Agent reads.
