import React from "react";
import { UI } from "../../../ui/index";

export const TwoFactorAuth: React.FC<any> = ({}) => {
  return (
    <UI.Form tag="form">
      <UI.Text tag="h2">Dwustopniowe logowanie</UI.Text>
      <UI.Text tag="p">
        Wprowadź 6-cyfrowy kod z aplikacji Google Authenticator lub SMS.
      </UI.Text>
      <UI.Form tag="input" type="text" placeholder="Wpisz kod" />
      <UI.Click tag="button" type="submit">
        Potwierdź
      </UI.Click>
      <UI.Click tag="a" url="/login">
        Wróć do logowania
      </UI.Click>
    </UI.Form>
  );
};
