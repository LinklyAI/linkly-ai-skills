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

#### "Port file not found"

- **Cause:** The Linkly AI desktop app isn't running — `~/.linkly/port` is written at startup.
- **Fix:** Launch the desktop app, wait a few seconds, then retry.

#### HTTP 403 "MCP is disabled in settings"

- **Cause:** The desktop app **is** running, but its MCP server is switched off in settings.
- **Important:** the port file still exists and the port still answers. The local API server stays up to serve other features (browser clipping, health checks) and only the `/mcp` route is gated. So "the port is reachable" does **not** mean MCP is enabled, and a disabled MCP server does **not** produce "connection refused".
- **Fix:** Open Settings → MCP → enable the MCP server. It takes effect on the next request; no restart needed.

#### `App: Unreachable` / `desktop_unreachable`

- **Meaning:** The CLI could not reach the configured Linkly AI Desktop endpoint. This is a transport result, not proof that the Desktop is stopped. In an AI-agent environment, the shell may be able to execute the CLI while its network sandbox blocks `127.0.0.1` or the LAN endpoint.
- **Recovery order:**
  1. Check whether Linkly MCP tools are available in the current agent environment. If they are, use MCP and stop retrying the sandboxed CLI.
  2. If MCP is unavailable and the shell is sandboxed, ask the user to approve retrying the **exact Linkly CLI command** outside the network sandbox. Do not recommend disabling the sandbox globally and do not request broad approval for every `linkly` subcommand.
  3. Only if the approved retry still fails, ask the user to launch or relaunch Linkly AI Desktop and try again. For LAN mode, also verify the configured host and port.

#### "Connection refused"

- **Cause:** Outside a network sandbox, nothing is listening on that port — usually a stale port file left by a crashed or force-quit app, or a wrong `--endpoint` in LAN mode. Inside an AI-agent sandbox, the same low-level failure may instead mean that localhost or LAN access is blocked.
- **Fix:** Follow the `App: Unreachable` recovery order above. If an approved retry outside the sandbox still gets connection refused, confirm the desktop app is actually running (relaunch if unsure). In LAN mode, re-check the `--endpoint` host and port.

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
  3. Remove `--type` or `--library` filters to widen the search across all local content.
  4. Confirm the user's target content is a supported document type (PDF, Markdown, Excel, CSV, DOC, TXT, DOCX, PPTX, RTF, EPUB, HTML, image, audio, video). Files outside this list are not indexed even if they live under indexed folders — check by running `linkly explore` and looking at the document-type distribution.
  5. For audio or video, check that transcription is switched on — it is opt-in per media kind in Desktop Settings → Indexing. Until it is enabled those files are indexed by filename only.
  6. If the user expects content from a **cloud** library, confirm the connection mode reaches it — see "Cloud library content is missing" below.

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

#### Cloud library content is missing

- **Cause:** the connection mode doesn't reach cloud libraries. Local and LAN connections serve **local content only** — `cloud://` references are rejected there, and `list_libraries` has no cloud section to show. This is a connection boundary, not an indexing problem.
- **Fix:** switch to a connection that reaches the gateway — `linkly --remote` for CLI commands, `linkly mcp --remote` for the stdio bridge, or the `linkly-ai-cloud` connector for MCP clients. Then run `list_libraries` to get the exact `cloud://owner/slug`, and pass it as `--library`.
- **Don't** report "not found" from a local connection as if the search had been exhaustive — say which tier was searched.

#### "Content not available for '<title>'"

The document is indexed and its `doc_id` is valid, but there is no readable text. The message names the reason:

| Reason in the message                     | What it means                                                                    | What to tell the user                                                    |
| ----------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| cloud placeholder, not downloaded locally | An online-only file from Dropbox / iCloud / OneDrive that was never materialized | Download it in the cloud client, wait for Linkly to index it, then retry |
| no audio track                            | A media file with no speech to transcribe                                        | Nothing to read; the file is findable by name only                       |
| transcription failed                      | Undecodable or unsupported audio                                                 | Nothing to read                                                          |
| signature doesn't match its extension     | A stub or renamed file whose contents aren't what the extension claims           | The file is likely corrupt or a placeholder                              |

