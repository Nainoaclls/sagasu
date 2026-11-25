# Sagasu

**Find the right suppliers, not just search results.**

Sagasu is an AI-assisted procurement app for construction buyers. A buyer pastes a material list, Sagasu groups it by
supplier type, suggests suppliers from the company's own records with the evidence behind each match and what still
has to be confirmed, and the buyer sends a bidder list to a manager for approval. People decide; every decision is traceable.

Le Wagon Tokyo final project, 2026. Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates).

## Run it locally

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

Open http://localhost:3000. Demo accounts (password `sagasu123`):

| Account | Role | What to show |
|---|---|---|
| `aiko@sagasu.test` | Buyer | "Shinjuku office tower" is a fresh draft: run *Group with AI*, *Suggest suppliers*, select, send for approval |
| `kenji@sagasu.test` | Approver | Approval queue, approve or return with a comment |
| `yuki@sagasu.test`, `daichi@sagasu.test` | Buyers | Other team members (reviews, approved project) |
| `hiroshi@sagasu.test` | Approver | Returned "Chiba residential block B" |

`bin/rails db:seed` resets the demo data at any time. All companies and people in the seeds are fictional.

### AI

Put an OpenAI key in `.env` (never committed):

```
OPENAI_API_KEY=sk-...
```

Without a key, or if the API fails or times out, Sagasu falls back to its own local matching, so a demo never breaks.
`SAGASU_AI_DISABLED=1` forces the local mode (tests and seeds use it). `SAGASU_AI_MODEL` overrides the model (default `gpt-4.1`).

AI calls run in **background jobs** (`GroupItemsJob`, `SuggestSuppliersJob`): the page shows "Sagasu is searching…" and updates
itself through Action Cable when the job is done. In development jobs run inside `bin/rails server` (async adapter).
In production (Heroku) run them inside Puma with Solid Queue: set `SOLID_QUEUE_IN_PUMA=true`.

## Tests and checks

```bash
bin/rails test     # models, AI services and jobs (local mode), Turbo Stream responses, full user journey, access rules
bin/rubocop
bin/brakeman
```

## Documentation

`docs/` holds the concept, user stories, routes, schema (`Sagasu_Schema_v3.1.xml` matches the database) and brand kit.

## Architecture

| Layer | Where | Role |
|---|---|---|
| Models | `app/models` | Validations, workflow rules (`Project#submit_for_approval!`, `Approval#decide!`), scopes for visibility (`Review.visible_to`, `Review.ai_context_for`) |
| Plain Ruby models | `MaterialListParser`, `MaterialCategory`, `Prefecture`, `DashboardStats` | Parsing pasted lists, material taxonomy, dashboard counters |
| Policies | `app/policies` (Pundit) | Who can see or change what. Every action is authorized, every index is scoped |
| Services | `app/services/ai` | `ItemGrouper`, `SupplierRecommender`, `LocalSupplierMatcher`, `SupplierContext`, versioned `Prompts` |
| Jobs | `app/jobs` | `GroupItemsJob`, `SuggestSuppliersJob` (ActiveJob): run the AI, then `broadcast_append_to` a toast and `broadcast_refresh_to` the project |
| Controllers | `app/controllers` | Thin: find, authorize, delegate, respond. Turbo Stream when possible, redirect as fallback (`ProjectWorkspace` concern). Routes follow `docs/Sagasu_Routes.pdf` |
| Views | `app/views` | ERB partials + Simple Form. `*.turbo_stream.erb` replace only what changed; Turbo Frames for live search and renaming a group in place |
| UI | Bootstrap 5.3 | Brand colors in `$theme-colors` (Tangerine = `accent`): cards, badges, nav-pills, progress, tables, pagination, Modal, Toast |
| Front end | `app/javascript` (importmap) | Stimulus controllers (reveal, countup, tilt, demo, typed, ripple, toast, modal, tom-select, autosubmit, filter, materials, visibility), SweetAlert2 for confirmations, Tom Select, Typed.js |

### Product rules built in

- **Evidence before confidence**: each AI suggestion stores `evidence` and `missing_info`; missing supplier data is shown as "to confirm".
- **People decide**: AI suggestions start unselected; only the buyer selects; only the assigned approver decides.
- **No silent blacklists**: reviews start `unverified`; the AI is told never to exclude a supplier on an unverified observation; a declined suggestion lowers a score slightly, never excludes.
- **Privacy is not one boolean**: review visibility (organization or one project), AI use (`ai_usable`) and author attribution are separate. The AI only reads reviews the requester may see, without authors.
- **Traceability**: each submission stores a frozen `snapshot` of the bidder list; each AI call is an `AiRun` with model, prompt version, input and output.

### Accessibility

Skip link, landmarks, one visible focus style, 44 px touch targets, labelled form fields, statuses always with text (never color alone),
Bootstrap modals (focus trap, Escape), live regions for toasts and search results, WCAG AA contrast (ratios documented in `config/_colors.scss`),
`prefers-reduced-motion` respected by every animation, pages usable without JavaScript where possible.
