/*
  Warnings:

  - You are about to drop the column `availableCount` on the `Vehicle` table. All the data in the column will be lost.
  - You are about to drop the column `bookedCount` on the `Vehicle` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "registry"."Vehicle" DROP COLUMN "availableCount",
DROP COLUMN "bookedCount";

-- CreateTable
CREATE TABLE "registry"."VehicleAvailability" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "weekday" "planning"."Weekday" NOT NULL,
    "availableCount" INTEGER NOT NULL,
    "bookedCount" INTEGER NOT NULL DEFAULT 0,
    "vehicleId" TEXT NOT NULL,

    CONSTRAINT "VehicleAvailability_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "VehicleAvailability_vehicleId_weekday_key" ON "registry"."VehicleAvailability"("vehicleId", "weekday");

-- AddForeignKey
ALTER TABLE "registry"."VehicleAvailability" ADD CONSTRAINT "VehicleAvailability_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "registry"."Vehicle"("id") ON DELETE CASCADE ON UPDATE CASCADE;
