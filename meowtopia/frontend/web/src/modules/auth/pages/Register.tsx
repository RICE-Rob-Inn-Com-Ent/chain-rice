import React from "react";
import Button from "../../../components/Button";
import Field from "../../../components/Field";
import Checkbox from "../../../components/Checkbox";
import Message from "../../../components/Message";
import { registerMessages } from "../configs/pages";
import type { RegisterFormData } from "../interfaces/pages";

interface RegisterProps {
  formData: RegisterFormData;
  loading: boolean;
  error: string;
  success: string;
  onInputChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => void;
  onSubmit: (e: React.FormEvent) => void;
  onSocialRegister: (provider: any) => void;
  onLogin: () => void;
}

const Register: React.FC<RegisterProps> = ({
  formData,
  loading,
  error,
  success,
  onInputChange,
  onSubmit,
  onSocialRegister,
  onLogin,
}) => {
  const messages = registerMessages;

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
              label={messages.fields.fullName.label}
              icon={messages.fields.fullName.icon}
              type={messages.fields.fullName.type}
              name="fullName"
              value={formData.fullName}
              onChange={onInputChange}
              placeholder={messages.fields.fullName.placeholder}
              required={messages.fields.fullName.required}
            />

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

            <Field
              label={messages.fields.confirmPassword.label}
              icon={messages.fields.confirmPassword.icon}
              type={messages.fields.confirmPassword.type}
              name="confirmPassword"
              value={formData.confirmPassword}
              onChange={onInputChange}
              placeholder={messages.fields.confirmPassword.placeholder}
              required={messages.fields.confirmPassword.required}
            />
          </div>

          <div className="space-y-4">
            <Checkbox
              label={messages.fields.terms.label}
              checked={formData.terms}
              onChange={() => onInputChange({
                target: {
                  name: "terms",
                  type: "checkbox",
                  checked: !formData.terms,
                },
              } as React.ChangeEvent<HTMLInputElement>)}
              required
            />

            {messages.fields.marketing && (
              <Checkbox
                label={messages.fields.marketing.label}
                checked={formData.marketing || false}
                onChange={() => onInputChange({
                  target: {
                    name: "marketing",
                    type: "checkbox",
                    checked: !(formData.marketing || false),
                  },
                } as React.ChangeEvent<HTMLInputElement>)}
              />
            )}
          </div>

          {error && <Message message={error} />}
          {success && <div className="text-green-600 text-center">{success}</div>}

          <Button
            type="submit"
            loading={loading}
            disabled={loading}
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            {loading ? messages.loading : messages.buttons.register}
          </Button>
        </form>

        <div className="text-center">
          <span className="text-gray-600">{messages.hasAccount} </span>
          <Button
            type="button"
            onClick={onLogin}
            className="text-blue-600 hover:text-blue-500"
          >
            {messages.buttons.login}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default Register; 