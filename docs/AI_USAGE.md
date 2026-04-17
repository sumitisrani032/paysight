# AI Tools Usage

## Tool Used
Claude Code (Anthropic CLI) — used as a pair programming assistant throughout the project.

## How AI Was Used

### Code Generation
- Initial project scaffolding and configuration
- Model, controller, and service boilerplate
- RSpec test structure and assertions
- Frontend components (Ant Design table, forms, charts)
- Seeder logic with batch insert optimization

### Architecture Decisions
- AI suggested service layer separation for analytics (accepted — real business logic)
- AI suggested service layer for CRUD (rejected — too thin, kept in controller)

### Developer-driven additions (not AI-suggested)
- Unified `average_by_job_title` method — single service method returns `{ average, titles }` in both modes. When a `job_title` param is passed, the scalar `average` is derived from the already-computed `titles` list rather than issuing a second query; when no `job_title` is passed, `average` is nil and the ranked `titles` list is returned. Collapses what would otherwise be two endpoints into one without duplicating the aggregation SQL.
- Model scopes (`by_country`, `by_job_title`, `by_status`, `by_email`) — added during review to DRY up filter chains in the controller. `by_email` does an exact, case-normalized match (not partial/fuzzy search).
- Database indexes — single-column on `country`, `job_title`, `employment_status`; composites on `(country, job_title)`, covering `(country, job_title, salary)` for analytics, and `(email, country, job_title, employment_status)` for list-endpoint filter combinations. Chosen based on the actual query patterns in `SalaryAnalyticsService` and the employees list filter chain.
- Response envelope `{ success, data, meta }` — standardized during review for a uniform frontend contract.
- `render_employee` helper and `filtered_employees` private method in `EmployeesController` — avoid repeating `key: :employee` / scope-chain boilerplate.
- Seeder logic, end to end:
  - Cycle-based country × job_title assignment via `Array#product.cycle` (even distribution, no modulo math).
  - Fixture data (countries, job titles, first/last names) lives in `db/data/fixtures/` so it can change without code edits.
  - Per-job-title salary bands as the inline frozen `SALARY_RANGES` constant with a `DEFAULT_SALARY_RANGE` fallback.
  - Per-batch `ActiveRecord::Base.transaction` around `upsert_all(unique_by: :index_employees_on_lower_email)` — partial failures don't roll back good batches, and re-runs refresh existing rows instead of duplicating them.
  - Start / per-batch / end logging via `Rails.logger`.
  - `Employee.delete_all` gated to `Rails.env.development?` — safe to run in test/staging without wiping data.
  - Frozen constants (`DATA_PATH`, `SALARY_RANGES`, `DEFAULT_SALARY_RANGE`) guard against accidental mutation.
  - `DATA_PATH` constant + `read_json`/`read_lines` helpers that centralize all fixture I/O in one place.

### Developer-driven code review catches
- N+1 query risk in analytics — spotted during review and verified with a single-query RSpec assertion (`stats_by_country` asserts exactly 1 DB call via `ActiveSupport::Notifications`).
- Inconsistent salary types (BigDecimal vs Float) in API responses — caught during envelope review; normalized to `.to_f.round(2)` across the service so all numeric fields serialize consistently.
- Seeder data distribution bug where modulo alignment caused one job title per country — diagnosed during review; fixed by switching to `country_names.product(job_titles).cycle`, which guarantees every country gets every title evenly.
- CORS misconfiguration (`credentials: true` without `withCredentials` on client) — caught during the first cross-origin request; origins are now configurable via `CORS_ORIGINS` env var and credentials turned off.

### Testing
- AI generated comprehensive test scenarios including edge cases (empty country, nil values, duplicate emails, SQL wildcard injection)
- Performance test for seeder (<10 seconds) was AI-suggested
- Single-query assertion test for analytics was AI-suggested

## What AI Did NOT Do
- All architectural decisions were reviewed and approved by the developer
- Commit structure and TDD discipline were developer-directed
- Requirements interpretation and scope decisions were developer-driven
- Every AI suggestion was tested before acceptance — several were rejected (service layer for CRUD, department field)
- Reducing two endpoints (`salary_by_job_title` and "top paying titles") to a single unified method was a developer-driven decision to eliminate duplicate aggregation logic

## Approach
The AI was used as an accelerator, not a replacement. Every generated piece of code was reviewed, tested, and often modified before committing. The developer maintained control over architecture, scope, and quality decisions throughout.
