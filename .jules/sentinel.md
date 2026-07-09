## 2024-07-02 - Atom Exhaustion DoS vulnerability
**Vulnerability:** Discovered `String.to_atom/1` used on unvalidated string input (password hash digest names).
**Learning:** In Elixir/Erlang, atoms are not garbage collected and there is a hard limit on the number of atoms. An attacker could send a large number of login requests with different dummy digest names, creating new atoms until the BEAM VM crashes (Denial of Service).
**Prevention:** Always use `String.to_existing_atom/1` instead of `String.to_atom/1` when parsing external or untrusted strings into atoms.

## 2024-07-04 - Local Uploader Path Traversal
**Vulnerability:** Path traversal in `Pleroma.Uploaders.Local` allowing arbitrary file writes and deletes outside the upload directory via `..` in upload paths.
**Learning:** Upload backends must sanitize the target paths they construct, as `Path.join` with untrusted input containing `..` will resolve to paths outside the intended directory.
**Prevention:** Validate that the provided file path does not contain `..` or use `Path.expand/1` and verify it starts with the expected base directory.
## 2024-05-24 - [Code.eval_string Arbitrary Code Execution]
**Vulnerability:** Found arbitrary code execution vulnerability in `lib/pleroma/config_db.ex` through the use of `Code.eval_string/1` to dynamically parse strings and regex from user configurations.
**Learning:** `Code.eval_string/1` allows malicious input to execute arbitrary commands or code, completely bypassing application constraints. String interpolation inside `Code.eval_string` exposes critical paths (e.g. `System.cmd` execution).
**Prevention:** Avoid `Code.eval_string` when parsing input from untrusted sources or dynamic configurations. Use safe equivalents like `Regex.compile!` for compiling regex patterns or `Code.string_to_quoted` with restricted AST evaluation for Elixir terms.

## 2024-07-08 - String Interpolation in Raw SQL Queries
**Vulnerability:** Found string interpolation being used directly in a raw PostgreSQL query `Repo.query!` inside `lib/pleroma/healthcheck.ex` (e.g., `"... where datname = '#{database}' ..."`).
**Learning:** Even internal configuration values (like the database name) can be risky if injected directly into query strings, especially if they are read from dynamic configs. Parameterization must be used everywhere.
**Prevention:** Always use parameterized queries (`"... where datname = $1 ..."` with `Repo.query!(query, [database])`) instead of Elixir string interpolation `#{}` for all SQL executions, regardless of the input source.
