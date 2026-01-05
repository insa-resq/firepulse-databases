-- DropForeignKey
ALTER TABLE "accounts"."User" DROP CONSTRAINT "User_stationId_fkey";

-- DropForeignKey
ALTER TABLE "registry"."Firefighter" DROP CONSTRAINT "Firefighter_stationId_fkey";

-- AddForeignKey
ALTER TABLE "accounts"."User" ADD CONSTRAINT "User_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "registry"."FireStation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "registry"."Firefighter" ADD CONSTRAINT "Firefighter_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "registry"."FireStation"("id") ON DELETE CASCADE ON UPDATE CASCADE;
