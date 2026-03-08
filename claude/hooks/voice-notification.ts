#!/usr/bin/env bun
/**
 * Voice Notification Hook — Notification + Stop events
 * Speaks via ElevenLabs TTS, falls back to macOS Notification Center.
 *
 * Environment variables:
 *   ELEVENLABS_API_KEY  — Required for voice. Falls back to macOS notification without it.
 *   ELEVENLABS_VOICE_ID — Optional. Defaults to Rachel (21m00Tcm4TlvDq8ikWAM).
 *
 * Setup in ~/.claude/settings.json:
 * {
 *   "hooks": {
 *     "Notification": [{
 *       "hooks": [{ "type": "command", "command": "bun ~/.claude/hooks/voice-notification.ts" }]
 *     }],
 *     "Stop": [{
 *       "hooks": [{ "type": "command", "command": "bun ~/.claude/hooks/voice-notification.ts", "timeout": 15 }]
 *     }]
 *   }
 * }
 */

import { tmpdir } from "os";
import { join } from "path";
import { unlink, stat } from "fs/promises";

interface HookInput {
  hook_event_name: string;
  session_id?: string;
  cwd?: string;
  permission_mode?: string;
  // Notification fields
  message?: string;
  title?: string;
  notification_type?: string;
  // Stop fields
  stop_hook_active?: boolean;
  last_assistant_message?: string;
}

const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY || "";
const VOICE_ID = process.env.ELEVENLABS_VOICE_ID || "21m00Tcm4TlvDq8ikWAM"; // Rachel
const LOCK_FILE = join(tmpdir(), "claude-voice-notify.lock");
const DEBOUNCE_MS = 5000;

function getMessage(event: string): string {
  switch (event) {
    case "Notification":
      return "Your agent needs input";
    case "Stop":
      return "Task complete";
    default:
      return "";
  }
}

async function isDebounced(): Promise<boolean> {
  try {
    const s = await stat(LOCK_FILE);
    return Date.now() - s.mtimeMs < DEBOUNCE_MS;
  } catch {
    return false;
  }
}

async function touchLock(): Promise<void> {
  await Bun.write(LOCK_FILE, String(Date.now()));
}

async function speakElevenLabs(text: string): Promise<boolean> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10_000);

  try {
    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}?output_format=mp3_44100_128`,
      {
        method: "POST",
        headers: {
          "xi-api-key": ELEVENLABS_API_KEY,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          text,
          model_id: "eleven_flash_v2_5",
        }),
        signal: controller.signal,
      }
    );

    if (!response.ok) return false;

    const tempPath = join(tmpdir(), `claude-notify-${Date.now()}.mp3`);
    await Bun.write(tempPath, response);

    const proc = Bun.spawn(["afplay", tempPath], { stderr: "ignore" });
    await proc.exited;

    await unlink(tempPath).catch(() => {});
    return true;
  } catch {
    return false;
  } finally {
    clearTimeout(timeout);
  }
}

async function notifyMacOS(text: string): Promise<void> {
  Bun.spawn([
    "osascript",
    "-e",
    `display notification "${text}" with title "Claude Code" sound name "Glass"`,
  ]);
}

async function main(): Promise<void> {
  let input = "";
  for await (const chunk of process.stdin) input += chunk;

  try {
    const data: HookInput = JSON.parse(input);
    const event = data.hook_event_name;

    // Only handle Notification and Stop events
    if (event !== "Notification" && event !== "Stop") {
      return console.log("{}");
    }

    // Prevent infinite loops on Stop
    if (event === "Stop" && data.stop_hook_active) {
      return console.log("{}");
    }

    // Debounce
    if (await isDebounced()) {
      return console.log("{}");
    }

    const message = getMessage(event);
    if (!message) return console.log("{}");

    await touchLock();

    // Try ElevenLabs, fall back to macOS notification
    if (ELEVENLABS_API_KEY) {
      const ok = await speakElevenLabs(message);
      if (!ok) await notifyMacOS(message);
    } else {
      await notifyMacOS(message);
    }

    console.log("{}");
  } catch {
    console.log("{}");
  }
}

if (import.meta.main) {
  main();
}
