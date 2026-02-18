import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Zaloguj się - Ceramix",
  description: "Zaloguj się do swojego konta Ceramix. System zarządzania dla profesjonalistów.",
  keywords: ["ceramix", "logowanie", "zaloguj się", "system zarządzania"],
  robots: {
    index: false,
    follow: false,
  },
  openGraph: {
    title: "Zaloguj się - Ceramix",
    description: "Zaloguj się do swojego konta Ceramix. System zarządzania dla profesjonalistów.",
    type: "website",
    url: "https://ceramix.ltd/sign-in",
  },
  twitter: {
    card: "summary_large_image",
    title: "Zaloguj się - Ceramix",
    description: "Zaloguj się do swojego konta Ceramix. System zarządzania dla profesjonalistów.",
  },
};

export default function SignInLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return <>{children}</>;
}



