import React, { useState } from 'react'
import { createRoot } from 'react-dom/client'

function App() {
  const [name, setName] = useState('World')
  return (
    <div style={{ fontFamily: 'system-ui', padding: 16 }}>
      <h1>Hello, {name}!</h1>
      <input value={name} onChange={e => setName(e.target.value)} />
    </div>
  )
}

createRoot(document.getElementById('root')).render(<App />)


