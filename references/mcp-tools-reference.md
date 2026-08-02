# Linkly AI MCP Tools Reference

The Linkly AI MCP server exposes nine tools: seven read-only document tools (`list_libraries`, `explore`, `find_paths`, `search`, `outline`, `grep`, `read`), one enumeration tool (`list`), and one write tool (`note_save`). Local documents require the Linkly AI desktop app to be running with its MCP server enabled; linked cloud libraries are served directly by the cloud gateway and stay reachable even when the desktop is offline.

**Server name:** `linkly-ai` (local Desktop MCP) or `linkly-ai-cloud` (the cloud gateway at `mcp.linkly.ai`, which exposes both your local libraries — via the desktop tunnel — and your linked cloud libraries). Both servers advertise the same nine tools.

**Notes are Desktop-only.** `list` and `note_save` operate on plain Markdown files on the user's computer; there is no cloud notes store. Neither tool takes a `library` parameter, and on the cloud gateway both are forwarded to the Desktop over the tunnel — so they need the Desktop online (which over the tunnel also means Pro) and have **no cloud library to fall back on** when it is not. A `library` passed to either is rejected as an unknown field.

## Response Metadata

Every successful tool response carries the wallclock time so callers can compute relative dates ("last 7 days", "after July 1, 2024", "in 2024") without relying on training cutoffs:

- **Markdown** output ends with a footer block: `\n---\n[meta] now=<ISO 8601 UTC>` (e.g. `[meta] now=2026-05-07T14:43:14Z`).
- **JSON** output (`output_format: "json"`) includes a top-level `_meta` object: `{ "now": "<ISO 8601 UTC>" }`.

Errors (`isError: true`) do **not** include this metadata — the error body itself conveys the failure cause. When deriving relative dates, prefer the most recent `now` value you've seen over any other source.

## list_libraries

