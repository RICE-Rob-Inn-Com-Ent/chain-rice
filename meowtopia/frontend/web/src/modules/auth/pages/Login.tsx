import React from "react";
import { Icon } from "@iconify/react";
import { Text } from "@/components/Text";
import { Field } from "@/components/Field";
import { Click } from "@/components/Click";
import { useLoginConfig } from "../configs/loginConfig";

const Login: React.FC = () => {
  const config = useLoginConfig();

  return (
    <form {...config.formConfig}>
      <Text {...config.titleText} />
      <div {...config.containerConfig}>
        <Field {...config.emailField} />
        <Text {...config.emailErrorText} />
        <Icon {...config.successIcon} />
      </div>
      <div {...config.containerConfig}>
        <Field {...config.passwordField} />
        <Text {...config.passwordErrorText} />
        <Icon {...config.successIcon} />
      </div>
      <Field {...config.rememberMeField} />
      <Click {...config.loginClick} />
      <Text {...config.registerText} />
      <Click {...config.registerClick} />
      <Text {...config.useSocialText} />
    </form>
  );
};

export default Login;
