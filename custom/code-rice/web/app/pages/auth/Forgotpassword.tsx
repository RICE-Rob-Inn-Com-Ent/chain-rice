"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Icon } from "@iconify/react";

const ForgotPassword: React.FC = () => {
  const [email, setEmail] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError("");

    // TODO: Implement actual password reset
    console.log("Password reset for:", email);
    
    setTimeout(() => {
      setIsLoading(false);
      setSuccess(true);
    }, 1000);
  };

  if (success) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-md w-full">
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-green-600 rounded-full mb-4">
              <Icon icon="mdi:check" className="text-4xl text-white" />
            </div>
            <h2 className="text-2xl font-semibold text-white mb-2">Check Your Email</h2>
            <p className="text-gray-400">
              We've sent password reset instructions to <strong className="text-white">{email}</strong>
            </p>
          </div>

          <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-8 border border-gray-700">
            <div className="space-y-4 text-sm text-gray-400">
              <div className="flex items-start gap-3">
                <Icon icon="mdi:information" className="text-blue-400 mt-0.5 flex-shrink-0" />
                <p>The email may take a few minutes to arrive. Check your spam folder if you don't see it.</p>
              </div>
              <div className="flex items-start gap-3">
                <Icon icon="mdi:clock-outline" className="text-purple-400 mt-0.5 flex-shrink-0" />
                <p>The password reset link will expire in 24 hours.</p>
              </div>
            </div>

            <div className="mt-6 flex flex-col gap-3">
              <Link
                href="/auth/signin"
                className="w-full bg-gradient-to-r from-blue-600 to-purple-600 text-white py-3 rounded-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all text-center"
              >
                Back to Sign In
              </Link>
              <button
                onClick={() => {
                  setSuccess(false);
                  setEmail("");
                }}
                className="w-full bg-gray-800 border border-gray-700 text-white py-3 rounded-lg font-semibold hover:bg-gray-700 transition-all"
              >
                Resend Email
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full">
        {/* Logo/Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold font-orbitron bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent mb-2">
            RICE AI
          </h1>
          <h2 className="text-2xl font-semibold text-white mb-2">Reset Password</h2>
          <p className="text-gray-400">Enter your email to receive reset instructions</p>
        </div>

        {/* Reset Form */}
        <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-8 border border-gray-700 shadow-2xl">
          {error && (
            <div className="mb-4 p-3 bg-red-900/20 border border-red-700 rounded-lg flex items-center gap-2">
              <Icon icon="mdi:alert-circle" className="text-red-400" />
              <span className="text-sm text-red-300">{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Email */}
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-300 mb-2">
                Email Address
              </label>
              <div className="relative">
                <Icon
                  icon="mdi:email"
                  className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"
                />
                <input
                  type="email"
                  id="email"
                  name="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="w-full bg-gray-800 border border-gray-700 rounded-lg pl-10 pr-4 py-3 text-white focus:outline-none focus:border-blue-500 transition-colors"
                  placeholder="you@example.com"
                />
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full bg-gradient-to-r from-blue-600 to-purple-600 text-white py-3 rounded-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all transform hover:scale-[1.02] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <>
                  <Icon icon="mdi:loading" className="text-xl animate-spin" />
                  Sending...
                </>
              ) : (
                <>
                  <Icon icon="mdi:email-fast" className="text-xl" />
                  Send Reset Link
                </>
              )}
            </button>
          </form>

          {/* Back to Sign In */}
          <div className="mt-6 text-center">
            <Link
              href="/auth/signin"
              className="text-sm text-gray-400 hover:text-white transition-colors inline-flex items-center gap-1"
            >
              <Icon icon="mdi:arrow-left" />
              Back to Sign In
            </Link>
          </div>
        </div>

        {/* Security Note */}
        <div className="mt-6 bg-blue-900/20 border border-blue-700/50 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <Icon icon="mdi:shield-lock" className="text-blue-400 mt-0.5 flex-shrink-0" />
            <p className="text-sm text-gray-400">
              For security reasons, we'll send the reset link even if the email doesn't exist in our system.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ForgotPassword;

