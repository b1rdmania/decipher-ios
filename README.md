# Decipher iOS

Native Swift companion app for [Decipher](https://decipher-two.vercel.app) — speed language learning with FSRS spaced repetition and AI voice conversation.

Built with SwiftUI via Bitrig. Talks to the Decipher API over HTTPS; no backend code lives here.

- Auth: Privy (`privy-io/privy-ios`)
- Voice: LiveKit (`livekit/client-sdk-swift`), push-to-talk against the Decipher voice agent
- Bundle ID: `com.birdmania.decipher`, iOS 17+
