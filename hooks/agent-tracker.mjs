#!/usr/bin/env node
// agent-tracker.mjs — Claude Code hook → Agent Office bridge (Windows-safe, no Python).
//
// Register in ~/.claude/settings.json for three events:
//   PreToolUse  (matcher "Agent|Task") → agent_task      (carries the description)
//   SubagentStart                      → agent_spawned   (real start, has agent_id)
//   SubagentStop                       → agent_completed (real finish, also for background agents)
//
// PostToolUse(Agent) is NOT used: for a background agent it fires at launch, not at finish.
// Always exits 0 and never blocks Claude Code, even when the office server is down.

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'

const SERVER_URL = 'http://127.0.0.1:3334/event'
const RUNTIME_DIR = join(homedir(), '.agent-office')

function readStdin() {
  try { return JSON.parse(readFileSync(0, 'utf8')) } catch { return null }
}

function toEvent(d) {
  switch (d.hook_event_name) {
    case 'PreToolUse': {
      if (d.tool_name !== 'Agent' && d.tool_name !== 'Task') return null
      const inp = d.tool_input ?? {}
      return {
        type: 'agent_task',
        agent: {
          role: inp.subagent_type || 'general-purpose',
          task: (inp.description || inp.prompt || '').slice(0, 80),
        },
      }
    }
    case 'SubagentStart':
      return { type: 'agent_spawned', agent: { id: `agent-${d.agent_id}`, role: d.agent_type || 'general-purpose' } }
    case 'SubagentStop':
      return {
        type: 'agent_completed',
        agentId: `agent-${d.agent_id}`,
        result: String(d.last_assistant_message || 'done').replace(/\s+/g, ' ').slice(0, 120),
      }
    default:
      return null
  }
}

async function main() {
  const d = readStdin()
  if (!d) return

  // Last raw payload per event, for debugging what Claude Code actually sends
  try {
    mkdirSync(RUNTIME_DIR, { recursive: true })
    writeFileSync(join(RUNTIME_DIR, `last-hook-${d.hook_event_name}.json`), JSON.stringify(d, null, 2))
  } catch {}

  const event = toEvent(d)
  if (!event) return

  let token = ''
  try { token = readFileSync(join(RUNTIME_DIR, 'auth-token'), 'utf8').trim() } catch {}

  try {
    await fetch(SERVER_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
      body: JSON.stringify(event),
      signal: AbortSignal.timeout(1000),
    })
  } catch {}  // office not running — ignore
}

main().finally(() => process.exit(0))
