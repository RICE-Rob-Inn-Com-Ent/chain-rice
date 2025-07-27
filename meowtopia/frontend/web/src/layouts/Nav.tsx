import React from "react";
import { Click } from "@/components/Click";

export function useNavConfig() {
  return {
    navConfig: {
      className: "bg-red-50 p-6 rounded-lg shadow-md max-w-md mx-auto",
    },
    ulConfig: {
      className: "flex items-center",
    },
    liConfig: {
      className: "flex items-center",
    },
    caffeConfig: {
      type: "button" as const,
      role: "primary" as const,
      state: "pressed" as const,
      ariaLabel: "Кав'ярня",
      to: "/caffe",
      icon: "cup",
      children: "Кав'ярня"

    },
    storageConfig: {
      type: "button" as const,
      role: "primary" as const,
      state: "pressed" as const,
      ariaLabel: "Склад",
      to: "/storage",
      icon: "warehouse",
      children: "Склад"
    },
  };
}
export const Nav: React.FC = () => {
  const config = useNavConfig();

  return (
    <nav {...config.navConfig}>
      <ul {...config.ulConfig}>
        <li {...config.liConfig}>
          <Click {...config.caffeConfig} />
        </li>
      </ul>
    </nav>
  );
};
