# PaySight Backend

Salary management API for organizations. Built with Rails 7.1 (API-only) and PostgreSQL.

## Setup

```bash
cp .env.example .env        # configure your database credentials
bundle install
rails db:create db:migrate
```

## Running

```bash
rails server                 # starts on http://localhost:3000
```

## Tests

```bash
bundle exec rspec            # run full test suite
bundle exec rspec spec/models # run model specs only
```

## Seeding

```bash
rails db:seed                # seed 10,000 employees
```
