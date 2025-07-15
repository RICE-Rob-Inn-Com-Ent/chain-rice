import React from "react";

export interface TableColumn {
  key: string;
  label: string;
  sortable?: boolean;
  width?: string;
  align?: "left" | "center" | "right";
  render?: (value: any, row: any) => React.ReactNode;
}

export interface TableProps {
  columns: TableColumn[];
  data: any[];
  loading?: boolean;
  emptyMessage?: string;
  onSort?: (key: string, direction: "asc" | "desc") => void;
  sortColumn?: string;
  sortDirection?: "asc" | "desc";
  className?: string;
  striped?: boolean;
  hover?: boolean;
  compact?: boolean;
}

const Table: React.FC<TableProps> = ({
  columns,
  data,
  loading = false,
  emptyMessage = "No data available",
  onSort,
  sortColumn,
  sortDirection,
  className = "",
  striped = true,
  hover = true,
  compact = false,
}) => {
  const handleSort = (column: TableColumn) => {
    if (!column.sortable || !onSort) return;
    
    const newDirection = sortColumn === column.key && sortDirection === "asc" ? "desc" : "asc";
    onSort(column.key, newDirection);
  };

  const getSortIcon = (column: TableColumn) => {
    if (!column.sortable) return null;
    
    if (sortColumn !== column.key) {
      return <span className="text-gray-400">↕</span>;
    }
    
    return sortDirection === "asc" ? <span>↑</span> : <span>↓</span>;
  };

  const getCellValue = (column: TableColumn, row: any) => {
    if (column.render) {
      return column.render(row[column.key], row);
    }
    return row[column.key];
  };

  const getAlignmentClass = (align?: string) => {
    switch (align) {
      case "center": return "text-center";
      case "right": return "text-right";
      default: return "text-left";
    }
  };

  if (loading) {
    return (
      <div className={`bg-white rounded-lg shadow overflow-hidden ${className}`}>
        <div className="flex justify-center items-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <span className="ml-2 text-gray-600">Ładowanie...</span>
        </div>
      </div>
    );
  }

  return (
    <div className={`bg-white rounded-lg shadow overflow-hidden ${className}`}>
      <div className="overflow-x-auto">
        <table className={`min-w-full divide-y divide-gray-200 ${compact ? "text-sm" : ""}`}>
          <thead className="bg-gray-50">
            <tr>
              {columns.map((column) => (
                <th
                  key={column.key}
                  className={`px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider ${
                    column.sortable ? "cursor-pointer hover:text-gray-700" : ""
                  } ${getAlignmentClass(column.align)}`}
                  style={{ width: column.width }}
                  onClick={() => handleSort(column)}
                >
                  <div className="flex items-center space-x-1">
                    <span>{column.label}</span>
                    {getSortIcon(column)}
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody className={`bg-white divide-y divide-gray-200 ${hover ? "hover:bg-gray-50" : ""}`}>
            {data.length === 0 ? (
              <tr>
                <td colSpan={columns.length} className="px-6 py-4 text-center text-gray-500">
                  {emptyMessage}
                </td>
              </tr>
            ) : (
              data.map((row, index) => (
                <tr key={index} className={striped && index % 2 === 1 ? "bg-gray-50" : ""}>
                  {columns.map((column) => (
                    <td
                      key={column.key}
                      className={`px-6 py-4 whitespace-nowrap text-sm text-gray-900 ${getAlignmentClass(column.align)}`}
                    >
                      {getCellValue(column, row)}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Table;
