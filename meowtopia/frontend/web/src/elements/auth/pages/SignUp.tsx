import React from "react";
import { Icon } from "@iconify/react";
import { UI } from "../../../ui/index";

export const SignUp: React.FC<any> = ({}) => {
  return (
    <UI.Form tag="form">
      <UI.Form tag="input" type="text" placeholder="Name" />
      <UI.Form tag="input" type="email" placeholder="Email" />
      <UI.Form tag="input" type="password" placeholder="Password" />
      <UI.Form tag="input" type="password" placeholder="Confirm Password" />
      <UI.Click tag="button" type="submit">
        Zarejestruj się
      </UI.Click>
      <UI.Container tag="div">
        <UI.Text tag="p">Masz już konto?</UI.Text>
        <UI.Click tag="a" url="/sign-in">
          Zaloguj się
        </UI.Click>
      </UI.Container>
      <UI.Text tag="p">Lub zarejestruj sie za pomoca</UI.Text>
      <UI.Click tag="button" type="button">
        <Icon icon="mdi:google" width="20" height="20" />
        Google
      </UI.Click>
      <UI.Click tag="button" type="button">
        <Icon icon="mdi:facebook" width="20" height="20" />
        Facebook
      </UI.Click>
    </UI.Form>
  );
};
