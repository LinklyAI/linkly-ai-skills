# Linkly AI MCP Tools Reference

The Linkly AI MCP server exposes three tools for document operations. These tools are available when the Linkly AI desktop app is running with MCP server enabled.

**Server name:** `linkly-ai`

## search

Search indexed local documents by keywords or phrases.

### Parameters

| Parameter       | Type       | Required | Default | Description                                     |
| --------------- | ---------- | -------- | ------- | ----------------------------------------------- |
| `query`         | `string`   | Yes      | —       | Search keywords or phrases                      |
| `limit`         | `integer`  | No       | 20      | Maximum results to return (1–50)                |
| `doc_types`     | `string[]` | No       | —       | Filter by document types (e.g. `["pdf", "md"]`) |
| `output_format` | `string`   | No       | —       | Set to `"json"` for structured JSON output      |

### Response Fields (JSON mode)

| Field     | Type     | Description                        |
| --------- | -------- | ---------------------------------- |
| `query`   | `string` | The original search query          |
| `total`   | `number` | Total number of matching documents |
| `results` | `array`  | List of search result items        |

Each result item:

| Field         | Type       | Description                                      |
| ------------- | ---------- | ------------------------------------------------ |
| `doc_id`      | `string`   | Unique document identifier (use in outline/read) |
| `title`       | `string`   | Document title                                   |
| `path`        | `string`   | Shortened file path                              |
| `relevance`   | `number`   | Relevance score (0–1)                            |
| `word_count`  | `number?`  | Total word count                                 |
| `total_lines` | `number?`  | Total line count                                 |
| `has_outline` | `boolean`  | Whether a structural outline is available        |
| `modified_at` | `number`   | Last modified timestamp (Unix ms)                |
| `keywords`    | `string[]` | Extracted keywords                               |
| `snippet`     | `string`   | Text snippet with matching context               |

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

| Field               | Type      | Description                                             |
| ------------------- | --------- | ------------------------------------------------------- |
| `doc_id`            | `string`  | Document identifier                                     |
| `title`             | `string`  | Document title                                          |
| `path`              | `string`  | Shortened file path                                     |
| `word_count`        | `number?` | Total word count                                        |
| `total_lines`       | `number?` | Total line count                                        |
| `has_outline`       | `boolean` | Whether a parsed outline exists                         |
| `outline_text`      | `string`  | Pre-rendered outline tree with node IDs and line ranges |
| `abstract_text`     | `string?` | Document abstract or first paragraph                    |
| `is_brief`          | `boolean` | True if document is short (<500 words)                  |
| `no_outline_reason` | `string?` | Reason if outline is unavailable                        |

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

Use node IDs (e.g. `"1.2"`, `"2"`) with the `expand` parameter to drill into specific sections. Use line ranges (e.g. L30-50) with the `read` tool's `offset` and `limit` parameters to read that section.

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

| Field         | Type      | Description                          |
| ------------- | --------- | ------------------------------------ |
| `doc_id`      | `string`  | Document identifier                  |
| `title`       | `string`  | Document title                       |
| `path`        | `string`  | Shortened file path                  |
| `word_count`  | `number?` | Total word count                     |
| `author`      | `string?` | Document author or summary           |
| `content`     | `string`  | Content with line numbers (prefixed) |
| `total_lines` | `number`  | Total lines in the document          |
| `shown_from`  | `number`  | First line shown (1-based)           |
| `shown_to`    | `number`  | Last line shown (1-based, inclusive) |

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

Documents without parsed outlines can still be read with line-based pagination.
