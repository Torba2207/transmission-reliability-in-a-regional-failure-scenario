"""Build the network topology shown in topology/topologie sieci/C3.jpg.

The graph is reconstructed from the image: 17 nodes connected by
undirected links. Node coordinates roughly match the drawing so the
generated layout can be compared against the original picture.
"""

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
    print(f"Diameter: {nx.diameter(G)}")
    print(f"Radius: {nx.radius(G)}")

    src, dst = 1, 17
    route, hops = primary_route(G, src, dst)
    print(f"Primary route {src} -> {dst}: {route} ({hops} hops)")
    G_copy = nx.Graph(G)  # Make a copy to avoid modifying the original graph.
    draw_graph(G_copy, filename="topology_copy.png")
    draw_graph(G, filename="topology_original.png")
