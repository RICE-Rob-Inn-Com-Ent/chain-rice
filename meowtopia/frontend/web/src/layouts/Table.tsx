import React, { useEffect, useState } from "react";
import axios from "axios";

export interface TableColumn {
  key: string;
  label: string;
  type?: "text" | "boolean" | "date" | "email";
}

export interface TableConfig {
  tableName?: string;
  apiEndpoint?: string;
  columns?: TableColumn[];
  headChildren?: React.ReactNode;
  bodyChildren?: React.ReactNode;
}

interface TableData {
  [key: string]: any;
}

export const Table: React.FC<TableConfig> = ({
  tableName,
  apiEndpoint,
  columns = [],
  headChildren,
  bodyChildren,
}) => {
  const [data, setData] = useState<TableData[]>([]);

  useEffect(() => {
    if (apiEndpoint) {
      fetchData();
    }
  }, [apiEndpoint]);

  const fetchData = async () => {
    try {
      const response = await axios.get(apiEndpoint!);
      setData(response.data);
    } catch (err) {
      console.error("Error fetching data:", err);
    }
  };

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
          {data.length > 0 ? (
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
          ) : (
            <tr>
              <td colSpan={columns.length || 1}>Brak danych do wyświetlenia</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
};