List all knowledge libraries available to the user. Returns **both** local libraries (cataloged on the user's Desktop) and cloud libraries (linked via Linkly Web), plus a note on the default search scope. Local libraries are addressed as `local://<library-id>`; cloud libraries as `cloud://<owner>/<slug>`. This is how you discover which cloud libraries are linked before scoping a `search` / `explore` / `find_paths` call.

### Parameters

No parameters required.

### Response

Returns a Markdown document with up to three sections — **Local libraries**, **Cloud libraries**, and **Default search scope**. Example:

```
## Local libraries

- **my-research** ("AI Research"): AI and ML papers (42 docs, 3 folders)
- **work-notes**: Daily work logs (128 docs, 1 folders)

## Cloud libraries (1)

> You are signed in as @blueeon. Libraries under cloud://blueeon/ are your own;
> any other username belongs to someone else. Each entry below is tagged
> [yours] (you own it) or [shared] (linked from another user).

- **cloud://blueeon/design-system** (15 docs) [yours]: Public design system docs

## Default search scope

When the `library` parameter is omitted, search and explore cover ALL your
local indexed content. To search a cloud library, specify it explicitly via
`library="cloud://owner/slug"`.
```

A library may carry a display title in addition to its identifier; when set it appears in quotes after the name. On a **local or LAN** connection there are no cloud libraries to reach, so only the local section is returned — see ["Know what your connection reaches"](../SKILL.md#3-know-what-your-connection-reaches) before concluding the user has none.

**When to use:** When the user asks what libraries exist, before scoping a `search` / `explore` / `find_paths` to a specific library, or to discover linked cloud libraries (the only way to learn their `cloud://owner/slug` identifiers).

## explore

Get a bird's-eye overview of all indexed documents or a specific library. Returns document type distribution, directory structure with file counts and median word counts, and top keywords with source attribution.

### Parameters

| Parameter | Type     | Required | Default | Description                                                                                                                                                                                                                           |
| --------- | -------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `library` | `string` | No       | —       | Scope to one library — `local://<id>` (local) or `cloud://<owner>/<slug>` (cloud). A plain string is treated as a local library name (backward-compatible). Omit to explore all **local** content (cloud libraries are not included). |

**Scope:** omit `library` to overview your local content only — cloud libraries are not included by default. Pass `cloud://<owner>/<slug>` to overview a linked cloud library; its README (if present) is shown before the overview. Use `list_libraries` to discover linked cloud libraries.

### Response

Returns a Markdown-formatted overview with four sections:

1. **Summary**: Total document count, outline count, and type distribution
2. **Directory Structure**: Tree view with file counts, median word counts, and last modified dates (UTC)
3. **Top Keywords**: Global keywords (spread across directories) and local keywords (concentrated ≥90% in a single directory, grouped by source)
4. **Recent Activity**: Directories with document changes in the last 7 days, with file counts and timestamps

**When to use:** When the user wants to understand what's in their knowledge base, wants an overview of themes, asks about recent changes, or doesn't yet know what to search for. Use the keywords, directory names, and recent activity from the output to formulate targeted search queries.

## find_paths

Locate real folder paths in the indexed documents by fuzzy keyword matching on the file path. Returns top folder candidates with file counts so the caller can pick a `path_glob` for a follow-up `search` call. Works on both local and cloud libraries; candidates from a cloud library carry the source library reference (`cloud://<owner>/<slug>`) — pass it as `library` on the follow-up `search` so the glob is scoped to the right backend.

### Parameters

| Parameter       | Type       | Required | Default      | Description                                                                                                                                                                                                                                                                                                                               |
| --------------- | ---------- | -------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `patterns`      | `string[]` | Yes      | —            | Keywords to substring-match against file paths. Multiple keywords are OR-matched (each one wrapped as SQL `LIKE %keyword%`); pass cross-language or spelling variants in a single call (e.g. `["WeChat", "微信", "xinWeChat", "wxid"]`). Case-insensitive for ASCII; CJK matches literally. **Limits:** max 10 patterns, each ≤ 64 bytes. |
| `library`       | `string`   | No       | —            | Scope to one library — `local://<id>` (local) or `cloud://<owner>/<slug>` (cloud). A plain string is treated as a local library name (backward-compatible). Omit = all **local** content (cloud not included). Use `list_libraries` to see available libraries.                                                                           |
| `limit`         | `integer`  | No       | 10           | Maximum folder candidates to return (max 50).                                                                                                                                                                                                                                                                                             |
| `output_format` | `string`   | No       | `"markdown"` | `"markdown"` (default) or `"json"`.                                                                                                                                                                                                                                                                                                       |

### Response Fields (JSON mode)

| Field         | Type      | Description                                                                                                                                                                                                  |
| ------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `total_files` | `number`  | Total files matched and bucketed across **all** folder candidates — including any tail dropped by `limit`. When `truncated` is `true` this can exceed the sum of `file_count` across returned `directories`. |
| `truncated`   | `boolean` | True when `limit` capped the directory list (more candidates exist than were returned).                                                                                                                      |
| `directories` | `array`   | Folder candidates, ordered by `file_count` descending (ties broken by path ascending).                                                                                                                       |

Each directory entry:

| Field        | Type     | Description                                                                                                                                                                                                                                                                                                                                              |
| ------------ | -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `library`    | `string` | Present for **cloud** results: the source library as `cloud://<owner>/<slug>`. Pass it to a follow-up `search` as `library`. Omitted for local results.                                                                                                                                                                                                  |
| `path`       | `string` | Folder path (full absolute path).                                                                                                                                                                                                                                                                                                                        |
| `path_glob`  | `string` | `path` quoted into a ready-to-use `path_glob` pattern: any glob metacharacters (`* ? [`) in the folder name are escaped so it matches that folder **literally** (not as a glob that would catch sibling dirs). Equals `path` when the name has no metacharacters. Prefer copying this verbatim into a follow-up `search` when you want the whole folder. |
| `file_count` | `number` | Number of indexed files inside this folder whose path matched any of the `patterns`.                                                                                                                                                                                                                                                                     |

### Aggregation behaviour (important)

- This is a "find folders" tool. Files whose `patterns` only match the **filename segment** (no matching directory segment) are **dropped** silently — they are not returned as their own folder. If a query yields zero directories despite matching files, fall back to `search` directly.
- Each match is bucketed by the **shallowest** pattern occurrence in its path, truncated at the next `/`. So `local:///Users/me/Library/.../com.tencent.xinWeChat/Data/...` matched by `WeChat` aggregates under `.../com.tencent.xinWeChat`, regardless of how deep the matching file lives.

**When to use:** The user names a container by a fuzzy or cross-language word ("in my WeChat files", "in my Notion notes", "在我的微信里") and you don't yet know the actual on-disk path. Pass several variants in `patterns` in a single call, then pipe a distinctive segment of any returned path back to `search` as `path_glob` (substring-matched, so `*xinWeChat*` works as well as a full prefix). To scope to a whole folder, copy that entry's `path_glob` field verbatim — it is already glob-quoted, so a folder name with `* ? [` still matches literally.

**When NOT to use:**

- Pure content/topic queries ("find resumes", "find AI papers") — call `search` directly; its hybrid retrieval already covers title/filename/content/path.
- Filtering by file type ("all PDFs") — call `search` with `doc_types=["pdf"]` directly. `path_glob` is path-pattern matching and would miss documents with absent or mismatched extensions.
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
      "path": "/Users/me/Library/Containers/com.tencent.xinWeChat",
      "path_glob": "/Users/me/Library/Containers/com.tencent.xinWeChat",
      "file_count": 940
    }
  ],
  "_meta": { "now": "2026-05-07T14:43:14Z" }
}
```

The follow-up `search` call would then use `path_glob: "*xinWeChat*"` to scope the actual content query.

## search

Search indexed documents by keywords or phrases — across all your local content, or scoped to a specific local or cloud library.

### Parameters

| Parameter         | Type       | Required | Default     | Description                                                                                                                                                                                                                                                                                                                                                         |
| ----------------- | ---------- | -------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `query`           | `string`   | Yes      | —           | Search keywords or phrases                                                                                                                                                                                                                                                                                                                                          |
| `limit`           | `integer`  | No       | 20          | Maximum results to return (1–50)                                                                                                                                                                                                                                                                                                                                    |
| `doc_types`       | `string[]` | No       | —           | Filter by document type name — one of `pdf`, `docx`, `pptx`, `epub`, `md`, `txt`, `html`, `image`, `audio`, `video` (e.g. `["pdf", "md"]`). Filter by type name, not by extension.                                                                                                                                                                                  |
| `library`         | `string`   | No       | —           | Scope search to one library — `local://<id>` (local) or `cloud://<owner>/<slug>` (cloud; must be the two-segment `owner/slug` form, a single segment is rejected). A plain string is treated as a local library name (backward-compatible). Omit = all **local** content (cloud libraries are not included by default). Use `list_libraries` to discover libraries. |
| `path_glob`       | `string`   | No       | —           | Glob **substring-matched** against the file path — may appear anywhere, no leading/trailing `*` needed. `*` matches any chars including `/`, `?` one char. Always case-sensitive. A full directory path (`/Users/me/notes/`) scopes to that dir. When the actual path is unknown, run `find_paths` first.                                                           |
| `modified_after`  | `string`   | No       | —           | Inclusive lower bound on modification time. Accepts ISO 8601 UTC: a bare date `"2024-01-01"` (expanded to `00:00:00Z`) or a full RFC 3339 datetime `"2024-01-01T00:00:00Z"`.                                                                                                                                                                                        |
| `modified_before` | `string`   | No       | —           | Inclusive upper bound on modification time. Same format as `modified_after`.                                                                                                                                                                                                                                                                                        |
| `time_sort`       | `string`   | No       | `"default"` | One of `"default"` / `"newest"` / `"oldest"`. `"default"` keeps hybrid relevance ordering; `"newest"` / `"oldest"` reorder by `modified_at` after dedup, useful for "latest / earliest".                                                                                                                                                                            |
| `scope`           | `string`   | No       | `"folder"`  | `"folder"` (default) searches all indexed content with the usual `library` / `path_glob` semantics. `"notes"` restricts results to the user's local Markdown card notes and **ignores `library` and `path_glob`**. Unknown values are rejected; `null` or omitted yields the default.                                                                               |
| `tags`            | `string[]` | No       | —           | Return only documents carrying **all** the given note tags (AND semantics). Tags are normalized: a leading `#` is stripped and ASCII is lowercased. For OR, issue one call per tag and union the results. Most useful with `scope="notes"`.                                                                                                                         |
| `output_format`   | `string`   | No       | —           | Set to `"json"` for structured JSON output                                                                                                                                                                                                                                                                                                                          |

