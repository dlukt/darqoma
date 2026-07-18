## 2024-05-24 - [CRITICAL] Remote Code Execution via ConfigDB
**Vulnerability:** The configuration database parser `Pleroma.ConfigDB` used `Code.eval_string/1` to deserialize database configurations (Regexes, tuples, and partial chains). This allows RCE if the config data is manipulated.
**Learning:** Even seemingly internal configuration parsing can be an attack vector for RCE when dynamic string execution is used in Elixir.
**Prevention:** Never use `Code.eval_string/1` to parse untrusted strings. Use `Regex.compile/2` for Regexes and `Code.string_to_quoted/1` coupled with strict AST whitelisting (`safe_ast?/1`) to deserialize tuples and native data types.
## 2024-05-18 - Prevent Atom Exhaustion in Elixir Password Verification
 **Vulnerability:** Unsafe atom creation using `String.to_atom` in `lib/pleroma/password/pbkdf2.ex` allowed attackers to exhaust the Erlang VM atom table by supplying unbounded unique digest strings in spoofed password hashes, causing a Denial of Service (DoS) crash.
 **Learning:** In Erlang/Elixir, atoms are not garbage collected. Dynamically creating atoms from untrusted user input using `String.to_atom` is extremely dangerous and can lead to immediate system crashes when the atom limit is reached.
 **Prevention:** Always use `String.to_existing_atom` when parsing untrusted input into atoms. Wrap the conversion in a `try...rescue ArgumentError` block to gracefully handle unrecognized inputs (e.g., returning `false` for failed verification) without crashing the process.
