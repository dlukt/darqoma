## 2024-05-24 - [CRITICAL] Remote Code Execution via ConfigDB
**Vulnerability:** The configuration database parser `Pleroma.ConfigDB` used `Code.eval_string/1` to deserialize database configurations (Regexes, tuples, and partial chains). This allows RCE if the config data is manipulated.
**Learning:** Even seemingly internal configuration parsing can be an attack vector for RCE when dynamic string execution is used in Elixir.
**Prevention:** Never use `Code.eval_string/1` to parse untrusted strings. Use `Regex.compile/2` for Regexes and `Code.string_to_quoted/1` coupled with strict AST whitelisting (`safe_ast?/1`) to deserialize tuples and native data types.
