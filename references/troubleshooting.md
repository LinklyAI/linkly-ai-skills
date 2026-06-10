# Troubleshooting Linkly AI

When Linkly AI is not working as expected, follow these steps based on your connection mode.

## Step 0: Identify Your Mode

| Mode             | How you're connected                                                                                                                                    | Typical setup                                      |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| **CLI (Local)**  | Running `linkly` commands in a terminal on the same machine as the desktop app                                                                          | Default — no extra flags needed                    |
| **CLI (LAN)**    | Running `linkly` with `--endpoint` and `--token` flags                                                                                                  | Connecting from another device on the same network |
| **CLI (Remote)** | Running `linkly` with `--remote` flag                                                                                                                   | Connecting via internet tunnel                     |
| **MCP**          | AI tool (Claude, Cursor, etc.) connects to the desktop's MCP server, or to the `mcp.linkly.ai` cloud gateway (which also serves linked cloud libraries) | Configured in the AI tool's MCP settings           |

## CLI Mode Troubleshooting

### First: Run `linkly doctor`

This is the single most useful diagnostic command. It checks every link in the connection chain and gives specific advice for each failure.

```bash
# Local mode (default)
linkly doctor

# LAN mode
linkly doctor --endpoint http://192.168.1.100:60606/mcp --token <token>

# Remote mode
linkly doctor --remote
```

### Common Issues and Solutions

#### "Port file not found" / "Connection refused"

- **Cause:** The Linkly AI desktop app is not running, or the MCP server is disabled.
- **Fix:**
  1. Launch the Linkly AI desktop app.
  2. Open Settings → MCP → Enable the MCP server.
  3. Wait a few seconds, then retry.

#### "Authentication failed" (LAN/Remote)

