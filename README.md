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
* Run `mix setup` to install dependencies, create/migrate the SQLite DB, seed it,
  and build assets
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

## Routes

* `/` - landing page
* `/dashboard` - authenticated dashboard
* `/dashboard/settings` - authenticated admin settings
* `/collections/export/json` - admin-only collection JSON export
* `/auth/:provider` - OAuth request
* `/auth/:provider/callback` - OAuth callback (GET or POST)
* `/auth/logout` - logout

## Development

Useful commands:

* `mix test` - run tests
* `mix format` - format Elixir/HEEx
* `mix credo` - run lint checks
* `mix compile --warnings-as-errors` - compile-check larger changes
* `mix assets.build` - build frontend assets

## Deployment

To build and run a production release:

* Set the required `SECRET_KEY_BASE` and `DATABASE_PATH` environment variables.
  `DATABASE_PATH` is the SQLite database path.
* Optionally set `PHX_HOST` (default: `example.com`) and `PORT` (default: `4000`).
* Optionally set `POOL_SIZE` and `DNS_CLUSTER_QUERY`.
* Set the Google OAuth variables listed above.
* Run `mix assets.deploy` during the build, then build the release with
  `MIX_ENV=prod mix release`.
* Before starting the release, run `bin/match_maker migrate`. This step is mandatory.
* Start the release with `bin/match_maker server`; this enables `PHX_SERVER`.

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

## Matching algorithms

Each collection can select its matching algorithm in the collection settings. The
available algorithms are `Randomized round-robin` (the default) and `Greedy
history-aware`.

### Randomized round-robin

This algorithm assigns every enabled task to exactly one enabled person. Before
assigning, both the task list and the person list are shuffled, so repeated runs do not
produce a predictable ordering. The shuffled people are then cycled and paired with the
shuffled tasks.

This gives the following behavior:

* If there are at least as many people as tasks, each task gets a different person, but
  some people may be unassigned in that run.
* If there are fewer people than tasks, the people list wraps around and people may be
  assigned multiple tasks.
* When there are at least as many tasks as people, every enabled person is used at least
  once.
* Disabled people and tasks are excluded before assignment.
* Previous matches are not considered, so repeat person/task pairs are possible.

### Greedy history-aware

This algorithm uses the existing match history for the same collection to reduce repeat
person/task pairs. For each task, it first prefers people who have not yet been used in
the current run. Candidates are then ranked by how many times that person/task pair has
appeared in previous matches. Pairs with fewer historical uses are preferred, and ties
are randomized.

The strategy preserves the same cardinality behavior as randomized round-robin: every
enabled task is assigned, every enabled person is used before people are reused when
there are enough tasks, and repeats are allowed when they are unavoidable. With no
history, it behaves like a randomized assignment with the same coverage rules.

Cron jobs only run for enabled collections. `cron_interval` can skip scheduled runs;
`0` means every cron trigger runs.

## Open points

* [ ] Implement and expose webhook template rendering
* [ ] Improve history-aware matching fairness and reporting
