# Transmission reliability in a regional failure scenario

Simulation study of network transmission reliability under **regional (areal) mass
failures** — disasters that simultaneously destroy all network elements inside a
geographic area, modelled as a circle of radius *r*.

University project (Niezawodność systemów sieciowych, PG WETI, temat 3). The accompanying
report is in [`docs/raport.typ`](docs/raport.typ) / `docs/raport.pdf` (Polish).

## Problem

For the assigned network topology the simulation:

1. computes the network diameter,
2. determines the primary route for end-node pairs using Dijkstra's algorithm,
3. generates failure scenarios — for every node as epicenter and every radius
   *r* ∈ {5%, 10%, 15%, 25%, 30%} of the geographic diameter — and
4. checks, for each affected primary route, whether a **node-disjoint protection route**
   surviving the disaster can be found.

The failure zone is a geometric disk: a node fails when its Euclidean distance to the
epicenter is ≤ *r*.

## Topology

The graph (17 nodes, 33 undirected edges) is reconstructed from
`topology/topologie sieci/C3.jpg`. Node coordinates are hand-estimated from the image and
used both for drawing and for the geometric failure model.

![Topology](topology.png)

## Setup

```bash
python -m venv .venv
source .venv/bin/activate          # fish: source .venv/bin/activate.fish
pip install -r requirements.txt
```

Dependencies: `networkx`, `matplotlib`.

## Usage

```bash
python main.py
```

This prints the diameters, an example primary route and the per-radius results table, and
writes two figures: `topology.png` (network drawing) and `reliability.png` (results chart).

### Key functions in `main.py`

| Function | Purpose |
|----------|---------|
| `build_graph()` | build the topology as an `nx.Graph` |
| `primary_route(G, s, t)` | shortest path (Dijkstra) for an end-node pair |
| `geographic_diameter(pos)` | max Euclidean distance between nodes |
| `failure_zone(pos, epicenter, r)` | nodes inside the disaster disk |
| `residual_graph(G, failed, primary)` | graph with failed + primary-transit nodes removed |
| `protection_route(...)` | node-disjoint backup route surviving the disaster |
| `analyze(G, pos)` | full study, averaged per radius |

## Results

Averaged over all 17 epicenters × 136 node pairs (geographic diameter ≈ 9.65):

| r (% of diameter) | need protection | protectable (of those) |
|------------------:|----------------:|-----------------------:|
| 5%  | 19.1% | 38.3% |
| 10% | 19.1% | 38.3% |
| 15% | 19.1% | 38.3% |
| 25% | 35.7% | 28.5% |
| 30% | 51.3% | 20.1% |

Larger disaster areas hit more primary routes and make protection harder. The 5–15% rows
coincide because the closest two nodes are farther apart than 15% of the diameter, so those
disks only catch the epicenter.

## Report

```bash
typst compile --root . docs/raport.typ docs/raport.pdf
```

The `--root .` flag is required because the report embeds figures from the project root.

## Project layout

```
main.py              # simulation
requirements.txt     # dependencies
topology/            # source topology image (C3.jpg)
docs/                # report (raport.typ/pdf) and task brief
topology.png         # generated network drawing
reliability.png      # generated results chart
```
