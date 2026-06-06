# IDEA

IDEA4 plugin for Ekylibre — durability diagnostic across the 53 indicators of
the [IDEA4 reference grid](https://methode-idea.org/) (Indicateurs de Durabilité
des Exploitations Agricoles).

## Coverage

The plugin instantiates one `IdeaDiagnosticItem` per IDEA4 indicator and one
`IdeaDiagnosticItemValue` per item — **53 indicators / 450 items** total.

| Dimension | Indicators | Items | Source of truth |
|---|---:|---:|---|
| **A** Agro-ecological | A1-A19 | 263 | `config/indicators.yml` + IDEA4 PDFs |
| **B** Socio-territorial | B1-B23 | 153 | idem |
| **C** Economic | C1-C11 | 34 | idem |

### Scoring precision per indicator

All 53 indicators now have IDEA4-conformant scoring implementations:

| Indicators | Scoring engine | Source |
|---|---|---|
| **A1-A5** | Bespoke (questionnaire + autofill + formula) | Historical implementation |
| **A6-A19** | Bespoke (AUT_N, PPHM, CEDI, EPE, conditional livestock, …) | `lib/idea/components/a{6..19}.rb` against `Spec dimension A (A6 à A19)_2021_09_07.pdf` |
| **B1-B23** | Bespoke check-list patterns | `lib/idea/components/b*.rb` against `Spéc dimension B_2021_09_07.pdf` |
| **C1-C11** | Bespoke formulas (PdD, TES, SA, EB, SI…) | `lib/idea/components/c*.rb` against `Spec dimension C_2021_09_07.pdf` |

Treshold values (the `/N` cap on each indicator) are extracted from the
IDEA4 PDFs and stored in `config/indicators.yml`. They range from 3
(small territorial indicators) to 20 (C1 capacité économique). Without
the matching score formula, an indicator falls back on the generic
"filled-ratio × treshold" defined in `Idea::Components::Base#compute_score`.

## Architecture

```
lib/idea/
├── indicators.rb              # Registry loaded from config/indicators.yml
├── question.rb                # Wizard question payload contract
├── sentence_helpers.rb        # idea_information_tag etc.
└── components/
    ├── base.rb                # next_question / compute_score / computable? defaults
    │                          # + helpers: item_numeric, item_truthy?,
    │                          #   boolean_checklist_score, rank_score
    ├── a1.rb … a5.rb          # Bespoke A1-A5 (legacy)
    ├── a6.rb … a19.rb         # Bespoke A6-A19 (PDF Dimension A formulas)
    ├── b1.rb … b23.rb         # Bespoke B1-B23 (PDF Dimension B check-lists)
    └── c1.rb … c11.rb         # Bespoke C1-C11 (PDF Dimension C economic formulas)

app/
├── controllers/backend/idea_diagnostics_controller.rb
│   ├─ next_question   # GET — emits the next Idea::Question to render
│   ├─ answer          # POST — persists one item_value, recomputes score
│   ├─ reset_indicator # POST — wipes an indicator's stored values
│   └─ stt_config      # GET — voice-input config (browser STT or Whisper)
├── service/idea/diagnostic_instigator.rb   # Seeds all 53 items on create
├── views/backend/idea_diagnostics/
│   ├── show.html.haml                 # 3-cobble dashboard + global score
│   ├── _indicator_row.html.haml       # One row per indicator
│   └── _question_modal.html.haml      # Wizard modal shell
└── assets/javascripts/
    ├── idea_wizard.js                 # Question loop (fetch GET/POST)
    └── idea_voice.js                  # Web Speech + Whisper dictation
```

## Diagnostic flow

1. **Creation** — `Backend::IdeaDiagnosticsController#create` invokes
   `Idea::DiagnosticInstigator#instigate`, which iterates over
   `Idea::Indicators.all_item_attributes` to seed the 53 `IdeaDiagnosticItem`
   rows + 450 `IdeaDiagnosticItemValue` placeholders, then enqueues
   `IdeaAutofillJob`.

2. **Wizard** — the user clicks `.idea_duke` on an indicator row in
   `show.html.haml`. `idea_wizard.js` opens the modal and POSTs to
   `/backend/idea_diagnostics/:id/next_question?indicator=…`. The controller
   instantiates the component (`Idea::Components.const_get(indicator)`) and
   returns the next `Idea::Question` payload, enriched with sentence (i18n)
   and nature (`Idea::Indicators.nature_for`).

   The `indicator` param is whitelisted against
   `Idea::Indicators.components` (the 53 ids from
   `config/indicators.yml`) before reaching `const_get` — adding a new
   indicator to the YAML automatically extends the whitelist, no
   controller change required.

