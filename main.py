"""Build the network topology shown in topology/topologie sieci/C3.jpg.

The graph is reconstructed from the image: 17 nodes connected by
undirected links. Node coordinates roughly match the drawing so the
generated layout can be compared against the original picture.
"""

import math

import networkx as nx


# Edges traced from C3.jpg (undirected links between numbered nodes).
EDGES = [
    (1, 2), (1, 3), (1, 4),
    (2, 6), (2, 7),
    (3, 5), (3, 9),
    (4, 5), (4, 6), (4, 8),
    (5, 8), (5, 12),
    (6, 7), (6, 8), (6, 11),
    (7, 11), (7, 13),
    (8, 10), (8, 12),
    (9, 12), (9, 15),
    (10, 11), (10, 12), (10, 14),
    (11, 13), (11, 14), (11, 16),
    (12, 14), (12, 15),
    (13, 16),
    (14, 17),
    (15, 17),
    (16, 17),
]

# Approximate node positions matching the layout in C3.jpg (x right, y up).
POSITIONS = {
    1: (0.5, 4.5), 2: (1.5, 7.5), 3: (1.8, 1.5), 4: (2.3, 4.5),
    5: (3.7, 2.5), 6: (4.0, 6.7), 7: (4.3, 9.5), 8: (4.2, 5.0),
    9: (5.2, 0.5), 10: (6.1, 4.3), 11: (6.4, 6.8), 12: (6.5, 2.3),
    13: (7.0, 9.6), 14: (7.8, 4.5), 15: (8.8, 1.8), 16: (9.2, 7.7),
    17: (9.6, 4.6),
}


def build_graph() -> nx.Graph:
    """Return the topology from C3.jpg as a networkx Graph."""
    graph = nx.Graph()
    graph.add_nodes_from(POSITIONS)
    graph.add_edges_from(EDGES)
    return graph


def primary_route(graph: nx.Graph, source, target, weight=None):
    """Return the primary route (shortest path) between two end nodes.

    Returns a tuple ``(path, length)`` where ``path`` is the list of nodes
    from ``source`` to ``target`` and ``length`` is the number of hops
    (or the summed edge weight when ``weight`` is given).

    Raises ``networkx.NetworkXNoPath`` if the nodes are disconnected.
    """
    path = nx.shortest_path(graph, source, target, weight=weight)
    length = nx.shortest_path_length(graph, source, target, weight=weight)
    return path, length


def euclidean(positions, a, b) -> float:
    """Euclidean distance between two nodes given their coordinates."""
    (ax, ay), (bx, by) = positions[a], positions[b]
    return math.hypot(ax - bx, ay - by)


def geographic_diameter(positions):
    """Largest Euclidean distance between any two nodes (the geographic diameter).

    Returns ``(distance, (node_a, node_b))``. The disaster radii are defined
    as percentages of this value.
    """
    nodes = list(positions)
    best, pair = 0.0, (None, None)
    for i, u in enumerate(nodes):
        for v in nodes[i + 1:]:
            dist = euclidean(positions, u, v)
            if dist > best:
                best, pair = dist, (u, v)
    return best, pair


def failure_zone(positions, epicenter, radius):
    """Return the set of failed nodes for a regional failure (step 3).

    The disaster area is modelled as a circle (disk) of the given ``radius``
    centred on the ``epicenter``: every node whose Euclidean distance to the
    epicenter is within the radius is destroyed. The radius is a fraction of
    the geographic network diameter.
    """
    return {
        node for node in positions
        if euclidean(positions, epicenter, node) <= radius
    }


def route_collides(route, failed_nodes) -> bool:
    """True if any node on the route belongs to the failure zone."""
    return bool(set(route) & set(failed_nodes))


def residual_graph(graph: nx.Graph, failed_nodes, primary) -> nx.Graph:
    """Graph with failed nodes and the primary route's intermediate nodes removed.

    Removing the primary's intermediate nodes guarantees that any path found
    in the residual graph is node-disjoint from the primary route. The end
    nodes (first/last of ``primary``) are kept so a backup can still start
    and terminate there.
    """
    intermediates = set(primary[1:-1])
    residual = graph.copy()
    residual.remove_nodes_from(set(failed_nodes) | intermediates)
    return residual


def protection_route(graph, source, target, primary, failed_nodes, weight=None):
    """Try to find a node-disjoint backup route avoiding the failure zone (step 4).

    Builds the residual graph and verifies connectivity with ``nx.has_path``.
    Returns the backup path (list of nodes) or ``None`` if no such route
    exists -- e.g. when an end node itself failed or the residual graph is
    disconnected.
    """
    residual = residual_graph(graph, failed_nodes, primary)
    if source not in residual or target not in residual:
        return None
    if not nx.has_path(residual, source, target):
        return None
    return nx.shortest_path(residual, source, target, weight=weight)


