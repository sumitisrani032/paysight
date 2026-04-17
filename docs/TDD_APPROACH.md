# TDD Approach

## Development Cycle

Every backend feature follows strict **test → feat → refactor** cycle:

1. **test** — Write failing specs covering happy path and edge cases. Commit.
2. **feat** — Write minimum code to pass all tests. Commit.
3. **refactor** — Clean up duplication, extract helpers, improve structure. Commit. Only if genuinely needed.

## Commit Evolution

The commit history is designed to be read sequentially. Each commit builds on the previous one, showing how the system evolved.

### Backend (action-by-action)

```
Employee Creation:
  test → feat

Employee Listing (with pagination):
  test → feat

Employee Show:
  test → feat

Employee Update:
  test → feat
  refactor: extract set_employee callback (duplication emerged after show + update)

Employee Delete:
  test → feat (uses set_employee from the start — earlier refactor already paid off)

  refactor: extract render_resource + render_employee helpers in ApplicationController
  (duplication across all CRUD actions)

Salary Stats:
  test → feat

Average by Job Title:
  test → feat

Salary Summary by Country:
  test → feat

Seed Script:
  test → feat  (feat commit carries the polished seeder:
                cycle-based country × job_title assignment, inline frozen SALARY_RANGES,
                per-batch transactional upsert_all with :index_employees_on_lower_email,
                dev-gated Employee.delete_all, logging, DATA_PATH constant)

Search + Filters on Employees Index (exact email + country + job title + status):
  test → feat  (feat commit also carries cross-cutting backend improvements
                that emerged during the same review cycle:
                DB indexes including covering [country, job_title, salary]
                  and [email, country, job_title, employment_status],
                salary analytics controller flattened with caching + require_param!,
                Employee enum + scopes (by_country / by_job_title / by_status / by_email),
                standardized { success, data, meta } envelope,
                StandardError rescue, clamp_per_page,
                SalaryAnalyticsService unified average_by_job_title shape)

  style: apply rubocop auto-corrections across backend

  refactor: tidy request specs with shared let(:body) and let(:headers)
```

### Frontend (feature-by-feature)

```
chore: scaffold Next.js project
feat: API client (with response-envelope interceptor) and app shell
feat: employee listing page with pagination
feat: create/edit modal
feat: delete with confirmation
feat: salary insights dashboard
feat: employee detail view page
chore: frontend .env example and README
feat: search and filter UI on employees page
refactor: restructure frontend (types, hooks, components, services, constants, styles)
```

### Docs

```
docs: project README, architecture (with diagrams), trade-offs, TDD approach, AI usage
```

## Testing Strategy

### What we test
- **Model specs** — validations, enum definition, email normalization callback, `by_country` scope
- **Request specs** — full HTTP cycle for every endpoint (happy path, validation errors, 404s, missing params, exact-email filter, filter combinations, pagination)
- **Service specs** — analytics logic with edge cases (single employee, empty country, decimal precision, single-query assertion)
- **Seeder specs** — correctness (count, name sources, currency mapping, job titles), dev-only `delete_all` behavior, performance (<10s)

### What we don't test
- Controllers in isolation (request specs cover the full stack)
- Frontend components (would require Jest + Testing Library — deferred for scope)
- Authentication (not implemented)

### Test characteristics
- **Fast** — 64 specs run in under 10 seconds including the slow seeder performance test
- **Deterministic** — no random data in assertions, factory-generated test data, fixed timestamps
- **Independent** — each test creates its own data, transactional rollback between tests, no shared state
- **Shared helpers** — `let(:body) { JSON.parse(response.body) }` and `let(:headers) { { 'CONTENT_TYPE' => 'application/json' } }` used across request specs for readability
