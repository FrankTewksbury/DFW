# Context Pack: Python Testing

**Domain:** Python
**Topic:** pytest test design, fixture patterns, and test quality conventions
**Situation trigger:** Writing pytest tests, designing test fixtures, or reviewing
  test coverage
**Validated by:** currency-arbitrage (PID-7KXNQ), 87 tests across 7 files,
  sessions S20260314–S20260316

---

## Core principles

**Test behaviour, not implementation**
Tests verify observable outputs given inputs. They do not inspect internal state,
private attributes, or implementation details. If a refactor changes an internal
data structure but keeps the public API identical, zero tests should break.

**Deterministic time**
Never let tests depend on wall-clock time or `time.monotonic()`. Add a `now`
parameter to any function that does freshness or staleness calculations:

```python
def stale_keys(self, max_age_ms: float, now: float | None = None) -> list[str]:
    now = now or time.monotonic()
    ...
```

In tests, pass a fixed `now` value. All time-dependent tests become deterministic
and never flake due to test execution speed.

**No network calls in unit tests**
Unit tests must never make live HTTP, WebSocket, or database connections. Use
fixtures, mocks (`unittest.mock.MagicMock`), and synthetic data. Integration
tests that require live connections are a separate test suite.

---

## Fixture design

**Shared JSON fixtures for realistic data**
Maintain a JSON fixture file matching real external data structure. All test
files that need realistic data load from the same fixture — one source of truth:

```python
FIXTURE_PATH = Path(__file__).parent / "fixtures" / "sample_data.json"

@pytest.fixture
def fixture_data() -> dict:
    return json.loads(FIXTURE_PATH.read_text())
```

**Synthetic fixtures for generic module tests**
For domain-agnostic components, use simple synthetic data — strings, floats,
tuples. Do not import domain fixtures into tests for generic components. This
keeps generic modules truly independent of domain changes.

**Domain invariants in synthetic data**
Synthetic test data must preserve all real-world constraints the code implicitly
assumes. Violating these constraints creates unexpected code paths that obscure
what is actually being tested.

Examples of constraints to preserve:
- Ordered pairs: if the domain assumes A < B, synthetic data must also have A < B
- Monotonic sequences: if timestamps must increase, synthetic timestamps must too
- Graph structure: if the algorithm assumes no self-loops, synthetic graphs must not have them

If a violation is intentional (to test an edge case), document it explicitly:
```python
# Intentional: testing the filter that rejects invalid data
event = StreamEvent(key="x", value=-1, timestamp=1000.0)  # negative value — tests rejection path
```

---

## Asymmetric weight functions in graph tests

When testing a weighted graph module with bidirectional edges, use asymmetric
weights to control the sign of cycles independently:

```python
# WRONG — symmetric weights always produce a negative cycle in the reverse direction:
weight_fn = lambda v, d: v if d == "forward" else -v
# reverse triangle: (-v) + (-v) + (-v) = always negative

# CORRECT — tuple gives independent control over each direction:
def weight_fn(v, direction):
    forward_w, reverse_w = v  # value is a (forward, reverse) tuple
    return forward_w if direction == "forward" else reverse_w

# Positive graph:  all edges (2.0, 2.0)  → every triangle sum = +6.0
# Negative graph:  edges   (2.0, -2.0)   → reverse triangle sum = -6.0
```

This pattern is essential whenever you need to test both "no anomaly found"
and "anomaly found" paths in the same test suite.

---

## Test structure

**Build order mirrors dependency order**
Write tests in the same order components were built. Each test file can assume
the components tested by earlier files are working correctly.

**Gate logic tests**
For components with multiple gates (debounce, health check, staleness), test
each gate in isolation — one test per gate, with all other gates passing.

**Test counters and callbacks explicitly**

```python
def test_tick_counter(engine):
    engine.on_tick(now=1000.05)
    engine.on_tick(now=1000.10)
    assert engine.ticks_processed == 2

def test_callback_invoked(engine, captured_events):
    engine.on_tick(now=1000.05)
    assert len(captured_events) == 1
```

---

## Baseline-first rule

Before making any changes to an existing codebase, run the full test suite and
confirm it is green. This is Step 0 — not optional:

1. Confirms the starting state is valid
2. Catches handoff inaccuracies before you build on top of them
3. Makes regressions introduced by your changes unambiguous

---

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| `time.monotonic()` hardcoded in logic | Flaky tests, data always appears stale | Add `now` parameter |
| Symmetric weights in graph tests | "No anomaly" case always has a negative cycle | Use asymmetric tuple weights |
| Live network calls in unit tests | Slow, flaky, environment-dependent | Mock or fixture everything |
| Domain fixtures in generic module tests | Generic tests break on domain changes | Use synthetic data |
| Testing internal state (`_field`) | Tests break on valid internal refactors | Test public interface only |
| Violated domain invariants in synthetic data | Unexpected code paths obscure test intent | Document or fix all invariant violations |
| Skipping baseline run | Can't distinguish pre-existing failures from regressions | Always run tests first |

---

## Source

- currency-arbitrage `tests/` — 87 tests across 7 files
- currency-arbitrage `tests/fixtures/sample_bookticker.json` — shared domain fixture
- currency-arbitrage `tests/test_graph_analysis.py` — asymmetric weight function pattern
- Retrospectives: retro-001 (synthetic data invariants), retro-004 (baseline-first)
- Handoff: 2026-03-16-modularisation-integration-complete.md (asymmetric weight mistake)

## Registration

- Index entry required: `DFW/Tools/context-packs/README.md`
- Update this pack when new testing patterns are validated across projects.
