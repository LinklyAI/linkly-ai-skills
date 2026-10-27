# Linkly AI App Guide

How to use the Linkly AI desktop app itself: where things are, how to do common tasks, and what to check when something doesn't work. Read this when the user asks about the app ("how do I give you access to my files", "where is the setting for…", "why can't it find…", "how do I connect ChatGPT") rather than about the content of their documents.

Distilled from the Linkly AI documentation as of 2026-10-26 and checked against the desktop app's own interface text (desktop 1.2.x).

## How to use this guide

- **Quote UI labels exactly as written here** (they are the app's English labels, shown in **bold**). If the user's app is in another language, the labels are translated there; describe the location (sidebar, footer, which Settings tab) so they can still find it.
- **Never invent a menu, button or setting.** If a question isn't covered here, say so and point to the full docs: `https://linkly.ai/docs/en/<page>` (index of all pages: `https://linkly.ai/docs/llms.txt`).
- **Numbers that change** (prices, quotas, model lists, file limits, download sizes) are deliberately left out. Send the user to https://linkly.ai/pricing, the web dashboard, or the in-app **Model quota** panel.
- `Mod` below means ⌘ on macOS and Ctrl on Windows/Linux. Shortcuts listed are defaults; the user may have changed them under **Settings → Shortcuts**.
- Connection errors from CLI / MCP calls are covered in `troubleshooting.md`; CLI commands in `cli-reference.md`; tool parameters in `mcp-tools-reference.md`. This guide doesn't repeat them.

## 1. App map

**Main window** (opens with `Mod+K`, or left-click the tray icon / Dock icon):

- **Sidebar, top:** **Ask** (AI chat), **Find** (search page), **Home**, **Note**, **Clips**, **Library**, then **Chat history**.
- **Sidebar footer:** **Index status** icon (hover card → **Show more** opens Index management), **Agent usage** icon, **Quota** icon (opens the **Model quota** panel), and an update button when a new version is downloaded.
- **Account menu** (bottom-left): **Settings**, **Keyboard shortcuts**, **Show getting started**, **Upgrade to Pro**, **Visit website**, **Help docs**.

**Settings** (account menu → **Settings**, or `Mod+,`) tabs: **General**, **Account**, **Appearance**, **Shortcuts**, **Network**, **Data Privacy**, **About**, then **AI Models** and **Skills**.

**Index management** (sidebar footer index icon, **Home → My knowledge assets** status card, or tray → **View Index**) tabs: **Index**, **Rules**, **Can't extract**, **Advanced**.

**Agent usage** page (sidebar footer Agent icon) tabs **Overview** / **Log**. Overview sections:

- Status card: **Running** / **Stopped** with **Start** / **Stop**.
- **Management**: **Allow local access**, **Allow LAN access**, **Allow remote access (internet)**.
- **Integration**: a setup line to send to any agent, and **View MCP connection settings** (sections **Local**, **LAN**, **Remote (internet)**, with **Copy address** / **Copy config**).
- **Advanced**: **Linkly AI CLI** and **Linkly AI Skills** rows (**Install** / **Update** / **Open folder** / **Uninstall**), **Auto-update CLI and Skills**, **Keep an access log**.

**Tray icon:** left-click opens the main window; right-click menu has **Open Linkly AI**, **Search** (Launcher), **Ask AI**, **View Index**, **⏸ Pause Indexing** / **▶ Start Indexing**, MCP server status and **Stop/Start MCP Server**, **Settings**, **Shortcuts**, Quit. Closing the main window only hides it; the app keeps running in the tray.

**Global shortcuts:** Launcher (**Search**) `Mod+L`, main window `Mod+K`. Installs upgraded from older versions may still use the old Launcher default `Mod+Shift+L`. Both are set in **Settings → Shortcuts**.

## 2. Getting started

**Install:** download from https://linkly.ai. macOS `.dmg` (drag **LinklyAI** to Applications), Windows `.exe`, Linux AppImage (x86_64 / arm64; `chmod +x`, needs a recent glibc — see the FAQ page). An agent can guide the whole setup: send it `Set up https://linkly.ai/docs/en/agent-setup.md`.

**First-run wizard:**

1. Cover page: tick the **Privacy Policy** agreement (required). **Help improve Linkly AI (anonymous)** is on by default.
2. **Bring your files in**: **Sample files** are always indexed; **Documents**, **Desktop** and **Downloads** are unticked by default — tick the ones to index.
3. **Let your agent put your files to work**: **Install** next to **Install the Linkly CLI and Skills** installs them (nothing is installed unless clicked); **Keep the CLI and Skills up to date** is on by default.
4. **All set** → **Get started**.

There is no sign-in step. Indexing, search, notes, the Launcher and local MCP all work without an account and offline. An account is needed only for official AI models, cloud libraries and remote access (section 12).

**After install** the app downloads its semantic-search and OCR models in the background. Keyword search works immediately; semantic search starts once the download and indexing finish (section 4).

## 3. Giving Linkly AI access to your files

If no folders were ticked in the wizard, only the sample files are indexed — the most common reason "it can't see my files".

- **Add a folder:** **Library** → **Add folder** → pick the folder. Indexing starts automatically. (Also on **Home**, the getting-started checklist step **Add folders**.)
- **Or drop files into the Linkly AI Space** (`~/LinklyAI`, watched by default; see section 13).
- **macOS permission errors:** in the wizard the folder shows **Not authorized**; later, in **Library** it shows **Authorization expired**, and a sidebar icon warns that folders lost authorization or can't be read. Use **Re-authorize** / **Grant Full Disk Access** on that folder, or System Settings → Privacy & Security → Full Disk Access → add Linkly AI, then restart the app.
- **NAS / network drives:** mount the share in the OS first (Windows Map network drive, macOS Finder → Connect to Server `smb://…`, Linux mount), then **Library → Add folder**. The folder is tagged **External** and shows **Offline** while unmounted; the index is kept. Change detection on network shares can lag until the next launch.
- **Cloud-drive folders (iCloud, Dropbox, OneDrive):** add them like any folder. Files not downloaded to this device are only searchable by name ("Not indexed · cloud placeholder"); set the folder to always keep files on this device in the sync client.
- **Stop indexing a folder:** **Library → Manage sources** → **Remove** on its row. Files on disk are untouched. The Linkly AI Space row can't be removed.
- **Code files are not indexed**, nor are archives and installers.

Agents connect separately — see section 11. Adding a folder in the app is what makes its files available to every connected agent.

## 4. Indexing

**Where to watch progress:** Index management → **Index** tab. Statuses: **Preparing**, **Scanning**, **Processing**, **Watching** (done, watching for changes), **Paused**, **Error**. Indexing happens in layers: file names (seconds) → full text / keywords → semantic vectors. Search works throughout, but results are incomplete until **Watching**.

**Semantic (natural-language) search doesn't work, results look keyword-only.** The app falls back to keyword search silently. Check:

1. Index management → **Index** → **Management** → **Semantic search** is on (turning it on backfills; no rebuild).
2. Status is still **Processing** → wait.
3. **Settings → AI Models → Embedding model** is still downloading or failed → **Retry**.

**Text in scanned PDFs / images isn't searchable:** **Management → Extraction enhancements → Text recognition (OCR)** must be on (it is by default). Files waiting for OCR are listed under **Can't extract → Needs OCR**.

**Audio / video can be found by name but not by what is said:** **Audio transcription** and **Video transcription** (same **Extraction enhancements** group) are off by default. Turning one on downloads a speech model and processes existing files; no rebuild. If greyed out, the Audio/Video file type is turned off under **Rules**. A `.srt` / `.vtt` subtitle file next to a video makes it searchable even with transcription off.

**Indexing slows the computer down:**

- **Policy → Performance mode**: **Auto** (default; full speed only while you're idle), **Performance**, **Balanced**.
- Turn off audio/video transcription.
- **Pause**: Index management status card → **Pause** / **Resume indexing**, or tray → **⏸ Pause Indexing**. The existing index stays searchable.
- Laptops: **Power saving** (off by default) pauses OCR, transcription and semantic indexing while on battery. **Sleep models when idle** (on by default) frees model memory.

**Some files show up but their content isn't searchable:** Index management → **Can't extract** groups them by reason: **Unreadable** (too large, password-protected, damaged, unknown encoding — re-save a CSV as "CSV UTF-8"), **Format mismatch**, **Language not supported**, **No audio track**, **Transcription failed**, **No text**, **Needs OCR**, **Transcription off**, **Cloud placeholder**, **Other**. Use **Retry all** or per-file retry; in **Library**, right-click a file/folder → **Re-extract**.

**Rebuild the index** — last resort, after checking the switches above, that indexing isn't paused, and **Can't extract**: **Advanced → Maintenance → Rebuild the index → Rebuild…**. It deletes the index and extracted text (OCR and transcripts are redone, which can take hours) and keeps the original files. Not allowed while paused or while scanning/processing.

**Index uses too much disk:** **Advanced → Maintenance → Index storage optimization → Optimize** ("Your index is already optimized" means nothing to do). **Advanced → Index data** shows the location and disk usage.

**GPU:** **Advanced → Hardware → Hardware acceleration** (on by default). Windows/Linux use a discrete GPU for semantic indexing; on Apple silicon it only affects OCR layout analysis. After a GPU crash the app falls back to the CPU and offers **Try the GPU again**.

## 5. Choosing what gets indexed

- **File types:** Index management → **Rules → File types**. Groups **Documents** (PDF, Word documents, Markdown and plain text, Web pages, E-books, Spreadsheets, Presentations) and **Images, audio and video**. All on by default. Turning a type off removes those files from the index about a minute later (files on disk untouched).
- **Exclusion rules for files/folders:** in **Library**, right-click → **Add exclusion rule…** (or the funnel icon on a folder), or **Rules → Exclusion rules** (**All folders** or one folder → **Edit** / **Add rules**). Syntax is `.gitignore`: `*.csv`, `drafts/` (any level), `/drafts/` (folder root only), `**/temp/**`, `!keep.md` (exception). Paths are relative to the watched folder. The editor previews matching files; after **Save** a toast offers **Undo**, and files leave the index about a minute later.
- A `.ignore` file (gitignore syntax) inside a folder also works; it takes effect at the next full scan.
- **Built-in rules** (listed at the bottom of **Rules**, can't be turned off): hidden files and folders, `node_modules`, `__pycache__`, NAS/OS recycle folders (`#recycle`, `@eaDir`, `$RECYCLE.BIN`), the app data folder, Office `~$` temp files, `.gitignore`d files in git repos, unsupported formats.
- An agent can draft rule text for the user to paste into the editor. Don't edit `config.json` directly.
- Notes, clips and canvas files in the Linkly AI Space are always indexed regardless of these rules.

## 6. Finding files yourself

**Launcher** (`Mod+L`, or tray → **Search**): a Spotlight-style search over local indexed files, keyword and semantic combined (a query in one language can find documents in another).

- Type to search; no Enter needed. Empty box shows **Recent Searches**.
- `@` → pick a library to search only that library; `Backspace` on an empty box removes it.
- **Type filter** (when results have 2+ types) and sort **Most Relevant** / **Newest** / **Oldest**.
- `Enter` previews a result: `Mod+I` details, `Shift+Enter` **Show in Folder**, **Open with default app**, `Mod+Shift+C` copy path, `Mod+E` original file / parsed text, `Esc` back.
- `Tab` or **Ask AI** sends the query to the chat; **Open in main window** continues on the **Find** page.
- Pin it open with the pin button (bottom-right).
- It searches local content only, not cloud libraries.

**"Why can't I find this file?"** — search its file name first:

1. **Found with a grey "Not indexed · …" badge** → only the name is indexed; hover for the reason, then see **Can't extract** (section 4).
2. **Found, no badge, but its content isn't matched** → a switch is off (OCR, audio/video transcription), it is still queued, or (macOS) it is a legacy `.doc` — re-save as `.docx`.
3. **Not found** → its folder was never added (**Library → Add folder**), its type is off or excluded (**Rules**), it sits in a built-in ignored folder, or the format isn't supported (e.g. `.htm`, `.avi`).

## 7. AI chat (Ask)

**Open:** sidebar **Ask**, tray → **Ask AI**, or `Tab` from the Launcher. `Mod+N` starts a new chat. Chats are kept locally with no automatic deletion; rename or delete from **⋯** on a chat in **Chat history**.

**Point the AI at a library, folder or file:** type `@` in the composer and pick from **Knowledge libraries** or (after typing a name) **Files and folders**. Or start from the item itself: **Chat with this file** / **Chat with this folder** / **Chat with this library** (in **Library** and **Find**), **Chat with this clip** (in **Clips**). Two things to know: `@` is a strong hint, not a hard filter — say "only look in X" to enforce it; and it applies to that one message, so repeat it in follow-ups.

**No file upload.** The chat only uses indexed files: add the folder in **Library** (or drop the file into `~/LinklyAI`), wait for indexing, then `@` it.

**Models:**

- Switch with the model picker in the composer toolbar.
- Official models: sign in under **Settings → Account**; the **Linkly Official** provider card under **Settings → AI Models → Providers** should read **Ready**. Free accounts see only the basic models.
- Your own model (any OpenAI-compatible API, including Ollama and LM Studio): **Settings → AI Models → Providers → Custom provider**; presets fill in the base URL, models are discovered from `/v1/models` or typed in. Local servers usually need no API key. Only models that support tool calling are listed.
- **Settings → AI Models → Language models**: **Default model** (for new chats) and **Response language** (**Auto** follows the language of your message; any other choice pins replies and chat titles to that language).

**Quota (official models only):** one shared pool; each model has a cost multiplier shown in the picker. Three windows (**5h quota**, **7d quota**, **30d quota**) count separately, and hitting any one pauses official models until it resets — switching to another official model doesn't help; a third-party or local model does. Check the **Model quota** panel (sidebar footer **Quota** icon). Third-party and local models use no Linkly quota.

**Long conversations:** compaction runs automatically near the context limit, or manually with `/compact`. Older messages fold into a summary behind **Earlier messages compacted (N)**. If a custom provider doesn't report its context size, compaction never runs automatically — use `/compact` or start a new chat.

**`/` menu:** **Commands & skills** — `/compact` and enabled skills. Manage skills in **Settings → Skills** (installed skills are read from `~/.agents/skills`).

**Right panel:** **Files in this chat** (**Referenced** / **Read**) and **Canvas**. Expand a tool-call group in the conversation to see what the AI searched and read. Export per item: **Download response**, **Download table**, **Download diagram** (to the Downloads folder); there is no whole-conversation export.

**Privacy:** with official or other cloud models, your messages and the document excerpts the AI retrieved are sent to that provider (official models go through Linkly's servers). With a local model, nothing leaves the computer.

## 8. Notes

- **Open:** sidebar **Note**, or `Mod+Shift+N` in the main window. Card notes on a timeline; each is a Markdown file in `~/LinklyAI/Notes/YYYY-MM/`.
- **Write:** type in the bottom box, `Mod+Enter` or **Publish note**. **Edit** → **Save** on a card. **⋯ → Delete → Delete permanently** deletes the file for good (no trash, no undo).
- **Tags:** write `#tag` in the body (`#` shows suggestions; nested tags with `/`, e.g. `#projects/client-a`). The body is the only source of tags; delete the `#tag` text to remove one. Click a tag to filter.
- **Sort / filter / search:** **Newest created**, **Oldest created**, **Recently edited**; **Author** filter (**Me** or an agent); search with the magnifier or `Mod+F`.
- **Just-written note not found by search:** normal for a short while — the timeline reads files directly, search waits for indexing.
- **Edit elsewhere:** **Open notes folder**; Obsidian, VS Code etc. work. Files moved out of `Notes/YYYY-MM/` or stripped of their header stay searchable but leave the timeline.
- **Agents** write notes with `note_save` (shown with an **Agent** badge); there is no delete tool. Notes stay local and are never synced to the cloud on their own.
- No pin, archive or export features; to export, copy the `.md` file.

## 9. Browser clipper (Linkly AI Clipper)

- Chrome Web Store extension (also Edge, Brave; no Firefox). Saves the current page as clean Markdown with images; also video subtitles and ChatGPT / Claude conversations. No sign-in needed.
- **Clip:** click the toolbar icon (pin it — there is no shortcut or context menu) → side panel converts the page → **Copy**, or **Download** → **Save clip** → **Save**.
- **Where it goes:** with the desktop app running, into `~/LinklyAI/Clips/` and indexed automatically (toast **Saved to LinklyAI Space**). Otherwise into `~/Downloads/Linkly/`, which is not indexed and never moved later (toast **Client offline — saved to browser downloads**).
- **Connection check:** extension **Settings → Download settings → Save to LinklyAI Space** shows **Online** or **App not detected** (**Re-check**, **Launch desktop app**). Still going to Downloads with the app running → update the desktop app.
- **In the app:** sidebar **Clips** → browse, read, **Chat with this clip**, **Open clips folder**.
- Pages are processed in the browser; translation and AI outline use Chrome's on-device model.

## 10. Libraries

**Local library** — an optional named group of folders for scoped search (and the unit that can be pushed to the cloud). Adding already-indexed folders doesn't re-index.

1. **Library** → **Libraries** tab → **My libraries** → **+** (**New library**).
2. **Title**, **Identifier** (lowercase letters, digits, hyphens; generated from the title), optional **Description** → **Create**.
3. Library page → settings icon → **Library settings** → **Add Folder**.

Search it with `@` in the Launcher or chat, or tell an agent "search my <identifier> library". Changing the identifier breaks earlier `@` references and agent configs that use it. Deleting a library keeps its documents indexed.

**Cloud library** — a copy of one local library on Linkly's servers, searchable by AI apps while your computer is off, and shareable. One-way: the local library is the source of truth.

1. Web: dashboard → **My Libraries** → **New**.
2. **Bind in Linkly Desktop** (or in the app: **Library settings** → **Cloud Library** → **Initialize cloud library** → paste the library URL → **Bind**). Desktop and web must be the same account.
3. **Push**; turn on **Auto sync**. Status **Synced to cloud** / **Local has changes**. Auto sync holds on large deletions until you push manually.

To let an agent search a cloud library — including your own — open its web page and click **Link** (uses one link slot; limits on the pricing page), or use **Use in AI** on the page and give the line to the agent. In the desktop app, linked cloud libraries appear under **Connected cloud libraries** in **Library** and in the chat's `@` picker. Sharing (**Public** / **Showcase** / **Private**, invitations, access requests) is managed on the web library's settings page. Agent-side details: `https://linkly.ai/docs/en/library-setup.md`.

## 11. Connecting AI apps and agents

**Pick the path by where the AI app runs and what it should reach:**

| Situation                                             | How                                                                          | Cost |
| ----------------------------------------------------- | ---------------------------------------------------------------------------- | ---- |
| App on this computer, supports HTTP MCP               | `http://127.0.0.1:60606/mcp`, server name `linkly-ai`, no auth               | Free |
| App on this computer, stdio only                      | command `linkly`, args `mcp` (needs the CLI)                                 | Free |
| Coding agent with a terminal                          | Linkly CLI + Skills (installed from the app, below)                          | Free |
| Another device on the same network (NAS, second PC)   | LAN access (below)                                                           | Free |
| Cloud app (ChatGPT, Claude.ai), only chosen documents | Cloud library via `https://mcp.linkly.ai/mcp`, server name `linkly-ai-cloud` | Free |
| Cloud app, everything on this computer                | Remote access via `https://mcp.linkly.ai/mcp`                                | Pro  |

The real address and port are in **Agent usage → View MCP connection settings** (60606 is the default; another port is used if it's taken).

**Install the CLI and Skills from the app:** the wizard's agent step → **Install**, or later **Agent usage → Advanced** → **Install** on the **Linkly AI CLI** / **Linkly AI Skills** rows (if the CLI row shows **One last step**, click **Set up**). Skills go to `~/.agents/skills/linkly-ai`, with a link in `~/.claude/skills` for Claude Code. Other install methods: `https://linkly.ai/docs/en/use-skills`.

**LAN access:** **Agent usage → Management → Allow LAN access** (requires **Allow local access**). **View MCP connection settings → LAN** shows the address and **Token**; the other device sends `Authorization: Bearer <token>`. The user should copy the token into the other app themselves — never paste it into a chat. Plain HTTP: trusted networks only. **Regenerate token** invalidates the old one at once.

**Remote access (Pro):** sign in, then **Agent usage → Management → Allow remote access (internet)** and wait for **Connected**. In the cloud app add `https://mcp.linkly.ai/mcp` and approve the OAuth sign-in. The desktop app must stay running. Status meanings: **Connecting**, **Connected**, **Not signed in**, **Pro required**, **Connection failed** (hover for the reason). Behind a proxy: **Settings → Network → Route the MCP tunnel through the proxy**. Revoke authorized apps on the web: dashboard → **Integrations** → **Authorized apps**.

**Turning access off:** **Allow local access** off cuts off the CLI and every AI app (LAN and remote switches are disabled with it). **Stop** on the status card stops the MCP server.

**See which apps read your files:** **Agent usage → Overview** and the **Log** tab (needs **Keep an access log**).

**Tools don't show up after connecting:** the AI app loads tools at session start — start a new conversation or fully restart the app.

**Supported apps** (setup page: `https://linkly.ai/docs/en/integration/use-in-<app>`): Claude (claude.ai) `use-in-claude`, Claude Desktop / Cowork `use-in-cowork`, ChatGPT `use-in-chatgpt`, Claude Code `use-in-claude-code`, Codex `use-in-codex`, Cursor `use-in-cursor`, Windsurf `use-in-windsurf`, GitHub Copilot `use-in-github-copilot`, Gemini CLI `use-in-gemini-cli`, Kimi Code `use-in-kimi-code`, ZCode `use-in-zcode`, OpenClaw `use-in-openclaw`, Cherry Studio `use-in-cherry-studio`, Raycast (stdio only) `use-in-raycast`, LM Studio `use-in-lm-studio`, WorkBuddy `use-in-workbuddy`, QoderWork `use-in-qoderwork`, QwenPaw `use-in-qwenpaw`, n8n `use-in-n8n`, Dify `use-in-dify`. Any other MCP client: use the table above.

## 12. Account and plans

- **Sign in:** **Settings → Account → Sign In** (opens the browser). Web sign-in uses Google, GitHub, Notion or an email code; the first sign-in asks for a display name and a username (the username appears in cloud library URLs and can't be changed later).
- **No browser on that machine:** expand "Optional: connect your account by setting an API key manually" at the bottom of **Settings → Account** and have the user paste the key there (dashboard → **Integrations → API Keys**). Never ask for the key in the chat.
- **"Needs setup" / "This sign-in is invalid or the key has expired."** → **Sign In** again.
- **Sign out:** **Settings → Account → Sign Out** — clears local credentials only; indexes, chats and cloud content are kept.
- **Free** covers all local features, MCP / CLI / Skills, the clipper, basic official models and private cloud libraries. **Pro** adds frontier official models, higher quotas, remote access, public / showcase cloud libraries, and cloud embedding / transcription. Limits and prices: https://linkly.ai/pricing.
- **Subscribe** on the pricing page; **cancel** via dashboard avatar menu → **My subscription**.
- Multiple computers: sign in on each; quota is per account. Custom model providers are set up per computer.

## 13. Data, privacy and maintenance

**What stays local:** original files (never modified), the search and vector indexes, chats, notes, logs, and local models. Anonymous usage statistics (counts, version, OS, a random device ID — never content, file names or queries) are on by default; turn off in **Settings → Data Privacy → User Experience Improvement Program**. What leaves the machine when chatting: see section 7.

**Linkly AI Space vs App Data:**

- **Linkly AI Space** (`~/LinklyAI`, in the home folder, not Documents) holds your content: `Notes/`, `Clips/`, `Canvas/`, `Linkly_AI_Examples/` (sample files, safe to delete). **Settings → General → Linkly AI Space → Open / Change / Restore Default**. **Change** doesn't move existing files — copy them yourself, then remove the old path in **Library → Manage sources** if wanted. Don't move or delete the folder in the file manager.
- **App Data** holds the index, database, logs and models. **Settings → General → App Data → Open / Change** (**Change and restart** moves everything to the new location and leaves a link at the old one). Never put it in a cloud-sync folder; network locations are refused. Don't delete the old location's leftover link.

**Logs:** **Settings → General → App Data → Open** → `logs/app.log`, or **Settings → About → Send diagnostic log**. After a crash, the next launch offers **Send report**.

**Updates:** **Settings → About → Check for Updates**; **Join Beta Program** for early builds.

**Offline / air-gapped computers:** download the installer and the official offline model pack on a connected machine, install, launch once, quit, copy the pack's `models/` folder into App Data's `data/` folder, relaunch. Steps and downloads: `https://linkly.ai/docs/en/offline-models`. Offline, everything except official AI models, sign-in, cloud libraries, Skills install and updates keeps working.

**Linux AppImage won't start:** `chmod +x`; missing FUSE → install the distribution's FUSE 2 package (`libfuse2`, `libfuse2t64` on Ubuntu 24.04+, `fuse-libs` on Fedora, `fuse2` on Arch) or run with `--appimage-extract-and-run`; GLIBC errors → the distribution is too old (don't replace libc). Don't run it with sudo.

**Server / Docker version:** not available. For a machine without a desktop, use the CLI there and connect to a desktop over LAN or remote access.

**Uninstall:** remove the app as usual. On Windows, the uninstaller's "Delete the application data" option also deletes the index and settings — leave it unticked to keep them for a reinstall.

## Not covered here

| Need                                         | Where                                                 |
| -------------------------------------------- | ----------------------------------------------------- |
| CLI commands and flags                       | `cli-reference.md`                                    |
| MCP tool parameters, supported file types    | `mcp-tools-reference.md`                              |
| Search tactics                               | `search-strategies.md`                                |
| CLI / MCP connection errors, `linkly doctor` | `troubleshooting.md`                                  |
| Anything else about the app                  | `https://linkly.ai/docs/llms.txt` → the matching page |
