import React, { useState } from "react";
import { Icon } from "@iconify/react";

export const Contact: React.FC = () => {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    company: "",
    message: "",
    interest: "general",
  });

  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    console.log("Form submitted:", formData);
    setSubmitted(true);

    // Reset after 3 seconds
    setTimeout(() => {
      setSubmitted(false);
      setFormData({
        name: "",
        email: "",
        company: "",
        message: "",
        interest: "general",
      });
    }, 3000);
  };

  return (
    <div className="py-12">
      {/* Header */}
      <div className="max-w-6xl mx-auto px-6 mb-12 text-center">
        <h1 className="text-5xl font-bold text-white mb-4">Get in Touch</h1>
        <p className="text-xl text-gray-300">
          Have questions about GiPT-1? Want a custom solution? Let's talk.
        </p>
      </div>

      <div className="max-w-6xl mx-auto px-6">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
          {/* Contact Form */}
          <div>
            <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-8">
              <h2 className="text-2xl font-bold text-white mb-6">Send us a message</h2>

              {submitted ? (
                <div className="bg-green-900/30 border border-green-500/30 rounded-lg p-8 text-center">
                  <Icon icon="mdi:check-circle" width={64} className="text-green-400 mx-auto mb-4" />
                  <h3 className="text-xl font-bold text-white mb-2">Message Sent!</h3>
                  <p className="text-gray-300">We'll get back to you within 24 hours.</p>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-4">
                  {/* Name */}
                  <div>
                    <label className="block text-sm font-semibold text-gray-300 mb-2">Name *</label>
                    <input
                      type="text"
                      required
                      value={formData.name}
                      onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                      className="w-full bg-black/30 border border-white/10 rounded-lg p-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-purple-500"
                      placeholder="John Doe"
                    />
                  </div>

                  {/* Email */}
                  <div>
                    <label className="block text-sm font-semibold text-gray-300 mb-2">Email *</label>
                    <input
                      type="email"
                      required
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                      className="w-full bg-black/30 border border-white/10 rounded-lg p-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-purple-500"
                      placeholder="john@company.com"
                    />
                  </div>

                  {/* Company */}
                  <div>
                    <label className="block text-sm font-semibold text-gray-300 mb-2">Company (optional)</label>
                    <input
                      type="text"
                      value={formData.company}
                      onChange={(e) => setFormData({ ...formData, company: e.target.value })}
                      className="w-full bg-black/30 border border-white/10 rounded-lg p-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-purple-500"
                      placeholder="Your Company Inc."
                    />
                  </div>

                  {/* Interest */}
                  <div>
                    <label className="block text-sm font-semibold text-gray-300 mb-2">I'm interested in *</label>
                    <select
                      required
                      value={formData.interest}
                      onChange={(e) => setFormData({ ...formData, interest: e.target.value })}
                      className="w-full bg-black/30 border border-white/10 rounded-lg p-3 text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
                    >
                      <option value="general">General inquiry</option>
                      <option value="subscription">GiPT-1 Subscription</option>
                      <option value="enterprise">Enterprise solution</option>
                      <option value="development">Custom development</option>
                      <option value="integration">AI integration</option>
                      <option value="training">LoRA training service</option>
                    </select>
                  </div>

                  {/* Message */}
                  <div>
                    <label className="block text-sm font-semibold text-gray-300 mb-2">Message *</label>
                    <textarea
                      required
                      value={formData.message}
                      onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                      className="w-full h-32 bg-black/30 border border-white/10 rounded-lg p-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-purple-500"
                      placeholder="Tell us about your project or question..."
                    />
                  </div>

                  {/* Submit */}
                  <button
                    type="submit"
                    className="w-full px-6 py-4 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold rounded-lg transition flex items-center justify-center gap-2"
                  >
                    <Icon icon="mdi:send" width={20} />
                    Send Message
                  </button>
                </form>
              )}
            </div>
          </div>

          {/* Contact Info */}
          <div className="space-y-6">
            {/* Direct Contact */}
            <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-8">
              <h2 className="text-2xl font-bold text-white mb-6">Other ways to reach us</h2>

              <div className="space-y-4">
                <div className="flex items-start gap-4">
                  <div className="w-12 h-12 bg-purple-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Icon icon="mdi:email" width={24} className="text-purple-400" />
                  </div>
                  <div>
                    <div className="font-semibold text-white mb-1">Email</div>
                    <a href="mailto:hello@rice-ai.com" className="text-purple-400 hover:text-purple-300 transition">
                      hello@rice-ai.com
                    </a>
                  </div>
                </div>

                <div className="flex items-start gap-4">
                  <div className="w-12 h-12 bg-blue-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Icon icon="mdi:github" width={24} className="text-blue-400" />
                  </div>
                  <div>
                    <div className="font-semibold text-white mb-1">GitHub</div>
                    <a
                      href="https://github.com/rice-mono"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-400 hover:text-blue-300 transition"
                    >
                      github.com/rice-mono
                    </a>
                  </div>
                </div>

                <div className="flex items-start gap-4">
                  <div className="w-12 h-12 bg-pink-500/20 rounded-lg flex items-center justify-center flex-shrink-0">
                    <Icon icon="mdi:twitter" width={24} className="text-pink-400" />
                  </div>
                  <div>
                    <div className="font-semibold text-white mb-1">Twitter</div>
                    <a href="#" className="text-pink-400 hover:text-pink-300 transition">
                      @RiceAI
                    </a>
                  </div>
                </div>
              </div>
            </div>

            {/* Quick Links */}
            <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-8">
              <h3 className="text-xl font-bold text-white mb-4">Quick Links</h3>
              <div className="space-y-2">
                <a
                  href="http://localhost:3001"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-purple-400 hover:text-purple-300 transition flex items-center gap-2"
                >
                  <Icon icon="mdi:cog" width={20} />
                  Admin Panel (Port 3001)
                </a>
                <a
                  href="https://github.com/rice-mono"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-blue-400 hover:text-blue-300 transition flex items-center gap-2"
                >
                  <Icon icon="mdi:book-open-variant" width={20} />
                  Documentation
                </a>
                <a
                  href="https://npmjs.com/package/@rice-mono/ui-kit"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block text-green-400 hover:text-green-300 transition flex items-center gap-2"
                >
                  <Icon icon="mdi:npm" width={20} />
                  NPM Package
                </a>
              </div>
            </div>

            {/* Office Hours */}
            <div className="bg-gradient-to-br from-purple-900/20 to-pink-900/20 border border-purple-500/30 rounded-2xl p-8">
              <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                <Icon icon="mdi:clock-outline" width={24} />
                Response Time
              </h3>
              <ul className="space-y-2 text-sm text-gray-300">
                <li className="flex items-start gap-2">
                  <Icon icon="mdi:email-fast" className="text-purple-400 mt-0.5" width={20} />
                  <span>General inquiries: Within 24 hours</span>
                </li>
                <li className="flex items-start gap-2">
                  <Icon icon="mdi:phone" className="text-pink-400 mt-0.5" width={20} />
                  <span>Enterprise sales: Same business day</span>
                </li>
                <li className="flex items-start gap-2">
                  <Icon icon="mdi:headset" className="text-blue-400 mt-0.5" width={20} />
                  <span>Support (Pro/Enterprise): 1-4 hours</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

