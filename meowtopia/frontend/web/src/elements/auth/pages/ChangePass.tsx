import React from "react";
import { UI } from "../../../ui/index";

export const ChangePass: React.FC<any> = ({}) => {
  return (
    <UI.Form tag="form">
      <UI.Text tag="h2">Zmień hasło</UI.Text>
      <UI.Form tag="input" type="password" placeholder="Obecne hasło" />
      <UI.Form tag="input" type="password" placeholder="Nowe hasło" />
      <UI.Form tag="input" type="password" placeholder="Powtórz nowe hasło" />
      <UI.Click tag="button" type="submit">
        Zmień hasło
      </UI.Click>
    </UI.Form>
  );
};
