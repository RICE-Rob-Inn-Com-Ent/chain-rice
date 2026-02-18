"use client";

import React, { useState } from "react";
import { Icon } from "@iconify/react";

const Contact: React.FC = () => {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    subject: "",
    message: "",
    type: "general"
  });

  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: Implement actual form submission
    console.log("Form submitted:", formData);
    setSubmitted(true);
    setTimeout(() => setSubmitted(false), 3000);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black py-20">
      <div className="container mx-auto px-6">
        {/* Header */}
        <div className="max-w-4xl mx-auto text-center mb-16">
          <h1 className="text-5xl md:text-6xl font-bold font-orbitron mb-6 bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
            Get in Touch
          </h1>
          <p className="text-xl text-gray-300">
            Have questions? We'd love to hear from you. Send us a message and we'll respond as soon as possible.
          </p>
        </div>

        <div className="max-w-6xl mx-auto grid md:grid-cols-3 gap-8">
          {/* Contact Info */}
          <div className="space-y-6">
            <div className="bg-gradient-to-br from-gray-900 to-gray-800 p-6 rounded-xl border border-gray-700">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Icon icon="mdi:email" className="text-2xl" />
                </div>
                <div>
                  <h3 className="font-semibold mb-1">Email</h3>
                  <p className="text-sm text-gray-400">contact@rice.pl</p>
                  <p className="text-sm text-gray-400">support@rice.pl</p>
                </div>
              </div>
            </div>

            <div className="bg-gradient-to-br from-gray-900 to-gray-800 p-6 rounded-xl border border-gray-700">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-purple-600 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Icon icon="mdi:map-marker" className="text-2xl" />
                </div>
                <div>
                  <h3 className="font-semibold mb-1">Location</h3>
                  <p className="text-sm text-gray-400">Warsaw, Poland</p>
                  <p className="text-sm text-gray-400">Remote Team Worldwide</p>
                </div>
              </div>
            </div>

            <div className="bg-gradient-to-br from-gray-900 to-gray-800 p-6 rounded-xl border border-gray-700">
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-pink-600 rounded-lg flex items-center justify-center flex-shrink-0">
                  <Icon icon="mdi:chat" className="text-2xl" />
                </div>
                <div>
                  <h3 className="font-semibold mb-1">Social Media</h3>
                  <div className="flex gap-3 mt-2">
                    <a href="#" className="text-gray-400 hover:text-blue-400 transition-colors">
                      <Icon icon="mdi:twitter" className="text-xl" />
                    </a>
                    <a href="#" className="text-gray-400 hover:text-blue-400 transition-colors">
                      <Icon icon="mdi:github" className="text-xl" />
                    </a>
                    <a href="#" className="text-gray-400 hover:text-blue-400 transition-colors">
                      <Icon icon="mdi:linkedin" className="text-xl" />
                    </a>
                    <a href="#" className="text-gray-400 hover:text-blue-400 transition-colors">
                      <Icon icon="mdi:discord" className="text-xl" />
                    </a>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-gradient-to-r from-blue-900/20 to-purple-900/20 p-6 rounded-xl border border-gray-700">
              <h3 className="font-semibold mb-2 flex items-center gap-2">
                <Icon icon="mdi:clock-outline" className="text-blue-400" />
                Response Time
              </h3>
              <p className="text-sm text-gray-400 mb-2">
                We typically respond within:
              </p>
              <ul className="text-sm text-gray-400 space-y-1">
                <li>• General inquiries: 24 hours</li>
                <li>• Support tickets: 4-8 hours</li>
                <li>• Enterprise: &lt;1 hour</li>
              </ul>
            </div>
          </div>

          {/* Contact Form */}
          <div className="md:col-span-2">
            <div className="bg-gradient-to-br from-gray-900 to-gray-800 p-8 rounded-xl border border-gray-700">
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid md:grid-cols-2 gap-6">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium mb-2">
                      Name
                    </label>
                    <input
                      type="text"
                      id="name"
                      name="name"
                      value={formData.name}
                      onChange={handleChange}
                      required
                      className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 focus:outline-none focus:border-blue-500 transition-colors"
                      placeholder="John Doe"
                    />
                  </div>
                  <div>
                    <label htmlFor="email" className="block text-sm font-medium mb-2">
                      Email
                    </label>
                    <input
                      type="email"
                      id="email"
                      name="email"
                      value={formData.email}
                      onChange={handleChange}
                      required
                      className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 focus:outline-none focus:border-blue-500 transition-colors"
                      placeholder="john@example.com"
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="type" className="block text-sm font-medium mb-2">
                    Inquiry Type
                  </label>
                  <select
                    id="type"
                    name="type"
                    value={formData.type}
                    onChange={handleChange}
                    className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 focus:outline-none focus:border-blue-500 transition-colors"
                  >
                    <option value="general">General Inquiry</option>
                    <option value="support">Technical Support</option>
                    <option value="sales">Sales & Pricing</option>
                    <option value="partnership">Partnership</option>
                    <option value="feedback">Feedback</option>
                  </select>
                </div>

                <div>
                  <label htmlFor="subject" className="block text-sm font-medium mb-2">
                    Subject
                  </label>
                  <input
                    type="text"
                    id="subject"
                    name="subject"
                    value={formData.subject}
                    onChange={handleChange}
                    required
                    className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 focus:outline-none focus:border-blue-500 transition-colors"
                    placeholder="How can we help you?"
                  />
                </div>

                <div>
                  <label htmlFor="message" className="block text-sm font-medium mb-2">
                    Message
                  </label>
                  <textarea
                    id="message"
                    name="message"
                    value={formData.message}
                    onChange={handleChange}
                    required
                    rows={6}
                    className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 focus:outline-none focus:border-blue-500 transition-colors resize-none"
                    placeholder="Tell us more about your inquiry..."
                  />
                </div>

                <button
                  type="submit"
                  className="w-full bg-gradient-to-r from-blue-600 to-purple-600 py-3 rounded-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all transform hover:scale-[1.02] flex items-center justify-center gap-2"
                >
                  {submitted ? (
                    <>
                      <Icon icon="mdi:check-circle" className="text-xl" />
                      Message Sent!
                    </>
                  ) : (
                    <>
                      <Icon icon="mdi:send" className="text-xl" />
                      Send Message
                    </>
                  )}
                </button>
              </form>
            </div>

            {/* FAQ Section */}
            <div className="mt-8 bg-gradient-to-br from-gray-900 to-gray-800 p-8 rounded-xl border border-gray-700">
              <h3 className="text-xl font-bold mb-4 font-orbitron">Quick Answers</h3>
              <div className="space-y-4">
                {[
                  {
                    q: "How do I get started with the free tier?",
                    a: "Download our desktop app, install it, and your GPU will be shared automatically when idle."
                  },
                  {
                    q: "Can I upgrade or downgrade my plan?",
                    a: "Yes, you can change your plan at any time. Changes take effect immediately."
                  },
                  {
                    q: "What GPUs are supported?",
                    a: "We support NVIDIA (RTX 30/40 series, A100, H100), AMD (RX 6000/7000), and Apple Silicon (M1/M2/M3)."
                  },
                  {
                    q: "How secure is my data?",
                    a: "All data is encrypted in transit and at rest. We follow industry best practices for security."
                  }
                ].map((faq, index) => (
                  <div key={index} className="border-l-2 border-blue-500 pl-4">
                    <h4 className="font-semibold mb-1 text-sm">{faq.q}</h4>
                    <p className="text-sm text-gray-400">{faq.a}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Contact;

