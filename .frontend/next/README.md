# Next.js 15 with React Server Components

## Overview
Modern Next.js 15 application with React Server Components (RSC), Server Actions, and full-stack type safety with tRPC.

## Features

- ✅ **Next.js 15** - Latest version with App Router
- ✅ **React 19** - Latest React with Server Components
- ✅ **Server Components** - Zero JavaScript by default
- ✅ **Server Actions** - Type-safe server mutations
- ✅ **tRPC** - End-to-end type safety
- ✅ **TanStack Query** - Powerful data fetching
- ✅ **Zustand** - Lightweight state management
- ✅ **XState** - State machines for complex UIs
- ✅ **Tailwind CSS** - Utility-first styling

## Project Structure

```
next/
├── app/                    # App Router
│   ├── (auth)/            # Auth route group
│   ├── (dashboard)/       # Dashboard route group
│   ├── api/               # API routes
│   ├── layout.tsx         # Root layout (Server Component)
│   └── page.tsx           # Home page (Server Component)
├── components/            # React components
│   ├── client/           # Client Components
│   └── server/           # Server Components
├── lib/                   # Utilities
│   ├── trpc/             # tRPC setup
│   ├── store/            # Zustand stores
│   └── machines/         # XState machines
├── server/               # Server-side code
│   ├── actions/         # Server Actions
│   └── db/              # Database
└── public/              # Static files
```

## React Server Components vs Client Components

### Server Components (Default)
```tsx
// app/users/page.tsx
async function UsersPage() {
  // Fetch data directly in component
  const users = await db.user.findMany();

  return (
    <div>
      <h1>Users</h1>
      {users.map(user => (
        <UserCard key={user.id} user={user} />
      ))}
    </div>
  );
}
```

### Client Components
```tsx
// components/client/counter.tsx
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}
```

## Server Actions

```tsx
// server/actions/user.ts
'use server';

import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
});

export async function createUser(formData: FormData) {
  const data = createUserSchema.parse({
    email: formData.get('email'),
    name: formData.get('name'),
  });

  const user = await db.user.create({ data });

  return { success: true, user };
}
```

Use in component:
```tsx
// app/users/new/page.tsx
import { createUser } from '@/server/actions/user';

export default function NewUserPage() {
  return (
    <form action={createUser}>
      <input name="email" type="email" required />
      <input name="name" required />
      <button type="submit">Create User</button>
    </form>
  );
}
```

## tRPC Integration

### Setup
```typescript
// lib/trpc/client.ts
import { createTRPCClient, httpBatchLink } from '@trpc/client';
import type { AppRouter } from '@/server/routers/_app';

export const trpc = createTRPCClient<AppRouter>({
  links: [
    httpBatchLink({
      url: '/api/trpc',
    }),
  ],
});
```

### Server Router
```typescript
// server/routers/_app.ts
import { router, publicProcedure } from '../trpc';
import { z } from 'zod';

export const appRouter = router({
  user: {
    list: publicProcedure.query(async () => {
      return await db.user.findMany();
    }),

    create: publicProcedure
      .input(z.object({
        email: z.string().email(),
        name: z.string(),
      }))
      .mutation(async ({ input }) => {
        return await db.user.create({ data: input });
      }),
  },
});

export type AppRouter = typeof appRouter;
```

### Use in Components
```tsx
'use client';

import { trpc } from '@/lib/trpc/client';

export function UserList() {
  const { data, isLoading } = trpc.user.list.useQuery();

  if (isLoading) return <div>Loading...</div>;

  return (
    <ul>
      {data?.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

## State Management with Zustand

```typescript
// lib/store/user-store.ts
import { create } from 'zustand';

interface UserState {
  user: User | null;
  setUser: (user: User) => void;
  logout: () => void;
}

export const useUserStore = create<UserState>((set) => ({
  user: null,
  setUser: (user) => set({ user }),
  logout: () => set({ user: null }),
}));
```

## State Machines with XState

```typescript
// lib/machines/auth-machine.ts
import { setup, assign } from 'xstate';

export const authMachine = setup({
  types: {
    context: {} as { user: User | null; error: string | null },
    events: {} as
      | { type: 'LOGIN'; email: string; password: string }
      | { type: 'LOGOUT' },
  },
}).createMachine({
  id: 'auth',
  initial: 'idle',
  context: { user: null, error: null },
  states: {
    idle: {
      on: {
        LOGIN: 'authenticating',
      },
    },
    authenticating: {
      invoke: {
        src: 'loginUser',
        onDone: {
          target: 'authenticated',
          actions: assign({ user: ({ event }) => event.output }),
        },
        onError: {
          target: 'idle',
          actions: assign({ error: ({ event }) => event.error.message }),
        },
      },
    },
    authenticated: {
      on: {
        LOGOUT: {
          target: 'idle',
          actions: assign({ user: null }),
        },
      },
    },
  },
});
```

## Quick Start

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

## Environment Variables

```env
# .env.local
DATABASE_URL="postgresql://..."
NEXT_PUBLIC_API_URL="http://localhost:3001"
```

## Best Practices

### When to use Server Components
- ✅ Fetching data
- ✅ Accessing backend resources
- ✅ Keeping sensitive information on server
- ✅ Reducing client-side JavaScript

### When to use Client Components
- ✅ Adding interactivity (onClick, onChange)
- ✅ Using React hooks (useState, useEffect)
- ✅ Using browser-only APIs
- ✅ Using Context API

## References
- [Next.js 15 Docs](https://nextjs.org/docs)
- [React Server Components](https://nextjs.org/docs/app/building-your-application/rendering/server-components)
- [Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions-and-mutations)
