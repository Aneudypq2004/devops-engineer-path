# DevOps Lab

> **Plan DevOps: de desarrollador full-stack a DevOps Engineer**
>
> A hands-on learning path for moving from full-stack development to DevOps engineering.

This repository holds the practice apps for the plan. The code is deliberately small, because the goal is to deploy, operate and break it rather than to build features. Each phase adds a new operational layer on top of the same API, web app and database. Every failure gets logged in [NOTES.md](NOTES.md).

## Contents

- [Learning path](#learning-path)
- [Architecture](#architecture)
- [Repository layout](#repository-layout)
- [Endpoints](#endpoints)
- [Run locally on Windows](#run-locally-on-windows)
- [Build the artifacts you deploy in Phase 2](#build-the-artifacts-you-deploy-in-phase-2)
- [What is deliberately NOT here](#what-is-deliberately-not-here)
- [Working method](#working-method)
- [Rules](#rules)

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