3. **Answer** — `POST .../answer` persists the value via `IdeaDiagnosticItemValue#set!`
   (typed by nature: boolean / integer / float / string), then recomputes
   the indicator's score via `component.update_global_score`. Cross-indicator
   writes (e.g. A2's questionnaire feeding A1_10) trigger a second
   recompute on the owning indicator, detected via the
   `/\A([ABC]\d+)_\d+\z/` regex on `item_value`.

4. **Display** — `show.html.haml` renders 3 cobbles (one per dimension) with
   per-dimension progress bars and a global IDEA score banner computed by
   `Idea::Indicators.global_score(diagnostic)` (IDEA4 "weakest dimension"
   rule).

## Voice input

The wizard supports voice dictation via two backends, picked transparently:

1. **Browser Web Speech API** — preferred when the browser exposes it
   (Chrome, Edge). The audio never leaves the device.
2. **Server-side Whisper** — fallback for Firefox & mobile. POSTs the audio
   blob to Duke's `/api/v1/stt/transcribe` endpoint, gated by the
   `DUKE_STT_SERVER_ENABLED` env var.

Auth config comes from `GET /backend/idea_diagnostics/stt_config`.

## Configuration

```
DUKE_STT_SERVER_ENABLED=true    # Enable Whisper fallback
DUKE_WS_URL=ws://duke:8000/ws   # Base URL for Duke (HTTP STT URL derived from it)
DUKE_HTTP_URL=http://duke:8000  # Optional override when WS and HTTP differ
```

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'idea', git: 'https://gitlab.com/ekylibre/ekylibre-idea.git', branch: 'dev'
```

Then:

```sh
bundle install
```

The plugin's engine auto-loads its assets (`idea_wizard.js`, `idea_voice.js`,
`idea/main.scss`) via `lib/idea/engine.rb`.

## Development

```sh
bin/setup        # bundle install
ruby -Itest test/lib/idea/<file>_test.rb  # run a single test file
```

Run the full test suite:

```sh
for f in test/lib/idea/*_test.rb; do ruby -Itest "$f"; done
```

## Testing

The plugin ships with isolated unit tests that don't need the main Ekylibre
repo:

- `test/lib/idea/indicators_test.rb` — registry, dimensions, nature lookup
- `test/lib/idea/components_loading_test.rb` — 53 component files declare
  the expected class
- `test/lib/idea/components_dimension_a_pdf_test.rb` — A6-A19 scoring
  (AUT_N, PPHM, CEDI, conditional livestock, malus)
- `test/lib/idea/components_dimension_b_test.rb` — B1-B23 check-list scoring
- `test/lib/idea/components_dimension_c_test.rb` — C1-C11 economic formulas
  (PdD, TES, SA, EB, SI…)
- `test/lib/idea/aggregated_score_test.rb` — `dimension_score` and the
  IDEA4 "weakest dimension" global score
- `test/lib/idea/question_test.rb`, `sentence_helpers_test.rb` —
  value-object basics

Run the full suite:

```sh
for f in test/lib/idea/*_test.rb; do ruby -Itest "$f"; done
# Current baseline: 147 runs, 438 assertions, 0 failures
```

Controller and end-to-end tests (next_question/answer integration, smoke
flows against a tenant) belong in the main Ekylibre repo where ActiveRecord
fixtures and the test runner are available.

## Roadmap

- Autofill for the C* economic indicators wired to the `accountancy` module
  (EBE, annuities, depreciation) so C1-C3, C8, C10-C11 stop relying on
  manual data entry
- Autofill for A8 (nitrogen balance), A11 (energy consumption), A16
  (water quality / IFT) and A18 (GHG balance) against
  `interventions` / `registered_phytosanitary_products`
- Radar chart on `IdeaDiagnosticResult#show`
- PDF export of the diagnostic via the Ekylibre printer
- Refine A18 (climate change) with the full LCA coefficients from
  `Tableau de référence IDEA_2021_08_17.xlsx`
- Cross-validate scores against a reference IDEA diagnostic produced by
  an IDEA4-certified expert (target: < 5% deviation on the global score)

## Contributing

Bug reports and pull requests are welcome on
[gitlab.com/ekylibre/ekylibre-idea](https://gitlab.com/ekylibre/ekylibre-idea).
