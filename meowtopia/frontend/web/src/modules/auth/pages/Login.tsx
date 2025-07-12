import React from "react";
import Button from "../../../components/Button";
import Field from "../../../components/Field";
import Checkbox from "../../../components/Checkbox";
import Message from "../../../components/Message";
import { loginMessages } from "../configs/pages";
import type { LoginFormData } from "../interfaces/pages";

interface LoginProps {
  formData: LoginFormData;
  loading: boolean;
  error: string;
  success: string;
  onInputChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  onSubmit: (e: React.FormEvent) => void;
  onSocialLogin: (provider: any) => void;
  onForgotPassword: () => void;
  onRegister: () => void;
}

const Login: React.FC<LoginProps> = ({
  formData,
  loading,
  error,
  success,
  onInputChange,
  onSubmit,
  onSocialLogin,
  onForgotPassword,
  onRegister,
}) => {
  const messages = loginMessages;

  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {messages.title}
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            {messages.subtitle}
          </p>
        </div>

        <form onSubmit={onSubmit} className="mt-8 space-y-6">
          <div className="space-y-4">
            <Field
              label={messages.fields.email.label}
              icon={messages.fields.email.icon}
              type={messages.fields.email.type}
              name="email"
              value={formData.email}
              onChange={onInputChange}
              placeholder={messages.fields.email.placeholder}
              required={messages.fields.email.required}
            />

            <Field
              label={messages.fields.password.label}
              icon={messages.fields.password.icon}
              type={messages.fields.password.type}
              name="password"
              value={formData.password}
              onChange={onInputChange}
              placeholder={messages.fields.password.placeholder}
              required={messages.fields.password.required}
            />
          </div>

          <div className="flex items-center justify-between">
            <Checkbox
              label={messages.fields.rememberMe.label}
              checked={formData.rememberMe}
              onChange={() =>
                onInputChange({
                  target: {
                    name: "rememberMe",
                    type: "checkbox",
                    checked: !formData.rememberMe,
                  },
                } as React.ChangeEvent<HTMLInputElement>)
              }
            />
            <Button
              type="button"
              onClick={onForgotPassword}
              className="text-sm text-blue-600 hover:text-blue-500"
            >
              {messages.buttons.forgotPassword}
            </Button>
          </div>

          {error && <Message message={error} />}
          {success && <div className="text-green-600 text-center">{success}</div>}

          <Button
            type="submit"
            loading={loading}
            disabled={loading}
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            {loading ? messages.loading : messages.buttons.login}
          </Button>
        </form>

        <div className="text-center">
          <span className="text-gray-600">{messages.noAccount} </span>
          <Button
            type="button"
            onClick={onRegister}
            className="text-blue-600 hover:text-blue-500"
          >
            {messages.buttons.register}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default Login;
