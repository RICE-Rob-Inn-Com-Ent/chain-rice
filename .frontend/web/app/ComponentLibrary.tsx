import React, { useState } from "react";
import { Icon } from "@iconify/react";
import { useTheme } from "../lib/contexts/ThemeContext";
import { ThemeName, themeNames, themes } from "../themes";
import {
  Header1,
  Header2,
  Header3,
  Header4,
  Header5,
  Button1,
  Button2,
  Button3,
  Button4,
  Button5,
  Button6,
  Button7,
  Button8,
  Button9,
  Button10,
} from "../lib/base";

export const ComponentLibrary: React.FC = () => {
  const { themeName, setTheme } = useTheme();
  const [copiedCode, setCopiedCode] = useState<string | null>(null);

  const copyCode = (code: string, id: string) => {
    navigator.clipboard.writeText(code);
    setCopiedCode(id);
    setTimeout(() => setCopiedCode(null), 2000);
  };

  const headerExamples = [
    {
      id: "header1",
      name: "Header 1 - Centered",
      component: <Header1 logo="🏺" title="Egyptian AI" />,
      code: `<Header1 logo="🏺" title="Egyptian AI" />`,
    },
    {
      id: "header2",
      name: "Header 2 - Left Aligned",
      component: (
        <Header2
          logo="🏺"
          title="Dashboard"
          nav={
            <div className="flex gap-4 text-white">
              <a href="#">Home</a>
              <a href="#">About</a>
            </div>
          }
        />
      ),
      code: `<Header2 logo="🏺" title="Dashboard" nav={<nav>...</nav>} />`,
    },
    {
      id: "header3",
      name: "Header 3 - Transparent",
      component: <Header3 logo="🏺" title="Hero Section" />,
      code: `<Header3 logo="🏺" title="Hero Section" />`,
    },
    {
      id: "header4",
      name: "Header 4 - Sticky",
      component: <Header4 logo="🏺" title="Dashboard" />,
      code: `<Header4 logo="🏺" title="Dashboard" />`,
    },
    {
      id: "header5",
      name: "Header 5 - Mega Menu",
      component: (
        <Header5
          logo="🏺"
          title="Platform"
          menuItems={[
            {
              label: "Products",
              items: [
                { label: "Models", icon: "mdi:robot", onClick: () => {} },
                { label: "Training", icon: "mdi:dna", onClick: () => {} },
              ],
            },
          ]}
        />
      ),
      code: `<Header5 logo="🏺" title="Platform" menuItems={[...]} />`,
    },
  ];

  const buttonExamples = [
    {
      id: "btn1",
      name: "Button 1 - Solid",
      component: <Button1>Click Me</Button1>,
      code: `<Button1>Click Me</Button1>`,
    },
    {
      id: "btn2",
      name: "Button 2 - Outline",
      component: <Button2>Click Me</Button2>,
      code: `<Button2>Click Me</Button2>`,
    },
    {
      id: "btn3",
      name: "Button 3 - Ghost",
      component: <Button3>Click Me</Button3>,
      code: `<Button3>Click Me</Button3>`,
    },
    {
      id: "btn4",
      name: "Button 4 - Gradient",
      component: <Button4>Click Me</Button4>,
      code: `<Button4>Click Me</Button4>`,
    },
    {
      id: "btn5",
      name: "Button 5 - Icon Left",
      component: <Button5 icon="🚀">Launch</Button5>,
      code: `<Button5 icon="🚀">Launch</Button5>`,
    },
    {
      id: "btn6",
      name: "Button 6 - Icon Right",
      component: <Button6 icon="→">Next</Button6>,
      code: `<Button6 icon="→">Next</Button6>`,
    },
    {
      id: "btn7",
      name: "Button 7 - Loading",
      component: <Button7 loading>Processing</Button7>,
      code: `<Button7 loading>Processing</Button7>`,
    },
    {
      id: "btn8",
      name: "Button 8 - Success",
      component: <Button8>Success</Button8>,
      code: `<Button8>Success</Button8>`,
    },
    { id: "btn9", name: "Button 9 - Error", component: <Button9>Delete</Button9>, code: `<Button9>Delete</Button9>` },
    {
      id: "btn10",
      name: "Button 10 - Pill",
      component: <Button10>Get Started</Button10>,
      code: `<Button10>Get Started</Button10>`,
    },
  ];

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-white mb-2">Component Library</h1>
        <p className="text-gray-300">Browse and copy reusable UI components</p>
      </div>

      {/* Theme Switcher */}
      <div className="mb-12 bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
          <Icon icon="mdi:palette" width={28} />
          Theme Selector
        </h2>
        <p className="text-gray-400 text-sm mb-4">Switch themes to preview components in different color schemes</p>

        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          {themeNames.map((name) => {
            const theme = themes[name];
            const isActive = themeName === name;

            return (
              <button
                key={name}
                onClick={() => setTheme(name)}
                className={`p-4 rounded-lg border-2 transition ${
                  isActive ? "border-white bg-white/10" : "border-white/20 hover:border-white/40"
                }`}
              >
                <div className="flex gap-1 mb-2">
                  <div className="w-6 h-6 rounded" style={{ backgroundColor: theme.colors.primary }} />
                  <div className="w-6 h-6 rounded" style={{ backgroundColor: theme.colors.secondary }} />
                  <div className="w-6 h-6 rounded" style={{ backgroundColor: theme.colors.accent }} />
                </div>
                <div className="text-white font-semibold text-sm">{theme.name}</div>
                {isActive && (
                  <div className="mt-1">
                    <Icon icon="mdi:check-circle" className="text-green-400" width={20} />
                  </div>
                )}
              </button>
            );
          })}
        </div>

        {/* Current Theme Info */}
        <div className="mt-6 grid grid-cols-3 md:grid-cols-6 gap-3">
          {Object.entries(themes[themeName].colors).map(([key, value]) => (
            <div key={key} className="bg-black/20 rounded-lg p-3">
              <div className="w-full h-8 rounded mb-2" style={{ backgroundColor: value }} />
              <div className="text-xs text-gray-400 capitalize">{key}</div>
              <div className="text-xs text-gray-500 font-mono">{value}</div>
            </div>
          ))}
        </div>
      </div>

      {/* Headers Section */}
      <div className="mb-12">
        <h2 className="text-3xl font-bold text-white mb-6 flex items-center gap-3">
          <Icon icon="mdi:page-layout-header" width={32} />
          Headers
        </h2>

        <div className="space-y-6">
          {headerExamples.map((example) => (
            <div
              key={example.id}
              className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 overflow-hidden"
            >
              <div className="p-4 border-b border-white/10 flex items-center justify-between">
                <h3 className="text-lg font-semibold text-white">{example.name}</h3>
                <button
                  onClick={() => copyCode(example.code, example.id)}
                  className="px-4 py-2 bg-blue-500/20 text-blue-400 border border-blue-500/30 rounded-lg font-semibold text-sm hover:bg-blue-500/30 transition flex items-center gap-2"
                >
                  {copiedCode === example.id ? (
                    <>
                      <Icon icon="mdi:check" width={20} />
                      Copied!
                    </>
                  ) : (
                    <>
                      <Icon icon="mdi:content-copy" width={20} />
                      Copy Code
                    </>
                  )}
                </button>
              </div>

              {/* Preview */}
              <div className="bg-gradient-to-br from-slate-900 to-slate-800 p-4">
                <div className="rounded-lg overflow-hidden border border-white/10">{example.component}</div>
              </div>

              {/* Code */}
              <div className="bg-black/30 p-4">
                <pre className="text-sm text-gray-300 overflow-x-auto">
                  <code>{example.code}</code>
                </pre>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Buttons Section */}
      <div className="mb-12">
        <h2 className="text-3xl font-bold text-white mb-6 flex items-center gap-3">
          <Icon icon="mdi:gesture-tap-button" width={32} />
          Buttons
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {buttonExamples.map((example) => (
            <div
              key={example.id}
              className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 overflow-hidden"
            >
              <div className="p-4 border-b border-white/10 flex items-center justify-between">
                <h3 className="text-base font-semibold text-white">{example.name}</h3>
                <button
                  onClick={() => copyCode(example.code, example.id)}
                  className="px-3 py-1 bg-blue-500/20 text-blue-400 border border-blue-500/30 rounded text-xs hover:bg-blue-500/30 transition"
                >
                  {copiedCode === example.id ? "Copied!" : "Copy"}
                </button>
              </div>

              {/* Preview */}
              <div className="bg-gradient-to-br from-slate-900 to-slate-800 p-6 flex items-center justify-center min-h-[120px]">
                {example.component}
              </div>

              {/* Code */}
              <div className="bg-black/30 p-3">
                <pre className="text-xs text-gray-300 overflow-x-auto">
                  <code>{example.code}</code>
                </pre>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Usage Instructions */}
      <div className="bg-blue-900/20 border border-blue-500/30 rounded-xl p-6">
        <h3 className="text-lg font-bold text-blue-400 mb-3 flex items-center gap-2">
          <Icon icon="mdi:information" width={24} />
          Usage Instructions
        </h3>
        <div className="space-y-2 text-sm text-gray-300">
          <p>
            <strong>Import:</strong> All components are available from{" "}
            <code className="bg-black/30 px-2 py-1 rounded">lib/base</code>
          </p>
          <pre className="bg-black/30 p-3 rounded text-xs overflow-x-auto mt-2">
            <code>{`import { Header1, Button1 } from '../lib/base';`}</code>
          </pre>
          <p className="mt-4">
            <strong>Theming:</strong> Components use CSS variables from the theme system. Colors automatically update
            when you switch themes.
          </p>
          <p className="mt-2">
            <strong>Customization:</strong> All components accept standard HTML props and className for additional
            styling.
          </p>
        </div>
      </div>
    </div>
  );
};
