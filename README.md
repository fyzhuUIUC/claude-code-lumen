# claude-code-lumen

Claude Code in a container, pointed at a [Lumen](https://github.com/ncsa/lumen)
server instead of api.anthropic.com, with web search that works.

Claude Code's built-in WebSearch runs inside Anthropic's service, so it cannot
work through Lumen. This image switches it off and gives Claude Code a search
tool through an MCP server instead: Exa or Brave if you have a key, DuckDuckGo
(no key) otherwise.

## Use

```bash
docker build -t claude-code-lumen .
cp ccl ~/.local/bin/          # the launcher

mkdir -p ~/.config/claude-code-lumen
cat > ~/.config/claude-code-lumen/env <<'CONF'
LUMEN_URL=https://lumen.example.edu      # no /v1
LUMEN_API_KEY=sk_...                     # from your Lumen Profile page
LUMEN_MODEL=qwen3-coder                  # a model id from Lumen's /v1/models
# EXA_API_KEY=...                        # optional, see below
CONF
chmod 600 ~/.config/claude-code-lumen/env

cd your-project && ccl                   # interactive
ccl -m other-model                       # another Lumen model
ccl -- -p "summarise README.md"          # anything after -- goes to claude
```

The current directory is mounted at `/work`; nothing else of the host is
visible. Claude Code's own state (login, history) lives in
`~/.local/share/claude-code-lumen`. The launcher checks that Lumen answers and
that the model exists before starting.

## Web search

| `CCL_SEARCH` | Backend | Key |
|---|---|---|
| `auto` (default) | Exa if `EXA_API_KEY` is set, else Brave if `BRAVE_API_KEY` is set, else DuckDuckGo | |
| `exa` | [Exa](https://exa.ai) | `EXA_API_KEY`, from https://dashboard.exa.ai/api-keys |
| `brave` | [Brave Search API](https://brave.com/search/api/) | `BRAVE_API_KEY`, from https://api-dashboard.search.brave.com |
| `ddg` | DuckDuckGo | none |
| `none` | no search | |

DuckDuckGo needs no account, but its results are thinner and it rate-limits
under heavy use. For regular use, get an Exa or Brave key.

## What is set for you

- The four settings Lumen needs (`CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`,
  `CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING`, `MAX_THINKING_TOKENS=0`,
  `CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT`); see Lumen's
  `docs/guides/anthropic.md`.
- Claude Code is pinned (2.1.284) and its auto-updater is off, because a newer
  client may ask for a feature Lumen refuses. Bump `CC_VERSION` in the
  Dockerfile after checking the new version against your Lumen.
- WebSearch is denied; the MCP search tools are allowed without a prompt.
- The key goes in as `ANTHROPIC_AUTH_TOKEN` (a Bearer header), so first-run
  Claude Code does not ask whether to use a custom API key.
- The Haiku, Sonnet and Opus aliases all point at your Lumen model, so the
  auto-mode permission classifier and subagents do not ask Lumen for a Claude
  model it does not have.

## Tested

2026-09-28, Claude Code 2.1.284, Lumen `feature/anthropic-messages-api-minimal`,
Qwen3.8-27B backend: headless (`-p`) runs answered a question that needs a live
search correctly with each of Exa, Brave and DuckDuckGo, with no Lumen errors.

Same day, Qwen3.8-Flash-Next backend (llama.cpp): headless runs of plain text,
Write/Read/Edit, Bash, WebFetch, a subagent, and search with Exa and Brave all
answered correctly. DuckDuckGo's search worked but its result snippet was out of
date, so the answer was an old version. An interactive session started, ran
Bash, search and WebFetch, and exited cleanly. In auto mode the permission
classifier approved WebFetch and `curl` but takes 30 to 75 s per decision on this
backend, and it timed out once ("temporarily unavailable") on a longer session.

This project was written with AI coding assistance.
