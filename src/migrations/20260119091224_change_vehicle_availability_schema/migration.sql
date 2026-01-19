/*
  Warnings:

  - You are about to drop the `VehicleAvailability` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "registry"."VehicleAvailability" DROP CONSTRAINT "VehicleAvailability_vehicleId_fkey";

-- DropTable
DROP TABLE "registry"."VehicleAvailability";

-- CreateTable
CREATE TABLE "planning"."VehicleAvailability" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "weekday" "planning"."Weekday" NOT NULL,
    "availableCount" INTEGER NOT NULL DEFAULT 0,
    "bookedCount" INTEGER NOT NULL DEFAULT 0,
    "vehicleId" TEXT NOT NULL,

    CONSTRAINT "VehicleAvailability_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "VehicleAvailability_vehicleId_weekday_key" ON "planning"."VehicleAvailability"("vehicleId", "weekday");

-- AddForeignKey
ALTER TABLE "planning"."VehicleAvailability" ADD CONSTRAINT "VehicleAvailability_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "registry"."Vehicle"("id") ON DELETE CASCADE ON UPDATE CASCADE;
