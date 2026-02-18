"use client";

import { useState, useEffect } from "react";
import { Play, Save, Trash2, Plus, Settings, Workflow } from "lucide-react";
import Link from "next/link";

type Workflow = {
  id: string;
  name: string;
  description: string;
  nodes: any[];
  edges: any[];
  status: "active" | "inactive";
};

export default function LangChainPage() {
  const [workflows, setWorkflows] = useState<Workflow[]>([]);
  const [selectedWorkflow, setSelectedWorkflow] = useState<Workflow | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadWorkflows();
  }, []);

  const loadWorkflows = async () => {
    try {
      setLoading(true);
      const response = await fetch("/api/cerai/langchain/workflows");
      if (!response.ok) {
        throw new Error("Failed to load workflows");
      }
      const data = await response.json();
      setWorkflows(data.workflows || []);
    } catch (error) {
      console.error("Error loading workflows:", error);
      // Fallback to empty array on error
      setWorkflows([]);
    } finally {
      setLoading(false);
    }
  };

  const createWorkflow = async () => {
    try {
      const response = await fetch("/api/cerai/langchain/workflows", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: "New Workflow",
          description: "Nowy workflow",
          nodes: [],
          edges: [],
          status: "inactive",
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to create workflow");
      }

      await loadWorkflows();
    } catch (error) {
      console.error("Error creating workflow:", error);
      alert("Błąd podczas tworzenia workflow");
    }
  };

  const updateWorkflow = async (workflow: Workflow) => {
    try {
      const response = await fetch(`/api/cerai/langchain/workflows/${workflow.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: workflow.name,
          description: workflow.description,
          nodes: workflow.nodes,
          edges: workflow.edges,
          status: workflow.status,
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to update workflow");
      }

      await loadWorkflows();
      alert("Workflow zaktualizowany!");
    } catch (error) {
      console.error("Error updating workflow:", error);
      alert("Błąd podczas aktualizacji workflow");
    }
  };

  const deleteWorkflow = async (workflowId: string) => {
    if (!confirm("Czy na pewno chcesz usunąć ten workflow?")) {
      return;
    }

    try {
      const response = await fetch(`/api/cerai/langchain/workflows/${workflowId}`, {
        method: "DELETE",
      });

      if (!response.ok) {
        throw new Error("Failed to delete workflow");
      }

      await loadWorkflows();
      if (selectedWorkflow?.id === workflowId) {
        setSelectedWorkflow(null);
      }
    } catch (error) {
      console.error("Error deleting workflow:", error);
      alert("Błąd podczas usuwania workflow");
    }
  };

  const runWorkflow = async (workflowId: string) => {
    try {
      const response = await fetch(`/api/cerai/langchain/workflows/${workflowId}/run`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}),
      });

      if (!response.ok) {
        throw new Error("Failed to run workflow");
      }

      const data = await response.json();
      alert(`Workflow uruchomiony! Status: ${data.status}`);
    } catch (error) {
      console.error("Error running workflow:", error);
      alert("Błąd podczas uruchamiania workflow");
    }
  };

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="font-display text-4xl text-ivory-100">LangChain Workflows</h1>
        <p className="mt-2 text-ivory-100/70">
          Zarządzaj workflowami AI zbudowanymi na LangChain
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Workflows List */}
        <div className="lg:col-span-1">
          <div className="marble-card p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-xl font-semibold text-ivory-100">Workflowy</h2>
              <button
                onClick={createWorkflow}
                className="p-2 rounded-lg bg-ember-500 hover:bg-ember-600 text-white transition-colors"
              >
                <Plus className="h-4 w-4" />
              </button>
            </div>

            <div className="space-y-2">
              {loading ? (
                <div className="text-center py-8 text-ivory-100/60">Ładowanie...</div>
              ) : workflows.length === 0 ? (
                <div className="text-center py-8 text-ivory-100/60">Brak workflowów</div>
              ) : (
                workflows.map((workflow) => (
                  <div
                    key={workflow.id}
                    onClick={() => setSelectedWorkflow(workflow)}
                    className={`p-4 rounded-lg border cursor-pointer transition-colors ${
                      selectedWorkflow?.id === workflow.id
                        ? "bg-ember-500/20 border-ember-500"
                        : "bg-white/5 border-white/10 hover:bg-white/10"
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <Workflow className="h-4 w-4 text-ivory-100/60" />
                          <span className="font-medium text-ivory-100">{workflow.name}</span>
                          <span
                            className={`px-2 py-0.5 rounded text-xs ${
                              workflow.status === "active"
                                ? "bg-green-500/20 text-green-400"
                                : "bg-gray-500/20 text-gray-400"
                            }`}
                          >
                            {workflow.status === "active" ? "Aktywny" : "Nieaktywny"}
                          </span>
                        </div>
                        <p className="text-xs text-ivory-100/60">{workflow.description}</p>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>

        {/* Workflow Editor */}
        <div className="lg:col-span-2">
          <div className="marble-card p-6">
            {selectedWorkflow ? (
              <>
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h2 className="text-xl font-semibold text-ivory-100">
                      {selectedWorkflow.name}
                    </h2>
                    <p className="text-sm text-ivory-100/60 mt-1">
                      {selectedWorkflow.description}
                    </p>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => runWorkflow(selectedWorkflow.id)}
                      className="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg transition-colors flex items-center gap-2"
                    >
                      <Play className="h-4 w-4" />
                      Uruchom
                    </button>
                    <button
                      onClick={() => updateWorkflow(selectedWorkflow)}
                      className="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors flex items-center gap-2"
                    >
                      <Save className="h-4 w-4" />
                      Zapisz
                    </button>
                    <button
                      onClick={() => deleteWorkflow(selectedWorkflow.id)}
                      className="px-4 py-2 bg-red-500 hover:bg-red-600 text-white rounded-lg transition-colors flex items-center gap-2"
                    >
                      <Trash2 className="h-4 w-4" />
                      Usuń
                    </button>
                  </div>
                </div>

                <div className="bg-white/5 rounded-lg p-8 border border-white/10 min-h-[400px]">
                  <div className="text-center text-ivory-100/60">
                    <Workflow className="h-12 w-12 mx-auto mb-4 opacity-50" />
                    <p>Edytor workflow będzie dostępny wkrótce</p>
                    <p className="text-sm mt-2">
                      Użyj LangGraph Studio do projektowania workflowów
                    </p>
                    <Link
                      href={process.env.NEXT_PUBLIC_LANGGRAPH_STUDIO_URL || "http://localhost:8123"}
                      target="_blank"
                      className="mt-4 inline-block px-4 py-2 bg-ember-500 hover:bg-ember-600 text-white rounded-lg transition-colors"
                    >
                      Otwórz LangGraph Studio
                    </Link>
                  </div>
                </div>
              </>
            ) : (
              <div className="text-center py-12 text-ivory-100/60">
                Wybierz workflow z listy, aby rozpocząć edycję
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Documentation */}
      <div className="mt-6 marble-card p-6">
        <h2 className="text-xl font-semibold text-ivory-100 mb-4">Dokumentacja</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="p-4 bg-white/5 rounded-lg">
            <h3 className="font-semibold text-ivory-100 mb-2">LangGraph</h3>
            <p className="text-sm text-ivory-100/60 mb-3">
              Framework do budowania stateful, multi-actor aplikacji z LLM
            </p>
            <Link
              href="https://langchain-ai.github.io/langgraph/"
              target="_blank"
              className="text-sm text-ember-400 hover:text-ember-300"
            >
              Dokumentacja →
            </Link>
          </div>
          <div className="p-4 bg-white/5 rounded-lg">
            <h3 className="font-semibold text-ivory-100 mb-2">LangGraph Studio</h3>
            <p className="text-sm text-ivory-100/60 mb-3">
              Wizualny edytor do projektowania i debugowania workflowów
            </p>
            <Link
              href={process.env.NEXT_PUBLIC_LANGGRAPH_STUDIO_URL || "http://localhost:8123"}
              target="_blank"
              className="text-sm text-ember-400 hover:text-ember-300"
            >
              Otwórz Studio →
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

