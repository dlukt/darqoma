## 2024-05-24 - [CRITICAL] Remote Code Execution via ConfigDB
**Vulnerability:** The configuration database parser `Pleroma.ConfigDB` used `Code.eval_string/1` to deserialize database configurations (Regexes, tuples, and partial chains). This allows RCE if the config data is manipulated.
**Learning:** Even seemingly internal configuration parsing can be an attack vector for RCE when dynamic string execution is used in Elixir.
**Prevention:** Never use `Code.eval_string/1` to parse untrusted strings. Use `Regex.compile/2` for Regexes and `Code.string_to_quoted/1` coupled with strict AST whitelisting (`safe_ast?/1`) to deserialize tuples and native data types.
## 2024-05-18 - Prevent Atom Exhaustion in Elixir Password Verification
 **Vulnerability:** Unsafe atom creation using `String.to_atom` in `lib/pleroma/password/pbkdf2.ex` allowed attackers to exhaust the Erlang VM atom table by supplying unbounded unique digest strings in spoofed password hashes, causing a Denial of Service (DoS) crash.
 **Learning:** In Erlang/Elixir, atoms are not garbage collected. Dynamically creating atoms from untrusted user input using `String.to_atom` is extremely dangerous and can lead to immediate system crashes when the atom limit is reached.
 **Prevention:** Always use `String.to_existing_atom` when parsing untrusted input into atoms. Wrap the conversion in a `try...rescue ArgumentError` block to gracefully handle unrecognized inputs (e.g., returning `false` for failed verification) without crashing the process.

## 2024-05-27 - [Timing Attack in Admin Authentication]
**Vulnerability:** Admin tokens were being compared using standard equality operators (`==`) and pattern matching (`[^token]`), which short-circuit on the first mismatched character. This allowed an attacker to guess the secret admin token by measuring server response times.
**Learning:** Elixir pattern matching against a bound variable (e.g., `[^token]`) is vulnerable to timing attacks when the variable contains a secret. It behaves similarly to the `==` operator under the hood.
**Prevention:** Always use `Plug.Crypto.secure_compare/2` for comparing any security-sensitive strings or tokens, and avoid pattern matching exact secret values in function heads or `case` statements.
## 2024-05-18 - [Timing Attack Mitigation in Hash Comparisons]
**Vulnerability:** Use of standard string equality operator (`==`) for comparing sensitive hashes, cryptographic signatures, and CAPTCHA answers.
**Learning:** Standard string comparisons exit early when a mismatch occurs, leaking information about the expected string's length and content through timing variations. This allows an attacker to brute-force hashes byte-by-byte.
**Prevention:** Always use `Plug.Crypto.secure_compare/2` when comparing security-sensitive strings like tokens, hashes, passwords, and cryptographic signatures in Elixir applications.
## 2024-05-24 - SQL Injection in Database Mix Task

**Vulnerability:** A Mix task for database administration interpolated an unvalidated string `tsconfig` straight into a raw `ALTER DATABASE ... SET default_text_search_config` query and a `CREATE INDEX` query. An attacker with access to run the Mix task could potentially inject arbitrary SQL commands.
**Learning:** Raw SQL interpolations (using `#{...}`) without parameterized query variables (`$1`, `$2`, etc.) in `Ecto.Adapters.SQL.query!` should always be reviewed, particularly when parameterized queries are not supported by the SQL dialect (such as in `ALTER DATABASE` or `CREATE INDEX` statement objects in Postgres). In such situations, validating the user input against a database catalog table is an effective way to implement strict whitelisting.
**Prevention:** If an identifier cannot be dynamically bound in the query using parameterized logic, validate the string dynamically against system catalogs (e.g. checking `pg_ts_config` for text search configurations) before interpolation.
## 2025-02-18 - Prevent Denial of Service via Atom Exhaustion in Config DB
 **Vulnerability:** Unbounded string-to-atom conversion using `String.to_atom/1` on potentially dynamic or external data.
 **Learning:** In Elixir/Erlang, atoms are not garbage collected. Dynamically creating atoms from untrusted inputs can quickly exhaust the atom table, crashing the BEAM virtual machine and causing a Denial of Service.
 **Prevention:** Use `String.to_existing_atom/1` for converting strings to atoms, especially when dealing with external or user-provided input. Do not catch the `ArgumentError` to return a default atom like `:invalid_atom` if it could corrupt valid config data.
