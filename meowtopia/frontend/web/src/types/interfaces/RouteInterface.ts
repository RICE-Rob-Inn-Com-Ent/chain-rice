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
