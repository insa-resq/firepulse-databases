# FirePulse Databases

This repository contains the database schemas, migrations, and deployment tooling for ResQ's FirePulse system. 
It uses [Prisma ORM](https://www.prisma.io/docs/orm) to manage the schemas, and [Docker](https://docs.docker.com/reference) to orchestrate a [PostgreSQL](https://www.postgresql.org/docs/18/) instance and a migration runner.

## Contents

- `src/schemas/`: Prisma schema files split by domain (`auth.prisma`, `planning.prisma`, `detection.prisma`, `main.prisma`, `registry.prisma`).
- `src/migrations/`: Prisma migration history.
- `src/prisma.config.ts`: Prisma configuration (schema and migrations paths, datasource env var).
- `src/Dockerfile.db-migrator`: Image that installs Prisma CLI and runs migrations.
- `src/docker-compose.yaml`: Compose stack with `postgres` and the `db-migrator` service.
- `.env.example`: Example environment variables for local/dev and CI.

## Prerequisites

- Docker and Docker Compose v2 ([installation instructions](https://docs.docker.com/get-docker/))
- Node.js 22.19+ and NPM (recommended to use [nvm](https://github.com/nvm-sh/nvm) to manage versions)

## Configuration

Create a `.env` file in the `src/` directory based on `.env.example`:

```
POSTGRES_DB=<name_of_the_database>
POSTGRES_USER=<username>
POSTGRES_PASSWORD=<password>
DATABASE_URL="postgresql://<username>:<password>@postgres:5432/<name_of_the_database>"
# When using docker-compose locally, the URL hostname is `postgres` (the service name).
# When using a local Postgres instance, use `localhost` instead.
```

> [!NOTE]
> - Prisma reads `DATABASE_URL` via `src/prisma.config.ts`.
> - The Docker Compose file exposes Postgres on `5432` and waits for it to be healthy before running migrations.

## Development Setup

You can work with the database locally either via Docker Compose (recommended) or by pointing Prisma to an existing Postgres instance.

### Option A — Run everything with Docker Compose

1. Ensure your `.env` is configured as described above.
2. From the `src/` directory, start the services:
   ```bash
   cd src
   docker compose up --build -d --wait
   ```
   - The `postgres` service will start.
   - The `db-migrator` container will install dependencies and run `npm run db:migration:deploy` automatically, applying all migrations to the database specified by `DATABASE_URL`.

### Option B — Use a local Postgres and run Prisma directly

1. Install dependencies for the migration tools:
   ```bash
   cd src
   npm install
   ```
2. Ensure `DATABASE_URL` in your `.env` points to your local Postgres.
3. Apply migrations:
   ```bash
   npm run db:migration:deploy
   ```

## Day-to-day Commands

Run these from the `src/` directory.

> [!WARNING]
> These commands will use/modify the database specified by `DATABASE_URL`.

- After editing files in `src/schemas/`, you **must** create a new migration:
  ```bash
  npm run db:migration:create
  ```
  You will be prompted for a name for the migration. Give it an appropriate one, reflecting the changes you made.
  A new migration in `src/migrations/` will then be created. Review and commit it.

- Apply all pending migrations (useful locally or in CI):
  ```bash
  npm run db:migration:deploy
  ```

- Reset the database (drops tables and recreates, then re-applies migrations):
  ```bash
  npm run db:reset
  ```

## Deployment

There are two supported approaches: automated via GitHub Actions, and manual via CLI.

### Automated (GitHub Actions)

This repository includes a workflow at `.github/workflows/deploy.yaml` that:
1. Triggers on pushes to `main` (or manually via workflow_dispatch).
2. Copies the `src/` directory to a remote server over SSH (using `appleboy/scp-action`).
3. On the remote host, writes a `.env` file from GitHub Secrets and runs `docker compose up --build -d --wait` to start Postgres and apply migrations via the `db-migrator` container.

Required GitHub Secrets on the repository:
- `SSH_HOST`, `SSH_USERNAME`, `SSH_PASSWORD`: used to connect to the remote host.
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`: used to generate `DATABASE_URL` on the remote.

Make sure Docker is installed on the target host, and the deployment path referenced by `DEPLOYMENT_PATH` (default `~/src`) is accessible.

### Manual deployment

If you prefer to deploy manually to a server running a Postgres instance, you can follow these steps:
1. Navigate to the `src/` directory.
2. Update the `DATABASE_URL` in `.env` to point to the remote Postgres instance.
3. Make sure the NPM dependencies are installed: `npm install`.
4. Apply migrations: `npm run db:migration:deploy`.

## Troubleshooting

- Connection issues: verify `DATABASE_URL` hostname matches the Postgres service name when using Docker Compose (`postgres`).
- Migrations not applying: check logs of the `db-migrator` container:
  ```bash
  docker logs db-migrator
  ```

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
