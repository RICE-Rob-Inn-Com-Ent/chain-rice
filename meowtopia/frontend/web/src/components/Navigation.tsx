import React from "react";
import { Link, useLocation } from "react-router-dom";

export interface RouteInterface {
  path: string;
  label: string;
  slug: string;
  file?: string;
  title?: string;
  element?: React.ReactNode;
  icon?: React.ReactNode;
  children?: RouteInterface[];
}

interface NavigationProps {
  routes: RouteInterface[];
  className?: string;
}

const Navigation: React.FC<NavigationProps> = ({ routes, className = "" }) => {
  const location = useLocation();

  const renderNavItem = (route: RouteInterface) => {
    const isActive = location.pathname === route.path || 
                    location.pathname.startsWith(route.path + "/");
    
    return (
      <li key={route.slug} className={`nav-item ${isActive ? "active" : ""}`}>
        <Link to={route.path} className="nav-link">
          {route.icon && <span className="nav-icon">{route.icon}</span>}
          <span className="nav-label">{route.label}</span>
        </Link>
        {route.children && route.children.length > 0 && (
          <ul className="nav-children">
            {route.children.map(renderNavItem)}
          </ul>
        )}
      </li>
    );
  };

  return (
    <nav className={`navigation ${className}`}>
      <ul className="nav-list">
        {routes.map(renderNavItem)}
      </ul>
    </nav>
  );
};

export default Navigation;
