# MatchMaker

MatchMaker is a lightweight Phoenix/LiveView application for assigning items in
collections. In the UI, left-side items are **People** and right-side items are
**Tasks**.

It supports:

* Managing collections and their people/tasks
* Enabling/disabling collections and individual items
* Running matchings manually or on cron schedules
* Sending optional webhook notifications with match results
* Preserving match history
* Admin-only JSON import/export of collections

## Setup

To start the Phoenix server locally:

* Clone the repository
* Run `mix setup` to install dependencies, create/migrate the SQLite DB, and build assets
* Start Phoenix with `mix phx.server` or `iex -S mix phx.server`

Visit [`localhost:4000`](http://localhost:4000) in your browser.

## Authentication

The dashboard uses Google OAuth via Ueberauth. Configure:

* `GOOGLE_CLIENT_ID`
* `GOOGLE_CLIENT_SECRET`
* `GOOGLE_REDIRECT_URI`
* `GOOGLE_ALLOWED_DOMAIN` - comma-separated allowed email domains

The first user to sign in becomes an admin. Admins can manage users and import/export
collections under `/dashboard/settings`.

## Development

Useful commands:

* `mix test` - run tests
* `mix format` - format Elixir/HEEx
* `mix credo` - run lint checks
* `mix compile --warnings-as-errors` - compile-check larger changes
* `mix assets.build` - build frontend assets

## Deployment

Production expects these environment variables:

* `SECRET_KEY_BASE`
* `DATABASE_URL` - SQLite database URL/path
* `PHX_HOST`
* `PORT`
* Google OAuth variables listed above

Optional: `POOL_SIZE`, `DNS_CLUSTER_QUERY`.

## Technical

Data model overview:

```text
[collections]
    ├── has_many → [items]
    │                ├─ side: :left  → [people]
    │                └─ side: :right → [tasks]
    └── has_many → [matches]
                      └── has_many → [match_assignments]
                                          ├── belongs_to → [left_item]
                                          └── belongs_to → [right_item]
```

## Matching algorithm

The current algorithm assigns each enabled task to one enabled person. Tasks are
shuffled; enabled people are shuffled and cycled as needed. If there are fewer people
than tasks, people may be assigned more than once. If there are more people than tasks,
some people may be unassigned in that run.

Cron jobs only run for enabled collections. `cron_interval` can skip scheduled runs;
`0` means every cron trigger runs.

## Open points

* [ ] Finish exposing historical matchings in the dashboard UI
* [ ] Implement and expose webhook template rendering
* [ ] Add other matching algorithms
