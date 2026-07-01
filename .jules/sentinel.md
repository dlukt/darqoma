## 2024-07-02 - Atom Exhaustion DoS vulnerability
**Vulnerability:** Discovered `String.to_atom/1` used on unvalidated string input (password hash digest names).
**Learning:** In Elixir/Erlang, atoms are not garbage collected and there is a hard limit on the number of atoms. An attacker could send a large number of login requests with different dummy digest names, creating new atoms until the BEAM VM crashes (Denial of Service).
**Prevention:** Always use `String.to_existing_atom/1` instead of `String.to_atom/1` when parsing external or untrusted strings into atoms.
