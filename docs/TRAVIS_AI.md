# Travis AI — Developer Guide

## What is Travis AI?

Travis AI is a virtual CTO assistant for the LongSang AI Empire. It provides:
- **79 tools** across 6 specialist domains
- Business intelligence, system monitoring, content strategy
- Powered by **Gemini 2.5 Flash** + **mem0** (memory) + **Supabase** (persistence)

## Architecture

```
┌─────────────────────────────────────────────────────┐
│             Travis AI Backend (Python)               │
│  https://travis-ai-9npn.onrender.com                │
│  Endpoints: /chat, /health, /stats, /history/:id    │
│             /alerts/pending, /sessions, /ws          │
└────────────┬────────────────────┬───────────────────┘
             │ REST               │ REST + WebSocket
             ▼                    ▼
┌────────────────────┐  ┌─────────────────────────────┐
│ Flutter (SABOHUB)  │  │ React (Admin + Nexus)        │
│ REST only          │  │ REST + WS + SSE streaming    │
│ Riverpod state     │  │                              │
└────────────────────┘  └─────────────────────────────┘
```

## Flutter Integration

### File Structure

```
lib/
├── models/
│   └── travis_message.dart              # TravisMessage, TravisHealth, TravisStats
├── services/
│   └── travis_service.dart              # REST client (singleton)
├── core/viewmodels/
│   └── travis_chat_view_model.dart      # TravisChatState + TravisChatViewModel
├── features/travis/
│   ├── constants/
│   │   └── travis_quick_actions.dart    # Shared quick action definitions
│   └── mixins/
│       └── travis_chat_mixin.dart       # Shared scroll/send behavior
├── pages/travis/
│   ├── travis_chat_page.dart            # Full-page chat (from route /travis)
│   └── travis_chat_tab.dart             # Embeddable tab (in CEO Utilities)
└── widgets/travis/
    └── travis_floating_chat.dart        # Floating overlay (for any page)
```

### How to Access Travis AI in the App

1. **CEO Utilities Tab**: Bottom nav → Tiện ích → Travis AI tab
2. **Navigation Drawer**: Open drawer → Travis AI (CEO-only)
3. **Direct Route**: Navigate to `/travis`
4. **Floating Widget**: Add `TravisFloatingChat()` to any page's Stack

### Configuration

Set the backend URL in your `.env` file:

```
TRAVIS_API_URL=https://travis-ai-9npn.onrender.com
```

Falls back to `https://travis-ai-9npn.onrender.com` if not set.

### Key Classes

| Class | File | Purpose |
|-------|------|---------|
| `TravisService` | `services/travis_service.dart` | Singleton REST client |
| `TravisChatViewModel` | `core/viewmodels/travis_chat_view_model.dart` | Riverpod ViewModel |
| `TravisChatState` | (same file) | Immutable chat state |
| `TravisMessage` | `models/travis_message.dart` | Chat message model |
| `TravisHealth` | (same file) | Health status model |
| `TravisQuickActions` | `features/travis/constants/` | Shared action definitions |
| `TravisChatMixin` | `features/travis/mixins/` | Shared scroll/send logic |

### Providers

```dart
// Travis service singleton
final travisServiceProvider = Provider<TravisService>((ref) => TravisService());

// Chat ViewModel
final travisChatViewModelProvider =
    AsyncNotifierProvider<TravisChatViewModel, TravisChatState>(
  TravisChatViewModel.new,
);
```

### Testing

```bash
# Run Travis-specific tests
flutter test test/models/travis_message_test.dart
flutter test test/services/travis_service_test.dart
flutter test test/core/viewmodels/travis_chat_state_test.dart
```

## React Integration (Admin Dashboard)

Files:
- `apps/admin/src/components/travis/TravisChat.tsx` — Floating chat widget
- `apps/admin/src/pages/TravisDashboardPage.tsx` — Full dashboard
- `apps/admin/src/services/travisService.ts` — Shared REST client

Config: Set `VITE_TRAVIS_API_URL` and `VITE_TRAVIS_WS_URL` in `.env`.

## Backend

- **Repo**: `github.com/longsangsabo2025/travis-ai`
- **Hosted**: Render.com (Singapore, Docker)
- **Stack**: Python, Gemini 2.5 Flash, mem0, Supabase, Telegram Bot
- **Local dev**: `python main.py` (port 8300)

### API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/chat` | Send message, get response |
| GET | `/health` | Health check + tools count |
| GET | `/stats` | Usage statistics |
| GET | `/history/:sessionId` | Conversation history |
| GET | `/alerts/pending` | Pending alerts |
| GET | `/sessions` | Recent sessions |
| WS | `/ws` | WebSocket real-time |
| GET | `/chat/stream` | SSE streaming |

### Request/Response Examples

**POST /chat:**
```json
// Request
{ "message": "Empire status", "session_id": "uuid-here" }

// Response
{
  "response": "Here's your empire status...",
  "specialist": "business_analyst",
  "confidence": 0.95,
  "tools_used": ["get_revenue", "get_users"],
  "latency_ms": 1200,
  "session_id": "uuid-here"
}
```

**GET /health:**
```json
{
  "status": "ok",
  "version": "v7.0",
  "total_tools": 79,
  "uptime_formatted": "2d 5h",
  "specialists": { "business_analyst": {"tools": 12}, "..." }
}
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Travis shows "Offline" | Check if Render service is awake (free tier sleeps after 15min) |
| First message slow | Render cold start ~30-60s, just wait |
| "TravisApiException: 429" | Rate limited, wait a moment |
| Empty response | Check backend logs on Render dashboard |
