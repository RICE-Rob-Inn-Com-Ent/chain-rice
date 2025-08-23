import React from "react";

export interface TextInterface extends React.HTMLAttributes<HTMLElement> {
  tag: "h1" | "h2" | "h3" | "h4" | "h5" | "h6" | "p" | "span" | "strong" | "u";
  variant: 
    | "title-1"
    | "title-2"
    | "title-3"
    | "subtitle"
    | "body"
    | "caption"
    | "label"
    | "error"
    | "success"
    | "helper";
  children: React.ReactNode;
}
