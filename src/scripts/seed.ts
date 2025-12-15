import { PrismaPg } from '@prisma/adapter-pg';
import { fakerFR as faker } from '@faker-js/faker';
import bcrypt from 'bcrypt';
import { $Enums, PrismaClient } from '../prisma-client/client';

const DEFAULT_PASSWORD = 'password' as const;
const WEEKS_COUNT = 53 as const;
const FRANCE_BOUNDING_BOX = {
    minLat: 42.5,
    maxLat: 51.15,
    minLng: -5.0,
    maxLng: 9.56
} as const;

const prisma = new PrismaClient({
    adapter: new PrismaPg({
        connectionString: process.env.DATABASE_URL
    }),
    transactionOptions: {
        timeout: 60000, // 60 seconds
    }
});

function generateAvatarUrl(seed: string) {
    return `https://api.dicebear.com/9.x/bottts-neutral/svg?seed=${encodeURIComponent(seed)}`;
}

async function main() {
    const hashedPassword = await bcrypt.hash(DEFAULT_PASSWORD, 10);
    
    console.log('Seeding database...');
    
    await prisma.$transaction(async (tx) => {
        console.log('Clearing existing data...');
        
        await tx.image.deleteMany();
        await tx.fireAlert.deleteMany();
        await tx.user.deleteMany();
        await tx.firefighterTraining.deleteMany();
        await tx.firefighter.deleteMany();
        await tx.vehicle.deleteMany();
        await tx.fireStation.deleteMany();
        await tx.availabilitySlot.deleteMany();
        await tx.shiftAssignment.deleteMany();
        await tx.planning.deleteMany();
        await tx.$executeRaw`ALTER SEQUENCE detection."FireAlert_id_seq" RESTART WITH 1`;
        
        console.log('Creating new data...');
        
        const images = await tx.image.createManyAndReturn({
            data: Array.from({ length: 500 }).map(() => ({
                url: faker.image.url({ width: 1024, height: 1024 }),
                width: 1024,
                height: 1024,
                split: faker.helpers.weightedArrayElement([
                    { value: $Enums.ImageSplit.TRAIN, weight: 70 },
                    { value: $Enums.ImageSplit.VALIDATION, weight: 15 },
                    { value: $Enums.ImageSplit.TEST, weight: 15 },
                ]),
                metadata: {
                    filename: faker.system.commonFileName('png'),
                    annotation: Object.values({
                        classId: faker.number.binary(),
                        xCenter: faker.number.float({ min: 0, max: 1, fractionDigits: 6 }),
                        yCenter: faker.number.float({ min: 0, max: 1, fractionDigits: 6 }),
                        width: faker.number.float({ min: 0, max: 1, fractionDigits: 6 }),
                        height: faker.number.float({ min: 0, max: 1, fractionDigits: 6 }),
                    }).join(' ')
                },
            })),
            skipDuplicates: true
        });
        
        console.log('-> Created images.');
        
        const testImages = images.filter((image) => image.split === $Enums.ImageSplit.TEST);
        const imageIds = faker.helpers.uniqueArray(
            () => faker.helpers.arrayElement(testImages).id,
            30
        );
        
        await tx.fireAlert.createMany({
            data: Array.from({ length: 30 }).map(() => ({
                description: faker.lorem.sentence({ min: 10, max: 20 }),
                confidence: faker.number.float({ min: 0.5, max: 1, fractionDigits: 2 }),
                latitude: faker.location.latitude({ min: FRANCE_BOUNDING_BOX.minLat, max: FRANCE_BOUNDING_BOX.maxLat }),
                longitude: faker.location.longitude({ min: FRANCE_BOUNDING_BOX.minLng, max: FRANCE_BOUNDING_BOX.maxLng }),
                severity: faker.helpers.weightedArrayElement([
                    { value: $Enums.FireSeverity.LOW, weight: 50 },
                    { value: $Enums.FireSeverity.MEDIUM, weight: 30 },
                    { value: $Enums.FireSeverity.HIGH, weight: 15 },
                    { value: $Enums.FireSeverity.CRITICAL, weight: 5 },
                ]),
                status: faker.helpers.weightedArrayElement([
                    { value: $Enums.AlertStatus.NEW, weight: 5 },
                    { value: $Enums.AlertStatus.IN_PROGRESS, weight: 5 },
                    { value: $Enums.AlertStatus.RESOLVED, weight: 75 },
                    { value: $Enums.AlertStatus.DISMISSED, weight: 15 },
                ]),
                imageId: faker.helpers.arrayElement(imageIds),
            })),
            skipDuplicates: true
        });
        
        console.log('-> Created fire alerts.');
        
        const fireStations = await tx.fireStation.createManyAndReturn({
            data: Array.from({ length: 10 }).map(() => ({
                name: faker.company.name(),
                latitude: faker.location.latitude({ min: FRANCE_BOUNDING_BOX.minLat, max: FRANCE_BOUNDING_BOX.maxLat }),
                longitude: faker.location.longitude({ min: FRANCE_BOUNDING_BOX.minLng, max: FRANCE_BOUNDING_BOX.maxLng }),
            })),
            skipDuplicates: true
        });
        
        console.log('-> Created fire stations.');
        
        const fireStationIds = fireStations.map(station => station.id);
        
        const vehicleTotalCounts = faker.helpers.multiple(() => faker.number.int({ min: 1, max: 10 }), { count: 50 });
        
        await tx.vehicle.createMany({
            data: Array.from({ length: 50 }).map((_, index) => ({
                type: faker.helpers.enumValue($Enums.VehicleType),
                totalCount: vehicleTotalCounts[index],
                availableCount: faker.number.int({ min: 0, max: vehicleTotalCounts[index] }),
                metadata: {
                    capacity: faker.helpers.arrayElement([1000, 2000, 3000, 4000, 5000]),
                    speed: faker.number.int({ min: 60, max: 120 }),
                },
                stationId: faker.helpers.arrayElement(fireStationIds),
            })),
            skipDuplicates: true
        });
        
        console.log('-> Created vehicles.');
        
        const adminEmails = new Set(
            (process.env.ADMIN_EMAILS ?? '').split(',').map(email => email.trim().toLowerCase())
        );
        const adminStations = faker.helpers.uniqueArray(
            () => faker.helpers.arrayElement(fireStationIds),
            adminEmails.size
        );
        
        await tx.user.createMany({
            data: Array.from(adminEmails).map((email, index) => ({
                email: email,
                password: hashedPassword,
                role: $Enums.UserRole.ADMIN,
                avatarUrl: generateAvatarUrl(`admin_${index+1}`),
                stationId: adminStations[index],
            })),
            skipDuplicates: true
        });
        
        console.log('-> Created admin users.');
        
        await tx.user.createMany({
            data: fireStationIds.flatMap((stationId) => ([
                {
                    email: faker.internet.email().toLowerCase(),
                    password: hashedPassword,
                    role: $Enums.UserRole.ALERT_MONITOR,
                    avatarUrl: generateAvatarUrl(`alert_monitor_${stationId}`),
                    stationId: stationId,
                },
                {
                    email: faker.internet.email().toLowerCase(),
                    password: hashedPassword,
                    role: $Enums.UserRole.PLANNING_MANAGER,
                    avatarUrl: generateAvatarUrl(`planning_manager_${stationId}`),
                    stationId: stationId,
                }
            ])),
        });
        
        const firefighterUsers = await tx.user.createManyAndReturn({
            data: fireStationIds.flatMap((stationId) =>
                Array.from({ length: faker.number.int({ min: 1, max: 10 }) }).map((_, index) => ({
                    email: faker.internet.email().toLowerCase(),
                    password: hashedPassword,
                    role: $Enums.UserRole.FIREFIGHTER,
                    avatarUrl: generateAvatarUrl(`firefighter_${stationId}_${index}`),
                    stationId: stationId,
                })),
            ),
            skipDuplicates: true
        });
        
        console.log('-> Created other users.');
        
        const firefighters = await tx.firefighter.createManyAndReturn({
            data: firefighterUsers.map(({ id, stationId }) => ({
                firstName: faker.person.firstName(),
                lastName: faker.person.lastName(),
                rank: faker.helpers.weightedArrayElement([
                    { value: $Enums.FirefighterRank.FIRST_CLASS, weight: 35 },
                    { value: $Enums.FirefighterRank.SECOND_CLASS, weight: 20 },
                    { value: $Enums.FirefighterRank.SERGEANT, weight: 20 },
                    { value: $Enums.FirefighterRank.CHIEF_SERGEANT, weight: 10 },
                    { value: $Enums.FirefighterRank.CORPORAL, weight: 5 },
                    { value: $Enums.FirefighterRank.CHIEF_CORPORAL, weight: 4 },
                    { value: $Enums.FirefighterRank.ADJUTANT, weight: 3 },
                    { value: $Enums.FirefighterRank.CHIEF_ADJUTANT, weight: 2 },
                    { value: $Enums.FirefighterRank.LIEUTENANT, weight: 1 },
                ]),
                stationId: stationId,
                userId: id,
            })),
            skipDuplicates: true
        });
        
        console.log('-> Created firefighters.');
        
        await tx.firefighterTraining.createMany({
            data: firefighters.map(({ id }) => ({
                firefighterId: id,
                ppbe: faker.datatype.boolean({ probability: 0.75 }),
                inc: faker.datatype.boolean({ probability: 0.75 }),
                roadRescue: faker.datatype.boolean({ probability: 0.75 }),
                fiSpv: faker.datatype.boolean({ probability: 0.75 }),
                teamLeader: faker.datatype.boolean({ probability: 0.45 }),
                ca1e: faker.datatype.boolean({ probability: 0.35 }),
                cate: faker.datatype.boolean({ probability: 0.25 }),
                cdg: faker.datatype.boolean({ probability: 0.15 }),
                cod0: faker.datatype.boolean({ probability: 0.15 }),
                cod1: faker.datatype.boolean({ probability: 0.10 }),
                permitB: faker.datatype.boolean({ probability: 0.95 }),
                permitC: faker.datatype.boolean({ probability: 0.15 }),
            })),
            skipDuplicates: true
        });
        
        console.log('-> Created firefighters trainings.');
        
        const availabilitySlots = await tx.availabilitySlot.createManyAndReturn({
            data: firefighters.flatMap(({ id }) =>
                [2025, 2026].flatMap((year) =>
                    Array.from({ length: WEEKS_COUNT }).flatMap((_, weekIndex) =>
                        Object.values($Enums.Weekday).map((weekday) => ({
                            year: year,
                            weekNumber: weekIndex + 1,
                            weekday: weekday,
                            isAvailable: faker.datatype.boolean({ probability: 0.8 }),
                            firefighterId: id,
                        }))
                    )
                )
            ),
            skipDuplicates: true
        });
        
        console.log('-> Created availability slots.');
        
        const plannings = await tx.planning.createManyAndReturn({
            data: fireStationIds.flatMap((stationId) =>
                [2025, 2026].flatMap((year) =>
                    Array.from({ length: WEEKS_COUNT }).map((_, weekIndex) => ({
                        year: year,
                        weekNumber: weekIndex + 1,
                        stationId: stationId,
                    }))
                )
            ),
            skipDuplicates: true
        });
        
        console.log('-> Created plannings.');
        
        await tx.shiftAssignment.createMany({
            data: plannings.flatMap(({ id: planningId, stationId, year, weekNumber }) =>
                firefighters.filter((firefighter) => firefighter.stationId === stationId)
                    .flatMap(({ id: firefighterId }) =>
                        Object.values($Enums.Weekday).map((weekday) => ({
                            weekday: weekday,
                            shiftType: faker.helpers.weightedArrayElement(
                                availabilitySlots.find((slot =>
                                        slot.firefighterId === firefighterId &&
                                        slot.year === year &&
                                        slot.weekNumber === weekNumber &&
                                        slot.weekday === weekday
                                ))!.isAvailable
                                    ? [
                                        { value: $Enums.ShiftType.ON_SHIFT, weight: 80 },
                                        { value: $Enums.ShiftType.OFF_DUTY, weight: 15 },
                                        { value: $Enums.ShiftType.ON_CALL, weight: 5 },
                                    ]
                                    : [
                                        { value: $Enums.ShiftType.OFF_DUTY, weight: 100 },
                                    ]
                            ),
                            planningId: planningId,
                            firefighterId: firefighterId,
                        }))
                    )
            ),
            skipDuplicates: true
        });
        
        console.log('-> Created shift assignments.');
        
        console.log('Seeding completed !');
    });
}

prisma.$connect()
    .then(main)
    .catch(console.error)
    .finally(async () => {
        try {
            await prisma.$disconnect();
        } catch {}
    });
