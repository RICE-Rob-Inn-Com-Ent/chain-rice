"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Icon } from "@iconify/react";

const SignIn: React.FC = () => {
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    rememberMe: false,
  });
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError("");

    // TODO: Implement actual authentication
    console.log("Sign in:", formData);
    
    setTimeout(() => {
      setIsLoading(false);
      // Simulate error for demo
      // setError("Invalid email or password");
    }, 1000);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    setFormData({
      ...formData,
      [name]: type === "checkbox" ? checked : value,
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full">
        {/* Logo/Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold font-orbitron bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent mb-2">
            RICE AI
          </h1>
          <h2 className="text-2xl font-semibold text-white mb-2">Welcome Back</h2>
          <p className="text-gray-400">Sign in to your account</p>
        </div>

        {/* Sign In Form */}
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
                  value={formData.email}
                  onChange={handleChange}
                  required
                  className="w-full bg-gray-800 border border-gray-700 rounded-lg pl-10 pr-4 py-3 text-white focus:outline-none focus:border-blue-500 transition-colors"
                  placeholder="you@example.com"
                />
              </div>
            </div>

            {/* Password */}
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-300 mb-2">
                Password
              </label>
              <div className="relative">
                <Icon
                  icon="mdi:lock"
                  className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"
                />
                <input
                  type={showPassword ? "text" : "password"}
                  id="password"
                  name="password"
                  value={formData.password}
                  onChange={handleChange}
                  required
                  className="w-full bg-gray-800 border border-gray-700 rounded-lg pl-10 pr-12 py-3 text-white focus:outline-none focus:border-blue-500 transition-colors"
                  placeholder="••••••••"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-white transition-colors"
                >
                  <Icon icon={showPassword ? "mdi:eye-off" : "mdi:eye"} className="text-xl" />
                </button>
              </div>
            </div>

            {/* Remember Me & Forgot Password */}
            <div className="flex items-center justify-between">
              <label className="flex items-center">
                <input
                  type="checkbox"
                  name="rememberMe"
                  checked={formData.rememberMe}
                  onChange={handleChange}
                  className="w-4 h-4 bg-gray-800 border-gray-700 rounded text-blue-600 focus:ring-blue-500 focus:ring-2"
                />
                <span className="ml-2 text-sm text-gray-400">Remember me</span>
              </label>
              <Link
                href="/auth/forgotpassword"
                className="text-sm text-blue-400 hover:text-blue-300 transition-colors"
              >
                Forgot password?
              </Link>
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
                  Signing in...
                </>
              ) : (
                <>
                  <Icon icon="mdi:login" className="text-xl" />
                  Sign In
                </>
              )}
            </button>
          </form>

          {/* Social Sign In */}
          <div className="mt-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-700"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-gray-800 text-gray-400">Or continue with</span>
              </div>
            </div>

            <div className="mt-6 grid grid-cols-3 gap-3">
              <button className="flex items-center justify-center bg-gray-800 border border-gray-700 rounded-lg py-2 hover:bg-gray-700 transition-colors">
                <Icon icon="mdi:google" className="text-xl" />
              </button>
              <button className="flex items-center justify-center bg-gray-800 border border-gray-700 rounded-lg py-2 hover:bg-gray-700 transition-colors">
                <Icon icon="mdi:github" className="text-xl" />
              </button>
              <button className="flex items-center justify-center bg-gray-800 border border-gray-700 rounded-lg py-2 hover:bg-gray-700 transition-colors">
                <Icon icon="mdi:twitter" className="text-xl" />
              </button>
            </div>
          </div>

          {/* Sign Up Link */}
          <div className="mt-6 text-center">
            <p className="text-gray-400">
              Don't have an account?{" "}
              <Link href="/auth/signup" className="text-blue-400 hover:text-blue-300 font-semibold transition-colors">
                Sign up
              </Link>
            </p>
          </div>
        </div>

        {/* Features */}
        <div className="mt-8 text-center">
          <div className="flex items-center justify-center gap-6 text-sm text-gray-500">
            <div className="flex items-center gap-1">
              <Icon icon="mdi:shield-check" className="text-green-400" />
              <span>Secure</span>
            </div>
            <div className="flex items-center gap-1">
              <Icon icon="mdi:lock" className="text-blue-400" />
              <span>Encrypted</span>
            </div>
            <div className="flex items-center gap-1">
              <Icon icon="mdi:check-decagram" className="text-purple-400" />
              <span>Verified</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SignIn;

