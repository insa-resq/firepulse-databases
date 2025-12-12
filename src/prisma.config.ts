import 'dotenv/config';
import { defineConfig, env } from 'prisma/config';

export default defineConfig({
    schema: 'schemas',
    migrations: {
        path: 'migrations',
        seed: 'tsx scripts/seed.ts',
    },
    datasource: {
        url: env('DATABASE_URL'),
    },
});
