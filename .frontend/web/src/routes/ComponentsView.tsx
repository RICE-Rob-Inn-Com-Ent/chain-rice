import React from 'react';
import { Header, Footer, Navbar } from '../../lib/molecules';
import { Button, Card, Input, Textarea, GradientText, Section, Reveal } from '../../lib/atoms';

export default function ComponentsView() {
  return (
    <div className="mx-auto max-w-7xl px-4 space-y-12">
      {/* Hero */}
      <Section className="text-center">
        <Reveal>
          <h2 className="text-4xl font-bold mb-4">
            <GradientText>Component Library</GradientText>
          </h2>
          <p className="text-gray-400 max-w-2xl mx-auto">
            Reusable atomic components built with React, TypeScript, and Tailwind CSS
          </p>
        </Reveal>
      </Section>

      {/* Atoms Section */}
      <Section>
        <h3 className="text-2xl font-bold mb-6 text-cyan-400">Atoms</h3>
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {/* Buttons */}
          <Card title="Buttons">
            <div className="space-y-3">
              <Button variant="default">Default Button</Button>
              <Button variant="outline">Outline Button</Button>
              <Button variant="gradient">Gradient Button</Button>
              <Button variant="ghost">Ghost Button</Button>
              <Button size="sm">Small Button</Button>
            </div>
          </Card>

          {/* Inputs */}
          <Card title="Inputs">
            <div className="space-y-3">
              <Input label="Email" type="email" placeholder="john@example.com" />
              <Input label="Password" type="password" placeholder="••••••••" />
              <Input label="Floating Label" floating neutralFocus />
            </div>
          </Card>

          {/* Textarea */}
          <Card title="Textarea">
            <Textarea label="Message" placeholder="Write your message..." rows={4} />
          </Card>

          {/* Gradient Text */}
          <Card title="Gradient Text">
            <div className="space-y-2">
              <GradientText>Beautiful Gradient</GradientText>
              <p className="text-sm text-gray-400">Auto-animated gradient text with multiple color stops</p>
            </div>
          </Card>

          {/* Reveal Animation */}
          <Card title="Reveal Animation">
            <Reveal>
              <div className="p-4 bg-gradient-to-r from-purple-600/20 to-pink-600/20 rounded-lg">
                <p className="text-sm">This element animates when scrolling into view</p>
              </div>
            </Reveal>
          </Card>
        </div>
      </Section>

      {/* Molecules Section */}
      <Section>
        <h3 className="text-2xl font-bold mb-6 text-purple-400">Molecules</h3>
        <div className="grid gap-6">
          <Card title="Layout Components">
            <div className="space-y-2 text-sm text-gray-300">
              <p>
                • <strong>Header</strong> - Full page layout with Navbar and Footer
              </p>
              <p>
                • <strong>Navbar</strong> - Responsive navigation with theme toggle
              </p>
              <p>
                • <strong>Footer</strong> - Footer with links and back-to-top button
              </p>
              <p>
                • <strong>ContactForm</strong> - Form with validation
              </p>
              <p>
                • <strong>TechStackGrid</strong> - Technology showcase grid
              </p>
              <p>
                • <strong>PricingCalculator</strong> - Interactive pricing tool
              </p>
              <p>
                • <strong>ChatWidget</strong> - AI chat interface
              </p>
              <p>
                • <strong>GodsPanel</strong> - AI models management panel
              </p>
              <p>
                • <strong>LoRaTrainingPanel</strong> - LoRA fine-tuning interface
              </p>
            </div>
          </Card>
        </div>
      </Section>

      {/* Usage Example */}
      <Section className="bg-gray-900/50 rounded-2xl p-8">
        <h3 className="text-2xl font-bold mb-4 text-green-400">Usage Example</h3>
        <pre className="bg-black/50 rounded-lg p-4 text-sm overflow-x-auto">
          <code className="text-green-300">{`import { Header, Button, GradientText } from '@rice/ui-kit/lib';

function MyApp() {
  return (
    <Header>
      <div className="p-8">
        <h1>
          <GradientText>Welcome to Rice</GradientText>
        </h1>
        <Button variant="gradient">Get Started</Button>
      </div>
    </Header>
  );
}`}</code>
        </pre>
      </Section>
    </div>
  );
}