FRACTIONS = (0.05, 0.10, 0.15, 0.25, 0.30)


def analyze(graph, positions, fractions=FRACTIONS, weight=None):
    """Regional-failure transmission-reliability analysis (steps 1-4).

    For each disaster radius (a fraction of the geographic network diameter),
    each epicenter (every node in turn) and each end-node demand pair, the
    routine:

      * determines the primary route with Dijkstra's algorithm,
      * builds the failure zone (circular disk of the radius around the
        epicenter),
      * counts the route as *needing protection* when its nodes collide with
        the failure zone, and
      * counts it as *protectable* when a node-disjoint protection route
        survives the disaster.

    Returns ``{fraction: stats}`` with averaged results per radius.
    """
    diameter, _ = geographic_diameter(positions)
    nodes = list(graph.nodes)
    demands = [(s, t) for i, s in enumerate(nodes) for t in nodes[i + 1:]]

    # Primary routes are independent of the disaster, so compute them once.
    primaries = {
        (s, t): nx.shortest_path(graph, s, t, weight=weight) for s, t in demands
    }

    summary = {}
    for frac in fractions:
        radius = frac * diameter
        total = need = protectable = 0
        for epicenter in nodes:
            failed = failure_zone(positions, epicenter, radius)
            for (s, t), primary in primaries.items():
                total += 1
                if not route_collides(primary, failed):
                    continue  # primary survives -> no protection needed
                need += 1
                if protection_route(graph, s, t, primary, failed, weight):
                    protectable += 1
        summary[frac] = {
            "radius": radius,
            "scenarios": total,
            "need_protection": need,
            "protectable": protectable,
            "pct_need": 100 * need / total if total else 0.0,
            "pct_protectable": 100 * protectable / need if need else 0.0,
        }
    return summary


def print_summary(summary, diameter):
    """Print the averaged results table broken down by radius."""
    print(f"\nGeographic network diameter: {diameter:.3f}")
    print("\n  r [% diam]   radius   need protection   protectable (of those)")
    print("  " + "-" * 62)
    for frac, s in summary.items():
        print(
            f"  {int(frac * 100):>6}%   {s['radius']:6.2f}"
            f"   {s['pct_need']:13.1f}%   {s['pct_protectable']:20.1f}%"
        )


def plot_summary(summary, filename="reliability.png"):
    """Bar chart of the two key percentages per radius."""
    import matplotlib.pyplot as plt

    fracs = list(summary)
    labels = [f"{int(f * 100)}%" for f in fracs]
    need = [summary[f]["pct_need"] for f in fracs]
    prot = [summary[f]["pct_protectable"] for f in fracs]
    x = range(len(fracs))
    width = 0.38

    plt.figure(figsize=(8, 5))
    plt.bar([i - width / 2 for i in x], need, width, label="need protection")
    plt.bar([i + width / 2 for i in x], prot, width, label="protectable (of those)")
    plt.xticks(list(x), labels)
    plt.xlabel("disaster radius (% of geographic diameter)")
    plt.ylabel("percentage of primary routes")
    plt.title("Transmission reliability under regional failures")
    plt.ylim(0, 100)
    plt.legend()
    plt.grid(axis="y", alpha=0.3)
    plt.savefig(filename, dpi=150, bbox_inches="tight")
    print(f"Saved chart to {filename}")


def draw_graph(graph: nx.Graph, filename: str = "topology.png") -> None:
    """Render the graph to a PNG using the picture's layout."""
    import matplotlib.pyplot as plt

    plt.figure(figsize=(10, 8))
    nx.draw(
        graph,
        pos=POSITIONS,
        with_labels=True,
        node_color="white",
        edgecolors="black",
        node_size=700,
        font_weight="bold",
    )
    plt.savefig(filename, dpi=150, bbox_inches="tight")
    print(f"Saved drawing to {filename}")


if __name__ == "__main__":
    G = build_graph()
    print(f"Nodes: {G.number_of_nodes()}")
    print(f"Edges: {G.number_of_edges()}")
    print(f"Connected: {nx.is_connected(G)}")

    # (1) Network diameter: graph (hops) and geographic (used for disk radii).
    print(f"Graph diameter (hops): {nx.diameter(G)}")
    geo_diam, geo_pair = geographic_diameter(POSITIONS)
    print(f"Geographic diameter: {geo_diam:.3f} (between nodes {geo_pair})")

    # (2) Primary route for an example end-node pair (Dijkstra).
    src, dst = 1, 17
    route, hops = primary_route(G, src, dst)
    print(f"Primary route {src} -> {dst}: {route} ({hops} hops)")

    # (3)+(4) Regional-failure protection analysis, averaged per radius.
    summary = analyze(G, POSITIONS)
    print_summary(summary, geo_diam)
    plot_summary(summary)
