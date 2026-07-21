## 2024-05-24 - [CRITICAL] Remote Code Execution via ConfigDB
**Vulnerability:** The configuration database parser `Pleroma.ConfigDB` used `Code.eval_string/1` to deserialize database configurations (Regexes, tuples, and partial chains). This allows RCE if the config data is manipulated.
**Learning:** Even seemingly internal configuration parsing can be an attack vector for RCE when dynamic string execution is used in Elixir.
**Prevention:** Never use `Code.eval_string/1` to parse untrusted strings. Use `Regex.compile/2` for Regexes and `Code.string_to_quoted/1` coupled with strict AST whitelisting (`safe_ast?/1`) to deserialize tuples and native data types.

## 2024-05-27 - [Timing Attack in Admin Authentication]
**Vulnerability:** Admin tokens were being compared using standard equality operators (`==`) and pattern matching (`[^token]`), which short-circuit on the first mismatched character. This allowed an attacker to guess the secret admin token by measuring server response times.
**Learning:** Elixir pattern matching against a bound variable (e.g., `[^token]`) is vulnerable to timing attacks when the variable contains a secret. It behaves similarly to the `==` operator under the hood.
**Prevention:** Always use `Plug.Crypto.secure_compare/2` for comparing any security-sensitive strings or tokens, and avoid pattern matching exact secret values in function heads or `case` statements.
