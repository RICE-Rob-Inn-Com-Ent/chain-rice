import React from "react";
import { Link } from "react-router-dom";
import { Icon } from "@iconify/react";

export const Prices: React.FC = () => {
  return (
    <div className="py-12">
      {/* Header */}
      <div className="max-w-7xl mx-auto px-6 mb-16 text-center">
        <h1 className="text-5xl md:text-6xl font-bold text-white mb-4">Simple, Transparent Pricing</h1>
        <p className="text-xl text-gray-300">
          Choose the perfect plan for your AI needs. All plans include GiPT-1 access.
        </p>
      </div>

      {/* GiPT-1 Plans */}
      <div className="max-w-7xl mx-auto px-6 mb-16">
        <h2 className="text-3xl font-bold text-white text-center mb-8">GiPT-1 Subscription Plans</h2>
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Starter */}
          <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-8 hover:border-purple-500/30 transition">
            <div className="text-4xl mb-4">🌱</div>
            <h3 className="text-2xl font-bold text-white mb-2">Starter</h3>
            <p className="text-gray-400 text-sm mb-6">Perfect for individuals and small projects</p>
            
            <div className="mb-6">
              <div className="text-4xl font-bold text-white mb-1">$49</div>
              <div className="text-gray-400 text-sm">per month</div>
            </div>

            <ul className="space-y-3 mb-8 text-sm">
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-green-400 mt-0.5 flex-shrink-0" width={20} />
                <span>1,000 API calls/month</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-green-400 mt-0.5 flex-shrink-0" width={20} />
                <span>Text generation (Thoth, Maat, Khnum)</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-green-400 mt-0.5 flex-shrink-0" width={20} />
                <span>Community support</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-green-400 mt-0.5 flex-shrink-0" width={20} />
                <span>API documentation</span>
              </li>
            </ul>

            <button className="w-full bg-white/10 hover:bg-white/20 text-white font-semibold py-3 rounded-lg transition">
              Get Started
            </button>
          </div>

          {/* Pro */}
          <div className="bg-gradient-to-b from-purple-900/30 to-pink-900/30 rounded-2xl border-2 border-purple-500 p-8 relative transform scale-105">
            <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
              <span className="bg-gradient-to-r from-purple-600 to-pink-600 text-white text-xs px-4 py-1.5 rounded-full font-bold">
                MOST POPULAR
              </span>
            </div>
            
            <div className="text-4xl mb-4">🚀</div>
            <h3 className="text-2xl font-bold text-white mb-2">Pro</h3>
            <p className="text-gray-400 text-sm mb-6">For professionals and growing teams</p>
            
            <div className="mb-6">
              <div className="text-4xl font-bold text-white mb-1">$199</div>
              <div className="text-gray-400 text-sm">per month</div>
            </div>

            <ul className="space-y-3 mb-8 text-sm">
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5 flex-shrink-0" width={20} />
                <span>20,000 API calls/month</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5 flex-shrink-0" width={20} />
                <span>All 6 gods (full multimodal access)</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5 flex-shrink-0" width={20} />
                <span>Image generation (Ra - Stable Diffusion)</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5 flex-shrink-0" width={20} />
                <span>Vision & code analysis</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5 flex-shrink-0" width={20} />
                <span>Priority support</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5 flex-shrink-0" width={20} />
                <span>Custom LoRA training (1 model/month)</span>
              </li>
            </ul>

            <button className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold py-3 rounded-lg transition">
              Start Pro Trial
            </button>
          </div>

          {/* Enterprise */}
          <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-8 hover:border-white/20 transition">
            <div className="text-4xl mb-4">🏢</div>
            <h3 className="text-2xl font-bold text-white mb-2">Enterprise</h3>
            <p className="text-gray-400 text-sm mb-6">For large organizations with custom needs</p>
            
            <div className="mb-6">
              <div className="text-4xl font-bold text-white mb-1">Custom</div>
              <div className="text-gray-400 text-sm">contact for pricing</div>
            </div>

            <ul className="space-y-3 mb-8 text-sm">
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5 flex-shrink-0" width={20} />
                <span>Unlimited API calls</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5 flex-shrink-0" width={20} />
                <span>On-premise deployment option</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5 flex-shrink-0" width={20} />
                <span>Dedicated infrastructure</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5 flex-shrink-0" width={20} />
                <span>Custom model training</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5 flex-shrink-0" width={20} />
                <span>24/7 dedicated support</span>
              </li>
              <li className="flex items-start gap-2 text-gray-300">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5 flex-shrink-0" width={20} />
                <span>SLA guarantees</span>
              </li>
            </ul>

            <Link
              to="/contact"
              className="block w-full bg-blue-600 hover:bg-blue-700 text-white text-center font-semibold py-3 rounded-lg transition"
            >
              Contact Sales
            </Link>
          </div>
        </div>
      </div>

      {/* Development Services */}
      <div className="max-w-7xl mx-auto px-6 mb-16">
        <h2 className="text-3xl font-bold text-white text-center mb-8">Development Services</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6 hover:border-cyan-500/30 transition">
            <Icon icon="mdi:web" width={40} className="text-cyan-400 mb-3" />
            <h4 className="text-white font-semibold mb-2 text-lg">Web Development</h4>
            <p className="text-gray-400 text-sm mb-3">Landing pages, dashboards, web apps</p>
            <p className="text-cyan-400 font-bold text-xl">from $5,000</p>
          </div>

          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6 hover:border-green-500/30 transition">
            <Icon icon="mdi:cellphone" width={40} className="text-green-400 mb-3" />
            <h4 className="text-white font-semibold mb-2 text-lg">Mobile Apps</h4>
            <p className="text-gray-400 text-sm mb-3">iOS, Android, React Native, Flutter</p>
            <p className="text-green-400 font-bold text-xl">from $15,000</p>
          </div>

          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6 hover:border-orange-500/30 transition">
            <Icon icon="mdi:robot-outline" width={40} className="text-orange-400 mb-3" />
            <h4 className="text-white font-semibold mb-2 text-lg">AI Integration</h4>
            <p className="text-gray-400 text-sm mb-3">Custom AI features, chatbots</p>
            <p className="text-orange-400 font-bold text-xl">from $8,000</p>
          </div>

          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6 hover:border-purple-500/30 transition">
            <Icon icon="mdi:server" width={40} className="text-purple-400 mb-3" />
            <h4 className="text-white font-semibold mb-2 text-lg">Backend API</h4>
            <p className="text-gray-400 text-sm mb-3">REST, GraphQL, microservices</p>
            <p className="text-purple-400 font-bold text-xl">from $10,000</p>
          </div>
        </div>
      </div>

      {/* FAQ */}
      <div className="max-w-4xl mx-auto px-6">
        <h2 className="text-3xl font-bold text-white text-center mb-8">Frequently Asked Questions</h2>
        
        <div className="space-y-4">
          {[
            {
              q: "Can I use GiPT-1 on-premise?",
              a: "Yes! Enterprise plans include on-premise deployment with Docker. You maintain full control of your data and models.",
            },
            {
              q: "What's included in custom LoRA training?",
              a: "We help you prepare datasets, configure training parameters, train the model, and deploy it to your infrastructure.",
            },
            {
              q: "Do you offer discounts for startups?",
              a: "Yes! Startups with < 2 years operation and < $1M revenue qualify for 50% discount on first 6 months.",
            },
            {
              q: "What hardware do I need for self-hosted?",
              a: "Minimum: 16GB RAM, 6GB VRAM GPU (RTX 3060 or better). Recommended: 32GB RAM, 12GB VRAM (RTX 3080 or better).",
            },
          ].map((faq, i) => (
            <details
              key={i}
              className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6 hover:border-white/20 transition group"
            >
              <summary className="text-white font-semibold cursor-pointer flex items-center justify-between">
                {faq.q}
                <Icon
                  icon="mdi:chevron-down"
                  width={24}
                  className="text-gray-400 group-open:rotate-180 transition-transform"
                />
              </summary>
              <p className="text-gray-400 text-sm mt-4">{faq.a}</p>
            </details>
          ))}
        </div>
      </div>

      {/* CTA */}
      <div className="max-w-4xl mx-auto px-6 mt-16 text-center">
        <div className="bg-gradient-to-r from-purple-900/30 to-pink-900/30 border border-purple-500/30 rounded-2xl p-12">
          <h3 className="text-3xl font-bold text-white mb-4">Need a custom solution?</h3>
          <p className="text-gray-300 mb-6">
            Contact our team to discuss your specific requirements and get a tailored quote.
          </p>
          <Link
            to="/contact"
            className="inline-block px-8 py-4 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold rounded-lg transition text-lg"
          >
            Contact Sales Team
          </Link>
        </div>
      </div>
    </div>
  );
};

