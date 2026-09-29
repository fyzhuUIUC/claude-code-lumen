#!/usr/bin/env bash
# Picks the web search backend, writes the MCP config, then starts claude.
#   CCL_SEARCH=auto (default) | exa | brave | ddg | none
#   auto = exa if EXA_API_KEY is set, else brave if BRAVE_API_KEY is set, else ddg.
set -euo pipefail

search="${CCL_SEARCH:-auto}"
fellback=
if [ "$search" = auto ]; then
  if [ -n "${EXA_API_KEY:-}" ]; then search=exa
  elif [ -n "${BRAVE_API_KEY:-}" ]; then search=brave
  else search=ddg; fellback=1
  fi
fi

mcp=/tmp/ccl-mcp.json
case "$search" in
  exa)
    [ -n "${EXA_API_KEY:-}" ] || { echo "CCL_SEARCH=exa needs EXA_API_KEY" >&2; exit 1; }
    jq -n --arg k "$EXA_API_KEY" \
      '{mcpServers:{search:{command:"exa-mcp-server",env:{EXA_API_KEY:$k}}}}' >"$mcp" ;;
  brave)
    [ -n "${BRAVE_API_KEY:-}" ] || { echo "CCL_SEARCH=brave needs BRAVE_API_KEY" >&2; exit 1; }
    jq -n --arg k "$BRAVE_API_KEY" \
      '{mcpServers:{search:{command:"brave-search-mcp-server",args:["--transport","stdio"],env:{BRAVE_API_KEY:$k}}}}' >"$mcp" ;;
  ddg)
    jq -n '{mcpServers:{search:{command:"duckduckgo-mcp-server"}}}' >"$mcp"
    if [ -n "$fellback" ] && [ -z "${CCL_QUIET:-}" ]; then
      cat >&2 <<'MSG'
[claude-code-lumen] Web search: DuckDuckGo (no API key; results are thinner and
  it rate-limits under heavy use). For better search, get a key and pass it in:
    Exa    https://dashboard.exa.ai/api-keys   -> EXA_API_KEY
    Brave  https://api-dashboard.search.brave.com -> BRAVE_API_KEY
  Set CCL_QUIET=1 to hide this note.
MSG
    fi ;;
  none) echo '{"mcpServers":{}}' >"$mcp" ;;
  *) echo "unknown CCL_SEARCH=$search (exa|brave|ddg|none)" >&2; exit 1 ;;
esac

# WebSearch is Anthropic's server-side tool: Lumen answers it with a 400, so it
# is denied here and the MCP server's search tool is what the model sees. The
# search tools are read-only and allowed without a prompt (headless -p runs
# would otherwise refuse them).
settings='{"permissions":{"deny":["WebSearch"],"allow":["mcp__search"]}}'
# Hooks are off by default: a project's (or a mounted home's) .claude/settings.json
# points hooks at host paths that do not exist in the container. CCL_HOOKS=1 keeps them.
if [ -z "${CCL_HOOKS:-}" ]; then
  settings=$(jq -c '. + {disableAllHooks: true}' <<<"$settings")
fi

exec claude --mcp-config "$mcp" --settings "$settings" "$@"
