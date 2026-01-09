-- CreateEnum
CREATE TYPE "planning"."PlanningStatus" AS ENUM ('GENERATING', 'FINALIZED');

-- AlterTable
ALTER TABLE "planning"."Planning" ADD COLUMN     "status" "planning"."PlanningStatus" NOT NULL DEFAULT 'GENERATING';
