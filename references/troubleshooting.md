# Troubleshooting Linkly AI

When Linkly AI is not working as expected, follow these steps based on your connection mode.

## Step 0: Identify Your Mode

| Mode             | How you're connected                                                             | Typical setup                                      |
| ---------------- | -------------------------------------------------------------------------------- | -------------------------------------------------- |
| **CLI (Local)**  | Running `linkly` commands in a terminal on the same machine as the desktop app   | Default — no extra flags needed                    |
| **CLI (LAN)**    | Running `linkly` with `--endpoint` and `--token` flags                           | Connecting from another device on the same network |
| **CLI (Remote)** | Running `linkly` with `--remote` flag                                            | Connecting via internet tunnel                     |
| **MCP**          | AI tool (Claude, Cursor, etc.) connects directly to the desktop app's MCP server | Configured in the AI tool's MCP settings           |

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

#### "No documents indexed"

- **Cause:** No folders have been added for indexing.
- **Fix:** Open Settings → Folders → Add Folder. Wait for scanning and indexing to complete.

#### Search returns no results

- **Cause:** Query terms may not match indexed content, or indexing is still in progress.
- **Fix:**
  1. Run `linkly status` to check if indexing is complete ("Watching" = ready).
  2. Try broader keywords or natural language queries.
  3. Remove `--type` or `--library` filters to search globally.

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

### MCP tools return errors

- **"Search failed":** The desktop app may have restarted. Wait a moment and retry.
- **"Document not found":** The document may have been moved or deleted. Search again to get fresh IDs.
- **Timeout:** The desktop app may be busy indexing. Check the app's tray icon status.

### MCP connection dropped

- MCP connections can drop if the desktop app restarts or the network changes.
- Most AI tools will automatically reconnect. If not, restart the AI tool's MCP connection.

## General Tips

1. **Always check `linkly status` first** (CLI) or verify MCP tools are responding (MCP mode).
2. **`linkly doctor` is your best friend** — run it before diving into manual debugging.
3. **Restart the desktop app** if all else fails — this resolves most transient issues.
4. **Check the system tray icon** — it shows the current indexing status and can help identify if the app is busy.

## When You Can't Resolve It

If the above steps don't fix the problem, clearly inform the user what went wrong and what they can try manually. Keep the language simple — the user may not be technical. Include the specific error message, and provide step-by-step instructions they can follow (e.g., restart the app, check settings, toggle a switch). If needed, point them to [linkly.ai/docs](https://linkly.ai/docs) or [GitHub Issues](https://github.com/LinklyAI/linkly-ai-skills/issues) for further help.
