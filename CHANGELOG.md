## v0.2.0 (2026-09-05)

### BREAKING CHANGE

- Replace GdPromise with GdbPromise and remove addons/gd_promise when upgrading to addons/gdb_promise.

### Feat

- integrate the gdbpromise dependency rename
- pin and re-vendor gd_promise from its own repository

### Fix

- allow retry after asynchronous resolution failures
- make the vendored checksum order locale independent
- keep readme and license out of archive root

## v0.1.0 (2026-09-01)

### Fix

- **ci**: validate commit messages only
