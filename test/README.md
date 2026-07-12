# test/ — unattended-bootstrap harnesses

Both spin up a throwaway, RAM-backed (`--tmpfs`) Debian container, mount this repo
read-only, and prove the install runs **without user intervention**. Nothing touches
your disk or the live hosts. Requires Docker.

| script | what it proves |
|---|---|
| `test-bootstrap.sh` | the uv-tools path: `aider` installs on a **compiler-less** Debian (numpy as a wheel, not a source build) |
| `test-full-bootstrap.sh` | the whole `bootstrap.sh --packages` as a non-root user with passwordless sudo, **stdin closed** under a timeout — any prompt fails instead of hanging — then asserts symlinks, apt tools, and aider are in place |

```sh
./test/test-full-bootstrap.sh          # native arch
./test/test-full-bootstrap.sh amd64    # match an x86 VPS
```

The stdin-closed + `timeout` design is the actual test: an unattended run must never
block waiting for input.
