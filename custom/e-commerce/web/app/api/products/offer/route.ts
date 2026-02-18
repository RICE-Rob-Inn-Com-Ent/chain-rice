import { NextRequest, NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redisHelpers } from "@/lib/redis";
import { kafkaHelpers } from "@/lib/kafka";
import { isManagerOrHigher } from "@/lib/rbac";
import { updateBundleStock } from "@/lib/bundle-products";

export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const user = session.user as any;
    const userIdentifier =
      (user?.role as string | undefined) ??
      (user?.id as string | undefined) ??
      "";

    if (!isManagerOrHigher(userIdentifier)) {
      console.error(
        "Insufficient permissions for creating offer. Resolved role:",
        userIdentifier,
        "raw role:",
        user?.role,
        "user id:",
        user?.id,
      );
      return NextResponse.json(
        { error: "Insufficient permissions" },
        { status: 403 }
      );
    }

    const body = await request.json();
    const {
      name,
      description,
      price,
      isBundle,
      specialOffer,
      productIds,
      specialOfferType,
      images,
    } = body;

    // Validation
    if (!name || !price || !productIds || productIds.length === 0) {
      return NextResponse.json(
        { error: "Name, price, and at least one product are required" },
        { status: 400 }
      );
    }

    // Validate that all product IDs exist
    const products = await prisma.product.findMany({
      where: {
        id: { in: productIds },
        active: true,
      },
    });

    if (products.length !== productIds.length) {
      return NextResponse.json(
        { error: "One or more selected products are invalid or inactive" },
        { status: 400 }
      );
    }

    // Get or create "Zestaw" category for bundles
    let bundleCategoryId: string;
    if (isBundle) {
      let bundleCategory = await prisma.category.findUnique({
        where: { slug: "zestaw" },
      });

      if (!bundleCategory) {
        bundleCategory = await prisma.category.create({
          data: {
            name: "Zestaw",
            slug: "zestaw",
            description: "Zestawy produktów",
            active: true,
            order: 100,
          },
        });
      }
      bundleCategoryId = bundleCategory.id;
    } else {
      // For special offers, use first product's category
      bundleCategoryId = products[0].categoryId;
    }

    // Create offer product
    const offerProduct = await prisma.product.create({
      data: {
        name,
        description: description || null,
        shortDescription: description
          ? description.substring(0, 150)
          : null,
        price: parseFloat(price),
        categoryId: bundleCategoryId,
        active: true,
        featured: false,
        specialOffer: specialOffer || false,
        isBundle: isBundle || false,
        stock: 0, // Will be calculated after creating bundle products
        images: images && Array.isArray(images) ? images : [],
        tags: specialOffer
          ? [specialOfferType || "special"]
          : ["bundle"],
      },
    });

    // Create bundle product relations if it's a bundle
    if (isBundle && productIds.length > 0) {
      await prisma.bundleProduct.createMany({
        data: productIds.map((productId: string) => ({
          bundleId: offerProduct.id,
          productId: productId,
          quantity: 1, // Default quantity, can be extended later
        })),
      });

      // Calculate and update bundle stock
      await updateBundleStock(offerProduct.id);
    }

    // Invalidate cache
    await redisHelpers.cacheInvalidatePattern("dashboard:*");
    await redisHelpers.cacheInvalidatePattern("products:*");

    // Send Kafka event
    kafkaHelpers.sendProductEvent(
      specialOffer ? "special_offer_created" : "bundle_created",
      {
        id: offerProduct.id,
        name: offerProduct.name,
        type: specialOffer ? "special_offer" : "bundle",
        specialOfferType: specialOfferType,
        productIds: productIds,
      }
    );

    return NextResponse.json(
      { success: true, product: offerProduct },
      { status: 201 }
    );
  } catch (error) {
    console.error("Error creating offer:", error);
    return NextResponse.json(
      {
        error: "Failed to create offer",
        details: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 }
    );
  }
}