### Response Fields (JSON mode)

| Field     | Type     | Description                        |
| --------- | -------- | ---------------------------------- |
| `query`   | `string` | The original search query          |
| `total`   | `number` | Total number of matching documents |
| `results` | `array`  | List of search result items        |

Each result item:

| Field         | Type       | Description                                                                                                                                                                                                                                                                                         |
| ------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `doc_id`      | `string`   | Opaque document identifier — pass through verbatim to `outline` / `grep` / `read`; never fabricate or reshape it. Local documents take the form `local://<integer>`, cloud documents the form `cloud://<owner>/<slug>/<root-hash>/<path>`. Bare integer IDs from older desktops are still accepted. |
| `title`       | `string`   | Document title                                                                                                                                                                                                                                                                                      |
| `path`        | `string`   | Full absolute file path                                                                                                                                                                                                                                                                             |
| `relevance`   | `number`   | Hybrid (BM25 + vector) relevance score, rendered to 2 decimals; higher = more relevant. Not normalized to a fixed range — use it for ordering, not as a 0–1 threshold.                                                                                                                              |
| `word_count`  | `number?`  | Total word count                                                                                                                                                                                                                                                                                    |
| `total_lines` | `number?`  | Total line count                                                                                                                                                                                                                                                                                    |
| `has_outline` | `boolean`  | Whether a structural outline is available                                                                                                                                                                                                                                                           |
| `modified_at` | `number`   | Last modified timestamp (Unix ms)                                                                                                                                                                                                                                                                   |
| `keywords`    | `string[]` | Extracted keywords                                                                                                                                                                                                                                                                                  |
| `snippet`     | `string`   | Text snippet with matching context                                                                                                                                                                                                                                                                  |

