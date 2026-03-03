# Advanced Search Strategies

Linkly AI uses **BM25 + vector hybrid retrieval**. Understanding how both signals work helps you craft better queries.

## How Search Works

- **BM25 (keyword)**: Tokenizes the query (jieba for CJK, lowercase for Latin) and matches terms against title (3x boost), filename (2x), content (1x), and path (0.5x). Multiple keywords use **OR logic** — all matching documents are returned, with higher scores for documents matching more terms.
- **Vector (semantic)**: The entire query string is encoded into a single embedding vector. Documents are ranked by cosine similarity. Results with vector distance > 0.6 are filtered as noise.
- **Hybrid fusion**: Both result sets are merged using RRF (Reciprocal Rank Fusion) with equal 50/50 weighting.
- **Graceful degradation**: If the embedding model is not ready, search falls back to pure BM25.

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

### Handling large result sets

- Start with `--limit 5` to check relevance quickly.
- If results look promising, increase to `--limit 20` or `--limit 50`.
- Prefer multiple focused searches over a single broad one with high limit.
