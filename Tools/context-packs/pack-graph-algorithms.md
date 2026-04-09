# Context Pack: Graph Algorithms

**Domain:** Algorithms
**Topic:** Weighted directed graph construction and negative cycle detection
**Situation trigger:** Implementing or reviewing weighted graph construction or
  cycle detection using NetworkX or equivalent
**Validated by:** currency-arbitrage (PID-7KXNQ), sessions S20260314–S20260316

---

## Core model

**Log-transform for multiplicative chains**
When the domain involves multiplicative rate chains (conversion rates, cost
multipliers, probability chains), transform values into additive log-weights so
standard shortest-path algorithms apply:

```python
# A negative cycle sum means the product of values around the cycle exceeds 1.0
# exp(-cycle_sum) approximates the gain factor for the cycle
weight = log(forward_rate)       # forward traversal
weight = -log(reverse_rate)      # reverse traversal
```

The caller supplies the weight formula. The graph infrastructure is domain-agnostic.

**Graph structure for bidirectional relationships**
- Each key (relationship between two entities) produces two directed edges,
  one in each direction
- The weight formula may differ per direction — supply both via a `weight_fn(value, direction)` callable
- Edges carry: `weight` (float), the original key, and the direction label
- Nodes are the entities; edges are the relationships between them

---

## Bellman-Ford with NetworkX

```python
import networkx as nx

for source in list(graph.nodes):
    try:
        cycle = nx.find_negative_cycle(graph, source, weight="weight")
    except nx.NetworkXError:
        continue  # No negative cycle reachable from this source
```

**Deduplication:** The same cycle is found from multiple source nodes. Deduplicate
by rotating each cycle to its canonical form (start from the lexicographically
smallest node):

```python
def canonical(nodes):
    min_idx = nodes.index(min(nodes))
    return tuple(nodes[min_idx:] + nodes[:min_idx])
```

**Minimum cycle length:** Always filter cycles to `len(unique_nodes) >= N` where
N is the minimum meaningful cycle length for your domain (typically 3). A 2-node
cycle (A→B→A) can appear spuriously in synthetic test data — filter it out.

---

## Incremental updates

Do not rebuild the full graph on every value update. Update only the edges for
the changed key:

```python
def update_edges(key, value):
    node_a, node_b = parse_nodes(key)
    graph.add_edge(node_a, node_b, weight=weight_fn(value, "forward"), ...)
    graph.add_edge(node_b, node_a, weight=weight_fn(value, "reverse"), ...)
```

`graph.add_edge` overwrites existing edges — no need to remove first.

---

## High-precision revalidation

When edge weights use `float` arithmetic, always revalidate cycle candidates
using a higher-precision method (e.g. `Decimal`) before acting on them:

```python
# Bellman-Ford says this cycle is profitable — verify with exact arithmetic
precise_result = compute_exact(cycle, current_values)
if not precise_result.is_profitable():
    return None  # float said yes, exact arithmetic says no — discard
```

Float rounding can produce false positives for cycles very close to the
break-even threshold.

---

## Measurement: enumerate all cycles of minimum length

Bellman-Ford only reports *negative* cycles. When no anomaly exists, it returns
nothing — giving you no data on how close you are to the threshold. For
measurement purposes, always run a separate pass that enumerates all minimum-
length cycles and reports the best (least negative) sum:

```python
# For triangles (n=3): O(nodes^3) — acceptable for small graphs (~20 nodes)
best = float("inf")
for a in nodes:
    for b in successors(a):
        for c in successors(b):
            if c != a and has_edge(c, a):
                s = w(a,b) + w(b,c) + w(c,a)
                best = min(best, s)
```

This is essential when Phase N of a project measures "how close are we to the
threshold" rather than just "did we cross it."

---

## N-arity hardcoding — never do this

When a component handles N-step cycles, never hardcode cost or penalty
calculations for the minimum case:

```python
# WRONG — hardcoded for minimum cycle length of 3:
cost = 1 - (1 - per_step_cost) ** 3

# CORRECT — computed from actual cycle length:
n_steps = len(cycle_nodes)
cost = 1 - (1 - per_step_cost) ** n_steps
```

The minimum case is always the only case tested and always the wrong assumption
for a general component.

---

## Node selection for large graphs

When working with a large universe of possible edges, filter to a well-connected
subgraph before building:

1. Qualify nodes that meet a threshold in a reference dimension
2. Include edges only where **both** endpoints are qualified nodes
3. Be careful about unit denomination: if the threshold is in unit X, ensure
   the values being compared are also in unit X — mixed units silently exclude
   or include the wrong nodes

---

## Common mistakes

| Mistake | Consequence | Fix |
|---------|-------------|-----|
| No minimum cycle length filter | Short spurious cycles trigger false positives | Filter `len(unique_nodes) >= N` |
| No deduplication | Same cycle emitted multiple times | Canonical rotation + seen set |
| float-only validation | False positives near threshold | High-precision revalidation pass |
| Per-step cost hardcoded to minimum N | Wrong cost for longer cycles | Compute from `len(nodes)` |
| Measuring only negative cycles | No data when no anomaly exists | Enumerate all cycles separately |
| Mixed unit denomination in node filter | Wrong nodes excluded silently | Normalise to common unit before filtering |

---

## Source

- currency-arbitrage `app/graph/builder.py` — edge weight formulas
- currency-arbitrage `app/detection/engine.py` — Bellman-Ford, deduplication, revalidation
- currency-arbitrage `app/graph/symbols.py` — node selection
- currency-arbitrage `app/graph_analysis/` — generic WeightedGraphBuilder, NegativeCycleDetector
- Retrospectives: retro-001 (N-arity), retro-002 (measurement), retro-003 (node filter)
- ADR-003: Detection algorithm selection

## Registration

- Index entry required: `DFW/Tools/context-packs/README.md`
- Update this pack if NetworkX API changes or the generic graph module interfaces change.
