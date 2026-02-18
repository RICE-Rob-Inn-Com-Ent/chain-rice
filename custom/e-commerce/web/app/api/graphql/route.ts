import { createYoga } from 'graphql-yoga'
import { createSchema } from 'graphql-yoga'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

// Example GraphQL schema
const typeDefs = `
  type Query {
    hello: String!
    users: [User!]!
    user(id: ID!): User
  }

  type User {
    id: ID!
    email: String!
    name: String
  }
`

const resolvers = {
  Query: {
    hello: () => 'Hello from GraphQL Yoga + Bun + Prisma!',
    users: async () => {
      return await prisma.user.findMany({
        take: 10,
      })
    },
    user: async (_: any, { id }: { id: string }) => {
      return await prisma.user.findUnique({
        where: { id },
      })
    },
  },
}

const schema = createSchema({
  typeDefs,
  resolvers,
})

const { handleRequest } = createYoga({
  schema,
  graphqlEndpoint: '/api/graphql',
  fetchAPI: {
    Request: Request,
    Response: Response,
  },
})

export {
  handleRequest as GET,
  handleRequest as POST,
}
