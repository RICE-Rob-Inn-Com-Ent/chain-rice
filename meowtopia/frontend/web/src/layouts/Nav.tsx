import React from "react";
import { Click, ClickConfig } from "@/components/Click";

export interface NavConfig {
  variant: "admin" | "user";
}

const linkConfig = {
  caffeLink: {
    type: "button",
    role: "primary",
    state: "pressed",
    ariaLabel: "Link do Kawiarni",
    to: "/cafe",
    icon: "cafe",
    children: "Kawiarnia",
  } as ClickConfig,
    usersLink: {
    type: "button",
    role: "primary",
    state: "pressed",
    ariaLabel: "Link do Użytkowników",
    to: "/users",
    icon: "users",
    children: "Użytkownicy",
  } as ClickConfig,
  storageLink: {
    type: "button",
    role: "primary",
    state: "pressed",
    ariaLabel: "Link do Magazynu",
    to: "/storage",
    icon: "storage",
    children: "Magazyn",
  } as ClickConfig,
  accountingLink: {
    type: "button",
    role: "primary",
    state: "pressed",
    ariaLabel: "Link do Księgowości",
    to: "/accounting",
    icon: "accounting",
    children: "Księgowość",
  } as ClickConfig,
};

export const Nav: React.FC<NavConfig> = ({ variant }) => {
  const variantClasses = {
    "admin": "flex flex-col",
    "user": "flex flex-row",
  };
  const className = variantClasses[variant];

  return (
    <nav className={className}>
      <ul className={className}>
        <li className={className}>
          <Click {...linkConfig.caffeLink} />
          <Click {...linkConfig.usersLink} />
          <Click {...linkConfig.storageLink} />
          <Click {...linkConfig.accountingLink} />
        </li>
      </ul>
    </nav>
  );
};
