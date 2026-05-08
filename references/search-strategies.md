# Advanced Search Strategies

Linkly AI uses **BM25 + vector hybrid retrieval**. Understanding how both signals work helps you craft better queries.

## How Search Works

- **BM25 (keyword)**: Tokenizes the query (jieba for CJK, lowercase for Latin) and matches terms against title (3x boost), filename (2x), content (1x), and path (0.5x). Multiple keywords use **OR logic** — all matching documents are returned, with higher scores for documents matching more terms.
- **Vector (semantic)**: The entire query string is encoded into a single embedding vector. Documents are ranked by cosine similarity. Results with vector distance > 0.6 are filtered as noise.
- **Hybrid fusion**: Both result sets are merged using RRF (Reciprocal Rank Fusion) with equal 50/50 weighting.
- **Graceful degradation**: If the embedding model is not ready, search falls back to pure BM25.
- **Pre-search path discovery**: when the user names a container by a fuzzy / cross-language word ("in my WeChat", "在 Notion 笔记里"), `find_paths` aggregates indexed paths by keyword and returns top folder candidates — pipe one as `path_glob` to scope the subsequent `search`. See ["Locate the container first"](#locate-the-container-first-with-find_paths) below.
- **Time-aware filtering and sorting**: `search` accepts `modified_after` / `modified_before` (ISO 8601 UTC) for explicit windows and `time_sort` (`newest` / `oldest`) for relative ordering. See ["Constraining by time"](#constraining-by-time) below.

## Query Crafting Strategies

### Precise keywords — leverage BM25

Best for finding specific documents, names, or technical terms:

```bash
linkly search "quarterly financial report 2024" --limit 10
linkly search "API authentication design" --limit 5
```

### Natural language descriptions — leverage vector search

Best for topical or conceptual searches where exact terms are unknown:

```bash
linkly search "notes about improving team collaboration and communication" --limit 10
linkly search "how to set up a local development environment for the backend" --limit 10
```

### Synonyms and multilingual terms — leverage OR logic

Since BM25 uses OR logic, listing synonyms or translations in a single query broadens recall while still ranking multi-match documents higher:

```bash
linkly search "meeting minutes notes recap summary" --limit 10
linkly search "authentication auth login sign-in" --limit 10
```

## Multi-round Search

For complex information-gathering tasks, a single query is rarely enough. Use iterative rounds:

1. **Broad sweep**: Start with the core topic, `--limit 20`, to survey what exists.
2. **Branch from results**: Read high-relevance snippets. Note new keywords, linked topics, or related document titles discovered in the results.
3. **Targeted follow-up**: Search with newly discovered keywords or rephrase the query using natural language for semantic coverage.
4. **Parallel queries**: When possible, run multiple independent searches in parallel (different keyword angles) and merge the doc_id sets.

## Complex Scenario Patterns

### Cross-document information aggregation

When assembling information scattered across many documents:

1. Search with multiple query variants (keyword-style + semantic-style) to maximize recall.
2. Use `--json` output for search results — easier to scan and extract doc_ids programmatically.
3. Use snippets to triage — only read documents whose snippets confirm relevance.
4. Watch for duplicate documents: the index may contain copies of the same content at different paths. Compare titles and snippets to avoid redundant reads.
5. Read short documents directly; use outline first for long ones.

### Finding a document you know exists

Try in this order:

1. **Exact title or phrase** — most precise, relies on BM25.
2. **Key content fragment** — search for a memorable sentence or data point.
3. **Semantic description** — describe the document's topic in natural language.
4. **Remove type filters** — drop `--type` to search all formats.
5. **In a specific container** — when the user mentions a folder/app ("in my WeChat", "in my Notion notes"), run `linkly find-paths --patterns ...` first to discover the real path, then `linkly search ... --path-glob "*<segment>*"`. See ["Locate the container first"](#locate-the-container-first-with-find_paths).

### Using grep for targeted pattern matching

After finding documents with `search`, use `grep` to locate specific content without reading entire files:

1. **Known terms or names**: `linkly grep "John Smith" <ID>` — find exact references to a person, product, or concept.
2. **Codes or identifiers**: `linkly grep "INV-\d{4}" <DOC_ID> -i` — search for invoice numbers, error codes, etc. `doc_id` takes a single ID; to scan multiple documents loop the call: `for id in <ID1> <ID2>; do linkly grep "INV-\d{4}" "$id" -i; done`.
3. **Count occurrences**: `linkly grep "TODO|FIXME" <ID> --mode count` — quickly tally matches.
4. **Context for understanding**: `linkly grep "pattern" <ID> -C 3` — see surrounding lines.
5. **Combine with read**: After finding a match at line N, use `linkly read <ID> --offset N-10 --limit 30` to read the full surrounding context.

**When to use grep vs outline:**

- Use **outline** when you need to understand the document's overall structure (sections, headings, hierarchy).
- Use **grep** when you know what specific text to look for (names, dates, terms, identifiers, keywords).
- They are complementary: outline tells you _where_ things are structurally, grep tells you _where_ things are textually.

### From overview to targeted search

When the user's request is broad or exploratory ("what do I have about AI?", "summarize my knowledge base"), start with `explore` to understand the landscape, then drill down with `search`:

```bash
linkly explore                                           # see themes, dirs, keywords, recent activity
linkly search "machine learning" --limit 10              # follow up on a keyword
linkly search "report" --path-glob "*2024*" --limit 5    # follow up on a directory
linkly search "design" --path-glob "*linkly-ai-v3*"      # follow up on a recently active directory
```

The explore output includes a **Recent Activity** section showing directories with changes in the last 7 days. Use this to answer questions like "what have I been working on?" or to focus searches on actively maintained content.

This two-step pattern avoids blind searches and produces more relevant results.

### Locate the container first with `find_paths`

When the user describes a target by a fuzzy or cross-language container name ("find shopping receipts in my WeChat", "搜一下我 Notion 笔记里的产品方案", "stuff in my work backup folder") and you don't yet know the on-disk path, jumping straight to `search` with a guessed `path_glob` is fragile — the actual folder is usually named after a real app/SDK identifier (`xinWeChat`, `notion`, `wxid_*`) that the user wouldn't say out loud.

The robust pattern is two-step:

1. **Discover the path with `find_paths`** — pass several variants in a single call (translation pairs, casing, real-app names if known) so they're OR-matched in one round-trip.
2. **Scope the actual content `search`** — take a distinctive segment of any returned folder path (often the leaf or a unique sub-segment) and pass it as `--path-glob "*<segment>*"`. The GLOB is substring-matched, so a partial segment works as well as a full prefix.

```bash
# 1. discover real path
linkly find-paths --patterns WeChat,微信,wxid --limit 5
# → top candidate ends with /com.tencent.xinWeChat/Data/.../xwechat_files (940 files)

# 2. scope the content search
linkly search "购物订单 receipt" --path-glob "*xinWeChat*" --limit 10
```

**Aggregation caveat:** `find_paths` is a "find folders" tool. Files whose patterns only match the **filename** (not any directory segment) are dropped silently. If `find_paths` returns zero folders despite obvious filename matches, fall back to `linkly search` directly — it can still match against filenames via the `filename` BM25 field.

**Skip this step when:**

- The query is purely about content/topic ("find resumes", "find AI papers about transformers") — call `search` directly.
- The user is filtering only by file type ("all my PDFs") — use `linkly search "..." --path-glob "*.pdf"` directly.

### Constraining by time

`search` supports two complementary time mechanisms. They can be combined.

**Window (explicit range)** — use `--modified-after` / `--modified-before` for queries with an explicit time scope. Both accept ISO 8601 UTC: a bare date `2024-01-01` (expanded to `00:00:00Z`) or a full RFC 3339 timestamp `2024-01-01T00:00:00Z`. Both bounds are inclusive.

```bash
linkly search "quarterly report"  --modified-after 2024-07-01 --modified-before 2024-09-30  # Q3 2024
linkly search "weekly retro"      --modified-after 2024-01-01 --modified-before 2024-12-31  # all of 2024
linkly search "incident postmortem" --modified-before 2023-01-01                            # before 2023
```

**Sort (relative ordering)** — use `--time-sort newest` or `--time-sort oldest` for queries that ask for "the most recent / earliest" without a fixed window. The candidate set is selected by the same hybrid retrieval, then reordered by `modified_at` after dedup.

```bash
linkly search "team standup notes" --time-sort newest --limit 10
linkly search "first version of the design doc" --time-sort oldest --limit 5
```

**Combining both** — useful for "the most relevant document from a specific window" or "earliest entry in 2024":

```bash
linkly search "release notes" --modified-after 2024-01-01 --modified-before 2024-12-31 --time-sort oldest
```

**Computing relative dates** — when the user phrases the time as "last month", "this year", "in the last 30 days", read the `now` value from any prior tool response (Markdown footer `[meta] now=…` or JSON `_meta.now`) and do the date math from there. Don't guess the current date from the model's training cutoff.

### Scoped search with libraries

Libraries let users curate folders into named collections. Use `--library` to restrict search scope:

```bash
linkly list-libraries                                    # see what's available
linkly search "transformer architecture" --library my-research --limit 10
```

**When to use:**

- The user explicitly names a library: "search in my-research for..."
- The user has been working within a library context in the current session

**When NOT to use:**

- General searches like "find my PDF about X" → global search is better
- You're unsure which library → search globally, or ask the user

Libraries are optional. **Default to global search** unless the user specifies otherwise.

### Filtering by file path

Use `--path-glob` to filter results by file path patterns (SQLite GLOB syntax):

```bash
linkly search "meeting notes" --path-glob "*2024*"       # files with "2024" in path
linkly search "report" --path-glob "*.pdf"               # only PDFs
linkly search "design" --path-glob "*projects/frontend*" # specific directory
```

`--path-glob` and `--library` can be combined for precise scoping.

### Handling large result sets

- Start with `--limit 5` to check relevance quickly.
- If results look promising, increase to `--limit 20` or `--limit 50`.
- Prefer multiple focused searches over a single broad one with high limit.
