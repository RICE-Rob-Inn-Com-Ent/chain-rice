import type { Metadata } from "next";

export const metadata: Metadata = {
  title: {
    default: "Authentication",
    template: "%s | RICE",
  },
};

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}

