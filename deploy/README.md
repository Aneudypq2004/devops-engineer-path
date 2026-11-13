# Deploy notes

Notes for setting up and operating the Ubuntu VM.

## Create the APT keyrings directory

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

### What `0755` means

| Digit | Applies to | Permissions | Meaning |
|---|---|---|---|
| `0` | special bits | none | no setuid, setgid or sticky bit |
| `7` | owner (root) | `rwx` | read, write, enter |
| `5` | group | `r-x` | read, enter |
| `5` | others | `r-x` | read, enter |

For a directory, "execute" means "can enter it". Everyone, including `apt`, can read the
keys, but only root can add or remove them.

### Why `install -d` and not `mkdir -p`

It does the same job in a single command, and it is **idempotent**: if the directory
already exists it just sets the requested permissions instead of failing, so the command
is safe to run again.

## Download Docker's GPG key

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

### Notes

- **Why `-o` and not `>`:** with `sudo curl ... > file`, the `>` redirect is performed by
  your normal shell, not by `sudo`, so it would fail with "Permission denied". `-o` makes
  `curl` itself (running as root) write the file.
- **Trust:** the key is fetched over HTTPS, which proves you talk to `download.docker.com`.
  To be stricter, compare the key's fingerprint with the one in Docker's official
  documentation (`gpg --show-keys /etc/apt/keyrings/docker.asc`).
- **Readable by `apt`:** the file must be readable by everyone. With the default umask it
  already is; Docker's docs add `sudo chmod a+r /etc/apt/keyrings/docker.asc` to be sure.
