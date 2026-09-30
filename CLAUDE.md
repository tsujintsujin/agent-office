# CLAUDE.md — Agent Office

Pixel-art office that shows Justin's Claude Code agents working, live. Fork of
[W17ant/Claude-Office](https://github.com/W17ant/Claude-Office) (MIT), adapted
for Windows and for Justin's own agents. Repo: `tsujintsujin/agent-office`
(private); upstream stays as the `upstream` remote. **Local only**: the server
binds to 127.0.0.1, nothing is deployed.

## Who is in the office (Justin's call — do not widen)
- **Claude** (the main session) is always in.
- Only these agents appear: **Rose, Priya, Dianne, Bella, Queenie, Ruby, Jeff**
  (`office.roster.json`). Every other agent type is ignored by the server.
- **No boss character for Justin** — he asked to be left out. What he types in
  the chat box still posts under his name (`office.config.json`, gitignored).

## How it works
Claude Code hooks → `hooks/agent-tracker.mjs` → `POST 127.0.0.1:3334/event`
(Bearer token from `~/.agent-office/auth-token`) → `server/index.js` →
WebSocket → React page on `localhost:3333`.
- Hooks registered in `~/.claude/settings.json`: `PreToolUse` (matcher
  `Agent|Task`, carries the task description), `SubagentStart`,
  `SubagentStop`. Not `PostToolUse` — for background agents it fires at launch.
- `SubagentStop` fires more than once per agent; the server handles the first.
- Last raw hook payloads: `~/.agent-office/last-hook-<Event>.json`.
- Sprites: roster `sprite` is a base in `public/sprites/characters/` or a path
  under `public/sprites/` (the 27 Office cast sets live in `office/characters/`).

## Running
- Starts at login via `Startup\Agent Office.lnk` → `scripts/start-office-windows.ps1`
  (hidden: server, Vite UI, chat watcher). Stop: `start-office-windows.ps1 -Stop`.
  Re-create / remove the shortcut: `scripts/install-startup-windows.ps1 [-Remove]`.
- Dev: `preview_start agent-office` (workspace `.claude/launch.json`), then open
  `localhost:3333` in real Chrome. The page animates only when its tab is in
  front — Chrome pauses animation in background tabs.
- Logs: `~/.agent-office/*.log`.

## Chat AI (toggle in the UI, default OFF)
`scripts/chat-ai-watcher.sh` runs `claude -p` for each message Justin types —
that uses his Claude plan. It ignores agent announcements. It needs the npm
`claude` CLI to be signed in (it was expired on 2026-09-30).

## Gates
`npx tsc --noEmit` and `npm run build`. Anything visible gets checked in real
Chrome with the tab in front.

## Known limits
- Fixed ~720px desktop layout: does not fit a phone (not reachable from one anyway).
- `/the-office` in the chat swaps to the Dunder Mifflin theme and random cast.
