/*
  Warnings:

  - You are about to drop the column `height` on the `Image` table. All the data in the column will be lost.
  - You are about to drop the column `width` on the `Image` table. All the data in the column will be lost.

*/
-- AlterEnum
ALTER TYPE "detection"."ImageSplit" ADD VALUE 'NONE';

-- AlterTable
ALTER TABLE "detection"."Image" DROP COLUMN "height",
DROP COLUMN "width",
ADD COLUMN     "containsFire" BOOLEAN NOT NULL DEFAULT false;
