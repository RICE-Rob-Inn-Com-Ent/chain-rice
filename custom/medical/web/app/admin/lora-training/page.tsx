"use client";

import { useState, useEffect } from "react";
import { Search, FileText, Plus, Edit, Trash2, Save, X, Download, Upload } from "lucide-react";
import Link from "next/link";

type TrainingFile = {
  filename: string;
  size: number;
  items_count: number;
  adapter_type: string;
  modified: number;
};

type TrainingDataItem = {
  text?: string;
  input?: string;
  [key: string]: any;
};

type TrainingFileContent = {
  filename: string;
  data: TrainingDataItem[];
  adapter_type: string;
};

export default function LoRATrainingPage() {
  const [files, setFiles] = useState<TrainingFile[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedFile, setSelectedFile] = useState<TrainingFileContent | null>(null);
  const [editingIndex, setEditingIndex] = useState<number | null>(null);
  const [editText, setEditText] = useState("");
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [showSearchResults, setShowSearchResults] = useState(false);
  const [adapterFilter, setAdapterFilter] = useState<string>("all");

  // Load files list
  useEffect(() => {
    loadFiles();
  }, []);

  const loadFiles = async () => {
    try {
      setLoading(true);
      const response = await fetch("/api/lora/training-data");
      const data = await response.json();
      setFiles(data.files || []);
    } catch (error) {
      console.error("Error loading files:", error);
    } finally {
      setLoading(false);
    }
  };

  const loadFile = async (filename: string) => {
    try {
      const response = await fetch(`/api/lora/training-data/${filename}`);
      const data = await response.json();
      setSelectedFile(data);
      setEditingIndex(null);
    } catch (error) {
      console.error("Error loading file:", error);
      alert("Błąd podczas ładowania pliku");
    }
  };

  const saveFile = async () => {
    if (!selectedFile) return;

    try {
      const response = await fetch(`/api/lora/training-data/${selectedFile.filename}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ data: selectedFile.data }),
      });

      if (!response.ok) {
        throw new Error("Failed to save");
      }

      alert("Plik zapisany pomyślnie");
      setEditingIndex(null);
      loadFiles();
    } catch (error) {
      console.error("Error saving file:", error);
      alert("Błąd podczas zapisywania pliku");
    }
  };

  const deleteFile = async (filename: string) => {
    if (!confirm(`Czy na pewno chcesz usunąć plik ${filename}?`)) {
      return;
    }

    try {
      const response = await fetch(`/api/lora/training-data/${filename}`, {
        method: "DELETE",
      });

      if (!response.ok) {
        throw new Error("Failed to delete");
      }

      if (selectedFile?.filename === filename) {
        setSelectedFile(null);
      }
      loadFiles();
      alert("Plik usunięty pomyślnie");
    } catch (error) {
      console.error("Error deleting file:", error);
      alert("Błąd podczas usuwania pliku");
    }
  };

  const createNewFile = async () => {
    const filename = prompt("Podaj nazwę pliku (bez rozszerzenia):");
    if (!filename) return;

    const adapterType = prompt("Typ adaptera (bielik/formatter):", "bielik");
    if (!adapterType) return;

    const newData: TrainingDataItem[] = [
      {
        text: "Przykładowy tekst treningowy...",
      },
    ];

    try {
      const response = await fetch("/api/lora/training-data", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          filename: `${filename}.json`,
          data: newData,
          adapter_type: adapterType,
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to create");
      }

      loadFiles();
      alert("Plik utworzony pomyślnie");
    } catch (error) {
      console.error("Error creating file:", error);
      alert("Błąd podczas tworzenia pliku");
    }
  };

  const handleSearch = async () => {
    if (!searchQuery.trim()) {
      setSearchResults([]);
      setShowSearchResults(false);
      return;
    }

    try {
      const response = await fetch("/api/lora/search", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          query: searchQuery,
          adapter_type: adapterFilter !== "all" ? adapterFilter : undefined,
          limit: 20,
        }),
      });

      const data = await response.json();
      setSearchResults(data.results || []);
      setShowSearchResults(true);
    } catch (error) {
      console.error("Error searching:", error);
    }
  };

  const startEdit = (index: number) => {
    if (!selectedFile) return;
    const item = selectedFile.data[index];
    setEditText(item.text || item.input || "");
    setEditingIndex(index);
  };

  const saveEdit = () => {
    if (!selectedFile || editingIndex === null) return;

    const updatedData = [...selectedFile.data];
    updatedData[editingIndex] = {
      ...updatedData[editingIndex],
      text: editText,
      input: editText,
    };

    setSelectedFile({ ...selectedFile, data: updatedData });
    setEditingIndex(null);
  };

  const cancelEdit = () => {
    setEditingIndex(null);
    setEditText("");
  };

  const addNewItem = () => {
    if (!selectedFile) return;

    const newItem: TrainingDataItem = {
      text: "Nowy element treningowy...",
    };

    setSelectedFile({
      ...selectedFile,
      data: [...selectedFile.data, newItem],
    });
    setEditingIndex(selectedFile.data.length);
    setEditText(newItem.text || "");
  };

  const deleteItem = (index: number) => {
    if (!selectedFile) return;
    if (!confirm("Czy na pewno chcesz usunąć ten element?")) return;

    const updatedData = selectedFile.data.filter((_, i) => i !== index);
    setSelectedFile({ ...selectedFile, data: updatedData });
  };

  const filteredFiles = files.filter((file) => {
    if (adapterFilter !== "all" && file.adapter_type !== adapterFilter) {
      return false;
    }
    return file.filename.toLowerCase().includes(searchQuery.toLowerCase());
  });

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="font-display text-4xl text-ivory-100">
          Zarządzanie danymi treningowymi LoRA
        </h1>
        <p className="mt-2 text-ivory-100/70">
          Edytuj i zarządzaj plikami treningowymi dla adapterów Bielik i Formatter
        </p>
      </div>

      {/* Search Bar */}
      <div className="mb-6 marble-card p-4">
        <div className="flex gap-4 items-center">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-ivory-100/60" />
            <input
              type="text"
              placeholder="Wyszukaj w plikach treningowych..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyPress={(e) => e.key === "Enter" && handleSearch()}
              className="w-full pl-10 pr-4 py-2 bg-white/5 border border-white/10 rounded-lg text-ivory-100 placeholder-ivory-100/50 focus:outline-none focus:ring-2 focus:ring-ember-500"
            />
          </div>
          <select
            value={adapterFilter}
            onChange={(e) => setAdapterFilter(e.target.value)}
            className="px-4 py-2 bg-white/5 border border-white/10 rounded-lg text-ivory-100 focus:outline-none focus:ring-2 focus:ring-ember-500"
          >
            <option value="all">Wszystkie typy</option>
            <option value="bielik">Bielik</option>
            <option value="formatter">Formatter</option>
          </select>
          <button
            onClick={handleSearch}
            className="px-6 py-2 bg-ember-500 hover:bg-ember-600 text-white rounded-lg transition-colors"
          >
            Szukaj
          </button>
          <button
            onClick={createNewFile}
            className="px-6 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg transition-colors flex items-center gap-2"
          >
            <Plus className="h-5 w-5" />
            Nowy plik
          </button>
        </div>

        {/* Search Results */}
        {showSearchResults && searchResults.length > 0 && (
          <div className="mt-4 p-4 bg-white/5 rounded-lg border border-white/10">
            <h3 className="text-lg font-semibold text-ivory-100 mb-3">
              Wyniki wyszukiwania ({searchResults.length})
            </h3>
            <div className="space-y-2 max-h-64 overflow-y-auto">
              {searchResults.map((result, idx) => (
                <div
                  key={idx}
                  className="p-3 bg-white/5 rounded border border-white/10 hover:bg-white/10 cursor-pointer"
                  onClick={() => {
                    loadFile(result.filename);
                    setShowSearchResults(false);
                  }}
                >
                  <div className="text-sm font-medium text-ivory-100">
                    {result.filename} (pozycja {result.index})
                  </div>
                  <div className="text-xs text-ivory-100/70 mt-1">
                    {result.text}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Files List */}
        <div className="marble-card p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-xl font-semibold text-ivory-100">
              Pliki treningowe ({filteredFiles.length})
            </h2>
            {loading && <div className="text-ivory-100/60">Ładowanie...</div>}
          </div>

          <div className="space-y-2 max-h-[600px] overflow-y-auto">
            {filteredFiles.length === 0 ? (
              <div className="text-center py-8 text-ivory-100/60">
                {loading ? "Ładowanie..." : "Brak plików"}
              </div>
            ) : (
              filteredFiles.map((file) => (
                <div
                  key={file.filename}
                  className={`p-4 rounded-lg border cursor-pointer transition-colors ${
                    selectedFile?.filename === file.filename
                      ? "bg-ember-500/20 border-ember-500"
                      : "bg-white/5 border-white/10 hover:bg-white/10"
                  }`}
                  onClick={() => loadFile(file.filename)}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <FileText className="h-4 w-4 text-ivory-100/60" />
                        <span className="font-medium text-ivory-100">
                          {file.filename}
                        </span>
                        <span
                          className={`px-2 py-0.5 rounded text-xs ${
                            file.adapter_type === "bielik"
                              ? "bg-blue-500/20 text-blue-400"
                              : file.adapter_type === "formatter"
                              ? "bg-purple-500/20 text-purple-400"
                              : "bg-gray-500/20 text-gray-400"
                          }`}
                        >
                          {file.adapter_type}
                        </span>
                      </div>
                      <div className="mt-2 text-xs text-ivory-100/60">
                        {file.items_count} elementów •{" "}
                        {(file.size / 1024).toFixed(2)} KB •{" "}
                        {new Date(file.modified * 1000).toLocaleString("pl-PL")}
                      </div>
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        deleteFile(file.filename);
                      }}
                      className="ml-2 p-2 text-red-400 hover:bg-red-500/20 rounded transition-colors"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* File Editor */}
        <div className="marble-card p-6">
          {selectedFile ? (
            <>
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-semibold text-ivory-100">
                  Edycja: {selectedFile.filename}
                </h2>
                <div className="flex gap-2">
                  <button
                    onClick={saveFile}
                    className="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg transition-colors flex items-center gap-2"
                  >
                    <Save className="h-4 w-4" />
                    Zapisz
                  </button>
                  <button
                    onClick={() => setSelectedFile(null)}
                    className="px-4 py-2 bg-gray-500 hover:bg-gray-600 text-white rounded-lg transition-colors"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              </div>

              <div className="mb-4">
                <button
                  onClick={addNewItem}
                  className="px-4 py-2 bg-ember-500 hover:bg-ember-600 text-white rounded-lg transition-colors flex items-center gap-2"
                >
                  <Plus className="h-4 w-4" />
                  Dodaj element
                </button>
              </div>

              <div className="space-y-4 max-h-[600px] overflow-y-auto">
                {selectedFile.data.map((item, index) => (
                  <div
                    key={index}
                    className="p-4 bg-white/5 rounded-lg border border-white/10"
                  >
                    {editingIndex === index ? (
                      <div className="space-y-3">
                        <textarea
                          value={editText}
                          onChange={(e) => setEditText(e.target.value)}
                          className="w-full h-32 px-3 py-2 bg-white/10 border border-white/20 rounded text-ivory-100 placeholder-ivory-100/50 focus:outline-none focus:ring-2 focus:ring-ember-500"
                          placeholder="Wprowadź tekst treningowy..."
                        />
                        <div className="flex gap-2">
                          <button
                            onClick={saveEdit}
                            className="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded transition-colors"
                          >
                            Zapisz
                          </button>
                          <button
                            onClick={cancelEdit}
                            className="px-4 py-2 bg-gray-500 hover:bg-gray-600 text-white rounded transition-colors"
                          >
                            Anuluj
                          </button>
                        </div>
                      </div>
                    ) : (
                      <div>
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="text-sm font-medium text-ivory-100/60 mb-2">
                              Element #{index + 1}
                            </div>
                            <div className="text-ivory-100 whitespace-pre-wrap">
                              {item.text || item.input || "(pusty)"}
                            </div>
                          </div>
                          <div className="flex gap-2 ml-4">
                            <button
                              onClick={() => startEdit(index)}
                              className="p-2 text-ember-400 hover:bg-ember-500/20 rounded transition-colors"
                            >
                              <Edit className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => deleteItem(index)}
                              className="p-2 text-red-400 hover:bg-red-500/20 rounded transition-colors"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </>
          ) : (
            <div className="text-center py-12 text-ivory-100/60">
              Wybierz plik z listy, aby rozpocząć edycję
            </div>
          )}
        </div>
      </div>
    </div>
  );
}



