# Claude Code pointed at a Lumen server instead of api.anthropic.com, with web
# search provided by an MCP server (Lumen cannot run Anthropic's server-side
# web_search tool, so the built-in WebSearch is switched off in entrypoint.sh).
FROM node:22-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      git curl ca-certificates ripgrep less jq python3 procps \
    && rm -rf /var/lib/apt/lists/*

# uv runs the DuckDuckGo MCP server (a Python package).
COPY --from=ghcr.io/astral-sh/uv:0.8 /uv /uvx /usr/local/bin/

# Pinned: Lumen refuses unknown anthropic-beta values, and a newer Claude Code
# may send one. 2.1.284 passed scripts/anthropic_smoke.py on 2026-09-28.
ARG CC_VERSION=2.1.284
ARG EXA_MCP_VERSION=3.4.1
ARG BRAVE_MCP_VERSION=2.1.4
RUN npm install -g @anthropic-ai/claude-code@${CC_VERSION} \
      exa-mcp-server@${EXA_MCP_VERSION} \
      @brave/brave-search-mcp-server@${BRAVE_MCP_VERSION} \
    && npm cache clean --force

ARG DDG_MCP_VERSION=0.7.0
ENV UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin
RUN uv tool install duckduckgo-mcp-server==${DDG_MCP_VERSION}

COPY entrypoint.sh /usr/local/bin/ccl-entrypoint
WORKDIR /work
ENTRYPOINT ["ccl-entrypoint"]
