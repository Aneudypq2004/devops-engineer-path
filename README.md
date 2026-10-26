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
