# Context Pack: Python Async

**Domain:** Python
**Topic:** Async programming with asyncio, aiohttp, and websockets
**Situation trigger:** Writing or reviewing async Python code
**Validated by:** currency-arbitrage (PID-7KXNQ), sessions S20260314–S20260316

---

## Core patterns

**aiohttp ClientSession lifecycle**
- Create one session per logical connection scope, not per request
- Always use `async with` or explicitly call `await session.close()`
- On Windows, `aiohttp` uses `aiodns` by default which cannot contact system
  DNS servers. Always use `ThreadedResolver` on Windows:
  ```python
  connector = aiohttp.TCPConnector(resolver=aiohttp.ThreadedResolver())
  session = aiohttp.ClientSession(connector=connector)
  ```
- If a class creates its own session internally (e.g. in `connect()`), it must
  also apply the resolver fix — not just the top-level entry point

**WebSocket lifecycle**
- Connect → subscribe → stream → ping-on-idle → disconnect
- Always send a subscription message immediately after connect before reading
- Implement a ping monitor: if no messages received within N seconds, send a
  ping to detect silent disconnects before the OS-level TCP timeout fires
- On disconnect, set a `suspended` flag immediately — do not wait for the
  reconnect to succeed before stopping downstream processing

**Backoff reconnect**
- Use a schedule, not exponential: `[5, 10, 30, 60, 60]` seconds
- Cap consecutive failures — after N failures switch to a periodic health check
  rather than hammering the server
- On successful reconnect, always reseed local state from a snapshot before
  resuming streaming — the stream may have missed updates during the gap

---

## Concurrency patterns

**Async generator feeds**
- Use `AsyncIterator` return type for streaming sources
- Yield events from the generator; let the caller own the loop
- Keep the generator thin — put processing logic in the caller, not the generator

**Background tasks**
- Use `asyncio.create_task()` for recurring background loops (ping, health check)
- Cancel background tasks explicitly in `stop()` / `disconnect()` —
  do not rely on garbage collection
- Check `task.done()` before cancelling to avoid `CancelledError` on
  already-finished tasks

**Deterministic testing**
- Never call `time.monotonic()` directly inside logic you want to test
- Add a `now: float | None = None` parameter; default to `time.monotonic()` in
  production, pass a fixed value in tests
- All freshness and staleness logic must go through this parameter

---

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| Default aiohttp resolver on Windows | `aiodns.error.DNSError: Could not contact DNS servers` | Use `ThreadedResolver` |
| Creating session per request | Session/connector leak, performance degradation | One session per connection scope |
| Not setting suspended flag on disconnect | Downstream processing continues on stale data | Set flag before reconnect loop |
| `time.monotonic()` hardcoded in logic | Tests always see data as stale | Add `now` parameter |
| Not cancelling background tasks | Tasks linger after shutdown, may raise errors | Cancel in `stop()` explicitly |

---

## Source

- currency-arbitrage `app/feed/kraken_ws.py` — WebSocket lifecycle
- currency-arbitrage `app/feed/kraken_rest.py` — REST session + ThreadedResolver
- currency-arbitrage `app/connection/manager.py` — backoff, suspended flag, ping loop
- currency-arbitrage `app/detection/engine.py` — deterministic time parameter
- Retrospectives: retro-003 (DNS fix), session S20260314 debugging notes

## Registration

- Index entry required: `DFW/Tools/context-packs/README.md`
- Update this pack if aiohttp or websockets library behaviour changes significantly.
