import React, { useEffect, useState } from "react";
import axios from "axios";

export interface TableColumn {
  key: string;
  label: string;
  type?: "text" | "boolean" | "date" | "email";
}

export interface TableConfig {
  tableName?: string;
  columns?: TableColumn[];
  headChildren?: React.ReactNode;
  bodyChildren?: React.ReactNode;
}

interface TableData {
  [key: string]: any;
}

export const Table: React.FC<TableConfig> = ({
  tableName,
  columns = [],
  headChildren,
  bodyChildren,
}) => {
  const [data, setData] = useState<TableData[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const formatValue = (value: any, type?: string) => {
    if (value === null || value === undefined) return "-";

    switch (type) {
      case "boolean":
        return value ? "Tak" : "Nie";
      case "date":
        return new Date(value).toLocaleDateString("pl-PL");
      case "email":
        return value;
      default:
        return String(value);
    }
  };

  return (
    <div>
      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}
      
      {loading && (
        <div className="text-center py-4">
          Завантаження...
        </div>
      )}

      <table table-name={tableName}>
        <thead>
          <tr>
            {columns.length > 0 ? (
              columns.map((column) => <th key={column.key}>{column.label}</th>)
            ) : (
              <th>{headChildren}</th>
            )}
          </tr>
        </thead>
        <tbody>
          {!loading && !error && data.length > 0 ? (
            data.map((row, index) => (
              <tr key={row.id || index}>
                {columns.length > 0 ? (
                  columns.map((column) => (
                    <td key={column.key}>
                      {formatValue(row[column.key], column.type)}
                    </td>
                  ))
                ) : (
                  <td>{bodyChildren}</td>
                )}
              </tr>
            ))
          ) : !loading && !error ? (
            <tr>
              <td colSpan={columns.length || 1}>Brak danych do wyświetlenia</td>
            </tr>
          ) : null}
        </tbody>
      </table>
    </div>
  );
};