## outline

Get metadata and structural outlines of documents by their IDs. Works the same on local and cloud documents; just keep each call to a single backend — see the `doc_ids` constraint below.

### Parameters

| Parameter       | Type       | Required | Default | Description                                                                                                                                                                                                                 |
| --------------- | ---------- | -------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `doc_ids`       | `string[]` | Yes      | —       | List of document IDs from search (each verbatim — `local://<integer>` or `cloud://<owner>/<slug>/<root-hash>/<path>`). Do **not** mix `local://` and `cloud://` IDs in one call — split them into separate `outline` calls. |
| `expand`        | `string[]` | No       | —       | Node IDs to expand (e.g. `["2", "3.1"]`). Only specified nodes are fully expanded; others collapsed.                                                                                                                        |
| `output_format` | `string`   | No       | —       | Set to `"json"` for structured JSON output                                                                                                                                                                                  |

### Response Fields (JSON mode)

| Field       | Type    | Description                      |
| ----------- | ------- | -------------------------------- |
| `documents` | `array` | List of document outline objects |

Each document object:

| Field               | Type      | Description                                                      |
| ------------------- | --------- | ---------------------------------------------------------------- |
| `doc_id`            | `string`  | Document identifier                                              |
| `title`             | `string`  | Document title                                                   |
| `path`              | `string`  | Full absolute file path                                          |
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

Locate specific lines within a single document by regex pattern. Best for documents with `has_outline=false` where outline is unavailable. Use after `search` to pinpoint exact positions of names, dates, terms, identifiers, or any pattern — then use `read` with offset to see full context. Works on all document types, including the text derived from images and scanned PDFs (OCR) and from audio and video (transcripts). The `doc_id` parameter takes a single ID — to scan multiple documents, call grep once per `doc_id`.

### Parameters

