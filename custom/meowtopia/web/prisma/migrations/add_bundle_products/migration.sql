-- CreateTable
CREATE TABLE "BundleProduct" (
    "id" TEXT NOT NULL,
    "bundleId" TEXT NOT NULL,
    "productId" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BundleProduct_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "BundleProduct_bundleId_productId_key" ON "BundleProduct"("bundleId", "productId");

-- CreateIndex
CREATE INDEX "BundleProduct_bundleId_idx" ON "BundleProduct"("bundleId");

-- CreateIndex
CREATE INDEX "BundleProduct_productId_idx" ON "BundleProduct"("productId");

-- AddForeignKey
ALTER TABLE "BundleProduct" ADD CONSTRAINT "BundleProduct_bundleId_fkey" FOREIGN KEY ("bundleId") REFERENCES "Product"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BundleProduct" ADD CONSTRAINT "BundleProduct_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE CASCADE ON UPDATE CASCADE;





































