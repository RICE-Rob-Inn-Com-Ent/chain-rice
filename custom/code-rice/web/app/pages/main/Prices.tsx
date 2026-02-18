"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Icon } from "@iconify/react";

const Prices: React.FC = () => {
  const [billingCycle, setBillingCycle] = useState<"monthly" | "yearly">("monthly");

  const plans = [
    {
      tier: "Free",
      price: { monthly: 0, yearly: 0 },
      description: "Perfect for local AI development",
      features: [
        "Local AI models only",
        "Unlimited model training (local)",
        "Mandatory GPU sharing when idle",
        "5GB dataset storage",
        "Community support",
        "Access to marketplace (download required)",
        "Basic benchmarking tools"
      ],
      requirements: ["GPU sharing required", "Desktop app installation"],
      cta: "Download Free",
      popular: false,
      color: "gray"
    },
    {
      tier: "Simple",
      price: { monthly: 29, yearly: 290 },
      description: "Cloud training for individuals",
      features: [
        "20 GPU hours/month",
        "Up to 5 trained models",
        "50GB dataset storage",
        "Cloud training access",
        "Email support",
        "Full marketplace access",
        "Advanced benchmarking",
        "API access"
      ],
      requirements: [],
      cta: "Start Simple",
      popular: false,
      color: "blue"
    },
    {
      tier: "Plus",
      price: { monthly: 79, yearly: 790 },
      description: "Professional AI development",
      features: [
        "100 GPU hours/month",
        "Up to 20 trained models",
        "200GB dataset storage",
        "Priority GPU allocation",
        "Priority support",
        "Custom genes creation",
        "Team collaboration (3 users)",
        "Advanced analytics"
      ],
      requirements: [],
      cta: "Go Plus",
      popular: true,
      color: "purple"
    },
    {
      tier: "Premium",
      price: { monthly: 199, yearly: 1990 },
      description: "For power users and teams",
      features: [
        "500 GPU hours/month",
        "Unlimited trained models",
        "1TB dataset storage",
        "Dedicated GPU instances",
        "24/7 priority support",
        "Advanced model versioning",
        "Team collaboration (10 users)",
        "Private model hosting",
        "SLA guarantee"
      ],
      requirements: [],
      cta: "Go Premium",
      popular: false,
      color: "pink"
    },
    {
      tier: "Enterprise",
      price: { monthly: "Custom", yearly: "Custom" },
      description: "Custom solutions for organizations",
      features: [
        "Unlimited GPU hours",
        "Unlimited everything",
        "Custom storage solutions",
        "On-premise deployment option",
        "Dedicated account manager",
        "Custom integrations",
        "White-label solutions",
        "Custom SLA",
        "Training and onboarding"
      ],
      requirements: [],
      cta: "Contact Sales",
      popular: false,
      color: "orange"
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black py-20">
      <div className="container mx-auto px-6">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-5xl md:text-6xl font-bold font-orbitron mb-4">
            Pricing Plans
          </h1>
          <p className="text-xl text-gray-300 mb-8">
            Choose the perfect plan for your AI development needs
          </p>
          
          {/* Billing Toggle */}
          <div className="inline-flex items-center bg-gray-900 rounded-lg p-1">
            <button
              onClick={() => setBillingCycle("monthly")}
              className={`px-6 py-2 rounded-md transition-all ${
                billingCycle === "monthly"
                  ? "bg-blue-600 text-white"
                  : "text-gray-400 hover:text-white"
              }`}
            >
              Monthly
            </button>
            <button
              onClick={() => setBillingCycle("yearly")}
              className={`px-6 py-2 rounded-md transition-all ${
                billingCycle === "yearly"
                  ? "bg-blue-600 text-white"
                  : "text-gray-400 hover:text-white"
              }`}
            >
              Yearly
              <span className="ml-2 text-xs text-green-400">Save 17%</span>
            </button>
          </div>
        </div>

        {/* Pricing Cards */}
        <div className="grid md:grid-cols-3 lg:grid-cols-5 gap-6 mb-12">
          {plans.map((plan, index) => (
            <div
              key={index}
              className={`relative bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-6 border ${
                plan.popular
                  ? "border-purple-500 shadow-2xl shadow-purple-500/20"
                  : "border-gray-700"
              } hover:border-${plan.color}-500 transition-all hover:transform hover:scale-105`}
            >
              {plan.popular && (
                <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                  <span className="bg-gradient-to-r from-purple-600 to-pink-600 px-4 py-1 rounded-full text-sm font-semibold">
                    Most Popular
                  </span>
                </div>
              )}
              
              <div className="mb-6">
                <h3 className="text-2xl font-bold font-orbitron mb-2">{plan.tier}</h3>
                <p className="text-gray-400 text-sm mb-4">{plan.description}</p>
                <div className="flex items-baseline">
                  <span className="text-4xl font-bold">
                    {typeof plan.price[billingCycle] === "number" ? "$" : ""}
                    {plan.price[billingCycle]}
                  </span>
                  {typeof plan.price[billingCycle] === "number" && plan.price[billingCycle] > 0 && (
                    <span className="text-gray-400 ml-2">
                      /{billingCycle === "monthly" ? "mo" : "yr"}
                    </span>
                  )}
                </div>
              </div>

              <ul className="space-y-3 mb-6">
                {plan.features.map((feature, i) => (
                  <li key={i} className="flex items-start">
                    <Icon icon="mdi:check-circle" className="text-green-400 mr-2 mt-1 flex-shrink-0" />
                    <span className="text-sm text-gray-300">{feature}</span>
                  </li>
                ))}
              </ul>

              {plan.requirements.length > 0 && (
                <div className="mb-6 p-3 bg-yellow-900/20 border border-yellow-700/50 rounded-lg">
                  {plan.requirements.map((req, i) => (
                    <p key={i} className="text-xs text-yellow-300 flex items-start">
                      <Icon icon="mdi:information" className="mr-1 mt-0.5 flex-shrink-0" />
                      {req}
                    </p>
                  ))}
                </div>
              )}

              <Link
                href={plan.tier === "Enterprise" ? "/contact" : "/auth/signup"}
                className={`block w-full py-3 text-center rounded-lg font-semibold transition-all ${
                  plan.popular
                    ? "bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700"
                    : `bg-${plan.color}-600 hover:bg-${plan.color}-700`
                }`}
              >
                {plan.cta}
              </Link>
            </div>
          ))}
        </div>

        {/* GPU Sharing Info */}
        <div className="bg-gradient-to-r from-blue-900/20 to-purple-900/20 rounded-xl p-8 border border-gray-700">
          <div className="flex items-start gap-4">
            <Icon icon="mdi:information-outline" className="text-4xl text-blue-400 flex-shrink-0" />
            <div>
              <h3 className="text-xl font-bold mb-2 font-orbitron">About GPU Sharing (Free Tier)</h3>
              <p className="text-gray-300 mb-4">
                The Free tier requires you to install our desktop application that shares your GPU when idle. 
                This helps power the network and provides cloud training for paid users. In return, you get:
              </p>
              <ul className="grid md:grid-cols-2 gap-2">
                <li className="flex items-center text-sm">
                  <Icon icon="mdi:check" className="text-green-400 mr-2" />
                  Unlimited local model training
                </li>
                <li className="flex items-center text-sm">
                  <Icon icon="mdi:check" className="text-green-400 mr-2" />
                  Access to community models
                </li>
                <li className="flex items-center text-sm">
                  <Icon icon="mdi:check" className="text-green-400 mr-2" />
                  Priority when GPU is available
                </li>
                <li className="flex items-center text-sm">
                  <Icon icon="mdi:check" className="text-green-400 mr-2" />
                  Earn credits for upgrades
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Prices;

