import React from "react";
import Button from "../../../components/Button";
import Field from "../../../components/Field";
import Message from "../../../components/Message";
import { resetPasswordMessages } from "../configs/pages";
import type { ResetPasswordFormData } from "../interfaces/pages";

interface ResetPasswordProps {
  formData: ResetPasswordFormData;
  loading: boolean;
  error: string;
  success: string;
  onInputChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  onSubmit: (e: React.FormEvent) => void;
  onBackToLogin: () => void;
}

const ResetPassword: React.FC<ResetPasswordProps> = ({
  formData,
  loading,
  error,
  success,
  onInputChange,
  onSubmit,
  onBackToLogin,
}) => {
  const messages = resetPasswordMessages;

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

          {error && <Message message={error} />}
          {success && <div className="text-green-600 text-center">{success}</div>}

          <Button
            type="submit"
            loading={loading}
            disabled={loading}
            className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
          >
            {loading ? messages.loading : messages.buttons.resetPassword}
          </Button>
        </form>

        <div className="text-center">
          <Button
            type="button"
            onClick={onBackToLogin}
            className="text-blue-600 hover:text-blue-500"
          >
            {messages.buttons.backToLogin}
          </Button>
        </div>
      </div>
    </div>
  );
};

export default ResetPassword; 