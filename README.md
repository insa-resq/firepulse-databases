# FirePulse Databases

This repository contains the database schemas, migrations, and deployment tooling for ResQ's FirePulse system. 
It uses [Prisma ORM](https://www.prisma.io/docs/orm) to manage the schemas, and [Docker](https://docs.docker.com/reference) to orchestrate a [PostgreSQL](https://www.postgresql.org/docs/18/) instance as well as a migration runner.

## Contents

- `src/schemas/`: Prisma schema files split by domain (`accounts.prisma`, `planning.prisma`, `detection.prisma`, `main.prisma`, `registry.prisma`).
- `src/migrations/`: Prisma migration history.
- `src/prisma.config.ts`: Prisma configuration (schema and migrations paths, datasource env var).
- `src/Dockerfile.db-migrator`: Image that installs Prisma CLI and runs migrations.
- `src/docker-compose.yaml`: Compose stack with `postgres` and the `db-migrator` service.
- `src/.env.example`: Example environment variables for local/dev setup.
- `./deploy.sh`: Script to deploy the databases or apply new migrations to a remote host.
- `./.env.deploy.example`: Example environment variables for running the deployment script.

## Development Setup

You can work with the database locally either via Docker Compose (recommended) or by pointing Prisma to an existing Postgres instance.

### Prerequisites

- Docker and Docker Compose v2 ([installation instructions](https://docs.docker.com/get-docker/))
- Node.js 22.19+ and NPM (recommended to use [nvm](https://github.com/nvm-sh/nvm) to manage versions)
- A local Postgres instance for testing (recommended to use Docker Compose)
- An extension/plugin for Prisma in your IDE:
  - [Prisma](https://marketplace.visualstudio.com/items?itemName=Prisma.prisma) for VSCode
  - [Prisma ORM](https://plugins.jetbrains.com/plugin/20686-prisma-orm) for JetBrains IDEs (WebStorm or IntelliJ)

### Configuration

Create a `.env` file in the [`src/`](./src) directory based on [`.env.example`](./src/.env.example):
```dotenv
POSTGRES_DB=<name_of_the_database>
POSTGRES_USER=<name_of_the_database_user>
POSTGRES_PASSWORD=<password_of_the_database_user>
DATABASE_URL="postgresql://<name_of_the_database_user>:<password_of_the_database_user>@<the_postgres_host>:5432/<name_of_the_database>"
# When testing using the `db-migrator` service from Docker Compose (Option A below), the host is `postgres`.
# When testing using direct Prisma access NPM scripts (Option B below), the host is `localhost`.
```

> [!NOTE]
> The default Postgres port is `5432`. Modify it if your Postgres instance uses a different one.

### Running

#### Option A: Run everything with Docker Compose

1. Ensure your `.env` is configured as described [above](#configuration).
2. From the [`src/`](./src) directory, start the services:
   ```bash
   cd src
   docker compose up --build -d --wait
   ```
   - The `postgres` service will start.
   - The `db-migrator` container will install dependencies and run `npm run db:migration:deploy` automatically, applying all migrations to the database specified by `DATABASE_URL`.

#### Option B: Run Prisma commands directly with NPM

1. Install dependencies for the migration tools:
   ```bash
   cd src
   npm install
   ```
2. Ensure your `.env` is configured as described [above](#configuration).
3. Start your local Postgres instance:
   ```bash
   docker compose up -d --wait postgres
   ```
4. Apply migrations:
   ```bash
   npm run db:migration:deploy
   ```

## Day-to-day Commands

Run these from the [`src/`](./src) directory.

> [!WARNING]
> These commands will use/modify the database specified by `DATABASE_URL`.

- After editing files in [`src/schemas/`](./src/schemas), you **must** create a new migration:
  ```bash
  npm run db:migration:create
  ```
  You will be prompted for a name for the migration. Give it an appropriate one, reflecting the changes you made.
  A new migration in [`src/migrations/`](./src/migrations) will then be created. Review and commit it.

- Apply all pending migrations (useful locally or in CI):
  ```bash
  npm run db:migration:deploy
  ```

- Reset the database (drops tables and recreates, then re-applies migrations):
  ```bash
  npm run db:reset
  ```

## Deployment

The deployment of the databases is done manually via CLI, by following these steps:
1. Create a `.env.deploy` file based on [`.env.deploy.example`](./.env.deploy.example) in the root directory.
    ```dotenv
    # Get the SSH and database credentials from the FirePulse team.
    SSH_HOST=<ip_address_or_server>
    SSH_USER=<name_of_the_ssh_user>
    SSH_PASSWORD=<password_of_the_ssh_user>
    POSTGRES_DB=<name_of_the_database>
    POSTGRES_USER=<name_of_the_database_user>
    POSTGRES_PASSWORD=<password_of_the_database_user>
    ```
2. Run the deployment script:
    ```bash
    chmod +x ./deploy.sh
    ./deploy.sh
    ```
The script will:
- Copy the `src/` directory and secrets to the remote host via SCP.
- Connect to the remote host via SSH.
- Install Docker and Docker Compose if not already installed.
- Start the Docker Compose stack (Postgres + `db-migrator`).
- The `db-migrator` container will then apply all pending migrations to the remote database and shut down.

## Troubleshooting

- **Connection issues:**
  - verify the SSH credentials in `.env.deploy`.
  - ensure the remote host is reachable from your local machine (via SSH).
  - verify `DATABASE_URL` hostname (`postgres` or `localhost`) matches your configuration.
- **Migrations not applying during deployment:** check logs of the `db-migrator` container on the remote host:
  ```bash
  docker logs db-migrator
  ```

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
