"use client";
import React from "react";

interface TechItem {
  name: string;
  category: string;
  icon?: string;
}

interface TechStackGridProps {
  items: TechItem[];
  columns?: number;
}

/**
 * TechStackGrid - Display technology stack in a grid
 */
export const TechStackGrid: React.FC<TechStackGridProps> = ({ items, columns = 4 }) => {
  return (
    <div
      className="grid gap-4"
      style={{
        gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))`,
      }}
    >
      {items.map((tech, idx) => (
        <div
          key={idx}
          className="flex flex-col items-center justify-center rounded-lg border border-gray-200 bg-white p-4 transition-all hover:border-green-500 hover:shadow-md dark:border-gray-700 dark:bg-gray-800 dark:hover:border-green-400"
        >
          {tech.icon && <div className="mb-2 text-3xl">{tech.icon}</div>}
          <div className="text-center text-sm font-semibold text-gray-900 dark:text-white">{tech.name}</div>
          <div className="text-xs text-gray-500 dark:text-gray-400">{tech.category}</div>
        </div>
      ))}
    </div>
  );
};

export default TechStackGrid;
