# Trade-offs and Decisions

## What we chose and why

### No authentication
The doc doesn't mention user login or access control. Adding auth (JWT/Devise) would add complexity without satisfying a stated requirement. In production, this would be the first addition.

### No service layer for CRUD
Employee create/update/delete logic is 3-5 lines each. Extracting to services would be premature abstraction — the controller is already thin with `render_resource` and `set_employee`. The analytics service exists because it has real logic (SQL aggregations, dual-purpose methods).

### Currency stored per employee, not derived
Each employee record stores its own `currency` field. An alternative would be a `countries` table with a currency column. We chose the simpler approach because:
- No need for a join on every query
- The seeder assigns currency from `countries.json` based on country
- The doc doesn't mention managing countries as a separate entity

### `upsert_all` for seeding (skips validations)
The doc says "performance of the script matters." `upsert_all` is ~10x faster than `create!` loops because it generates a single `INSERT … ON CONFLICT DO UPDATE` per batch. We use `unique_by: :index_employees_on_lower_email` so re-running the seeder refreshes existing rows instead of erroring on uniqueness. The tradeoff is no model validations — acceptable because seed data is generated programmatically from known-good sources.

### Hard delete, not soft delete
The doc says "delete employees." We use `destroy` which permanently removes the record. In production, we'd add a `deleted_at` column with `paranoia` gem for audit trails.

### Single `average_by_job_title` endpoint instead of separate "top paying titles"
Originally we had a separate endpoint. We refactored to make `job_title` optional:
- With `job_title` param: returns single average (doc requirement 2b)
- Without `job_title` param: returns all titles ranked by average (doc requirement 2c)

This reduces API surface area and code duplication while serving both use cases.

### CORS allows all origins in development
Set to `*` by default for local development. In production, this should be restricted via the `CORS_ORIGINS` environment variable.

## Performance Considerations

### Query optimization
- `stats_by_country` fetches `MIN, MAX, AVG, COUNT` in one SQL query using `pick()` — verified with a test that asserts exactly 1 database query.
- `average_by_job_title` uses `.group(:job_title).average(:salary)` (single SQL aggregate) plus a Ruby-side `sort_by`. The per-title result set is at most ~10 rows, so in-memory sort is negligible and we avoid raw SQL strings.
- Per-request responses in the analytics controller are cached via `Rails.cache.fetch` with a 10-minute TTL — repeat queries in the same window skip the DB entirely.
- Database indexes cover all analytics and filter query patterns:
  - `country`, `job_title`, `employment_status` — single-column filters
  - `country+job_title` — common group-by pattern
  - `country+job_title+salary` — covering index for aggregate queries (PostgreSQL can satisfy `MIN/MAX/AVG` via index-only scan)
  - `email+country+job_title+employment_status` — covers the list endpoint's full filter combination in one index lookup
  - `LOWER(email)` unique — both enforces case-insensitive uniqueness and serves as the conflict target for seeder `upsert_all`

### Pagination
- Backend caps `per_page` at 100 to prevent memory issues.
- Frontend offers 10/25/50/100 page sizes.
- `render_resource` in ApplicationController handles pagination logic once, reused by all list endpoints.
- **Lazy evaluation** — Kaminari's `.page().per()` chains `LIMIT` and `OFFSET` onto the ActiveRecord::Relation. The full collection is never materialized. Controller passes a Relation (e.g., `Employee.order(:id).by_country(...)`) to `render_resource`, which adds pagination. Only when Rails serializes the response does SQL execute: one `SELECT ... LIMIT 25 OFFSET 0` for the records and one `COUNT(*)` for meta. At most 25 records are loaded, never all 10,000.

### Seeding performance
- 10,000 employees in batches of 1,000 using `upsert_all(unique_by: :index_employees_on_lower_email)` within a per-batch transaction (so one bad batch doesn't roll back good ones; re-runs refresh existing rows instead of duplicating).
- Country × job-title pairs assigned via `Array#cycle` for even, deterministic distribution — no modulo math.
- Per-job-title salary bands defined inline as the frozen `SALARY_RANGES` constant with a `DEFAULT_SALARY_RANGE` fallback.
- `Employee.delete_all` is gated to `Rails.env.development?` — safe to run in other environments without wiping real data.
- Completes in under 10 seconds (verified by RSpec performance test).
