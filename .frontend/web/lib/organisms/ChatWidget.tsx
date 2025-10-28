"use client";
import React, { useState } from "react";

/**
 * ChatWidget - Floating chat button with expandable chat window
 */
export const ChatWidget: React.FC = () => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="fixed bottom-6 right-6 z-50">
      {isOpen && (
        <div className="mb-4 h-96 w-80 rounded-lg border border-gray-200 bg-white shadow-2xl dark:border-gray-700 dark:bg-gray-800">
          <div className="flex items-center justify-between border-b border-gray-200 p-4 dark:border-gray-700">
            <h3 className="font-semibold text-gray-900 dark:text-white">
              💬 Chat z AI
            </h3>
            <button
              onClick={() => setIsOpen(false)}
              className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
            >
              ✕
            </button>
          </div>
          <div className="flex h-[calc(100%-60px)] flex-col p-4">
            <div className="flex-1 overflow-y-auto">
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Witaj! Czym mogę Ci pomóc?
              </p>
            </div>
            <div className="mt-4 flex gap-2">
              <input
                type="text"
                placeholder="Wpisz wiadomość..."
                className="flex-1 rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-green-500 focus:outline-none dark:border-gray-600 dark:bg-gray-700 dark:text-white"
              />
              <button className="rounded-lg bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700">
                →
              </button>
            </div>
          </div>
        </div>
      )}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex h-14 w-14 items-center justify-center rounded-full bg-green-600 text-2xl text-white shadow-lg transition-transform hover:scale-110 hover:bg-green-700"
      >
        💬
      </button>
    </div>
  );
};

export default ChatWidget;

