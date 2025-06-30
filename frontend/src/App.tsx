import React, { useState } from 'react'
import Button from './components/ui/Button'
import { Card, CardHeader, CardBody, CardFooter } from './components/ui/Card'
import Input from './components/ui/Input'
import Badge from './components/ui/Badge'
import Modal from './components/ui/Modal'
import { Spinner, LoadingCard, Skeleton } from './components/ui/Loading'

function App() {
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [darkMode, setDarkMode] = useState(false)

  React.useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }, [darkMode])

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-8">
      <div className="container-lg space-y-8">
        {/* Header */}
        <div className="text-center space-y-4">
          <h1 className="text-4xl font-bold gradient-text">
            Chain Rice Frontend
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
            A comprehensive styling system built with Tailwind CSS, featuring dark mode,
            animations, and a complete component library.
          </p>
          
          <div className="flex justify-center gap-4">
            <Button
              variant="primary"
              onClick={() => setDarkMode(!darkMode)}
              leftIcon={darkMode ? '☀️' : '🌙'}
            >
              {darkMode ? 'Light Mode' : 'Dark Mode'}
            </Button>
            <Button
              variant="secondary"
              onClick={() => setIsModalOpen(true)}
            >
              Open Modal
            </Button>
          </div>
        </div>

        {/* Component Showcase */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Buttons Card */}
          <Card hover padding="lg">
            <CardHeader divider>
              <h3 className="text-lg font-semibold">Buttons</h3>
            </CardHeader>
            <CardBody>
              <div className="space-y-3">
                <Button variant="primary" fullWidth>Primary Button</Button>
                <Button variant="secondary" fullWidth>Secondary Button</Button>
                <Button variant="ghost" fullWidth>Ghost Button</Button>
                <Button variant="success" size="sm">Success</Button>
                <Button variant="danger" size="lg" loading>Loading...</Button>
              </div>
            </CardBody>
          </Card>

          {/* Badges Card */}
          <Card hover padding="lg">
            <CardHeader divider>
              <h3 className="text-lg font-semibold">Badges & Status</h3>
            </CardHeader>
            <CardBody>
              <div className="space-y-4">
                <div className="flex flex-wrap gap-2">
                  <Badge variant="primary">Primary</Badge>
                  <Badge variant="success">Success</Badge>
                  <Badge variant="warning">Warning</Badge>
                  <Badge variant="error">Error</Badge>
                </div>
                <div className="flex items-center gap-2">
                  <Badge dot variant="success" />
                  <span className="text-sm">Online</span>
                </div>
                <div className="flex items-center gap-2">
                  <Badge dot variant="warning" />
                  <span className="text-sm">Pending</span>
                </div>
              </div>
            </CardBody>
          </Card>

          {/* Loading States Card */}
          <Card hover padding="lg">
            <CardHeader divider>
              <h3 className="text-lg font-semibold">Loading States</h3>
            </CardHeader>
            <CardBody>
              <div className="space-y-4">
                <div className="flex items-center gap-4">
                  <Spinner size="sm" />
                  <Spinner size="md" />
                  <Spinner size="lg" />
                </div>
                <Skeleton lines={3} />
                <div className="flex justify-between">
                  <Skeleton width="30%" height="2rem" className="rounded-lg" />
                  <Skeleton width="40%" height="2rem" className="rounded-lg" />
                </div>
              </div>
            </CardBody>
          </Card>

          {/* Forms Card */}
          <Card hover padding="lg" className="md:col-span-2">
            <CardHeader divider>
              <h3 className="text-lg font-semibold">Form Elements</h3>
            </CardHeader>
            <CardBody>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <Input
                  label="Email Address"
                  type="email"
                  placeholder="john@example.com"
                  helper="We'll never share your email."
                />
                <Input
                  label="Password"
                  type="password"
                  placeholder="••••••••"
                  error="Password must be at least 8 characters"
                />
                <Input
                  label="Search"
                  placeholder="Search anything..."
                  leftIcon={<span>🔍</span>}
                />
                <Input
                  label="Amount"
                  placeholder="0.00"
                  rightIcon={<span className="text-xs font-medium">USD</span>}
                />
              </div>
            </CardBody>
            <CardFooter divider>
              <div className="flex gap-3">
                <Button variant="primary">Save Changes</Button>
                <Button variant="ghost">Cancel</Button>
              </div>
            </CardFooter>
          </Card>

          {/* Loading Card Example */}
          <LoadingCard />
        </div>

        {/* Features Grid */}
        <div className="text-center space-y-6">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-gray-100">
            Styling Features
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="glass p-6 rounded-xl text-center space-y-2">
              <div className="text-2xl">🎨</div>
              <h3 className="font-semibold">Design System</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Comprehensive color palette and typography
              </p>
            </div>
            
            <div className="glass p-6 rounded-xl text-center space-y-2">
              <div className="text-2xl">🌙</div>
              <h3 className="font-semibold">Dark Mode</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Complete dark mode support
              </p>
            </div>
            
            <div className="glass p-6 rounded-xl text-center space-y-2">
              <div className="text-2xl">✨</div>
              <h3 className="font-semibold">Animations</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Smooth transitions and micro-interactions
              </p>
            </div>
            
            <div className="glass p-6 rounded-xl text-center space-y-2">
              <div className="text-2xl">📱</div>
              <h3 className="font-semibold">Responsive</h3>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                Mobile-first responsive design
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Modal Example */}
      <Modal
        open={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Example Modal"
        size="md"
      >
        <Modal.Body>
          <div className="space-y-4">
            <p className="text-gray-600 dark:text-gray-400">
              This is an example modal with full styling support. It includes
              backdrop blur, smooth animations, and responsive design.
            </p>
            <Input
              label="Modal Input"
              placeholder="Type something..."
              fullWidth
            />
          </div>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="ghost" onClick={() => setIsModalOpen(false)}>
            Cancel
          </Button>
          <Button variant="primary" onClick={() => setIsModalOpen(false)}>
            Confirm
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  )
}

export default App