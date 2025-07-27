import React from "react";
import { Text } from "@/components/Text";

const ConfirmEmail: React.FC = () => {
  return (
    <div className="flex flex-col items-center justify-center min-h-[300px]">
      <Text tag="h2" className="mb-4" children="Potwierdź swój adres e-mail" />
      <Text tag="p" className="mb-2" children="Dziękujemy za rejestrację! Sprawdź swoją skrzynkę e-mail i kliknij w link potwierdzający, aby aktywować konto." />
    </div>
  );
};

export default ConfirmEmail;