| Parameter          | Type      | Required | Default     | Description                                                                                                                                                                                                                                    |
| ------------------ | --------- | -------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pattern`          | `string`  | Yes      | —           | Regular expression pattern to search for                                                                                                                                                                                                       |
| `doc_id`           | `string`  | Yes      | —           | Document ID to search within — pass verbatim from search (`local://<integer>` or `cloud://<owner>/<slug>/<root-hash>/<path>`; bare integers still accepted)                                                                                    |
| `context`          | `integer` | No       | 3           | Lines of context before and after each match (-C)                                                                                                                                                                                              |
| `before`           | `integer` | No       | —           | Lines of context before each match (-B), overrides `context`                                                                                                                                                                                   |
| `after`            | `integer` | No       | —           | Lines of context after each match (-A), overrides `context`                                                                                                                                                                                    |
| `case_insensitive` | `boolean` | No       | false       | Case-insensitive matching                                                                                                                                                                                                                      |
| `output_mode`      | `string`  | No       | `"content"` | `"content"` (matching lines with context) or `"count"` (match count only, preview totals first)                                                                                                                                                |
| `limit`            | `integer` | No       | 20          | Maximum matching lines to return (max 100)                                                                                                                                                                                                     |
| `offset`           | `integer` | No       | 0           | Number of matches to skip for pagination                                                                                                                                                                                                       |
| `fuzzy_whitespace` | `boolean` | No       | —           | Fuzzy whitespace matching for PDF noise tolerance. null/omit = auto (PDF on, others off), `true` = force on, `false` = force off. NOTE: cloud documents (`cloud://` doc_id) do not yet support `true` — omit or set `false` for cloud targets. |
| `output_format`    | `string`  | No       | —           | Set to `"json"` for structured JSON output                                                                                                                                                                                                     |

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
| `path`        | `string` | Full absolute file path                               |
| `match_count` | `number` | Number of matches in this document                    |
| `matches`     | `array`  | List of match objects (only in `content` output_mode) |

Each entry in `matches` — match lines and their surrounding context lines are interleaved in line order; use `is_match` to tell them apart:

| Field         | Type      | Description                                                                        |
| ------------- | --------- | ---------------------------------------------------------------------------------- |
| `line_number` | `number`  | 1-based line number                                                                |
| `content`     | `string`  | The line text                                                                      |
| `is_match`    | `boolean` | `true` for a line that matched the pattern, `false` for a surrounding context line |

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

| Parameter       | Type      | Required | Default      | Description                                                                                                                                                                                                                                                                                                                                                                                  |
| --------------- | --------- | -------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `doc_id`        | `string`  | Yes      | —            | Document ID — pass verbatim from search (`local://<integer>` or `cloud://<owner>/<slug>/<root-hash>/<path>`; bare integers still accepted)                                                                                                                                                                                                                                                   |
| `offset`        | `integer` | No       | 1            | Starting line number (1-based)                                                                                                                                                                                                                                                                                                                                                               |
| `limit`         | `integer` | No       | 200          | Number of lines to read (max 500)                                                                                                                                                                                                                                                                                                                                                            |
| `image_text`    | `string`  | No       | `"abstract"` | Detail level for the referenced-images mapping appended to the result (markdown image refs inside the shown line range are resolved to indexed image documents). `"none"` = mapping only (line, file, doc_id); `"abstract"` = plus a one-line excerpt and word count per image; `"full"` = plus inline OCR text (2000 chars per image, 20000 total; over-budget images degrade to abstract). |
| `output_format` | `string`  | No       | —            | Set to `"json"` for structured JSON output                                                                                                                                                                                                                                                                                                                                                   |

### Response Fields (JSON mode)

| Field               | Type      | Description                                                                                                                                                                                                                         |
| ------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `doc_id`            | `string`  | Document identifier                                                                                                                                                                                                                 |
| `title`             | `string`  | Document title                                                                                                                                                                                                                      |
| `path`              | `string`  | Full absolute file path                                                                                                                                                                                                             |
| `word_count`        | `number?` | Total word count                                                                                                                                                                                                                    |
| `author`            | `string?` | Document author or summary                                                                                                                                                                                                          |
| `content`           | `string`  | Content with line numbers (prefixed)                                                                                                                                                                                                |
| `total_lines`       | `number`  | Total lines in the document (always present, computed from actual file content)                                                                                                                                                     |
| `shown_from`        | `number`  | First line shown (1-based)                                                                                                                                                                                                          |
| `shown_to`          | `number`  | Last line shown (1-based, inclusive)                                                                                                                                                                                                |
| `ocr_pending`       | `boolean` | The body shown is incomplete — a background job (OCR or audio/video transcription) still owes text, or the extracted text was truncated. The wire name says OCR for backward compatibility, but it covers any partial-content case. |
| `partial_notice`    | `string?` | Human-readable explanation accompanying `ocr_pending`.                                                                                                                                                                              |
| `referenced_images` | `array`   | Markdown image references found in the shown range, resolved to indexed image documents. Omitted when empty. Detail per entry depends on `image_text`.                                                                              |

