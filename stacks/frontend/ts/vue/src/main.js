import { createApp, ref } from 'vue'

const App = {
  setup() {
    const name = ref('World')
    return { name }
  },
  template: `
    <div style="font-family: system-ui; padding: 16px">
      <h1>Hello, {{ name }}!</h1>
      <input v-model="name" />
    </div>
  `
}

createApp(App).mount('#app')


