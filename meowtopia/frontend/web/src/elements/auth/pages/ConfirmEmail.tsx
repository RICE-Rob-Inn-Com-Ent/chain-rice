import React from "react";
import { UI } from "../../../ui/index";

export const ConfirmEmail: React.FC<any> = ({}) => {
  return (
    <UI.Form tag="form">
      <UI.Text tag="h2">Adres e-mail został potwierdzony</UI.Text>
      <UI.Text tag="p">
        Twoje konto zostało aktywowane. Teraz możesz się zalogować.
      </UI.Text>

      <UI.Click tag="a" url="/sign-in">
        Przejdź do logowania
      </UI.Click>
    </UI.Form>
  );
};