### Content Format

The `content` field contains line-numbered text:

```
 1	First line of the document
 2	Second line of the document
 3	Third line of the document
```

Line numbers are right-aligned and tab-separated from the content.

## list

Enumerate the contents of a container. Unlike `search`, it does **no** full-text matching — it lists and paginates.

### Parameters

| Parameter       | Type       | Required | Default          | Description                                                                                                                                                                                                                                                                          |
| --------------- | ---------- | -------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `scope`         | `string`   | **Yes**  | —                | Container to list. Currently only `"notes"` (the user's local Markdown card notes) is accepted; unknown values are rejected. Note: `search.scope` has a value also spelled `"folder"` meaning "all indexed content" — a different concept that shares no values with this parameter. |
| `tags`          | `string[]` | No       | —                | Return only items carrying **all** the given tags (AND semantics), normalized like `search.tags`. For keyword search over notes use `search` with `scope="notes"` instead.                                                                                                           |
| `limit`         | `integer`  | No       | 50               | Maximum items (max 200; drops to 50 while `snippet` is enabled).                                                                                                                                                                                                                     |
| `offset`        | `integer`  | No       | 0                | Pagination offset counted in sort order. Use `has_more` to decide whether to fetch the next page.                                                                                                                                                                                    |
| `snippet`       | `boolean`  | No       | `true` (notes)   | Include a per-item snippet (first ~200 chars of the body, YAML stripped). Set `false` to page with limits above 50 — the field stays present but null.                                                                                                                               |
| `sort`          | `string`   | No       | `"recent"`       | `"recent"` (creation time, newest first) / `"oldest"` / `"name"` (basename, UTF-8 code point order). Page order follows sort direction, and every sort ends with a deterministic tiebreaker so offset pagination is stable.                                                          |
| `output_format` | `string`   | No       | `"json"` (notes) | `scope="notes"` defaults to JSON because each item is a CAS handle (`note_id` + `version`) for `note_save`. `"markdown"` is a human-readable opt-in and still carries both inline.                                                                                                   |

### Response Fields (JSON mode)

| Field                 | Type       | Description                                                                                               |
| --------------------- | ---------- | --------------------------------------------------------------------------------------------------------- |
| `scope`               | `string`   | Echo of the requested scope                                                                               |
| `total`               | `number`   | Total items matching the filter                                                                           |
| `items`               | `array`    | This page of items                                                                                        |
| `offset` / `limit`    | `number`   | Echo of the pagination window                                                                             |
| `has_more`            | `boolean`  | Whether more items exist past this page                                                                   |
| `available_tags`      | `string[]` | Tags in use across **all** notes — computed before filtering, top 50 by usage, same snapshot as this page |
| `available_tags_hint` | `string`   | Fixed guidance on reusing those tags                                                                      |

Each item carries: `note_id`, `version` (sha256 — this is the `base_version` you need to edit it), `title`, `doc_id`, `path`, `created_at`, `modified_at`, `tags`, `snippet`.

**When to use:** the user wants to browse or enumerate notes ("what notes do I have?", "show my notes tagged work"). To find notes by content, use `search` with `scope="notes"`.

## note_save

Create or rewrite one of the user's local Markdown notes. **This is the only write tool** — every other tool in this reference is read-only.

The write always lands on the user's Desktop, including when you reach it through the cloud gateway (`--remote`): the tunnel forwards to that machine, it does not write to the cloud. There is no delete tool — deletion is user-only in the app UI.

### Parameters

| Parameter      | Type       | Required      | Description                                                                                                                                                                                                             |
| -------------- | ---------- | ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mode`         | `string`   | Yes           | `"create"` writes a new note; `"edit"` rewrites an existing one. Edit **requires `note_id`, `base_version` and `tags` together** — missing any of them returns `NOTE_INVALID_INPUT` with a fix example.                 |
| `content`      | `string`   | Yes           | Markdown body **without** YAML front matter. See the whitelist below.                                                                                                                                                   |
| `note_id`      | `string`   | edit only     | Note UUID. Required for edit. On create it is reserved for future cloud sync, and a create carrying an already-existing id is rejected as `NOTE_DUPLICATE_ID`.                                                          |
| `base_version` | `string`   | edit only     | The note's current version hash (sha256 of the raw file). Read it from `list` or from a previous `note_save` response. A stale value returns `NOTE_VERSION_CONFLICT` with the actual version — re-read before retrying. |
| `tags`         | `string[]` | edit required | **Full replacement set** on edit: pass back exactly what you read to leave tags unchanged; omitting a previously present tag removes it. Optional on create.                                                            |

### Content whitelist

**Allowed:** paragraphs, line breaks, bold, strikethrough, ordered and unordered lists, plain text (bare URLs are fine as plain text).

**Rejected** with `NOTE_INVALID_INPUT` (the error lists the offending constructs): headings, italics, blockquotes, inline code, code blocks, links, images, raw HTML, thematic breaks, tables, task lists, footnotes. An edit may keep constructs the note already contains, but must not introduce new forbidden kinds.

Inline `#tags` in the body stay plain text — they are **not** extracted into the tag set. Use the `tags` parameter.

### Tag policy

**Do not add tags on your own initiative.** Pass only tags the user explicitly asked for; never invent them. The `available_tags` list from `list` exists for filtering, not for decorating new notes.

### Response

`note_id`, `created_at`, `updated_at`, `updated_by`, `version`, and the note's path. On a version conflict the error body carries `note_id`, `expected_version`, `actual_version` and `actual_updated_at`.

### Error codes

`NOTE_INVALID_INPUT`, `NOTE_NOT_FOUND`, `NOTE_DUPLICATE_ID`, `NOTE_VERSION_CONFLICT`, `NOTE_OUTSIDE_ROOT`, `NOTE_PARSE_ERROR`, `NOTE_IO_ERROR`.

## Supported Document Types

| Type       | `doc_types` value | Extensions                                      | Outline Support             |
| ---------- | ----------------- | ----------------------------------------------- | --------------------------- |
| Markdown   | `md`              | `.md`, `.mdx`                                   | Yes (parsed)                |
| PDF        | `pdf`             | `.pdf`                                          | No                          |
| Word       | `docx`            | `.docx`                                         | Yes (parsed)                |
| PowerPoint | `pptx`            | `.pptx`                                         | Yes (slide outlines)        |
| Text       | `txt`             | `.txt`                                          | No                          |
| HTML       | `html`            | `.html`                                         | No                          |
| EPUB       | `epub`            | `.epub`                                         | Yes (from ToC)              |
| Image      | `image`           | `.png`, `.jpg`, `.jpeg`, `.bmp`, `.webp`        | No (OCR text)               |
| Audio      | `audio`           | `.mp3`, `.wav`, `.m4a`, `.flac`, `.aac`, `.ogg` | Yes (chapters / time spans) |
| Video      | `video`           | `.mp4`, `.mov`, `.mkv`, `.webm`                 | Yes (chapters / time spans) |

The middle column is what you pass to `doc_types` / `--type` — filter by type name, not by extension.

Notes on the derived types:

- **Audio and video** are indexed from their **transcript**, produced by on-device speech recognition. Searching them matches transcript text; `outline` returns chapters and time spans (`HH:MM:SS`) rather than headings. Transcription is opt-in per media kind in Desktop Settings → Indexing — if the user's recordings return nothing, that toggle is the first thing to check.
- **Images and scanned PDFs** are indexed from their **OCR text**. Images referenced from within another document also surface through `read`'s `image_text` parameter.
- **Subtitle sidecars** (`.srt`, `.vtt`) sitting next to a media file are paired with that file rather than indexed as separate documents.

For document types without outline support, `has_outline` is always `false` in search results. Use the `read` tool with pagination to browse these documents.
