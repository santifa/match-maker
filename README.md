# MatchMaker

MatchMaker is a lightweight web application designed to match items grouped within
collections. It provides an intuitive user interface to:

* Manage collections and their items
* Run matchings manually or on a schedule using cron expressions
* Automatically deliver match results to a webhook endpoint for further processing or
  integration (test webhooks with webhook.site)

Whether triggered manually or via cron, each matching assigns items from one side of the
collection to the other in a randomized but complete way. Unmatched items are handled
gracefully, and full match history is preserved.

## Setup

To start the phoenix server locally:

  * Clone the repository
  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

*Everything is prepared for deployment on [gigalixir](https://gigalixir.com/).*

## Technical

The picture shows the visual representation of the data model.

```
[collections]
    ├── has_many → [items]
    │                ├─ side: :left  → [left_items]
    │                └─ side: :right → [right_items]
    └── has_many → [matches]
                      └── has_many → [match_assignments]
                                          ├── belongs_to → [left_item]
                                          └── belongs_to → [right_item]
```

### Open points

* [ ] Show old matchings
* [ ] Make webhook optional
* [ ] Other matching algorithms
* [ ] Support templating for webhooks
