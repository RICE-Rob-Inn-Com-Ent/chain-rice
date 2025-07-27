import React from "react";
import { Text } from "@/components/Text";
import { Field } from "@/components/Field";
import { Click } from "@/components/Click";
import { useRegisterConfig } from "../configs/registerConfig";

const Register: React.FC = () => {
  const config = useRegisterConfig();

  return (
    <form {...config.formProps}>
      <Text {...config.pageTitle} />
      <Field {...config.firstNameField} />
      {config.firstNameErrorText && <Text {...config.firstNameErrorText} />}
      <Field {...config.lastNameField} />
      {config.lastNameErrorText && <Text {...config.lastNameErrorText} />}
      <Field {...config.emailField} />
      {config.emailErrorText && <Text {...config.emailErrorText} />}
      <Field {...config.usernameField} />
      {config.usernameErrorText && <Text {...config.usernameErrorText} />}
      <Field {...config.phoneField} />
      <Field {...config.passwordField} />
      {config.passwordErrorText && <Text {...config.passwordErrorText} />}
      <Field {...config.passwordConfirmField} />
      {config.passwordConfirmErrorText && (
        <Text {...config.passwordConfirmErrorText} />
      )}
      <Field {...config.termsField} />
      {config.termsErrorText && <Text {...config.termsErrorText} />}
      <Field {...config.privacyField} />
      {config.privacyErrorText && <Text {...config.privacyErrorText} />}
      <Field {...config.cookiesField} />
      {config.cookiesErrorText && <Text {...config.cookiesErrorText} />}
      <Field {...config.amlField} />
      {config.amlErrorText && <Text {...config.amlErrorText} />}
      <Field {...config.newsletterField} />
      {config.errorText && <Text {...config.errorText} />}
      {config.successText && <Text {...config.successText} />}
      <Click {...config.registerButton} />
      <Text {...config.useSocial} />
    </form>
  );
};

export default Register;
