import { setup, assign } from 'xstate';

interface User {
  id: string;
  email: string;
  name: string;
}

export const authMachine = setup({
  types: {
    context: {} as {
      user: User | null;
      error: string | null;
    },
    events: {} as
      | { type: 'LOGIN'; email: string; password: string }
      | { type: 'LOGOUT' }
      | { type: 'REFRESH' },
  },
  actions: {
    setUser: assign({
      user: ({ event }) => (event as any).user,
    }),
    setError: assign({
      error: ({ event }) => (event as any).error,
    }),
    clearUser: assign({
      user: null,
      error: null,
    }),
  },
}).createMachine({
  id: 'auth',
  initial: 'checkingAuth',
  context: {
    user: null,
    error: null,
  },
  states: {
    checkingAuth: {
      invoke: {
        src: 'checkAuth',
        onDone: {
          target: 'authenticated',
          actions: 'setUser',
        },
        onError: 'unauthenticated',
      },
    },
    unauthenticated: {
      on: {
        LOGIN: 'authenticating',
      },
    },
    authenticating: {
      invoke: {
        src: 'loginUser',
        onDone: {
          target: 'authenticated',
          actions: 'setUser',
        },
        onError: {
          target: 'unauthenticated',
          actions: 'setError',
        },
      },
    },
    authenticated: {
      on: {
        LOGOUT: {
          target: 'unauthenticated',
          actions: 'clearUser',
        },
        REFRESH: 'checkingAuth',
      },
    },
  },
});
