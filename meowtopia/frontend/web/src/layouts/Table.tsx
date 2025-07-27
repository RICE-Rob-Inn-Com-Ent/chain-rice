import React from "react";

const Table: React.FC<TableConfig> = ({
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
  return (
    <table>
      <thead>
        <tr>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td></td>
        </tr>
      </tbody>
    </table>
  );
};

export default Table;
