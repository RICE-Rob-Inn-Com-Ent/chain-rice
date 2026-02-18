"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Icon } from "@iconify/react";

const SignUp: React.FC = () => {
  const [formData, setFormData] = useState({
    displayName: "",
    email: "",
    password: "",
    confirmPassword: "",
    agreeToTerms: false,
  });
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [passwordStrength, setPasswordStrength] = useState(0);

  const calculatePasswordStrength = (pwd: string) => {
    let strength = 0;
    if (pwd.length >= 8) strength++;
    if (pwd.length >= 12) strength++;
    if (/[a-z]/.test(pwd) && /[A-Z]/.test(pwd)) strength++;
    if (/\d/.test(pwd)) strength++;
    if (/[^a-zA-Z0-9]/.test(pwd)) strength++;
    return strength;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError("");

    if (formData.password !== formData.confirmPassword) {
      setError("Passwords do not match");
      setIsLoading(false);
      return;
    }

    if (!formData.agreeToTerms) {
      setError("Please agree to the Terms of Service and Privacy Policy");
      setIsLoading(false);
      return;
    }

    // TODO: Implement actual registration
    console.log("Sign up:", formData);
    
    setTimeout(() => {
      setIsLoading(false);
    }, 1000);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value, type, checked } = e.target;
    setFormData({
      ...formData,
      [name]: type === "checkbox" ? checked : value,
    });

    if (name === "password") {
      setPasswordStrength(calculatePasswordStrength(value));
    }
  };

  const getStrengthColor = () => {
    if (passwordStrength <= 1) return "bg-red-500";
    if (passwordStrength <= 3) return "bg-yellow-500";
    return "bg-green-500";
  };

  const getStrengthText = () => {
    if (passwordStrength <= 1) return "Weak";
    if (passwordStrength <= 3) return "Medium";
    return "Strong";
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full">
        {/* Logo/Header */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold font-orbitron bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent mb-2">
            RICE AI
          </h1>
          <h2 className="text-2xl font-semibold text-white mb-2">Create Account</h2>
          <p className="text-gray-400">Start training AI models today</p>
        </div>

        {/* Sign Up Form */}
        <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-8 border border-gray-700 shadow-2xl">
          {error && (
            <div className="mb-4 p-3 bg-red-900/20 border border-red-700 rounded-lg flex items-center gap-2">
              <Icon icon="mdi:alert-circle" className="text-red-400" />
              <span className="text-sm text-red-300">{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Display Name */}
            <div>
              <label htmlFor="displayName" className="block text-sm font-medium text-gray-300 mb-2">
                Display Name
              </label>
              <div className="relative">
                <Icon
                  icon="mdi:account"
                  className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"
                />
                <input
                  type="text"
                  id="displayName"
                  name="displayName"
                  value={formData.displayName}
                  onChange={handleChange}
                  required
                  className="w-full bg-gray-800 border border-gray-700 rounded-lg pl-10 pr-4 py-3 text-white focus:outline-none focus:border-blue-500 transition-colors"
                  placeholder="Your Name"
                />
              </div>
            </div>

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
              {formData.password && (
                <div className="mt-2">
                  <div className="flex items-center justify-between text-xs mb-1">
                    <span className="text-gray-400">Password strength:</span>
                    <span className={`font-semibold ${passwordStrength <= 1 ? "text-red-400" : passwordStrength <= 3 ? "text-yellow-400" : "text-green-400"}`}>
                      {getStrengthText()}
                    </span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full transition-all ${getStrengthColor()}`}
                      style={{ width: `${(passwordStrength / 5) * 100}%` }}
                    ></div>
                  </div>
                </div>
              )}
            </div>

            {/* Confirm Password */}
            <div>
              <label htmlFor="confirmPassword" className="block text-sm font-medium text-gray-300 mb-2">
                Confirm Password
              </label>
              <div className="relative">
                <Icon
                  icon="mdi:lock-check"
                  className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"
                />
                <input
                  type={showPassword ? "text" : "password"}
                  id="confirmPassword"
                  name="confirmPassword"
                  value={formData.confirmPassword}
                  onChange={handleChange}
                  required
                  className="w-full bg-gray-800 border border-gray-700 rounded-lg pl-10 pr-4 py-3 text-white focus:outline-none focus:border-blue-500 transition-colors"
                  placeholder="••••••••"
                />
              </div>
            </div>

            {/* Terms Agreement */}
            <div>
              <label className="flex items-start gap-2">
                <input
                  type="checkbox"
                  name="agreeToTerms"
                  checked={formData.agreeToTerms}
                  onChange={handleChange}
                  className="w-4 h-4 mt-1 bg-gray-800 border-gray-700 rounded text-blue-600 focus:ring-blue-500 focus:ring-2"
                />
                <span className="text-sm text-gray-400">
                  I agree to the{" "}
                  <Link href="/terms" className="text-blue-400 hover:text-blue-300">
                    Terms of Service
                  </Link>{" "}
                  and{" "}
                  <Link href="/privacy" className="text-blue-400 hover:text-blue-300">
                    Privacy Policy
                  </Link>
                </span>
              </label>
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
                  Creating account...
                </>
              ) : (
                <>
                  <Icon icon="mdi:account-plus" className="text-xl" />
                  Create Account
                </>
              )}
            </button>
          </form>

          {/* Social Sign Up */}
          <div className="mt-6">
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-gray-700"></div>
              </div>
              <div className="relative flex justify-center text-sm">
                <span className="px-2 bg-gray-800 text-gray-400">Or sign up with</span>
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

          {/* Sign In Link */}
          <div className="mt-6 text-center">
            <p className="text-gray-400">
              Already have an account?{" "}
              <Link href="/auth/signin" className="text-blue-400 hover:text-blue-300 font-semibold transition-colors">
                Sign in
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SignUp;

