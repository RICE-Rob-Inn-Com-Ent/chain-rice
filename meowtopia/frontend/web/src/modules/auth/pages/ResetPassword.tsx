import React from "react";
import { Text, TextProps } from "@/components/Text";
import { Field, FieldProps } from "@/components/Field";
import { Click, ClickProps } from "@/components/Click";
import resetPasswordConfig from "../configs/resetPasswordConfig";

const ResetPassword: React.FC = () => {
  const formProps = resetPasswordConfig.resetPasswordForm.useResetPasswordForm();
  return (
    <form {...resetPasswordConfig.resetPasswordForm} {...formProps.formProps}>
      <Text {...resetPasswordConfig.pageTitle} />
      <Field {...resetPasswordConfig.passwordField} {...formProps.passwordFieldProps} />
      {formProps.error && <Text {...resetPasswordConfig.errorText}>{formProps.error}</Text>}
      {formProps.success && <Text {...resetPasswordConfig.successText}>{formProps.success}</Text>}
      <Click {...resetPasswordConfig.changeButton} {...formProps.changeButtonProps} />
    </form>
  );
};

export default ResetPassword;
