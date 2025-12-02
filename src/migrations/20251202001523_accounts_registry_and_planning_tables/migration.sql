-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "accounts";

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "planning";

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "registry";

-- CreateEnum
CREATE TYPE "accounts"."UserRole" AS ENUM ('ADMIN', 'ALERT_MONITOR', 'PLANNING_MANAGER', 'FIREFIGHTER');

-- CreateEnum
CREATE TYPE "planning"."Weekday" AS ENUM ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY');

-- CreateEnum
CREATE TYPE "planning"."ShiftType" AS ENUM ('ON_SHIFT', 'OFF_DUTY', 'ON_CALL');

-- CreateEnum
CREATE TYPE "registry"."VehicleType" AS ENUM ('CCFL', 'CCFM', 'CCFS', 'CCGC', 'VLHR', 'VTUF');

-- CreateEnum
CREATE TYPE "registry"."FirefighterRank" AS ENUM ('SECOND_CLASS', 'FIRST_CLASS', 'CORPORAL', 'CHIEF_CORPORAL', 'SERGEANT', 'CHIEF_SERGEANT', 'ADJUTANT', 'CHIEF_ADJUTANT', 'LIEUTENANT');

-- CreateTable
CREATE TABLE "accounts"."User" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" "accounts"."UserRole" NOT NULL,
    "name" TEXT,
    "avatarUrl" TEXT,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "planning"."Planning" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "year" INTEGER NOT NULL,
    "weekNumber" INTEGER NOT NULL,
    "stationId" TEXT NOT NULL,

    CONSTRAINT "Planning_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "planning"."ShiftAssignment" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "weekday" "planning"."Weekday" NOT NULL,
    "shiftType" "planning"."ShiftType" NOT NULL,
    "firefighterId" TEXT NOT NULL,
    "planningId" TEXT NOT NULL,

    CONSTRAINT "ShiftAssignment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "planning"."AvailabilitySlot" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "year" INTEGER NOT NULL,
    "weekNumber" INTEGER NOT NULL,
    "weekday" "planning"."Weekday" NOT NULL,
    "isAvailable" BOOLEAN NOT NULL,
    "firefighterId" TEXT NOT NULL,

    CONSTRAINT "AvailabilitySlot_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "registry"."FireStation" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "name" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "FireStation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "registry"."Vehicle" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "type" "registry"."VehicleType" NOT NULL,
    "totalCount" INTEGER NOT NULL,
    "availableCount" INTEGER NOT NULL,
    "stationId" TEXT NOT NULL,

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "registry"."Firefighter" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "rank" "registry"."FirefighterRank" NOT NULL,
    "stationId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,

    CONSTRAINT "Firefighter_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "registry"."FirefighterTraining" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "firefighterId" TEXT NOT NULL,
    "ppbe" BOOLEAN NOT NULL DEFAULT false,
    "inc" BOOLEAN NOT NULL DEFAULT false,
    "roadRescue" BOOLEAN NOT NULL DEFAULT false,
    "fiSpv" BOOLEAN NOT NULL DEFAULT false,
    "teamLeader" BOOLEAN NOT NULL DEFAULT false,
    "ca1e" BOOLEAN NOT NULL DEFAULT false,
    "cate" BOOLEAN NOT NULL DEFAULT false,
    "cdg" BOOLEAN NOT NULL DEFAULT false,
    "cod0" BOOLEAN NOT NULL DEFAULT false,
    "cod1" BOOLEAN NOT NULL DEFAULT false,
    "permitB" BOOLEAN NOT NULL DEFAULT false,
    "permitC" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "FirefighterTraining_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "accounts"."User"("email");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "accounts"."User"("role");

-- CreateIndex
CREATE UNIQUE INDEX "Planning_year_weekNumber_stationId_key" ON "planning"."Planning"("year", "weekNumber", "stationId");

-- CreateIndex
CREATE UNIQUE INDEX "ShiftAssignment_planningId_weekday_firefighterId_key" ON "planning"."ShiftAssignment"("planningId", "weekday", "firefighterId");

-- CreateIndex
CREATE INDEX "AvailabilitySlot_year_weekNumber_weekday_isAvailable_idx" ON "planning"."AvailabilitySlot"("year", "weekNumber", "weekday", "isAvailable");

-- CreateIndex
CREATE UNIQUE INDEX "AvailabilitySlot_firefighterId_year_weekNumber_weekday_key" ON "planning"."AvailabilitySlot"("firefighterId", "year", "weekNumber", "weekday");

-- CreateIndex
CREATE INDEX "FireStation_name_idx" ON "registry"."FireStation"("name");

-- CreateIndex
CREATE INDEX "Vehicle_stationId_idx" ON "registry"."Vehicle"("stationId");

-- CreateIndex
CREATE INDEX "Vehicle_type_idx" ON "registry"."Vehicle"("type");

-- CreateIndex
CREATE UNIQUE INDEX "Firefighter_userId_key" ON "registry"."Firefighter"("userId");

-- CreateIndex
CREATE INDEX "Firefighter_stationId_idx" ON "registry"."Firefighter"("stationId");

-- CreateIndex
CREATE INDEX "Firefighter_rank_idx" ON "registry"."Firefighter"("rank");

-- CreateIndex
CREATE UNIQUE INDEX "FirefighterTraining_firefighterId_key" ON "registry"."FirefighterTraining"("firefighterId");

-- CreateIndex
CREATE INDEX "FireAlert_createdAt_idx" ON "detection"."FireAlert"("createdAt");

-- AddForeignKey
ALTER TABLE "planning"."Planning" ADD CONSTRAINT "Planning_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "registry"."FireStation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "planning"."ShiftAssignment" ADD CONSTRAINT "ShiftAssignment_firefighterId_fkey" FOREIGN KEY ("firefighterId") REFERENCES "registry"."Firefighter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "planning"."ShiftAssignment" ADD CONSTRAINT "ShiftAssignment_planningId_fkey" FOREIGN KEY ("planningId") REFERENCES "planning"."Planning"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "planning"."AvailabilitySlot" ADD CONSTRAINT "AvailabilitySlot_firefighterId_fkey" FOREIGN KEY ("firefighterId") REFERENCES "registry"."Firefighter"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "registry"."Vehicle" ADD CONSTRAINT "Vehicle_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "registry"."FireStation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "registry"."Firefighter" ADD CONSTRAINT "Firefighter_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "registry"."FireStation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "registry"."Firefighter" ADD CONSTRAINT "Firefighter_userId_fkey" FOREIGN KEY ("userId") REFERENCES "accounts"."User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "registry"."FirefighterTraining" ADD CONSTRAINT "FirefighterTraining_firefighterId_fkey" FOREIGN KEY ("firefighterId") REFERENCES "registry"."Firefighter"("id") ON DELETE CASCADE ON UPDATE CASCADE;