**These are terminal states.** Don't re-run `search` and retry the read — the document really is in the index, it simply has no body.

#### Partial content warnings

A `read` response may say the text is incomplete (`ocr_pending` in JSON). That means a background job — OCR or media transcription — still owes text, or the extraction was truncated. Retrying later can genuinely help here, unlike the errors above. If it never resolves, the background job may have failed permanently.

#### Note operations fail

- **`NOTE_VERSION_CONFLICT`** — someone (or something) changed the note since you read it. The error carries the actual version. Re-read via `linkly list --scope notes`, merge your change into the current body, then retry with the fresh `base_version`. **Never retry by blindly reusing the old version.**
- **`NOTE_INVALID_INPUT`** — either a required field is missing (`edit` needs `note_id` + `base_version`), or the content uses Markdown outside the allowed subset. The error lists the offending constructs. Allowed: paragraphs, line breaks, bold, strikethrough, lists. Not allowed: headings, italics, blockquotes, code, links, images, raw HTML, rules, tables, task lists, footnotes.
- **`NOTE_NOT_FOUND`** — the `note_id` doesn't exist; re-list to get a current one.
- **Tags can't be edited in the app UI on an AI-written note** — a note written by an old Desktop (< 0.11.0) may store tags only in YAML. Since 0.11.0, tags live in the body as `#tokens`; one agent edit materializes the legacy tags into the body and the note heals itself.
- **A tag keeps coming back after you remove it from `tags`** — the `tags` parameter only adds. Remove a tag by deleting its `#token` from the note `content` on edit.

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

### Gateway error codes

Errors coming back from the `mcp.linkly.ai` gateway carry a JSON-RPC `code` and a `data` object with recovery guidance. Read the `data.reason` — it names which side failed.

| Code     | Situation                   | What it means and what to do                                                                                                                                 |
| -------- | --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `-32000` | Desktop unavailable         | The call defaulted to local scope but the desktop couldn't be reached. Start the desktop and reconnect its tunnel, **or** scope the call to a cloud library. |
| `-32000` | No local Desktop paired     | No desktop is paired with this account at all. Either pair one, or use an explicit cloud library.                                                            |
| `-32000` | Tunnel requires Pro         | The call targeted **local** content, which needs tunnel access — a Pro feature. See "Free vs Pro" below.                                                     |
| `-32000` | Cloud tool execution failed | The cloud backend errored while running the tool. Retry; if it persists, report it.                                                                          |
| `-32001` | Stale session               | The desktop went away mid-session. Reconnect the MCP connection in your AI tool.                                                                             |
| `-32002` | Cloud library not found     | The `cloud://owner/slug` doesn't resolve. Re-check it with `list_libraries` — slugs can be renamed on the web side.                                          |
|          | Namespace conflict          | `doc_id` and `library` point to different namespaces (one local, one cloud). Pass a matching pair, or drop `library`.                                        |
|          | Mixed outline doc_ids       | One `outline` call mixed `local://` and `cloud://` IDs. Split into one call per backend.                                                                     |
|          | Invalid doc_id              | The ID is stale (documents were re-indexed) or never existed. Search again for fresh IDs — never hand-edit a `doc_id`.                                       |
|          | Unknown tool                | The tool name isn't recognized by this server — usually a version gap. See "Version Mismatch Issues" below.                                                  |

### Free vs Pro

The gateway gates by **what the call targets**, not by where it came from:

