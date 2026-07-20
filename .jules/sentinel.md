## 2024-05-24 - [CRITICAL] Remote Code Execution via ConfigDB
**Vulnerability:** The configuration database parser `Pleroma.ConfigDB` used `Code.eval_string/1` to deserialize database configurations (Regexes, tuples, and partial chains). This allows RCE if the config data is manipulated.
**Learning:** Even seemingly internal configuration parsing can be an attack vector for RCE when dynamic string execution is used in Elixir.
**Prevention:** Never use `Code.eval_string/1` to parse untrusted strings. Use `Regex.compile/2` for Regexes and `Code.string_to_quoted/1` coupled with strict AST whitelisting (`safe_ast?/1`) to deserialize tuples and native data types.

## 2024-05-18 - [Timing Attack in String Comparison]
**Vulnerability:** String comparison vulnerabilities via `==` in password verification, URL signature validation, and admin authentication.
**Learning:** `==` fails early and exposes timing information allowing attackers to progressively guess secret strings, hashes, and tokens.
**Prevention:** Always use `Plug.Crypto.secure_compare/2` when comparing security-sensitive material like tokens, hashes, and signatures.
