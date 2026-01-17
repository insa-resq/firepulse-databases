/*
  Warnings:

  - A unique constraint covering the columns `[type,stationId]` on the table `Vehicle` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "registry"."Vehicle_stationId_idx";

-- DropIndex
DROP INDEX "registry"."Vehicle_type_idx";

-- AlterTable
ALTER TABLE "registry"."Vehicle" ADD COLUMN     "bookedCount" INTEGER NOT NULL DEFAULT 0;

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_type_stationId_key" ON "registry"."Vehicle"("type", "stationId");
