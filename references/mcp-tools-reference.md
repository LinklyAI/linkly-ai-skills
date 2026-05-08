# Linkly AI MCP Tools Reference

The Linkly AI MCP server exposes seven tools for document operations. These tools are available when the Linkly AI desktop app is running with MCP server enabled.

**Server name:** `linkly-ai`

## Response Metadata

Every successful tool response carries the wallclock time so callers can compute relative dates ("last month", "this year") without relying on training cutoffs:

- **Markdown** output ends with a footer block: `\n---\n[meta] now=<ISO 8601 UTC>` (e.g. `[meta] now=2026-05-07T14:43:14Z`).
- **JSON** output (`output_format: "json"`) includes a top-level `_meta` object: `{ "now": "<ISO 8601 UTC>" }`.

Errors (`isError: true`) do **not** include this metadata — the error body itself conveys the failure cause. When deriving relative dates, prefer the most recent `now` value you've seen over any other source.

## list_libraries

List all knowledge libraries configured by the user.

### Parameters

No parameters required.

### Response

Returns a Markdown-formatted list of libraries with descriptions and document counts. Example:

```
# Libraries

- **my-research**: AI and ML papers (42 docs, 3 folders)
- **work-notes**: Daily work logs (128 docs, 1 folders)
```

**When to use:** Only when the user asks what libraries exist, or before using the `library` parameter in `search` to verify a library name.

## explore

Get a bird's-eye overview of all indexed documents or a specific library. Returns document type distribution, directory structure with file counts and median word counts, and top keywords with source attribution.

### Parameters

| Parameter | Type     | Required | Default | Description                                                                    |
| --------- | -------- | -------- | ------- | ------------------------------------------------------------------------------ |
| `library` | `string` | No       | —       | Restrict to a specific library by name. Omit to explore all indexed documents. |

### Response

Returns a Markdown-formatted overview with four sections:

1. **Summary**: Total document count, outline count, and type distribution
2. **Directory Structure**: Tree view with file counts, median word counts, and last modified dates (UTC)
3. **Top Keywords**: Global keywords (spread across directories) and local keywords (concentrated ≥90% in a single directory, grouped by source)
4. **Recent Activity**: Directories with document changes in the last 7 days, with file counts and timestamps

**When to use:** When the user wants to understand what's in their knowledge base, wants an overview of themes, asks about recent changes, or doesn't yet know what to search for. Use the keywords, directory names, and recent activity from the output to formulate targeted search queries.

## find_paths

Locate real folder paths in the indexed documents by fuzzy keyword matching on the file path. Returns top folder candidates with file counts so the caller can pick a `path_glob` for a follow-up `search` call.

### Parameters

| Parameter       | Type       | Required | Default      | Description                                                                                                                                                                                                                                                                                 |
| --------------- | ---------- | -------- | ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `patterns`      | `string[]` | Yes      | —            | Keywords to substring-match against file paths. Multiple keywords are OR-matched (each one wrapped as SQL `LIKE %keyword%`); pass cross-language or spelling variants in a single call (e.g. `["WeChat", "微信", "xinWeChat", "wxid"]`). Case-insensitive for ASCII; CJK matches literally. |
| `library`       | `string`   | No       | —            | Restrict to a specific library by name. Use `list_libraries` to see available names.                                                                                                                                                                                                        |
| `limit`         | `integer`  | No       | 10           | Maximum folder candidates to return (max 50).                                                                                                                                                                                                                                               |
| `output_format` | `string`   | No       | `"markdown"` | `"markdown"` (default) or `"json"`.                                                                                                                                                                                                                                                         |

### Response Fields (JSON mode)

| Field         | Type      | Description                                                                               |
| ------------- | --------- | ----------------------------------------------------------------------------------------- |
| `total_files` | `number`  | Total files aggregated across all returned folder candidates (before `limit` truncation). |
| `truncated`   | `boolean` | True when `limit` capped the directory list (more candidates exist than were returned).   |
| `directories` | `array`   | Folder candidates, ordered by `file_count` descending (ties broken by path ascending).    |

Each directory entry:

| Field        | Type     | Description                                                                                                           |
| ------------ | -------- | --------------------------------------------------------------------------------------------------------------------- |
| `path`       | `string` | Folder path (privacy-aware: shortened to `.../parent/leaf` unless the user opted into full path display in Settings). |
| `file_count` | `number` | Number of indexed files inside this folder whose path matched any of the `patterns`.                                  |

### Aggregation behaviour (important)

- This is a "find folders" tool. Files whose `patterns` only match the **filename segment** (no matching directory segment) are **dropped** silently — they are not returned as their own folder. If a query yields zero directories despite matching files, fall back to `search` directly.
- Each match is bucketed by the **shallowest** pattern occurrence in its path, truncated at the next `/`. So `local:///Users/me/Library/.../com.tencent.xinWeChat/Data/...` matched by `WeChat` aggregates under `.../com.tencent.xinWeChat`, regardless of how deep the matching file lives.

**When to use:** The user names a container by a fuzzy or cross-language word ("in my WeChat files", "in my Notion notes", "在我的微信里") and you don't yet know the actual on-disk path. Pass several variants in `patterns` in a single call, then pipe a distinctive segment of any returned path back to `search` as `path_glob` (substring-matched, so `*xinWeChat*` works as well as a full prefix).

**When NOT to use:**

- Pure content/topic queries ("find resumes", "find AI papers") — call `search` directly; its hybrid retrieval already covers title/filename/content/path.
- Filtering by file type ("all PDFs") — call `search` with `path_glob="*.pdf"` directly.
- Vague queries with no container intent ("find recent stuff") — call `search`.

### Example

Call:

```json
{ "patterns": ["WeChat", "微信", "wxid"], "limit": 5 }
```

Response (JSON mode):

```json
{
  "total_files": 940,
  "truncated": false,
  "directories": [
    {
      "path": ".../com.tencent.xinWeChat/Data",
      "file_count": 940
    }
  ],
  "_meta": { "now": "2026-05-07T14:43:14Z" }
}
```

The follow-up `search` call would then use `path_glob: "*xinWeChat*"` to scope the actual content query.

## search

Search indexed local documents by keywords or phrases.

### Parameters

| Parameter         | Type       | Required | Default     | Description                                                                                                                                                                              |
| ----------------- | ---------- | -------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `query`           | `string`   | Yes      | —           | Search keywords or phrases                                                                                                                                                               |
| `limit`           | `integer`  | No       | 20          | Maximum results to return (1–50)                                                                                                                                                         |
| `doc_types`       | `string[]` | No       | —           | Filter by document types (e.g. `["pdf", "md"]`)                                                                                                                                          |
| `library`         | `string`   | No       | —           | Restrict search to a specific library by name. Use `list_libraries` to see available names.                                                                                              |
| `path_glob`       | `string`   | No       | —           | SQLite GLOB pattern to filter by file path. `*` matches any chars including `/`, `?` matches one char. Always case-sensitive. When the actual path is unknown, run `find_paths` first.   |
| `modified_after`  | `string`   | No       | —           | Inclusive lower bound on modification time. Accepts ISO 8601 UTC: a bare date `"2024-01-01"` (expanded to `00:00:00Z`) or a full RFC 3339 datetime `"2024-01-01T00:00:00Z"`.             |
| `modified_before` | `string`   | No       | —           | Inclusive upper bound on modification time. Same format as `modified_after`.                                                                                                             |
| `time_sort`       | `string`   | No       | `"default"` | One of `"default"` / `"newest"` / `"oldest"`. `"default"` keeps hybrid relevance ordering; `"newest"` / `"oldest"` reorder by `modified_at` after dedup, useful for "latest / earliest". |
| `output_format`   | `string`   | No       | —           | Set to `"json"` for structured JSON output                                                                                                                                               |

### Response Fields (JSON mode)

| Field     | Type     | Description                        |
| --------- | -------- | ---------------------------------- |
| `query`   | `string` | The original search query          |
| `total`   | `number` | Total number of matching documents |
| `results` | `array`  | List of search result items        |

Each result item:

| Field         | Type       | Description                                                                                                |
| ------------- | ---------- | ---------------------------------------------------------------------------------------------------------- |
| `doc_id`      | `string`   | Unique document identifier, always an integer string (e.g. `"1044"`). Obtain from search; never fabricate. |
| `title`       | `string`   | Document title                                                                                             |
| `path`        | `string`   | Shortened file path                                                                                        |
| `relevance`   | `number`   | Relevance score (0–1)                                                                                      |
| `word_count`  | `number?`  | Total word count                                                                                           |
| `total_lines` | `number?`  | Total line count                                                                                           |
| `has_outline` | `boolean`  | Whether a structural outline is available                                                                  |
| `modified_at` | `number`   | Last modified timestamp (Unix ms)                                                                          |
| `keywords`    | `string[]` | Extracted keywords                                                                                         |
| `snippet`     | `string`   | Text snippet with matching context                                                                         |

## outline

Get metadata and structural outlines of documents by their IDs.

### Parameters

| Parameter       | Type       | Required | Default | Description                                                                                          |
| --------------- | ---------- | -------- | ------- | ---------------------------------------------------------------------------------------------------- |
| `doc_ids`       | `string[]` | Yes      | —       | List of document IDs (from search results)                                                           |
| `expand`        | `string[]` | No       | —       | Node IDs to expand (e.g. `["2", "3.1"]`). Only specified nodes are fully expanded; others collapsed. |
| `output_format` | `string`   | No       | —       | Set to `"json"` for structured JSON output                                                           |

### Response Fields (JSON mode)

| Field       | Type    | Description                      |
| ----------- | ------- | -------------------------------- |
| `documents` | `array` | List of document outline objects |

Each document object:

| Field               | Type      | Description                                                      |
| ------------------- | --------- | ---------------------------------------------------------------- |
| `doc_id`            | `string`  | Document identifier                                              |
| `title`             | `string`  | Document title                                                   |
| `path`              | `string`  | Shortened file path                                              |
| `word_count`        | `number?` | Total word count                                                 |
| `total_lines`       | `number?` | Total line count                                                 |
| `has_outline`       | `boolean` | Whether a parsed outline exists                                  |
| `outline_text`      | `string`  | Pre-rendered outline tree with node IDs and line ranges          |
| `abstract_text`     | `string?` | Document abstract or first paragraph                             |
| `is_brief`          | `boolean` | True if document is short (<500 words, determined at index time) |
| `no_outline_reason` | `string?` | Reason if outline is unavailable                                 |

### Outline Text Format

The `outline_text` field contains a tree structure with node IDs and line ranges:

```
[1] Introduction [L1-25, 25行]
  [1.1] Background [L5-15, 11行]
  [1.2] Motivation [L16-25, 10行]
[2] Methods [L26-80, 55行]
  [2.1] Data Collection [L30-50, 21行]
  [2.2] Analysis [L51-80, 30行]
[3] Results [L81-120, 40行]
```

Use node IDs (e.g. `"1.2"`, `"2"`) with the `expand` parameter to drill into specific sections. Use line ranges with the `read` tool's `offset` and `limit` parameters to read that section. For example, to read section `[L30-50]`, use `offset=30` and `limit=21` (50 - 30 + 1 = 21 lines).

## grep

Locate specific lines within a single document by regex pattern. Best for documents with `has_outline=false` where outline is unavailable. Use after `search` to pinpoint exact positions of names, dates, terms, identifiers, or any pattern — then use `read` with offset to see full context. Works on all document types (PDF, Markdown, DOCX, TXT, HTML). The `doc_id` parameter takes a single ID — to scan multiple documents, call grep once per `doc_id`.

### Parameters