- **Local content over the tunnel is Pro-only.** On a Free plan, a call that defaults to local scope (or explicitly names a local library) returns `-32000` saying the tunnel requires Pro.
- **Linked cloud libraries are served on all plans.** Scoping to `library="cloud://owner/slug"` works on Free.
- Purely local connections (no gateway) are unaffected — the desktop's own MCP server has no plan gating.

So on a Free plan, "everything fails over `--remote` except cloud libraries" is expected behaviour, not a broken setup. Either scope to a cloud library, or use a local connection for local content.

### MCP connection dropped

- MCP connections can drop if the desktop app restarts or the network changes.
- Most AI tools will automatically reconnect. If not, restart the AI tool's MCP connection.

## Version Mismatch Issues

### CLI version outdated

The CLI evolves alongside the desktop app. An outdated CLI may be missing commands, parameters, or have incompatible argument syntax. (The versions below are the **CLI's own** required versions; the separate **desktop** version thresholds are in "Desktop app version outdated" further down.) Common symptoms:

- `error: unexpected argument '--library'` → CLI too old, missing library support
- `error: unexpected argument '--remote'` → CLI below v0.2.0, missing remote mode
- `error: unexpected argument '--modified-after'` / `--modified-before` / `--time-sort` → CLI below v0.4.0, missing search time filters
- `error: unrecognized subcommand 'find-paths'` → CLI below v0.4.0, missing the find_paths command
- `error: unexpected argument '--scope'` / `--tags` / `--image-text`, or `error: unrecognized subcommand 'note-save'` / `'list'` / `'completions'` → CLI below v0.6.0, missing note support, referenced-image detail and shell completions
- `error: unexpected argument '--exit-code'` → CLI below v0.6.0; without it an empty result is indistinguishable from a failure by exit code alone
- `linkly read` or `linkly grep` rejects a second document ID, or `-` is treated as a literal ID → CLI below v0.6.0, missing batch and stdin input
- `error: unexpected argument '--path'` / `--type` / `--modified-after` **on `linkly list`**, or `--library` rejected there → CLI below v0.6.1, which is where `list` grew the `folder` and `library` scopes
- `linkly doctor` not recognized → CLI needs updating
- Commands fail silently or return unexpected errors after a desktop app update

**Fix:** Update the CLI:

```bash
linkly self-update
```

After updating, verify with `linkly --version` and retry.

### Desktop app version outdated

> Forward-compatibility note (read when symptoms below appear). For routine diagnostics start with **First: Run `linkly doctor`** above — that will surface a version gap as part of its checklist.

The opposite mismatch also bites: the CLI is up to date but the desktop app on the other end is on an older release whose MCP server doesn't expose the newer tools or parameters yet. Symptoms:

- `Error: ... unknown tool '<name>'` (or "tool not found" / "method not found") — that tool doesn't exist in the desktop's MCP surface yet
- `Error: ... unknown field '<param>'` — the tool exists but not that parameter
- A call **looks** like it succeeded but a filter had no effect — the same documents come back as a query without it. Very old desktops silently drop parameters they don't recognise instead of erroring
- The `[meta] now=` footer / `_meta.now` field is missing from successful responses

Known thresholds worth naming to the user:

- **Desktop 0.11.0** — `list` with `scope="folder"` / `scope="library"`, and additive `note_save` tags. Below it, CLI v0.6.1 refuses outright on a local or LAN connection rather than sending a call that would misbehave; over the cloud gateway you get `UPDATE_REQUIRED` for the local scopes while cloud libraries keep working.

**Diagnose with `linkly status`** — it prints the desktop's version alongside the CLI's, and recent CLI builds show a ⚠ banner under the `App` line naming the features the desktop is too old for.

**Fix:** update the desktop app: Settings → About → Check for Updates, or download the latest installer from [linkly.ai](https://linkly.ai). As a rule, keep the desktop app and the CLI both current — the MCP surface has grown steadily (library scoping, path and time filters, `find_paths`, cloud libraries, media and OCR types, notes), and every gap shows up as one of the symptoms above.

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
