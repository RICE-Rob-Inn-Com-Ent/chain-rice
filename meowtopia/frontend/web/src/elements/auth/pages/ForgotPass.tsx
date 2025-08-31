import React from "react";
import { UI } from "../../../ui/index";

export const ForgotPass: React.FC<any> = ({}) => {
  return (
    <UI.Form tag="form">
      <UI.Form tag="input" type="email" placeholder="Email" />
      <UI.Click tag="button" type="submit">
        Resetuj hasło
      </UI.Click>
      <UI.Text tag="p">
        Masz już konto?
        <UI.Click tag="a" url="/sign-in">
          Zaloguj się
        </UI.Click>
      </UI.Text>
    </UI.Form>
  );
};
