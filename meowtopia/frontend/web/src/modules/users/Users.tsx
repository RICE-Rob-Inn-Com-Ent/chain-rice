import React from "react";
import { Table, TableConfig, TableColumn } from "@/layouts/Table";

const userColumns: TableColumn[] = [
  { key: "id", label: "ID", type: "text" },
  { key: "fullName", label: "Imię i nazwisko", type: "text" },
  { key: "email", label: "Email", type: "email" },
  { key: "firstName", label: "Imię", type: "text" },
  { key: "lastName", label: "Nazwisko", type: "text" },
  { key: "username", label: "Nazwa użytkownika", type: "text" },
  { key: "phone", label: "Telefon", type: "text" },
  { key: "terms", label: "Akceptacja regulaminu", type: "boolean" },
  { key: "privacy", label: "Polityka prywatności", type: "boolean" },
  { key: "cookies", label: "Pliki cookies", type: "boolean" },
  { key: "marketing", label: "Marketing", type: "boolean" },
  { key: "newsletter", label: "Newsletter", type: "boolean" },
  { key: "created_at", label: "Data utworzenia", type: "date" },
  { key: "updated_at", label: "Ostatnia aktualizacja", type: "date" },
];

const Users: React.FC = () => {
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Zarządzanie użytkownikami</h1>
      <Table
        tableName="users"
        apiEndpoint="/api/v1/auth/users"
        columns={userColumns}
      />
    </div>
  );
};

export default Users;
