# Decipher iOS — agent instructions

Native SwiftUI app for Decipher (speed language learning). This repo is iOS-only; the backend is the existing production API at `https://decipher-two.vercel.app` and must not be reimplemented here.

## Project constants

- Bundle ID: `com.birdmania.decipher`, iOS 17+, SwiftUI
- Auth: Privy — SPM package `https://github.com/privy-io/privy-ios`
- Voice: LiveKit — SPM package `https://github.com/livekit/client-sdk-swift`
- Mic usage description is required (voice conversation feature)

## API contract (do not guess endpoints — these are verified against the backend)

Every request sends `Authorization: Bearer <privy access token>` (fetched fresh from the Privy SDK per request; it handles refresh). No cookies.

| Endpoint | Method | Body | Returns |
|---|---|---|---|
| `/api/speak/session/start` | POST | `{"scenarioType": <slug>, "mode": "guided"}` | `{ok, session: {id, ...}, livekit: {url, token, roomName}}` |
| `/api/speak/session/end` | POST | `{"sessionId", "durationSec"}` | session summary |
| `/api/vocab/rate` | POST | `{"vocabId", "rating": 1-4}` | FSRS review update (Again/Hard/Good/Easy) |
| `/api/vocab/learn` | POST | `{"vocabId", "confidence": 1-3}` | graduate a new word |
| `/api/vocab/scan` | POST | `{"wordIds": []}` | `{ok, count, xpGain}` |

Error handling: 401 → re-authenticate with Privy; 403 → account blocked, show message; 429 → monthly token budget exceeded, show message. Surface these as human-readable states, never raw errors.

Scenario slugs (hardcode, same as web): `struggle_bus`, `ordering_coffee`, `meeting_someone`, `shopping`, `asking_directions`, `restaurant`.

## LiveKit voice protocol (push-to-talk — the agent expects exactly this)

All data messages are JSON text sent with `reliable: true`. The remote agent joins the room and speaks first — subscribe to and play remote audio tracks.

1. After connecting: enable + publish the microphone track, then immediately **mute** it, then send `{"type": "mic_ready", "hasMicPublication": true, "trackSid": <mic track sid>}`
2. Hold-to-talk press: unmute the mic track, send `{"type": "ptt_press", "hasMicPublication": true}`
3. Release: mute the mic track, send `{"type": "ptt_release"}` — the agent discards very short holds, so debounce accidental taps in the UI
4. The agent also publishes debug-stage data messages; ignore them.

On hangup or app background: POST `/api/speak/session/end` with the `session.id` from start and elapsed seconds.

## Conventions

- Plain SwiftUI + URLSession; no third-party networking, DI, or architecture frameworks beyond the two SDKs above.
- Dark theme first.
- Keep views small; API client in one file (`DecipherAPI.swift`).
- Commit messages: short imperative subject lines.

## Roadmap context

Phase 0 (current): Privy login → start session → LiveKit voice loop with push-to-talk. This is a proof-of-integration; keep it minimal.
Phase 1: scenario grid, session lifecycle polish, error states.
Phase 2: FSRS flashcards (blocked on new backend read endpoints — do not invent `/api/vocab/due` etc.; they don't exist yet).
Phase 3: WidgetKit + Live Activities for streaks and due cards.
