# Linkly AI Skills

![Version](https://img.shields.io/badge/version-0.1.13-blue)
![License](https://img.shields.io/badge/license-Apache--2.0-green)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)

[Agent Skills](https://agentskills.io) for [Linkly AI](https://linkly.ai) — search, browse, and read your local documents from any AI coding agent.

This skill teaches AI agents how to use Linkly AI's document search capabilities, enabling them to find and read your locally indexed documents (PDF, Markdown, DOCX, TXT, HTML, and more).

## What is Linkly AI?

[Linkly AI](https://linkly.ai) is a desktop application that indexes documents on your computer and provides full-text search, structural outlines, and content reading through a local MCP server. Think of it as a local knowledge base that AI agents can query.

## What Does This Skill Do?

When installed, this skill enables AI agents to:

- **Search** your local documents by keywords with relevance ranking
- **Browse** document outlines to understand structure before diving in
- **Grep** for specific text patterns with regex matching
- **Read** document content with line-based pagination
- **Auto-detect** whether to use CLI commands or MCP tools based on the environment
- **Guide setup** if Linkly AI is not yet installed

The skill supports two access modes:

| Mode | When Used                      | How It Works                             |
| ---- | ------------------------------ | ---------------------------------------- |
| CLI  | Agent has Bash/terminal access | Runs `linkly` CLI commands (preferred)   |
| MCP  | Agent has MCP tool access      | Calls search/outline/grep/read MCP tools |

## Prerequisites

1. **Linkly AI desktop app** — [download from linkly.ai](https://linkly.ai)
2. **Linkly AI CLI** (for CLI mode) — see [installation](#cli-installation)

### CLI Installation

macOS / Linux:

```bash
curl -sSL https://updater.linkly.ai/cli/install.sh | sh
```

Or via Homebrew:

```bash
brew tap LinklyAI/tap
brew install linkly
```

Windows (PowerShell):

```powershell
irm https://updater.linkly.ai/cli/install.ps1 | iex
```

Cross-platform (requires Rust):

```bash
cargo install linkly-ai-cli
```

## Installing This Skill

### skills.sh (Recommended)

Install to all supported agents with a single command:

```bash
npx skills add LinklyAI/linkly-ai-skills
```

Or install to a specific agent:

```bash
# Claude Code only
npx skills add LinklyAI/linkly-ai-skills -a claude-code

# Codex CLI only
npx skills add LinklyAI/linkly-ai-skills -a codex

# Global install (available across all projects)
npx skills add LinklyAI/linkly-ai-skills -g
```

### Claude Code (manual)

Copy the skill to your personal skills directory:

```bash
git clone https://github.com/LinklyAI/linkly-ai-skills.git ~/.claude/skills/linkly-ai
```

Or for a specific project:

```bash
git clone https://github.com/LinklyAI/linkly-ai-skills.git .claude/skills/linkly-ai
```

### Codex CLI (OpenAI)

```bash
git clone https://github.com/LinklyAI/linkly-ai-skills.git ~/.agents/skills/linkly-ai
```

### Claude.ai (web)

Download `linkly-ai.zip` from the [Releases](https://github.com/LinklyAI/linkly-ai-skills/releases) page, then upload it in Claude.ai → Settings → Capabilities → Skills.

### ClawHub (OpenClaw)

```bash
clawhub install linkly-ai
```

### Other AI Agents

Any AI agent that supports the [Agent Skills](https://agentskills.io) open standard can use this skill. Copy the `SKILL.md` file and the `references/` directory to the appropriate skills location for your agent.

## Skill Contents

```
├── SKILL.md                           # Core skill instructions
├── references/
│   ├── cli-reference.md               # CLI commands and options
│   └── mcp-tools-reference.md         # MCP tool schemas and responses
└── scripts/
    └── package.sh                     # Build linkly-ai.zip for upload
```

| File                                | Purpose                                                            |
| ----------------------------------- | ------------------------------------------------------------------ |
| `SKILL.md`                          | Main instructions: environment detection, workflow, best practices |
| `references/cli-reference.md`       | Detailed CLI installation, commands, options, JSON output format   |
| `references/mcp-tools-reference.md` | MCP tool parameters, response schemas, supported document types    |

## Compatibility

This skill follows the [Agent Skills](https://agentskills.io) open standard and works with:

- [Claude Code](https://claude.ai/code) (Anthropic)
- [OpenClaw](https://openclaw.ai)
- [Codex CLI](https://github.com/openai/codex) (OpenAI)
- Any agent supporting the Agent Skills specification

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on [GitHub](https://github.com/LinklyAI/linkly-ai-skills).

## License

[Apache-2.0](LICENSE)
