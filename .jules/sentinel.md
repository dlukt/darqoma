## 2024-07-08 - String Interpolation in Raw SQL Queries
**Vulnerability:** Found string interpolation being used directly in a raw PostgreSQL query `Repo.query!` inside `lib/pleroma/healthcheck.ex` (e.g., `"... where datname = '#{database}' ..."`).
**Learning:** Even internal configuration values (like the database name) can be risky if injected directly into query strings, especially if they are read from dynamic configs. Parameterization must be used everywhere.
**Prevention:** Always use parameterized queries (`"... where datname = $1 ..."` with `Repo.query!(query, [database])`) instead of Elixir string interpolation `#{}` for all SQL executions, regardless of the input source.
