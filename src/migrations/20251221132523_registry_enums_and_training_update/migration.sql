/*
  Warnings:

  - The values [SECOND_CLASS,FIRST_CLASS,CHIEF_CORPORAL,CHIEF_SERGEANT,CHIEF_ADJUTANT] on the enum `FirefighterRank` will be removed. If these variants are still used in the database, this will fail.
  - The values [FIRE_TRUCK] on the enum `VehicleType` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `ca1e` on the `FirefighterTraining` table. All the data in the column will be lost.
  - You are about to drop the column `cate` on the `FirefighterTraining` table. All the data in the column will be lost.
  - You are about to drop the column `cdg` on the `FirefighterTraining` table. All the data in the column will be lost.
  - You are about to drop the column `cod0` on the `FirefighterTraining` table. All the data in the column will be lost.
  - You are about to drop the column `cod1` on the `FirefighterTraining` table. All the data in the column will be lost.
  - You are about to drop the column `fiSpv` on the `FirefighterTraining` table. All the data in the column will be lost.
  - You are about to drop the column `ppbe` on the `FirefighterTraining` table. All the data in the column will be lost.
  - You are about to drop the column `roadRescue` on the `FirefighterTraining` table. All the data in the column will be lost.
  - You are about to drop the column `teamLeader` on the `FirefighterTraining` table. All the data in the column will be lost.
  - You are about to drop the column `metadata` on the `Vehicle` table. All the data in the column will be lost.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "registry"."FirefighterRank_new" AS ENUM ('SAPPER', 'CORPORAL', 'SERGEANT', 'ADJUTANT', 'LIEUTENANT', 'CAPTAIN');
ALTER TABLE "registry"."Firefighter" ALTER COLUMN "rank" TYPE "registry"."FirefighterRank_new" USING ("rank"::text::"registry"."FirefighterRank_new");
ALTER TYPE "registry"."FirefighterRank" RENAME TO "FirefighterRank_old";
ALTER TYPE "registry"."FirefighterRank_new" RENAME TO "FirefighterRank";
DROP TYPE "registry"."FirefighterRank_old";
COMMIT;

-- AlterEnum
BEGIN;
CREATE TYPE "registry"."VehicleType_new" AS ENUM ('AMBULANCE', 'CANADAIR', 'SMALL_TRUCK', 'MEDIUM_TRUCK', 'LARGE_TRUCK', 'SMALL_BOAT', 'LARGE_BOAT', 'HELICOPTER');
ALTER TABLE "registry"."Vehicle" ALTER COLUMN "type" TYPE "registry"."VehicleType_new" USING ("type"::text::"registry"."VehicleType_new");
ALTER TYPE "registry"."VehicleType" RENAME TO "VehicleType_old";
ALTER TYPE "registry"."VehicleType_new" RENAME TO "VehicleType";
DROP TYPE "registry"."VehicleType_old";
COMMIT;

-- AlterTable
ALTER TABLE "registry"."FirefighterTraining" DROP COLUMN "ca1e",
DROP COLUMN "cate",
DROP COLUMN "cdg",
DROP COLUMN "cod0",
DROP COLUMN "cod1",
DROP COLUMN "fiSpv",
DROP COLUMN "ppbe",
DROP COLUMN "roadRescue",
DROP COLUMN "teamLeader",
ADD COLUMN     "largeTeamLeader" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "mediumTeamLeader" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "permitAircraft" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "smallTeamLeader" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "suap" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "registry"."Vehicle" DROP COLUMN "metadata";
