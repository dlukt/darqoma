## 2024-07-02 - Atom Exhaustion DoS vulnerability
**Vulnerability:** Discovered `String.to_atom/1` used on unvalidated string input (password hash digest names).
**Learning:** In Elixir/Erlang, atoms are not garbage collected and there is a hard limit on the number of atoms. An attacker could send a large number of login requests with different dummy digest names, creating new atoms until the BEAM VM crashes (Denial of Service).
**Prevention:** Always use `String.to_existing_atom/1` instead of `String.to_atom/1` when parsing external or untrusted strings into atoms.

## 2024-07-04 - Local Uploader Path Traversal
**Vulnerability:** Path traversal in `Pleroma.Uploaders.Local` allowing arbitrary file writes and deletes outside the upload directory via `..` in upload paths.
**Learning:** Upload backends must sanitize the target paths they construct, as `Path.join` with untrusted input containing `..` will resolve to paths outside the intended directory.
**Prevention:** Validate that the provided file path does not contain `..` or use `Path.expand/1` and verify it starts with the expected base directory.
