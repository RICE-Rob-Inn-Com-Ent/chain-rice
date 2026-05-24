//! Module dependency graph — topological order, cycle detection, dead-code reachability.

// TODO(mint):
// [ ] CLERK / base — cryptographic & policy correctness; no UI.
// [ ] Soft-code: env + workspace Cargo features; never hardcode chain or tenant IDs.
// [ ] Contracts: cosmwasm / proto from infra/schemas/ via MASON.
// [ ] Stack surface: tokio, cosmwasm-std, serde, thiserror, k256, arkworks, etc. — extend per crate purpose.
//
use petgraph::algo::is_cyclic_directed;
use petgraph::graph::DiGraph;
use petgraph::visit::Topo;

// [ ] https://docs.rs/petgraph/
// [ ] cycle detection; toposort; dead code; CLERK_MINT_PARALLEL_BATCH

pub type ModuleGraph = DiGraph<String, ()>;

pub fn topo_sort(graph: &ModuleGraph) -> Option<Vec<petgraph::prelude::NodeIndex>> {
    let mut topo = Topo::new(graph);
    let mut out = Vec::new();
    while let Some(n) = topo.next(graph) {
        out.push(n);
    }
    Some(out)
}

pub fn has_cycle(graph: &ModuleGraph) -> bool {
    is_cyclic_directed(graph)
}
