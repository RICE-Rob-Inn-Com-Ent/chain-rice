import React from "react";

export interface ContainerInterface extends React.HTMLAttributes<HTMLElement> {
  tag?:
    | "div"
    | "form"
    | "section"
    | "article"
    | "main"
    | "aside"
    | "header"
    | "footer"
    | "nav"
    | "table";
  variant?:
    | "default"
    | "form"
    | "card"
    | "section"
    | "panel"
    | "boxed"
    | "highlight"
    | "loader-small"
    | "loader-medium"
    | "loader-large"
    | "loader-global"
    | "admin-nav"
    | "user-nav"
    | "data-table"
    | "demo";
  children?: React.ReactNode;
  // Nav-specific props
  navVariant?: "admin" | "user";
  // Table-specific props
  tableName?: string;
  columns?: Array<{
    key: string;
    label: string;
    type?: "text" | "boolean" | "date" | "email";
  }>;
  tableData?: any[];
  loading?: boolean;
  error?: string | null;
}
