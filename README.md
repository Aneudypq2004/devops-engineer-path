# DevOps Lab

> **DevOps Plan: from Full-Stack Developer to DevOps Engineer**
>
> A hands-on learning path for moving from full-stack development to DevOps engineering.

This repository holds the practice apps for the plan. The code is deliberately small, because the goal is to deploy, operate and break it rather than to build features. Each phase adds a new operational layer on top of the same API, web app and database. Every failure gets logged in [NOTES.md](NOTES.md).

## Contents

- [Starting point: the full-stack developer](#starting-point-the-full-stack-developer)
- [Learning path](#learning-path)
- [Architecture](#architecture)
- [Technologies](#technologies)
- [Repository layout](#repository-layout)
- [Endpoints](#endpoints)
- [Run locally on Windows](#run-locally-on-windows)
- [Build the artifacts you deploy in Phase 2](#build-the-artifacts-you-deploy-in-phase-2)
- [Command reference (Docker, apt and shell)](#command-reference-docker-apt-and-shell)
- [What is deliberately NOT here](#what-is-deliberately-not-here)
- [Working method](#working-method)
- [Rules](#rules)

## Starting point: the full-stack developer

The path starts from a working full-stack developer. The technologies below are what I already build with, and each one maps to a DevOps skill I need to learn.

| Area | Technologies I already use | DevOps skill it leads to |
| --- | --- | --- |
| Frontend web | **Angular**, TypeScript, HTML/CSS | Building and serving static assets, Nginx, CDN and caching |
| Mobile | **Flutter** | Build pipelines, app signing, release automation |
| Backend | **.NET** / C# (ASP.NET Core, EF Core), **Odoo** | Running services in production, systemd, containers, migrations |
| Data | PostgreSQL, SQL Server, Firestore | Backups, access control, running databases safely |
| Backend as a service | **Firebase** (Auth, Firestore, Functions, Hosting) | Managed cloud services, secrets, security rules |
| Cloud | **Google Cloud**, **Azure** | IAM, networking, infrastructure as code |
| Tooling | Git, **Bitbucket**, **Jira**, **Sentry** | CI/CD with Bitbucket Pipelines, observability, incident tracking |

## Learning path

| Phase | Focus | Outcome | Status |
| --- | --- | --- | --- |
| 1 | Linux foundations: Ubuntu VM, static IP with netplan, SSH keys and config, users, packages, PostgreSQL | A reachable, hardened VM with a database that only listens on localhost | ☐ |
| 2 | Manual deployment: Nginx reverse proxy, systemd service, service user, file permissions, environment file, local HTTPS | The app runs on the VM, survives reboots and is reachable at `https://` | ☐ |
| 3 | Automation: scripted, repeatable deploys and DB migrations | One command deploys a new version and rolls back on failure | ☐ |
| 4 | Containers: Dockerfiles, multi-stage builds, Docker Compose | The whole stack starts with `docker compose up` | ☐ |
| 5 | CI/CD: Bitbucket Pipelines (build, test, publish, deploy) | Every merge to `main` is built, tested and deployed automatically | ☐ |
| 6 | Cloud and IaC: Azure / Google Cloud, Terraform or Bicep | The environment can be recreated from code | ☐ |
| 7 | Observability: structured logs, metrics, alerts, Sentry | Failures are visible before users report them | ☐ |

Mark a phase ✅ when its outcome works end to end and its problems are written down in `NOTES.md`.

## Architecture

```text
 Browser
    │  HTTPS
    ▼
 ┌──────────────────────── Ubuntu VM ────────────────────────┐
 │  Nginx                                                     │
 │   ├── /            → static files in /var/www/devops-web   │
 │   └── /api, /health → Kestrel on 127.0.0.1:5000            │
 │                         (DevOpsLab.Api, systemd service)   │
 │                              │                             │
 │                              ▼                             │
 │                     PostgreSQL (localhost:5432)            │
 └────────────────────────────────────────────────────────────┘
```

- The Angular app always calls relative URLs (`/api/...`). In development, `web/proxy.conf.json` forwards them to `http://localhost:5000`. On the server, Nginx does the forwarding.
- Nginx handles TLS. The API does not redirect to HTTPS, and it reads `X-Forwarded-For` / `X-Forwarded-Proto` to get the real client IP and scheme.

| Part | Stack | Path |
| --- | --- | --- |
| API | ASP.NET Core (.NET 10), EF Core + Npgsql, xUnit | [api/](api/) |
| Web | Angular 21 (standalone, signals, zoneless), Vitest | [web/](web/) |
| Database | PostgreSQL (in the Ubuntu VM) | - |

## Technologies

### Application

| Technology | Role in this project |
| --- | --- |
| **ASP.NET Core (.NET 10)** | Web API framework. Runs on the built-in Kestrel server and exposes the tasks CRUD, `/api/info` and `/health` through controllers. |
| **Entity Framework Core 10** | ORM that maps `TaskItem` to tables, runs queries and manages schema changes through migrations (`dotnet ef`). |
| **Npgsql** | The PostgreSQL provider for EF Core. |
| **ASP.NET Core Health Checks** | The `/health` endpoint, including a database check. Deploy scripts and monitors use it to tell if the app is really up. |
| **OpenAPI** | Generates the API description, enabled in Development only. |
| **xUnit** | Unit tests for the service layer (`TaskServiceTests`). |
| **Angular 21** | Single-page frontend built with standalone components, signals and zoneless change detection. It always calls relative `/api/...` URLs. |
| **TypeScript** | Language for the frontend, with strict type checking. |
| **Vitest + jsdom** | Test runner and DOM environment for the Angular unit tests. |
| **Prettier** | Code formatting for the web project. |
| **npm** | Package manager for the web project (`npm ci` for reproducible installs). |

### Infrastructure and operations

| Technology | Role in this project |
| --- | --- |
| **Ubuntu Server (VM)** | The Linux machine where the stack is deployed and operated. |
| **netplan** | Configures the VM's static IP, gateway and DNS (see [testing-files/netplan.yml](testing-files/netplan.yml)). |
| **OpenSSH** | Remote access to the VM and the tunnel (`ssh -L`) that reaches PostgreSQL from Windows. |
| **PostgreSQL** | Relational database. It listens only on `localhost` inside the VM. |
| **Nginx** | Reverse proxy and static file server. Terminates HTTPS, serves the Angular build and forwards `/api` and `/health` to Kestrel. |
| **systemd** | Runs the API as a service: starts it on boot, restarts it on failure, and supplies the environment file. |
| **.NET user-secrets** | Keeps the local connection string out of Git during development. |

### Planned (later phases)

| Technology | Phase | Purpose |
| --- | --- | --- |
| **Docker / Docker Compose** | 4 | Package and run the whole stack as containers. |
| **Bitbucket Pipelines** | 5 | Build, test and deploy on every merge to `main`. |
| **Azure / Google Cloud** | 6 | Host the environment in the cloud. |
| **Terraform or Bicep** | 6 | Define the infrastructure as code. |
| **Sentry** | 7 | Error tracking and alerting. |

## Repository layout

```text
api/
  src/DevOpsLab.Api/        Controllers, services, EF Core DbContext and repositories
  tests/DevOpsLab.Api.Tests xUnit tests
web/                        Angular app (tasks and about pages)
testing-files/              Scratch config used while practicing (e.g. netplan)
deploy/                     (you create it) Nginx, systemd and deploy scripts
NOTES.md                    Troubleshooting log
```

## Endpoints

| Path | Purpose |
| --- | --- |
| `GET /health` | Health check, including the database. Use it in deploy scripts and monitors |
| `GET /api/info` | Version, environment and host of the running build |
| `GET/POST /api/tasks`, `GET/PUT/DELETE /api/tasks/{id}` | Tasks CRUD |

`/api/info` is the quickest way to confirm which version actually got deployed.

## Run locally on Windows

### Prerequisites

- .NET 10 SDK
- Node.js (LTS) and npm
- SSH access to the lab VM, with a `devops-lab` host entry in `~/.ssh/config`

### 1. Open a tunnel to PostgreSQL

PostgreSQL runs in the VM and only listens on localhost there. Reach it through an SSH tunnel and keep this terminal open:

```powershell
ssh -L 5432:localhost:5432 devops-lab
```

### 2. Run the API

In another terminal:

```powershell
cd api
dotnet tool restore
dotnet user-secrets set "ConnectionStrings:Default" "Host=localhost;Port=5432;Database=devops_tasks;Username=devops_app;Password=<your-password>" --project src/DevOpsLab.Api
dotnet ef migrations add InitialCreate --project src/DevOpsLab.Api --output-dir Data/Migrations   # first time only
dotnet ef database update --project src/DevOpsLab.Api
dotnet test
dotnet run --project src/DevOpsLab.Api      # http://localhost:5000/health
```

### 3. Run the web app

```powershell
cd web
npm ci
npm start                                   # http://localhost:4200
```

## Build the artifacts you deploy in Phase 2

```powershell
# API for Linux (framework-dependent: install the ASP.NET Core 10 runtime on the VM)
dotnet publish api/src/DevOpsLab.Api -c Release -r linux-x64 --self-contained false -p:Version=1.0.0 -o out/api

# Migrations as a single Linux executable (run it on the VM with --connection "<conn string>")
dotnet ef migrations bundle --project api/src/DevOpsLab.Api -r linux-x64 --self-contained -o out/efbundle

# Angular static files -> copy the contents of web/dist/web/browser to /var/www/devops-web
cd web; npm run build
```

Bump `-p:Version` on every deploy so `/api/info` tells you what is running.

## Command reference (Docker, apt and shell)

What each command used in the setup does, flag by flag. Written while following the plan,
so that every command is understood before it is automated.

### Here-documents and `EOF`

A **here-document** feeds a block of text to a command's standard input. It starts with
`<<DELIMITER` after the command and ends at a line containing only that delimiter.

```bash
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
EOF
```

| Part | Meaning |
|---|---|
| `<<EOF` | Start of the here-document. Everything on the following lines is sent to the command's stdin. |
| `EOF` (closing line) | Ends the block. It must be **alone on its line, at column 0, with no trailing spaces**, and match the opening word exactly. |
| `EOF` as a word | Only a convention ("end of file"). Any word works (`END`, `SQL`, `README_EOF`), as long as it is the same at both ends. |

**Variants**

| Form | Behavior |
|---|---|
| `<<EOF` | Your **local** shell expands `$VAR`, `$(command)` and backticks before the text is sent. Use it when you want values filled in (for example the Ubuntu codename in `docker.sources`). |
| `<<'EOF'` (quoted) | **No expansion at all**: the text is sent literally. Use it when the receiver should expand it, for example a script sent over ssh (`ssh host bash -s <<'EOF'`, as in `deploy/scripts/deploy.sh` and `rollback.sh`), or when the text contains `$` that must stay as it is. |
| `<<-EOF` | Like `<<EOF`, but leading **tab** characters (not spaces) are stripped, so the block and its closing line can be indented inside functions. |
| `<<< "text"` | A *here-string*: sends one string to stdin (`bc <<< "2+2"`). |

**Common uses**

```bash
# Write a file (sudo tee, because with `sudo cat > file` the > is done by YOUR shell, not by sudo)
sudo tee /etc/example.conf <<'EOF'
key=value
EOF

# Run a multi-line script on a remote server, with arguments ($1 = first argument)
ssh devops-lab bash -s -- "$API_BASE" <<'EOF'
cd "$1/releases" && ls -1
EOF
```

- `tee` reads stdin and writes it to a file **and** to stdout. Add `> /dev/null` to silence the echo, or `-a` to append instead of overwrite.
- If the body itself contains a line `EOF` (for example a heredoc inside a heredoc), use a **different delimiter** for the outer one, otherwise the shell ends the block too early.
- If the shell complains about an unexpected end of file, check that the closing delimiter has no spaces before or after it.

### Create the APT keyrings directory

```bash
sudo install -m 0755 -d /etc/apt/keyrings
```

Creates `/etc/apt/keyrings`, the directory where `apt` keeps the GPG signing keys of
third-party repositories (for example Docker or Microsoft). It must exist before you
download a repository key into it.

| Part | Meaning |
|---|---|
| `sudo` | Run as root. Needed because only root can write under `/etc`. |
| `install` | A coreutils program that copies files and sets permissions and ownership in one step. With `-d` it creates directories instead. |
| `-m 0755` | **m**ode: the permissions of the directory, in octal (see below). |
| `-d` | **d**irectory: treat the argument as a directory to create (parent directories are created too) instead of a file to copy. |
| `/etc/apt/keyrings` | The directory to create. |

#### What `0755` means

| Digit | Applies to | Permissions | Meaning |
|---|---|---|---|
| `0` | special bits | none | no setuid, setgid or sticky bit |
| `7` | owner (root) | `rwx` | read, write, enter |
| `5` | group | `r-x` | read, enter |
| `5` | others | `r-x` | read, enter |

For a directory, "execute" means "can enter it". Everyone, including `apt`, can read the
keys, but only root can add or remove them.

#### Why `install -d` and not `mkdir -p`

It does the same job in a single command, and it is **idempotent**: if the directory
already exists it just sets the requested permissions instead of failing, so the command
is safe to run again.

### Download Docker's GPG key

```bash
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
```

Downloads Docker's public GPG key into the keyrings directory. `apt` uses it to check
that Docker packages are really signed by Docker before installing them.

| Part | Meaning |
|---|---|
| `sudo` | Run `curl` as root, so it can write into the root-owned `/etc/apt/keyrings`. |
| `curl` | Command-line tool that transfers data over URLs. |
| `-f` | **f**ail: on an HTTP error (404, 500...) exit with an error instead of saving the error page as if it were the key. |
| `-s` | **s**ilent: no progress bar. |
| `-S` | Show **e**rrors even in silent mode. Always combined with `-s`, so failures are still visible. |
| `-L` | Follow redirects (**L**ocation headers) if the server moves the file. |
| `-o <file>` | **o**utput: write the response to this file instead of printing it to the terminal. |
| `https://download.docker.com/linux/ubuntu/gpg` | Docker's official URL for the Ubuntu signing key. |
| `/etc/apt/keyrings/docker.asc` | Where the key is saved. `.asc` means ASCII-armored (text) format, which `apt` accepts as is. |

The flags are usually written together as `-fsSL`.

#### Notes

- **Why `-o` and not `>`:** with `sudo curl ... > file`, the `>` redirect is performed by
  your normal shell, not by `sudo`, so it would fail with "Permission denied". `-o` makes
  `curl` itself (running as root) write the file.
- **Trust:** the key is fetched over HTTPS, which proves you talk to `download.docker.com`.
  To be stricter, compare the key's fingerprint with the one in Docker's official
  documentation (`gpg --show-keys /etc/apt/keyrings/docker.asc`).
- **Readable by `apt`:** the file must be readable by everyone. With the default umask it
  already is; Docker's docs add `sudo chmod a+r /etc/apt/keyrings/docker.asc` to be sure.

### Run database migrations with Docker Compose

```bash
docker compose --profile tools run --rm migrate
```

Applies the EF Core migrations to the Postgres container by running the migration bundle
(`efbundle`) in a one-off container. The `migrate` service is defined in `compose.yaml`.

| Part | Meaning |
|---|---|
| `docker compose` | Docker Compose v2 command, reads `compose.yaml` (and `compose.override.yaml`) from the current directory. |
| `--profile tools` | Enables the `tools` profile for this command. Services with `profiles: ["tools"]` are skipped by a normal `docker compose up`, so migrations never run by accident. |
| `run` | Starts a one-off container for a single service instead of starting the whole stack. |
| `--rm` | Deletes the container when it finishes, so finished migration containers do not pile up. |
| `migrate` | The service to run. |

#### How the `migrate` service works

- **Image:** `mcr.microsoft.com/dotnet/runtime-deps:10.0` is a minimal Linux image with only
  the native libraries a self-contained .NET program needs. The bundle already contains the
  .NET runtime, so no SDK is required.
- **Volume:** `./efbundle:/app/efbundle:ro` mounts the bundle from the repo root into the
  container, read-only. It is not baked into any image.
- **Command:** `/app/efbundle --connection "<connection string>"`. The connection string is
  built from `POSTGRES_DB`, `POSTGRES_USER` and `POSTGRES_PASSWORD` in `.env`. `Host=db` is the
  Postgres service name on the Docker network.
- **`depends_on` + `service_healthy`:** waits until Postgres passes its `pg_isready`
  healthcheck before the bundle starts.
- **Network:** joins `backend`, the internal network where `db` lives.

#### Before the first run

1. Build a Linux, self-contained bundle in the repo root:
   ```bash
   cd api/src/DevOpsLab.Api
   dotnet ef migrations bundle --self-contained -r linux-x64 -o ../../../efbundle
   ```
   If the output is `efbundle.exe`, it is a Windows build and will not run in the container.
2. Make it executable: `chmod +x efbundle` (otherwise: "permission denied").
3. Start the database first: `docker compose up -d db`.

`/efbundle` is listed in `.gitignore`: the binary is large (about 70 MB) and must not be
committed.

#### Security note

The password is passed on the command line, so it is visible in `docker inspect` and the
process list. That is acceptable for a local learning lab. For anything shared or real, pass
the connection string through an environment variable instead.

### Install Docker Engine: the remaining steps

The first steps (`install -m 0755 -d /etc/apt/keyrings` and the `curl` that downloads the GPG
key) are explained above. These are the rest, in order.

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo docker run --rm hello-world
```

| Command | What it does |
|---|---|
| `sudo apt update` | Refreshes the package index from all configured repositories. Run it after adding a repository so `apt` can see its packages. |
| `sudo apt install ca-certificates curl` | `ca-certificates` lets tools verify HTTPS certificates; `curl` downloads the key. Both are needed before the next steps. |
| `sudo chmod a+r /etc/apt/keyrings/docker.asc` | `a` = all users, `+r` = add read permission. `apt` must be able to read the key. |
| `sudo tee /etc/apt/sources.list.d/docker.sources <<EOF ... EOF` | Writes the text between the `EOF` lines to the repository file. `tee` is used because it runs as root; with `sudo cat > file` the `>` would be done by your normal shell and fail. |
| `sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin` | Installs the Docker daemon (`docker-ce`), the `docker` command (`docker-ce-cli`), the container runtime (`containerd.io`), `docker buildx` and `docker compose` v2. |
| `sudo systemctl enable --now docker` | `enable` starts the service at every boot; `--now` also starts it right now. |
| `sudo docker run --rm hello-world` | Smoke test: pulls a tiny image, runs it once, prints a message and removes the container (`--rm`). |

#### The repository file (`docker.sources`)

| Line | Meaning |
|---|---|
| `Types: deb` | Binary packages (not source code). |
| `URIs: https://download.docker.com/linux/ubuntu` | Where the packages are downloaded from. |
| `Suites: $(...)` | The Ubuntu codename, for example `noble`. `. /etc/os-release` loads the OS info file; `${UBUNTU_CODENAME:-$VERSION_CODENAME}` means "use `UBUNTU_CODENAME`, or `VERSION_CODENAME` if it is empty". The heredoc is **unquoted** (`<<EOF`), so your shell expands this before `tee` receives it. |
| `Components: stable` | The release channel. |
| `Signed-By: /etc/apt/keyrings/docker.asc` | Only packages signed with this key are trusted for this repository. |

#### Run Docker without `sudo` (lab VM only)

```bash
sudo usermod -aG docker $USER
```

`usermod` modifies a user account. `-G docker` sets the supplementary group and `-a` means
**append** (without it you would remove the user from all other groups). Log out and in
again for it to apply. Members of the `docker` group have root-equivalent power on the host,
so do this only on a personal lab VM, never on a shared server.

#### Free the ports before starting the stack

```bash
sudo systemctl disable --now nginx devops-api
```

Stops the native Phase 2 services and prevents them from starting at boot, because the
containers need the same ports (80, 443, 5000). Take a database backup first.

### Everyday Docker commands

| Command | Function |
|---|---|
| `docker ps -a` | Lists containers. `-a` includes stopped ones. |
| `docker images` / `docker image ls` | Lists local images and their sizes. |
| `docker logs -f --tail 50 <name>` | `-f` follows the output live; `--tail 50` starts from the last 50 lines. |
| `docker exec -it <name> sh` | Runs a command inside a running container. `-i` keeps stdin open and `-t` allocates a terminal, so you get an interactive shell (only if the image contains `sh`). |
| `docker inspect <name>` | Prints the full configuration and state as JSON. |
| `docker stats` | Live CPU, memory and network usage per container. |
| `docker run --rm -it alpine sh` | Throwaway container: a shell in a tiny Alpine image, deleted on exit. |
| `docker system df` | Disk used by images, containers and volumes. |

#### Try a throwaway web server

```bash
docker run -d --name web-test -p 127.0.0.1:8080:80 nginx:alpine
curl -I http://127.0.0.1:8080
docker logs web-test
docker exec web-test nginx -v
docker stop web-test && docker rm web-test
```

| Command | What it does |
|---|---|
| `docker run -d --name web-test -p 127.0.0.1:8080:80 nginx:alpine` | `-d` runs in the background, `--name` names it, `-p host:container` publishes a port. Binding to `127.0.0.1` makes it reachable only from the VM itself. Docker edits `iptables` directly, so a port published without `127.0.0.1` can bypass UFW rules. |
| `curl -I <url>` | `-I` sends a HEAD request and prints only the response headers. |
| `docker logs web-test` | Prints what the container wrote to stdout/stderr. |
| `docker exec web-test nginx -v` | Runs `nginx -v` inside the container and prints the nginx version. |
| `docker stop web-test && docker rm web-test` | Stops the container, then (only if that succeeded, `&&`) deletes it. |

### Build and inspect an image

```bash
docker build -t devops-api:dev ./api
docker image ls devops-api
docker history devops-api:dev
docker inspect -f '{{.Config.User}} {{.Config.Healthcheck}}' devops-api:dev
```

| Command | What it does |
|---|---|
| `docker build -t devops-api:dev ./api` | Builds an image from the Dockerfile in `./api` (the build context). `-t name:tag` names and tags the result. |
| `docker image ls devops-api` | Lists the images of that repository with their size. |
| `docker history devops-api:dev` | Shows every layer, the instruction that created it and its size. Useful to find what makes an image big. |
| `docker inspect -f '<template>' <image>` | `-f` formats the JSON with a Go template. This one prints the user the container runs as (should be `app`, not root) and the configured healthcheck. |

**Layer caching:** copy dependency manifests (`package-lock.json`, `*.csproj`) and restore
first, source code later, so a code change reuses the cached dependency layer. Keep
`node_modules`, build output and `.env` out of the context with `.dockerignore`.

### Networks, volumes and resource limits

```bash
docker network create demo
docker run -d --name db1 --network demo -e POSTGRES_PASSWORD=<LAB_PASSWORD> postgres:17-alpine
docker run --rm --network demo postgres:17-alpine pg_isready -h db1
docker volume create demo-data
docker run -d --name limited --memory 128m --cpus 0.5 nginx:alpine
docker stats --no-stream limited
```

| Command | What it does |
|---|---|
| `docker network create demo` | Creates a user-defined bridge network. Containers on it reach each other **by name**; the default bridge has no name resolution. |
| `docker run -d --name db1 --network demo -e POSTGRES_PASSWORD=<LAB_PASSWORD> postgres:17-alpine` | Starts Postgres on that network. `-e NAME=value` sets an environment variable. Use a throwaway lab password, never a real one. |
| `docker run --rm --network demo postgres:17-alpine pg_isready -h db1` | Runs `pg_isready` from a second container to check that `db1` accepts connections, proving name resolution works. |
| `docker volume create demo-data` | Creates a named volume managed by Docker. It outlives containers. |
| `docker run -d --name limited --memory 128m --cpus 0.5 nginx:alpine` | `--memory` caps RAM and `--cpus` caps CPU time, so one container cannot starve the VM. |
| `docker stats --no-stream limited` | Prints one snapshot of the usage instead of a live view. |

### Docker Compose commands

```bash
docker compose config
docker compose up -d --build
docker compose ps
docker compose logs -f api
docker compose exec redis redis-cli ping
docker compose down
```

| Command | What it does |
|---|---|
| `docker compose config` | Validates `compose.yaml` and prints the merged result (including `compose.override.yaml` and `.env` values; do not paste its output anywhere public). |
| `docker compose up -d --build` | Creates and starts the stack in the background. `--build` rebuilds the images first. |
| `docker compose ps` | Shows the stack's containers, their state and health. |
| `docker compose logs -f api` | Follows the logs of the `api` service. |
| `docker compose exec redis redis-cli ping` | Runs `redis-cli ping` inside the running `redis` service. `PONG` means it is alive. |
| `docker compose down` | Removes containers and networks but **keeps volumes**, so data survives. |
| `docker compose -f compose.yaml up -d` | Production form: `-f` names the file explicitly so `compose.override.yaml` (development settings) is **not** applied. |

`depends_on` with `condition: service_healthy` makes a service wait until its dependency's
healthcheck passes. That is the correct fix for start-up ordering; a `sleep` only guesses.

### Tag and push images to a registry

Never deploy only `latest`: you cannot tell what is running or go back. Tag every image with
the version and the short commit SHA.

```bash
VERSION=1.2.0
SHA=$(git rev-parse --short HEAD)
docker build -t <namespace>/devops-api:$VERSION -t <namespace>/devops-api:$SHA ./api
echo "$REGISTRY_TOKEN" | docker login -u <user> --password-stdin
docker push <namespace>/devops-api:$VERSION
docker push <namespace>/devops-api:$SHA
```

| Command | What it does |
|---|---|
| `VERSION=1.2.0` | Stores the version in a shell variable. |
| `SHA=$(git rev-parse --short HEAD)` | Stores the short hash of the current commit. |
| `docker build -t A -t B ./api` | One build, two tags: the same image gets both names. |
| `echo "$REGISTRY_TOKEN" \| docker login -u <user> --password-stdin` | Logs in to the registry. `--password-stdin` reads the token from the pipe, so it never appears in the process list or in `docker login` arguments. Use an access token with minimum scope, not your account password. |
| `docker push <name>:<tag>` | Uploads that tag to the registry. |

Azure Container Registry:

```bash
az acr login --name <acr-name>
docker tag devops-api:$SHA <acr-name>.azurecr.io/devops-api:$SHA
docker push <acr-name>.azurecr.io/devops-api:$SHA
```

| Command | What it does |
|---|---|
| `az acr login --name <acr-name>` | Authenticates Docker against your ACR using your Azure CLI login. |
| `docker tag <source> <target>` | Adds another name to an existing image (here: the registry-qualified name). Nothing is copied. |
| `docker push ...` | Uploads it to ACR. |

On the VM, after setting `APP_VERSION` in `.env`: `docker compose pull && docker compose up -d`
(`pull` downloads the new images, then `up -d` recreates only the containers that changed).

### Redis checks

```bash
docker compose exec redis redis-cli ping                     # PONG
docker compose exec redis redis-cli set lab:test ok
docker compose exec redis redis-cli get lab:test
docker compose exec redis redis-cli info persistence | head
```

| Command | What it does |
|---|---|
| `redis-cli ping` | Health check; the server answers `PONG`. |
| `redis-cli set lab:test ok` / `get lab:test` | Writes and reads a test key. |
| `redis-cli info persistence \| head` | Shows persistence status (append-only file on or off, last save). `head` keeps the first 10 lines. |

Redis lives on the internal `backend` network, is reachable as `redis:6379` and is never
published to the host. To go further, add `--requirepass ${REDIS_PASSWORD}` to its command.

### Break-and-fix commands

| Command | What it does |
|---|---|
| `docker volume ls` | Lists named volumes. Run it before and after `down -v` to see `pgdata` disappear. |
| `docker compose down -v` | Like `down`, but `-v` also **deletes the named volumes** declared in the file. The database contents are lost; images, `compose.yaml` and `.env` are not. Restore from a `pg_dump`. |
| `docker compose logs --tail 30 api` | Last 30 log lines of the API (look for "connection refused" when it starts before the database). |
| `docker inspect -f '{{.State.Health.Status}}' $(docker compose ps -q db)` | `docker compose ps -q db` prints the container ID of `db`; `$(...)` passes it to `inspect`, which prints `starting`, `healthy` or `unhealthy`. |
| `docker logs --tail 50 devops-lab-api-1` | Logs of one container by its generated name (`<project>-<service>-<number>`). |
| `docker inspect -f '{{.State.ExitCode}} {{.RestartCount}} {{.State.OOMKilled}}' <name>` | How it exited, how many times it was restarted, and whether the kernel killed it for using too much memory. |
| `docker inspect -f '{{json .Config.Env}}' <name>` | Prints the container's environment variables as JSON (check for a wrong variable name). It can contain secrets: do not share the output. |

| Exit code | Typical meaning |
|---|---|
| `0` | The process finished normally (a foreground process that ended). |
| `1` | Application error: read the logs. |
| `137` | Killed (SIGKILL), often out of memory: check `OOMKilled`. |
| `139` | Segmentation fault. |
| `143` | Stopped with SIGTERM (a normal `docker stop`). |

## What is deliberately NOT here

Phase 2 is yours to build on the server:

- [ ] Nginx server block (static files + reverse proxy for `/api` and `/health`)
- [ ] systemd unit for the API
- [ ] `www-api` service user and file permissions
- [ ] Environment file with `ConnectionStrings__Default` (mode `600`)
- [ ] Local HTTPS

Write them in `deploy/` as you go, and log every error in `NOTES.md`.

## Working method

1. **Do it by hand first.** Run each step manually before you automate it.
2. **Break it on purpose.** Stop the database, use wrong permissions, fill the disk. Then watch what `/health`, `journalctl` and the Nginx logs say.
3. **Write it down.** Log every problem in `NOTES.md`: symptom, the command that found it, root cause and fix.
4. **Automate what you understand.** A script is only worth writing once you know every step it does.

## Rules

- No secrets in Git. Use user-secrets locally and an `EnvironmentFile` with mode `600` on the server.
- Fake data only.
- Work through pull requests to `main`, using branches named `feature/PROJ-123-short-desc` and commits named `PROJ-123: short description`.
