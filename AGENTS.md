# AGENTS.md

Guidance for AI coding agents working in this repository. Assume no prior knowledge of the project.

## Project overview

**Sagasu** is an AI-assisted procurement app for construction buyers ("Find the right suppliers, not just
search results"). A buyer pastes a material list, Sagasu groups it by supplier type, suggests suppliers
from the company's own records with the evidence behind each match, and the buyer sends a bidder list to
a manager (approver) for approval. People decide; every decision is traceable.

It is a **Le Wagon Tokyo final project (2026)**, generated from
[lewagon/rails-templates](https://github.com/lewagon/rails-templates). Project documentation (concept,
user stories, routes, database schema, brand kit) lives in `docs/`; the schema reference that matches the
database is `docs/Sagasu_Schema_v3.1.xml`, and routes follow `docs/Sagasu_Routes.pdf` (route comments cite
user story numbers).

### Core domain workflow

1. Buyer creates a **Project** and pastes a material list → `MaterialListParser` (plain Ruby model) turns
   it into **Item** records.
2. **ItemGroups**: AI (`Ai::ItemGrouper`) groups items by supplier type; groups can also be added/renamed
   by hand. Ungrouped items block submission.
3. **GroupSuppliers**: AI (`Ai::SupplierRecommender`) suggests suppliers per group, each with `evidence`
   and `missing_info`; only the buyer selects suggestions. Suppliers can also be found via full-text
   search (pg_search).
4. **Reviews** on suppliers: rating 1–5, visibility (`organization` or single `project`), separate
   `ai_usable` flag, status (`unverified`/`verified`/`disputed`). The AI only reads reviews the requester
   may see, without author names, and is told never to exclude a supplier on an unverified observation.
5. **Approval**: `Project#submit_for_approval!` freezes a `snapshot` of the bidder list and assigns an
   approver; only the assigned approver decides (`Approval#decide!` → approved or returned with comment).
   Project status: `draft → pending_approval → approved/returned`. Editing is only possible while
   `draft` or `returned` (`Project#editable?`).

Every AI call is recorded as an **AiRun** (kind: `grouping`/`supplier_suggestion`, model, prompt with
versioned `Ai::Prompts`, input, output, status `running/succeeded/fallback/failed`).

### Product rules baked into the code (do not break these)

- **Evidence before confidence**: suggestions store evidence and missing info; missing supplier data is
  shown as "to confirm".
- **People decide**: AI suggestions start unselected; only the buyer selects; only the assigned approver
  decides.
- **No silent blacklists**: reviews start `unverified`; a declined suggestion lowers a score slightly,
  never excludes.
- **Privacy is not one boolean**: review visibility, AI use (`ai_usable`), and author attribution are
  separate controls (see `Review.visible_to` and `Review.ai_context_for` scopes).
- **Traceability**: submissions store frozen snapshots; AI calls store AiRuns.

## Technology stack

- **Ruby 3.3.5** (`.ruby-version`), **Rails 8.1** (`config.load_defaults 8.1`), **PostgreSQL** (`pg` gem),
  **Puma**.
- **Frontend**: Hotwire (Turbo + Stimulus), **importmap-rails** (no Node build), **Bootstrap 5.3** via the
  `bootstrap`/`sassc-rails`/`autoprefixer-rails` gems, Font Awesome, Simple Form, SweetAlert2 (confirm
  dialogs), Tom Select, Typed.js, Mapbox GL JS (pinned from the jsdelivr CDN). Stimulus controllers in
  `app/javascript/controllers`.
- **Theming**: light/dark via Bootstrap's `data-bs-theme`. An inline script in the layout head paints the
  first frame from `localStorage["sg-theme"]` or the OS preference; `theme_controller.js` handles toggles.
  Colors live in CSS custom properties `--sg-*` (`app/assets/stylesheets/components/_theme.scss`), with
  dark overrides under `[data-bs-theme="dark"]` — always read `var(--sg-*)` in SCSS, never a raw hex.
- **i18n**: English, French, Japanese (`config/locales/{en,fr,ja}.yml` + `rails-i18n`/`devise-i18n`).
  `LocalesController#update` (`GET /locale/:locale`) stores the choice in a permanent cookie;
  `ApplicationController#switch_locale` applies it. Every user-facing string goes through `t()`;
  JS controllers receive texts via `data-*-value` attributes. `GroupSupplier::FEEDBACK_REASONS` stay
  stored in English and are translated at display time (`ApplicationHelper#feedback_reason_label`).
  Broadcast toasts (AI jobs) render in the default locale — they are shared between viewers.
- **Geocoding/map**: `geocoder` gem (Nominatim; stubbed in test via `Geocoder::Lookup::Test`).
  Suppliers geocode on address change unless coordinates were given. The map partial
  (`app/views/suppliers/_map.html.erb`) renders only when `MAPBOX_ACCESS_TOKEN` is set; it follows the
  light/dark theme through the Mapbox Standard style `lightPreset`.
- **PWA**: branded manifest (`app/views/pwa/manifest.json.erb`) and a service worker
  (`app/views/pwa/service-worker.js.erb`, network-first for pages with a `public/offline.html` fallback,
  cache-first for same-origin assets). The service worker is registered in production only
  (`<html data-env>`), so development never serves stale caches.
- **Auth**: Devise (users have `name` and `role`: `buyer` or `approver`).
- **Authorization**: **Pundit** — one policy per model.
- **AI**: `ruby_llm` gem calling OpenAI (default model `gpt-4.1`, override with `SAGASU_AI_MODEL`),
  structured output via JSON schema (`app/services/ai/`).
- **Search**: `pg_search` (PostgreSQL tsearch) on suppliers.
- **Background jobs / cache / cable**: Solid Queue, Solid Cache, Solid Cable (database-backed; separate
  DBs in production, see `config/database.yml`). In development jobs run inside Puma (async adapter);
  in production set `SOLID_QUEUE_IN_PUMA=true`.
- **Deployment**: Docker (`Dockerfile`) + **Kamal** (`config/deploy.yml`, `bin/kamal`), Thruster in front
  of Puma. The README also documents a Heroku path with `SOLID_QUEUE_IN_PUMA=true`.

## How the code is organized

| Layer | Where | Notes |
|---|---|---|
| Models | `app/models` | Validations, workflow rules (`Project#submit_for_approval!`, `Approval#decide!`), visibility scopes (`Review.visible_to`, `Review.ai_context_for`, `Project.involving`) |
| Plain Ruby models | `app/models` (`MaterialListParser`, `MaterialCategory`, `Prefecture`, `DashboardStats`) | Parsing pasted lists, material taxonomy (`MaterialCategory::CATALOG` drives supplier categories and local matching), dashboard counters |
| Policies | `app/policies` | Pundit. `ProjectContentPolicy` is a shared base for content nested under a project |
| AI services | `app/services/ai` | `Client` (thin RubyLLM wrapper, structured JSON), `ItemGrouper`, `SupplierRecommender`, `LocalSupplierMatcher` (offline fallback), `SupplierContext`, versioned `Prompts` |
| Jobs | `app/jobs` | `GroupItemsJob`, `SuggestSuppliersJob`; shared broadcast logic in `app/jobs/concerns/ai_job_broadcasts.rb` (`broadcast_append_to` a toast + `broadcast_refresh_to` the project) |
| Controllers | `app/controllers` | Thin: find, authorize, delegate, respond. Turbo Stream first, redirect fallback via the `ProjectWorkspace` concern; `SupplierReviews` concern shares review loading |
| Views | `app/views` | ERB partials + Simple Form; `*.turbo_stream.erb` replace only what changed; Turbo Frames for live search and in-place group renaming |
| Styles | `app/assets/stylesheets` | SCSS (sassc); brand theme colors in `$theme-colors` (Tangerine = `accent`); WCAG AA contrast ratios documented in `config/_colors.scss` |

### Authorization rules (enforced globally)

`ApplicationController` includes Pundit with `after_action` verifications: **every non-index action must
call `authorize`, every index must use `policy_scope`**. `Pundit::NotAuthorizedError` and
`RecordNotFound` are rescued into redirects. When adding an action, add the policy method too —
the app will raise otherwise.

### AI fallback design (important)

`Ai::Client.available?` is false when `OPENAI_API_KEY` is missing or `SAGASU_AI_DISABLED=1` is set. Every
AI service then falls back to local matching (`Ai::LocalSupplierMatcher`, `MaterialCategory.classify`) so
a demo never breaks; fallback runs are recorded with the `sagasu-local-matcher-v1` model name and the UI
labels them "(offline matching)". AI calls run in background jobs; the page shows progress and updates
itself via Action Cable. Keep this fallback intact when changing AI code.

### Environment variables

- `OPENAI_API_KEY` — in `.env` (never committed; `.env` is loaded via `dotenv-rails` in dev/test).
- `SAGASU_AI_DISABLED=1` — force local mode (used by tests and seeds).
- `SAGASU_AI_MODEL` — override the OpenAI model (default `gpt-4.1`).
- `SOLID_QUEUE_IN_PUMA=true` — run Solid Queue inside Puma in production.
- `MAPBOX_ACCESS_TOKEN` — enables the supplier map (free Mapbox token); without it the map partial is
  simply not rendered.
- Production DB password: `SAGASU_DATABASE_PASSWORD`.

Rails config: time zone is `Tokyo`; generators are configured with `assets false`, `helper false`,
`test_framework :test_unit, fixture: false`.

## Setup, build and run

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server          # http://localhost:3000
```

`bin/rails db:seed` **resets the demo data at any time** (it deletes all records first). All companies
and people in the seeds are fictional; websites use the reserved `.example` domain. Demo accounts
(password `sagasu123` for all):

| Account | Role | Purpose |
|---|---|---|
| `aiko@sagasu.test` | Buyer | "Shinjuku office tower" is a fresh draft for the full AI journey |
| `kenji@sagasu.test` | Approver | Approval queue, approve or return with a comment |
| `yuki@sagasu.test`, `daichi@sagasu.test` | Buyers | Other team members (reviews, approved project) |
| `hiroshi@sagasu.test` | Approver | Returned "Chiba residential block B" |

## Testing instructions

```bash
bin/rails test                  # full test suite (Minitest)
bin/rails test test/models      # one directory
bin/rails test test/integration/bidder_list_flow_test.rb   # one file
bin/rubocop                     # style (rubocop-rails-omakase)
bin/brakeman                    # security static analysis
bin/bundler-audit               # gem vulnerability audit
bin/importmap audit             # JS dependency audit
bin/ci                          # everything: setup, rubocop, audits, tests, seed replant
```

- Test framework is **Minitest** (`test/`), **no fixtures** — `test/test_helper.rb` provides small
  builders (`create_user`, `create_supplier`, `create_project`, `create_ready_project`) so each test
  states the data it needs. Integration tests get `sign_in_as(user)`.
- Tests **never call OpenAI**: `test_helper.rb` sets `SAGASU_AI_DISABLED=1`, so AI services run in local
  fallback mode. Tests run in parallel (`parallelize(workers: :number_of_processors)`).
- Coverage includes models, AI services and jobs (local mode), Turbo Stream responses, the full user
  journey (`test/integration/bidder_list_flow_test.rb`), access rules, the PWA endpoints, the supplier
  map, and locale switching (`test/integration/locales_test.rb` renders every main page in fr and ja to
  catch missing translations).
- Capybara/selenium-webdriver are in the Gemfile for system tests, but no system tests exist yet
  (the `bin/ci` system-test step is commented out).
- CI definition: `config/ci.rb` (run via `bin/ci`); no GitHub Actions workflow — only Dependabot.

## Code style guidelines

- RuboCop config (`.rubocop.yml`) extends **rubocop-rails-omakase** (Rails omakase style); several Style
  cops disabled (conditional assignment, string literals, redundant return, documentation). `bin/`,
  `db/`, `config/`, `tmp/` and `test/` are excluded from linting.
- Comments and docs are in **English**. Comment style in this codebase: a short sentence above a class or
  non-obvious method explaining the *why* or the user story it implements (e.g. `# Story 12: freeze the
  bidder list and hand it to an approver.`), not line-by-line narration. Match that.
- Keep controllers thin; put workflow rules in models, AI logic in `app/services/ai`, and authorization
  in policies.
- User-facing routes and behavior follow the user stories in `docs/` — route comments reference story
  numbers; keep them in sync when changing routes.
- Front-end behavior belongs in Stimulus controllers; pages must stay usable without JavaScript where
  possible (Turbo Stream responses always have a redirect fallback).
- Accessibility is a stated requirement: skip link, landmarks, visible focus styles, 44px touch targets,
  labelled form fields, statuses always with text (never color alone), live regions for toasts and
  search results, `prefers-reduced-motion` respected by every animation, WCAG AA contrast (ratios
  documented in `config/_colors.scss`).

## Security considerations

- **Never commit secrets**: `OPENAI_API_KEY` lives in `.env` (git-ignored); Rails credentials in
  `config/credentials.yml.enc`. `.kamal/secrets` supplies `RAILS_MASTER_KEY` for deploys.
- Authorization is deny-by-default via Pundit with global `verify_authorized`/`verify_policy_scoped`
  hooks — do not bypass them, and do not expose reviews or projects outside their visibility scopes
  (`Review.visible_to`, `Project.involving`).
- Supplier `website`/`source_url` are validated as full-string `https?://` URLs because they are rendered
  as hrefs (no `javascript:` URLs).
- `Project#submit_for_approval!` takes a row lock so double-clicks cannot create two pending approvals.
- AI prompts/outputs are stored truncated to 20,000 chars on AiRun; reviews are fed to the AI only
  through the `ai_context_for` scope and without author names.
- `bin/ci` runs Brakeman (`--exit-on-warn --exit-on-error`), bundler-audit and importmap audit — keep
  them green.
