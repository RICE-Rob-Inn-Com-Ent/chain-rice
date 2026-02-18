import { prisma } from "./prisma";

/**
 * Oblicza stan magazynowy zestawu jako minimum z dostępnych ilości produktów składowych
 * Uwzględnia quantity z BundleProduct (ile danego produktu jest w zestawie)
 */
export async function calculateBundleStock(bundleId: string): Promise<number> {
  const bundleProducts = await prisma.bundleProduct.findMany({
    where: { bundleId },
    include: {
      product: {
        select: {
          id: true,
          stock: true,
          active: true,
        },
      },
    },
  });

  if (bundleProducts.length === 0) {
    return 0;
  }

  // Obliczamy ile zestawów można złożyć z dostępnych produktów
  // Dla każdego produktu składowego: stock / quantity
  const availableBundles = bundleProducts.map((bp) => {
    if (!bp.product.active || bp.product.stock <= 0) {
      return 0;
    }
    // Jeśli quantity = 1, to po prostu stock
    // Jeśli quantity = 2, to stock / 2 (zaokrąglone w dół)
    return Math.floor(bp.product.stock / bp.quantity);
  });

  // Minimum z dostępnych zestawów
  return Math.min(...availableBundles);
}

/**
 * Aktualizuje stan magazynowy zestawu na podstawie produktów składowych
 */
export async function updateBundleStock(bundleId: string): Promise<void> {
  const newStock = await calculateBundleStock(bundleId);
  
  await prisma.product.update({
    where: { id: bundleId },
    data: { stock: newStock },
  });
}

/**
 * Aktualizuje stan wszystkich zestawów zawierających dany produkt
 * Wywoływane przy zmianie stanu produktu składowego
 */
export async function updateBundlesContainingProduct(productId: string): Promise<void> {
  // Znajdź wszystkie zestawy zawierające ten produkt
  const bundles = await prisma.bundleProduct.findMany({
    where: { productId },
    select: { bundleId: true },
    distinct: ["bundleId"],
  });

  // Zaktualizuj stan każdego zestawu
  await Promise.all(
    bundles.map((bundle) => updateBundleStock(bundle.bundleId))
  );
}

/**
 * Pobiera listę produktów składowych zestawu
 */
export async function getBundleComponents(bundleId: string) {
  return await prisma.bundleProduct.findMany({
    where: { bundleId },
    include: {
      product: {
        select: {
          id: true,
          name: true,
          price: true,
          stock: true,
          active: true,
        },
      },
    },
    orderBy: {
      createdAt: "asc",
    },
  });
}



