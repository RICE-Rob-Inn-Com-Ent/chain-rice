import React from "react";
import { ContainerConfig } from "../interfaces/Container";

export const Container: React.FC<ContainerConfig> = ({
  tag = "div",
  variant = "default",
  children,
  navVariant,
  tableName,
  columns = [],
  tableData = [],
  loading = false,
  error = null,
  ...props
}) => {
  const Tag = tag;
  
  const variantClasses = {
    "default": "flex flex-row",
    "form": "flex flex-col",
    "card": "bg-green shadow-md rounded-xl p-5",
    "section": "py-8 px-4 sm:px-8",
    "panel": "bg-gray-100 p-4 rounded-md",
    "boxed": "border border-gray-200 p-4 rounded",
    "highlight": "bg-yellow-100 p-4 border-l-4 border-yellow-400",
    "loader-small": "flex items-center justify-center p-2",
    "loader-medium": "flex items-center justify-center p-4",
    "loader-large": "flex flex-col items-center justify-center p-8 space-y-4",
    "loader-global": "flex items-center justify-center min-h-screen bg-gray-100 text-gray-600",
    // Nav variants
    "admin-nav": "w-full bg-red-500 text-white shadow",
    "user-nav": "w-full bg-blue-500 border-b",
    // Table variant
    "data-table": "w-full border-collapse border border-gray-300",
    // Demo variant
    "demo": "p-8 bg-gradient-to-br from-blue-50 to-indigo-100 min-h-screen",
  };

  const className = variantClasses[variant] || "";

  // Render Demo variant to showcase all functionality
  if (variant === "demo") {
    const sampleTableData = [
      { id: 1, name: "Jan Kowalski", email: "jan@example.com", active: true, created: "2024-01-15" },
      { id: 2, name: "Anna Nowak", email: "anna@example.com", active: false, created: "2024-01-20" },
      { id: 3, name: "Piotr Wiśniewski", email: "piotr@example.com", active: true, created: "2024-01-25" },
    ];

    const sampleColumns: Array<{ key: string; label: string; type?: "text" | "boolean" | "date" | "email" }> = [
      { key: "id", label: "ID", type: "text" },
      { key: "name", label: "Imię i nazwisko", type: "text" },
      { key: "email", label: "Email", type: "email" },
      { key: "active", label: "Aktywny", type: "boolean" },
      { key: "created", label: "Data utworzenia", type: "date" },
    ];

    return (
      <div className={className}>
        <h1 className="text-3xl font-bold text-gray-800 mb-8 text-center">Container Component Demo</h1>
        
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Nav Demo */}
          <div className="space-y-4">
            <h2 className="text-xl font-semibold text-gray-700">Navigation Variants</h2>
            
            <div className="bg-white rounded-lg shadow-md p-4">
              <h3 className="font-medium text-gray-600 mb-2">Admin Navigation</h3>
              <Container tag="nav" variant="admin-nav" />
            </div>
            
            <div className="bg-white rounded-lg shadow-md p-4">
              <h3 className="font-medium text-gray-600 mb-2">User Navigation</h3>
              <Container tag="nav" variant="user-nav" />
            </div>
          </div>

          {/* Table Demo */}
          <div className="space-y-4">
            <h2 className="text-xl font-semibold text-gray-700">Table Variant</h2>
            
            <div className="bg-white rounded-lg shadow-md p-4">
              <h3 className="font-medium text-gray-600 mb-2">Sample Data Table</h3>
              <Container
                tag="table"
                variant="data-table"
                tableName="demo-users"
                columns={sampleColumns}
                tableData={sampleTableData}
              />
            </div>
          </div>
        </div>

        {/* Other Variants Demo */}
        <div className="mt-8 space-y-4">
          <h2 className="text-xl font-semibold text-gray-700">Other Container Variants</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Container variant="card" className="p-4">
              <h3 className="font-medium text-gray-700">Card Variant</h3>
              <p className="text-gray-600 text-sm">Beautiful card styling</p>
            </Container>
            
            <Container variant="panel" className="p-4">
              <h3 className="font-medium text-gray-700">Panel Variant</h3>
              <p className="text-gray-600 text-sm">Panel with gray background</p>
            </Container>
            
            <Container variant="boxed" className="p-4">
              <h3 className="font-medium text-gray-700">Boxed Variant</h3>
              <p className="text-gray-600 text-sm">Bordered container</p>
            </Container>
            
            <Container variant="highlight" className="p-4">
              <h3 className="font-medium text-gray-700">Highlight Variant</h3>
              <p className="text-gray-600 text-sm">Highlighted content</p>
            </Container>
          </div>
        </div>
      </div>
    );
  }

  // Render Nav component when tag is "nav"
  if (tag === "nav") {
    if (variant === "admin-nav" || navVariant === "admin") {
      return (
        <nav className={variantClasses["admin-nav"]}>
          <ul className="flex flex-col items-center gap-3 px-4 py-2">
            <li className="list-none">
              <a href="/admin" className="text-white hover:text-gray-200 px-3 py-2 rounded">
                Kawiarnia
              </a>
              <a href="/admin/users" className="text-white hover:text-gray-200 px-3 py-2 rounded">
                Użytkownicy
              </a>
              <a href="/admin/storage" className="text-white hover:text-gray-200 px-3 py-2 rounded">
                Magazyn
              </a>
              <a href="/admin/accounting" className="text-white hover:text-gray-200 px-3 py-2 rounded">
                Księgowość
              </a>
              <a href="/admin/demo" className="text-white hover:text-gray-200 px-3 py-2 rounded">
                Demo
              </a>
            </li>
          </ul>
        </nav>
      );
    } else if (variant === "user-nav" || navVariant === "user") {
      return (
        <nav className={variantClasses["user-nav"]}>
          <ul className="flex flex-row items-start gap-3 px-4 py-2">
            <li className="list-none">
              <a href="/cafe" className="text-white hover:text-gray-200 px-3 py-2 rounded">
                Kawiarnia
              </a>
              <a href="/profile" className="text-white hover:text-gray-200 px-3 py-2 rounded">
                Profil
              </a>
              <a href="/orders" className="text-white hover:text-gray-200 px-3 py-2 rounded">
                Zamówienia
              </a>
            </li>
          </ul>
        </nav>
      );
    }
  }

  // Render Table component when tag is "table"
  if (tag === "table") {
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
            Ładowanie...
          </div>
        )}

        <table table-name={tableName} className={variantClasses["data-table"]}>
          <thead>
            <tr>
              {columns.length > 0 ? (
                columns.map((column) => (
                  <th key={column.key} className="border border-gray-300 px-4 py-2 bg-gray-100">
                    {column.label}
                  </th>
                ))
              ) : (
                <th className="border border-gray-300 px-4 py-2 bg-gray-100">
                  {children}
                </th>
              )}
            </tr>
          </thead>
          <tbody>
            {!loading && !error && tableData.length > 0 ? (
              tableData.map((row, index) => (
                <tr key={row.id || index}>
                  {columns.length > 0 ? (
                    columns.map((column) => (
                      <td key={column.key} className="border border-gray-300 px-4 py-2">
                        {formatValue(row[column.key], column.type)}
                      </td>
                    ))
                  ) : (
                    <td className="border border-gray-300 px-4 py-2">
                      {children}
                    </td>
                  )}
                </tr>
              ))
            ) : !loading && !error ? (
              <tr>
                <td colSpan={columns.length || 1} className="border border-gray-300 px-4 py-2 text-center text-gray-500">
                  Brak danych do wyświetlenia
                </td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    );
  }

  // Default container rendering
  return <Tag className={className} {...props}>{children}</Tag>;
};
