import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import ProductsPageContent from "./ProductsPageContent";

async function getProducts() {
  return await prisma.product.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      category: true,
      orderItems: {
        select: { quantity: true },
      },
      bundleProducts: {
        include: {
          product: {
            select: {
              id: true,
              name: true,
              stock: true,
              active: true,
            },
          },
        },
      },
    },
  });
}

export default async function ProductsPage({
  params,
}: {
  params: { username: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect(`/signin?callbackUrl=/${params.username}/products`);
  }

  const userRole = (session.user as any)?.role || "USER";
  const allowedRoles = ["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"];

  if (!allowedRoles.includes(userRole)) {
    redirect(`/${params.username}/dashboard`);
  }

  const products = await getProducts();

  return <ProductsPageContent products={products} />;
}

