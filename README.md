# PaySight — Salary Management Tool

A minimal yet practical salary management system for organizations, designed to help HR Managers manage employee compensation efficiently.

## Monorepo Structure

```
paysight/
├── paysight-backend/    Ruby 3.3 + Rails 8.0 API with PostgreSQL
├── paysight-frontend/   Next.js 15 + React 19 + Ant Design + Recharts
└── docs/                Architecture decisions and planning artifacts
```

## Quick Start
### Application Live Demo Link
[https://wondrous-mandazi-2c33df.netlify.app/employees](https://wondrous-mandazi-2c33df.netlify.app/employees)
### Backend
```bash
cd paysight-backend
cp .env.example .env
bundle install
rails db:create db:migrate db:seed
rails server                    # http://localhost:3000
```

### Frontend
```bash
cd paysight-frontend
cp .env.example .env.local
npm install
npm run dev                     # http://localhost:3001
```

### Tests
```bash
cd paysight-backend
bundle exec rspec               # 64 specs, all passing
```

## Documentation

Component READMEs:
- [Backend README](paysight-backend/README.md) — Rails API setup, env vars, testing, DB seeding
- [Frontend README](paysight-frontend/README.md) — Next.js setup, env vars, running the UI

Design and planning:
- [Architecture](docs/ARCHITECTURE.md) — system diagrams, backend/frontend design, DB schema, API envelope
- [Trade-offs](docs/TRADEOFFS.md) — decisions taken, what was deferred, performance considerations
- [TDD Approach](docs/TDD_APPROACH.md) — how the commit-by-commit test→feat→refactor narrative was built
- [AI Usage](docs/AI_USAGE.md) — AI prompts used during development

## Features

### Employee Management
- Add, view, update, delete employees via UI
- Paginated employee listing with configurable page size
- Employee detail view page

### Salary Insights
- Min, max, average salary by country
- Average salary by job title in a country (with/without filter)
- Salary summary across all countries with local currency
- Interactive bar chart for salary comparison

### Seeding
- 10,000 employees generated from first_names.txt and last_names.txt
- Country-specific currency assignment
- Bulk insert in batches of 1,000 within a transaction
- Completes in under 10 seconds
