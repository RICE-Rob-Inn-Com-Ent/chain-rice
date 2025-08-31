import React from "react";
import { Icon } from "@iconify/react";
import { UI } from "../../../ui/index";

export const SignIn: React.FC<any> = ({}) => {
  return (
    <UI.Form tag="form">
      <UI.Form tag="input" type="email" placeholder="Email" />
      <UI.Form tag="input" type="password" placeholder="Password" />
      <UI.Text tag="p">
        <UI.Form tag="input" type="checkbox" />
        Zapamiętaj mnie
      </UI.Text>
      <UI.Click tag="button" type="submit">
        Zaloguj się
      </UI.Click>
      <UI.Click tag="a" url="/forgot-pass">
        Zapomniałeś hasła?
      </UI.Click>
      <UI.Text tag="p">
        Nie masz jeszcze konta?
        <UI.Click tag="a" url="/sign-up">
          Zarejestruj się
        </UI.Click>
      </UI.Text>
      <UI.Text tag="p">Lub zaloguj sie za pomoca</UI.Text>
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
