import React from "react";
import { UI } from "../../../ui/index";

export const ResetPass: React.FC<any> = ({}) => {
  return (
    <UI.Form tag="form">
      <UI.Form tag="input" type="password" placeholder="Password" />
      <UI.Form tag="input" type="password" placeholder="Confirm Password" />
      <UI.Click tag="button" type="submit">
        Resetuj hasło
      </UI.Click>
      <UI.Text tag="p">
        Masz już konto?
        <UI.Click tag="a" url="/login">
          Zaloguj się
        </UI.Click>
      </UI.Text>
    </UI.Form>
  );
};
