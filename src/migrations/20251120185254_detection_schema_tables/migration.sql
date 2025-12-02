-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "detection";

-- CreateEnum
CREATE TYPE "detection"."FireSeverity" AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');

-- CreateEnum
CREATE TYPE "detection"."AlertStatus" AS ENUM ('NEW', 'IN_PROGRESS', 'RESOLVED', 'DISMISSED');

-- CreateEnum
CREATE TYPE "detection"."ImageSplit" AS ENUM ('TRAIN', 'VALIDATION', 'TEST');

-- CreateTable
CREATE TABLE "detection"."FireAlert" (
    "id" SERIAL NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "description" TEXT NOT NULL,
    "confidence" DOUBLE PRECISION NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "severity" "detection"."FireSeverity" NOT NULL,
    "status" "detection"."AlertStatus" NOT NULL DEFAULT 'NEW',
    "imageId" TEXT,

    CONSTRAINT "FireAlert_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "detection"."Image" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "url" TEXT NOT NULL,
    "width" INTEGER NOT NULL,
    "height" INTEGER NOT NULL,
    "split" "detection"."ImageSplit" NOT NULL,
    "metadata" JSONB NOT NULL DEFAULT '{}',

    CONSTRAINT "Image_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "FireAlert_severity_idx" ON "detection"."FireAlert"("severity");

-- CreateIndex
CREATE INDEX "FireAlert_status_idx" ON "detection"."FireAlert"("status");

-- CreateIndex
CREATE UNIQUE INDEX "Image_url_key" ON "detection"."Image"("url");

-- CreateIndex
CREATE INDEX "Image_split_idx" ON "detection"."Image"("split");

-- AddForeignKey
ALTER TABLE "detection"."FireAlert" ADD CONSTRAINT "FireAlert_imageId_fkey" FOREIGN KEY ("imageId") REFERENCES "detection"."Image"("id") ON DELETE SET NULL ON UPDATE CASCADE;
