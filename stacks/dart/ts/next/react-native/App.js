import React, { useState } from 'react'
import { SafeAreaView, Text, TextInput } from 'react-native'

export default function App() {
  const [name, setName] = useState('World')
  return (
    <SafeAreaView style={{ padding: 16 }}>
      <Text style={{ fontSize: 24, marginBottom: 8 }}>Hello, {name}!</Text>
      <TextInput value={name} onChangeText={setName} style={{ borderWidth: 1, padding: 8 }} />
    </SafeAreaView>
  )
}