| Parameter          | Type      | Required | Default     | Description                                                                                     |
| ------------------ | --------- | -------- | ----------- | ----------------------------------------------------------------------------------------------- |
| `pattern`          | `string`  | Yes      | —           | Regular expression pattern to search for                                                        |
| `doc_id`           | `string`  | Yes      | —           | Document ID to search within (from search results)                                              |
| `context`          | `integer` | No       | 3           | Lines of context before and after each match (-C)                                               |
| `before`           | `integer` | No       | —           | Lines of context before each match (-B), overrides `context`                                    |
| `after`            | `integer` | No       | —           | Lines of context after each match (-A), overrides `context`                                     |
| `case_insensitive` | `boolean` | No       | false       | Case-insensitive matching                                                                       |
| `output_mode`      | `string`  | No       | `"content"` | `"content"` (matching lines with context) or `"count"` (match count only, preview totals first) |
| `limit`            | `integer` | No       | 20          | Maximum matching lines to return (max 100)                                                      |
| `offset`           | `integer` | No       | 0           | Number of matches to skip for pagination                                                        |
| `output_format`    | `string`  | No       | —           | Set to `"json"` for structured JSON output                                                      |

### Response Fields (JSON mode)

| Field             | Type     | Description                        |
| ----------------- | -------- | ---------------------------------- |
| `pattern`         | `string` | The regex pattern used             |
| `total_matches`   | `number` | Total number of matching lines     |
| `total_documents` | `number` | Number of documents with matches   |
| `results`         | `array`  | List of per-document match results |

Each result item:

| Field         | Type     | Description                                           |
| ------------- | -------- | ----------------------------------------------------- |
| `doc_id`      | `string` | Document identifier                                   |
| `title`       | `string` | Document title                                        |
| `path`        | `string` | Shortened file path                                   |
| `match_count` | `number` | Number of matches in this document                    |
| `matches`     | `array`  | List of match objects (only in `content` output_mode) |

Each match object:

| Field            | Type                 | Description                                 |
| ---------------- | -------------------- | ------------------------------------------- |
| `line_number`    | `number`             | 1-based line number of the match            |
| `content`        | `string`             | The matching line text                      |
| `context_before` | `[number, string][]` | Lines before the match (line number + text) |
| `context_after`  | `[number, string][]` | Lines after the match (line number + text)  |

### Content Format (Markdown mode)

Matching lines are shown with a `>` marker and line numbers:

```
  23	import { useState, useEffect } from 'react';
  45>	  const [notes, setNotes] = useState([]);
  78>	  const [isLoading, setIsLoading] = useState(false);
```

Use the line numbers with `read --offset` to see more surrounding context.

## read

Read document content by ID with line-based pagination.

### Parameters

| Parameter       | Type      | Required | Default | Description                                |
| --------------- | --------- | -------- | ------- | ------------------------------------------ |
| `doc_id`        | `string`  | Yes      | —       | Document ID (from search results)          |
| `offset`        | `integer` | No       | 1       | Starting line number (1-based)             |
| `limit`         | `integer` | No       | 200     | Number of lines to read (max 500)          |
| `output_format` | `string`  | No       | —       | Set to `"json"` for structured JSON output |

### Response Fields (JSON mode)

| Field         | Type      | Description                                                                     |
| ------------- | --------- | ------------------------------------------------------------------------------- |
| `doc_id`      | `string`  | Document identifier                                                             |
| `title`       | `string`  | Document title                                                                  |
| `path`        | `string`  | Shortened file path                                                             |
| `word_count`  | `number?` | Total word count                                                                |
| `author`      | `string?` | Document author or summary                                                      |
| `content`     | `string`  | Content with line numbers (prefixed)                                            |
| `total_lines` | `number`  | Total lines in the document (always present, computed from actual file content) |
| `shown_from`  | `number`  | First line shown (1-based)                                                      |
| `shown_to`    | `number`  | Last line shown (1-based, inclusive)                                            |

### Content Format

The `content` field contains line-numbered text:

```
 1	First line of the document
 2	Second line of the document
 3	Third line of the document
```

Line numbers are right-aligned and tab-separated from the content.

## Supported Document Types

| Type     | Extensions      | Outline Support |
| -------- | --------------- | --------------- |
| Markdown | `.md`, `.mdx`   | Yes (parsed)    |
| PDF      | `.pdf`          | No              |
| Word     | `.docx`         | Yes (parsed)    |
| Text     | `.txt`          | No              |
| HTML     | `.html`, `.htm` | No              |

For document types without outline support, `has_outline` is always `false` in search results. Use the `read` tool with pagination to browse these documents.