- **Cause:** Invalid or expired token/API key.
- **Fix (LAN):** Check the access token in the desktop app: Settings → MCP → LAN Access → Access Token. Copy and use with `--token`.
- **Fix (Remote):** Re-save your API key: `linkly auth set-key <your-api-key>`. Get your key from [linkly.ai](https://linkly.ai).

#### "Tunnel not connected" (Remote)

- **Cause:** The desktop app's remote tunnel is not connected.
- **Fix:** Open Settings → MCP → Remote Access → Connect Tunnel. Ensure you have an API key configured.
- **Note:** This only blocks access to **local** content. Linked **cloud** libraries are served by the gateway directly and stay searchable even while the tunnel is down — scope to one with `library="cloud://owner/slug"`. (Requires CLI ≥ v0.4.1; older CLIs aborted on a disconnected tunnel even for cloud-only queries.)

#### "No documents indexed"

- **Cause:** No folders have been added for indexing.
- **Fix:** Open Settings → Folders → Add Folder. Wait for scanning and indexing to complete.

#### Search returns no results

- **Cause:** Query terms may not match indexed content, or indexing is still in progress.
- **Fix:**
  1. Run `linkly status` to check if indexing is complete ("Watching" = ready).
  2. Try broader keywords or natural language queries.
  3. Remove `--type` or `--library` filters to search globally.
  4. Confirm the user's target content is a supported document type (PDF, Markdown, DOCX, PPTX, TXT, HTML, image). Files outside this list are not indexed even if they live under indexed folders — check by running `linkly explore` and looking at the document-type distribution.

#### `Invalid modified_after` / `Invalid modified_before`

- **Cause:** The date string isn't valid ISO 8601 UTC (typo, missing digits, wrong separator, or month/day out of range).
- **Fix:** Use a bare date (`2024-01-01`) or a full RFC 3339 timestamp (`2024-01-01T00:00:00Z`). The error message echoes back what you passed and the expected format — check it for typos.

#### `Invalid time_sort`

- **Cause:** `time_sort` was set to a value other than `default`, `newest`, or `oldest`.
- **Fix:** Pass `default`, `newest`, or `oldest`. `default` and omitting the flag entirely are equivalent — both keep the hybrid relevance ordering.

#### `find-paths` returns no folders

- **Cause:** The patterns missed every directory segment in the indexed paths. Two common reasons:
  - The user's wording differs from the actual folder name across languages (e.g. user says "微信" but the indexed path contains `xinWeChat`). Try several variants in a single call: `--patterns WeChat,微信,wxid,xinWeChat`.
  - The patterns only match the **filename** segment, not a directory segment. `find_paths` is a "find folders" tool — orphan filename matches are dropped silently. In that case, fall back to `linkly search` directly without `--path-glob`.
- **Fix:** Broaden or vary the patterns first. If still empty, the container may not be indexed yet (check `linkly status`) or use `linkly search` without path scoping.

### CLI not found

If `linkly --version` fails:

The CLI is not installed. Direct the user to: [Install Linkly AI CLI](https://linkly.ai/docs/en/use-cli)

## MCP Mode Troubleshooting

When using Linkly AI through an AI tool's MCP connection (Claude, Cursor, ChatGPT, etc.):

### MCP tools not available

- **Check:** Is the Linkly AI desktop app running?
- **Check:** Is the MCP server enabled? (Settings → MCP → toggle on)
- **Check:** Is the AI tool configured to connect to the correct MCP endpoint?
  - Local: `http://localhost:<port>/mcp` (port shown in Settings → MCP)
  - Tunnel: configured through the AI tool's connector settings
- **Note:** A running desktop is required only for **local** content. If you only need a linked **cloud** library, the gateway serves it without the desktop — scope to it with `library="cloud://owner/slug"`.

### MCP tools return errors

- **"Search failed":** The desktop app may have restarted. Wait a moment and retry.
- **"Document not found":** The document may have been moved or deleted. Search again to get fresh IDs.
- **Timeout:** The desktop app may be busy indexing. Check the app's tray icon status.

### MCP connection dropped

- MCP connections can drop if the desktop app restarts or the network changes.
- Most AI tools will automatically reconnect. If not, restart the AI tool's MCP connection.

## Version Mismatch Issues

### CLI version outdated

The CLI evolves alongside the desktop app. An outdated CLI may be missing commands, parameters, or have incompatible argument syntax. (The versions below are the **CLI's own** required versions; the separate **desktop** version thresholds are in "Desktop app version outdated" further down.) Common symptoms:

- `error: unexpected argument '--library'` → CLI too old, missing library support
- `error: unexpected argument '--remote'` → CLI below v0.2.0, missing remote mode
- `error: unexpected argument '--modified-after'` / `--modified-before` / `--time-sort` → CLI below v0.3.1, missing search time filters
- `error: unrecognized subcommand 'find-paths'` → CLI below v0.3.1, missing the find_paths command
- `linkly doctor` not recognized → CLI needs updating
- Commands fail silently or return unexpected errors after a desktop app update

**Fix:** Update the CLI:

```bash
linkly self-update
```

After updating, verify with `linkly --version` and retry.

### Desktop app version outdated

> Forward-compatibility note (read when symptoms below appear). For routine diagnostics start with **First: Run `linkly doctor`** above — that will surface a version gap as part of its checklist.

The opposite mismatch can also bite: the CLI is up to date but the desktop app on the other end is still on an older release whose MCP server doesn't yet expose the newer tools / parameters. Symptoms:

- `Error: ... unknown tool 'find_paths'` (or similar "tool not found" / "method not found") — the desktop is below v0.4.1 and doesn't ship the find_paths tool yet
- A `search` call with `--modified-after` / `--modified-before` / `--time-sort` looks like it succeeded but the result set ignores the time bounds (the same documents come back as a query without those flags). Pre-v0.4.1 desktop silently drops parameters it doesn't recognise. **Run `linkly status` to confirm — if `App` is below v0.4.1, the time filters aren't actually being applied.** From v0.4.1 onward this case becomes an explicit `Error: ... unknown field 'modified_after'` instead of a silent miss.
- The `[meta] now=` footer / `_meta.now` field is absent from successful responses — the desktop hasn't started attaching metadata, also a pre-v0.4.1 indicator

**Fix:** Update the desktop app to a release that matches or exceeds your CLI. Open the desktop app and check Settings → About → Check for Updates, or download the latest installer from [linkly.ai](https://linkly.ai). Run `linkly status` after the update — the displayed `App` version should be ≥ v0.4.1 to use `find_paths` and the search time filters. Recent CLI builds also surface a ⚠ banner under the `App` line when the desktop is too old.

### MCP schema out of sync

When the MCP tool definitions evolve (e.g., adding `list_libraries` / `find_paths`, new parameters like `library`/`path_glob`/`modified_after`/`time_sort` on `search`, or cloud-aware changes such as `cloud://owner/slug` library scoping and the `local://` / `cloud://` doc_id forms), connected AI tools may still cache the old schema. Symptoms:

- New tools not visible in the AI tool (e.g. `find_paths` doesn't appear)
- New parameters silently ignored or rejected as unknown (`modified_after`, `time_sort`, etc.)
- Stale tool descriptions
- Trailing `[meta] now=…` footer or top-level `_meta.now` field appearing in responses for the first time and the AI tool not understanding it (it's safe to ignore — see [Response Metadata](mcp-tools-reference.md#response-metadata))

**Fix:** Disconnect and reconnect the MCP connection in your AI tool:

- **Claude Desktop / Cursor:** Restart the app, or remove and re-add the MCP server.
- **`linkly mcp` bridge users:** Run `linkly self-update` first, then restart the `linkly mcp` process.

### Skills version outdated

This skill itself may be outdated — it might reference commands or parameters that no longer exist, or miss newly added features. There is currently no automatic version check for skills.

**Fix:** As a fallback when other troubleshooting steps don't help, try reinstalling or updating the skill. See the [Skills installation guide](https://linkly.ai/docs/en/use-skills) for instructions.

## General Tips

1. **Always check `linkly status` first** (CLI) or verify MCP tools are responding (MCP mode).
2. **`linkly doctor` is your best friend** — run it before diving into manual debugging.
3. **Restart the desktop app** if all else fails — this resolves most transient issues.
4. **Check the system tray icon** — it shows the current indexing status and can help identify if the app is busy.

## When You Can't Resolve It

If the above steps don't fix the problem, clearly inform the user what went wrong and what they can try manually. Keep the language simple — the user may not be technical. Include the specific error message, and provide step-by-step instructions they can follow (e.g., restart the app, check settings, toggle a switch). If needed, point them to [linkly.ai/docs](https://linkly.ai/docs) or [GitHub Issues](https://github.com/LinklyAI/linkly-ai-skills/issues) for further help.
