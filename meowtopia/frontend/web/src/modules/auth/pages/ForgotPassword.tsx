import React from "react";
import { Text, TextProps } from "@/components/Text";
import { Field, FieldProps } from "@/components/Field";
import { Click, ClickProps } from "@/components/Click";
import forgotPasswordConfig from "../configs/forgotPasswordConfig";

const ForgotPassword: React.FC = () => {
  const formProps = forgotPasswordConfig.forgotPasswordForm.useForgotPasswordForm();
  return (
    <form {...forgotPasswordConfig.forgotPasswordForm} {...formProps.formProps}>
      <Text {...forgotPasswordConfig.pageTitle} />
      <Field {...forgotPasswordConfig.emailField} {...formProps.emailFieldProps} />
      {formProps.error && <Text {...forgotPasswordConfig.errorText}>{formProps.error}</Text>}
      {formProps.success && <Text {...forgotPasswordConfig.successText}>{formProps.success}</Text>}
      <Click {...forgotPasswordConfig.sendButton} {...formProps.sendButtonProps} />
    </form>
  );
};

export default ForgotPassword;
