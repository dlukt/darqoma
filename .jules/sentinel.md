## 2024-05-30 - [Timing Attacks on Token Verification]
 **Vulnerability:** Pattern matching (e.g. `{:ok, %Token{token: ^session_token}}`) on string values (like tokens) using `^` results in a non-constant time comparison in Elixir which is susceptible to timing attacks.
 **Learning:** Elixir's `=`/`^` and `==` operators perform short-circuit evaluations on strings, exposing timing differences based on matching characters.
 **Prevention:** Use `Plug.Crypto.secure_compare/2` for all security-sensitive string comparisons, and guard inputs (e.g., `when is_binary(token)`) as the function expects non-nil binaries.
