# Workflow — Adapter `ekylibre-idea` au nouveau Duke

> **Contraintes finales** :
> - L'ancien projet `ekylibre-duke` (Rails gem, https://github.com/ekylibre/ekylibre-duke/tree/dev) **sera supprimé** — aucun chemin de migration "coexistence" n'est valable.
> - Le plugin `ekylibre-idea` doit fonctionner **uniquement** avec :
>   1. Le main repo Ekylibre (Rails)
>   2. Le nouveau Duke (Python FastAPI, `/home/djoulin/projects/duke`)
> - **Plus aucune référence à `Duke::*` (Ruby), à `D.webchat`, à `duke_integration.js`, ni au gem `duke` dans `Gemfile`/`gemspec`** ne doit subsister.
>
> Document de planification uniquement — aucune modification de code n'est exécutée par ce workflow.

---

## 1. Méthode de saisie actuelle (à remplacer)

> _"Identifie la méthode qui permet de saisir les informations idea via le widget duke present dans ekylibre."_

### 1.1 Côté Rails — méthode `duke_redirect`

Chaque composant indicateur expose **une méthode `duke_redirect`** qui dit à Duke quelle question poser ensuite et avec quelles options. C'est l'API de saisie côté serveur :

| Indicateur | Fichier | Méthode |
|---|---|---|
| A1 | `lib/idea/components/a1.rb:12` | `def duke_redirect` |
| A2 | `lib/idea/components/a2.rb:12` | `def duke_redirect` |
| A3 | `lib/idea/components/a3.rb:13` | `def duke_redirect` |
| A4 | `lib/idea/components/a4.rb:13` | `def duke_redirect` |
| A5 | `lib/idea/components/a5.rb:12` | `def duke_redirect` |

Toutes héritent de `Idea::Components::Base` (`lib/idea/components/base.rb:1-12`) qui inclut **`Duke::Utils::BaseDuke`** — ce mixin disparaît avec l'ancien gem ; il faudra l'extraire ou le rapatrier.

Chacune renvoie une structure **`Duke::DukeResponse.new(redirect:, sentence:, parsed:, options:)`** qui disparaît également avec l'ancien gem.

### 1.2 Côté JS — déclencheur `Duke.webchat.new_active_session`

Bouton `<a class="idea_duke" data-indicator="A1" data-diagnostic-id="42">` rendu par `app/views/backend/idea_diagnostics/show.html.haml:28`, qui appelle via `app/assets/javascripts/duke_integration.js:4-7` :

```js
$(document).on('click', '.idea_duke', function() {
  intent = 'IDEA_' + this.dataset.indicator
  D.webchat.new_active_session(intent, this.dataset.diagnosticId)
});
```

`D.webchat` est exposé globalement par l'ancien gem `duke` — disparaîtra avec lui.

### 1.3 Chemins indépendants de Duke (à conserver tel quel)

- Bouton reset `a.idea_restart` → `POST /reset_idea_indicator` → `Backend::IdeaDiagnosticsController#reset_indicator`.
- `DiagnosticInstigator#instigate` → `IdeaAutofillJob.perform_later` → méthodes calculatrices (`a1_2`, `a1_4`, …).

Ces chemins n'utilisent ni le mixin ni le widget Duke ; ils restent valides à condition que la classe `Idea::Components::Base` cesse d'exiger `Duke::Utils::BaseDuke`.

---

## 2. État du nouveau Duke (cible unique de la migration)

Inspection de `/home/djoulin/projects/duke` (cf. son `CLAUDE.md`) :

- **Stack** : Python 3.12 / FastAPI / Starlette WS / SQLAlchemy 2 async / Alembic — **service externe**, plus jamais un gem Rails.
- **Authentification** : `Authorization: simple-token <email> <token>` + `X-Tenant: <tenant>` sur chaque ouverture WS et chaque POST STT.
- **Widget JS** intégré dans `ekylibre/app/javascript/duke/` (pas dans le plugin) :
  - `widget.js` — UI flottante, point d'entrée : `new DukeWidget(rootEl)` ; ouvert via clic sur la bulle (`open()`, ligne 407). **Pas d'API `new_active_session(intent, id)`** ni de mécanisme de questionnaire scripté.
  - `client.js` — client WebSocket, protocole : `auth`, `user_message`, `clarify`, `confirm_intervention`, `cancel`, `ping`.
  - Saisie vocale intégrée : Web Speech API (lignes 221-278) + fallback MediaRecorder POSTé à `/api/v1/stt/transcribe` (lignes 292-403).
- **Controller Rails de configuration** : `Backend::DukeWidgetController#show` (`ekylibre/app/controllers/backend/duke_widget_controller.rb`) renvoie `ws_url`, `token`, `tenant`, `stt_url`, `stt_server_enabled`. C'est l'unique point d'attache du widget côté Rails.
- **Intents Duke** (`duke/src/duke/domain/intent.py`) : `RECORD_INTERVENTION | QA_STOCK | QA_HISTORY | OUT_OF_SCOPE | UNKNOWN`. Aucun intent `IDEA_*` ni équivalent ; aucun mécanisme de questionnaire indicateur-par-indicateur. Le nouveau Duke est laser-focalisé sur la saisie d'interventions en langage naturel et le Q&A en lecture seule.

### 2.1 Conséquence structurelle

Le concept de questionnaire indicateur-par-indicateur déterministe, persistant dans `IdeaDiagnosticItemValue`, **n'a pas et n'aura pas d'analogue dans le nouveau Duke**. Plutôt que d'étendre le nouveau Duke (couplage à un service en mouvement), le plugin IDEA doit assurer **lui-même** la couche questionnaire — UI, transport, persistance.

Le seul service que le plugin peut réutiliser du nouveau Duke est **la transcription vocale serveur** (`POST /api/v1/stt/transcribe`), qui est utile mais générique et ne contraint pas le couplage.

---

## 3. Stratégie retenue

**Stratégie B — Wizard natif Ekylibre, intégralement dans le plugin, vocal compris.**

- Construire un wizard modal Ekylibre natif (HAML + JS Vanilla) servi entièrement par le plugin engine.
- Récupérer la logique des méthodes `duke_redirect` (renommées `next_question`) avec une struct interne `Idea::Question` qui remplace `Duke::DukeResponse`.
- Rapatrier les ~5 helpers réellement utiles de `Duke::Utils::BaseDuke` (essentiellement `duke_information_tag`) dans le plugin.
- Ajouter la **saisie vocale** : Web Speech API en frontal + fallback vers le endpoint STT du nouveau Duke (`POST /api/v1/stt/transcribe`).
- Aucun bouton "deep-link vers le widget Duke" n'est inclus — pour préserver l'autonomie du plugin (et parce que les questions IDEA, étant déterministes et numériques, n'ont pas de bénéfice à passer par le NLU/LLM de Duke).

### Pourquoi pas "demander à Duke" en complément ?

Le widget Duke reste disponible globalement dans Ekylibre pour la saisie d'interventions et le Q&A factuel. Il n'y a aucun verrouillage. Mais l'**intégrer dans le flux IDEA** introduirait un couplage croisé entre le plugin et le widget du main repo, et ce sans gain fonctionnel : les questions IDEA sont scriptées avec réponses oui/non/numériques/options, et le NLU LLM n'apporte rien dessus.

---

## 4. Le wizard reste-t-il dans le plugin ?

**Oui, intégralement.** Le plugin est déjà un Rails engine autonome qui sert ses routes, contrôleurs, vues, assets JS et SCSS. L'engine `Idea::Engine` (`lib/idea/engine.rb:18-32`) sait déjà injecter ses assets dans le pipeline du main repo :

```ruby
initializer :hack_idea_javascript do
  tmp_file = Rails.root.join('tmp', 'plugins', 'javascript-addons', 'plugins.js.coffee')
  tmp_file.open('a') do |f|
    import = '#= require idea_wizard'   # <-- remplace 'duke_integration'
    f.puts(import) unless tmp_file.open('r').read.include?(import)
  end
end
```

Tous les fichiers du wizard tiennent donc dans le plugin :

| Fichier | Rôle |
|---|---|
| `app/assets/javascripts/idea_wizard.js` | Wizard JS (remplace `duke_integration.js`) |
| `app/assets/javascripts/idea_voice.js` | Module STT (Web Speech + Whisper fallback) |
| `app/assets/stylesheets/idea/wizard.scss` | Style de la modale (sourcé via `hack_idea_stylesheets`) |
| `app/views/backend/idea_diagnostics/_question_modal.html.haml` | Partial HAML de la modale |
| `app/controllers/backend/idea_diagnostics_controller.rb` | +2 endpoints (`next_question`, `answer`) + 1 endpoint (`stt_config`) |
| `config/routes.rb` | +3 routes |
| `lib/idea/question.rb` | Struct remplaçant `Duke::DukeResponse` |
| `lib/idea/sentence_helpers.rb` | Helpers rapatriés de `Duke::Utils::BaseDuke` |

**Aucun fichier du main repo Ekylibre n'est touché.** Désinstaller le plugin retire l'intégralité du flux IDEA proprement.

---

## 5. Plan d'exécution

### Phase 1 — Audit & inventaire (1 jour)

| # | Tâche | Sortie | Validation |
|---|---|---|---|
| 1.1 | Lister exhaustivement les références `Duke::*`, `D.webchat`, `duke_integration`, `BaseDuke` dans le plugin | Tableau de symboles avec emplacements | Couverture exhaustive |
| 1.2 | Lister les branches de chaque `duke_redirect` (chaque `elsif item('X_Y').value.nil?`) | Arbre de décision par indicateur | Couverture des 5 indicateurs (A1-A5) |
| 1.3 | Lister les helpers `Duke::Utils::BaseDuke` réellement appelés (`duke_information_tag`, `confirm_*`, etc.) | Liste minimale à rapatrier | < 10 helpers |
| 1.4 | Identifier les déclarations du gem `duke` dans `idea.gemspec` et `Gemfile` | Diff à appliquer | gem `duke` retiré, pas de gem ajouté |

**Checkpoint** : si l'inventaire 1.1 révèle des couplages non triviaux (state machine partagée, callbacks `ApplicationCable`, etc.), **alerter et réévaluer le scope avant d'engager Phase 2**.

### Phase 2 — Extraction du contrat de question (1 jour)

| # | Tâche | Sortie | Validation |
|---|---|---|---|
| 2.1 | Définir `Idea::Question` avec champs `next_indicator:`, `sentence:`, `prefilled_value:`, `diagnostic_id:`, `terminal:` (bool — true quand le flow est fini) | `lib/idea/question.rb` | Tests unitaires sur les champs + `as_json` |
| 2.2 | Rapatrier `duke_information_tag` et les autres helpers identifiés en 1.3 dans un module `Idea::SentenceHelpers` inclus par `Idea::Components::Base` | `lib/idea/sentence_helpers.rb` | Aucun helper Duke n'est encore requis |
| 2.3 | Remplacer toutes les occurrences de `Duke::DukeResponse.new(redirect:, sentence:, parsed:, options:)` par `Idea::Question.new(next_indicator:, sentence:, prefilled_value:, diagnostic_id:)` dans les 5 composants | Patch sur `a1.rb`-`a5.rb` | `grep "Duke::DukeResponse" lib/` → 0 |
| 2.4 | Renommer `duke_redirect` → `next_question` (clarté et signal de migration) | Renommage avec ripgrep | Aucun appelant orphelin |
| 2.5 | Retirer `include Duke::Utils::BaseDuke` de `Idea::Components::Base` | Patch | `grep -rn "Duke::" lib/` → 0 |

### Phase 3 — Endpoints REST & wizard UI (3 jours)

| # | Tâche | Sortie | Validation |
|---|---|---|---|
| 3.1 | Endpoint `GET /backend/idea_diagnostics/:id/next_question?indicator=A1` → `Idea::Components::A1.new(diagnostic_id: id).next_question.as_json` | Action dans `idea_diagnostics_controller.rb` + route | Test contrôleur : payload JSON conforme |
| 3.2 | Endpoint `POST /backend/idea_diagnostics/:id/answer` (`{ indicator:, item_value:, value: }`) → écrit la valeur, recompute le score si `computable?`, renvoie la `next_question` suivante | Action + route | Test : enchaînement question → réponse → question suivante |
| 3.3 | Partial HAML `_question_modal.html.haml` (modale Bootstrap standard Ekylibre) avec slots question / options / champ texte + bouton micro | Vue partielle | Render isolé OK depuis `show.html.haml` |
| 3.4 | `app/assets/javascripts/idea_wizard.js` (JS Vanilla, pas d'ActionCable, pas de jQuery nouveau au-delà de ce que le main repo charge déjà) : intercepte `.idea_duke`, ouvre la modale, GET `next_question`, POST `answer` en boucle jusqu'à `terminal: true` | Asset JS | Smoke manuel : flux A1 complet sur tenant de dev |
| 3.5 | Mettre à jour `show.html.haml` : `.idea_duke` reste, perd `data-indicator` côté Duke, gagne le nouveau handler (idéalement `data-controller="idea-wizard"` style Stimulus si dispo, sinon listener délégué) | Patch vue | UI identique sauf cible JS |
| 3.6 | Supprimer `app/assets/javascripts/duke_integration.js` et basculer le hack engine sur `idea_wizard` (`lib/idea/engine.rb:18-24`) | Patch | `grep duke_integration` → 0 |

### Phase 3 bis — Saisie vocale (1.5 jour)

| # | Tâche | Sortie | Validation |
|---|---|---|---|
| 3b.1 | Endpoint `GET /backend/idea_diagnostics/stt_config` (plugin) : renvoie `{ stt_url, stt_server_enabled, auth: { email, token, tenant } }` à partir de `Backend::DukeWidgetController#show` ou en réimplémentant la lecture des ENV `DUKE_WS_URL`/`DUKE_HTTP_URL`/`DUKE_STT_SERVER_ENABLED` | Action + route plugin | Test : JSON non vide quand `DUKE_STT_SERVER_ENABLED=true` |
| 3b.2 | `app/assets/javascripts/idea_voice.js` — module STT Vanilla réutilisant le pattern `_startWebSpeech` (Web Speech API) + `_startServerRecording` + `_uploadAudio` du widget Duke (`ekylibre/app/javascript/duke/widget.js:221-403`). Le module **n'envoie rien à Duke en WebSocket** ; il fait uniquement de la dictée et insère le texte transcrit dans le champ de la modale | Asset JS | Tests manuels : Chrome (Web Speech), Firefox (Whisper fallback) |
| 3b.3 | Intégrer le bouton micro dans `_question_modal.html.haml`, masqué par défaut et démasqué par `idea_voice.js` si Web Speech OU `stt_server_enabled` | Patch vue | Bouton apparaît seulement quand au moins un backend est dispo |

**Notes importantes** :
- La "saisie vocale intelligente" se limite ici à la **dictée** (speech-to-text). L'extraction NLU/LLM ("30 litres de glyphosate sur parcelle 12") est inutile pour IDEA dont les réponses sont oui/non/numériques/option — un simple `parseInt` côté JS suffit.
- L'endpoint STT serveur appartient au nouveau Duke ; le plugin l'appelle directement par HTTPS avec l'auth simple-token + X-Tenant fournie par `stt_config`.

### Phase 4 — Suppression définitive du gem `duke` (0.5 jour)

| # | Tâche | Sortie | Validation |
|---|---|---|---|
| 4.1 | Retirer la déclaration du gem `duke` de `idea.gemspec` (s'il y est) et de tout `Gemfile`/`Gemfile.lock` | Patch | `bundle install` réussit sans `duke` |
| 4.2 | Confirmer qu'aucun fichier du plugin ne référence encore Duke : `grep -rn -E "Duke::|D\.webchat|duke_integration|BaseDuke" .` → 0 | Audit final | Sortie vide |
| 4.3 | Renommer la classe Ruby `DiagnosticInstigator` → `Idea::DiagnosticInstigator` (préfixe namespace, conforme conventions Ekylibre) | Renommage | Pas de pollution du top-level |

### Phase 5 — Vérifications & non-régression (2 jours)

| # | Tâche | Sortie | Validation |
|---|---|---|---|
| 5.1 | Test contrôleur : POST `/backend/idea_diagnostics` → instigation OK, autofill job déclenché | `test/controllers/backend/idea_diagnostics_controller_test.rb` | Vert |
| 5.2 | Test contrôleur : flux complet A1 via les nouveaux endpoints `next_question`/`answer` (question → réponse → score) | Idem | Vert |
| 5.3 | Test unitaire par composant : `next_question` retourne la bonne `Idea::Question` selon chaque branche `item('X_Y').value.nil?` | `test/lib/idea/components/*_test.rb` | Vert + couverture des branches |
| 5.4 | Test contrôleur : `GET stt_config` renvoie la bonne shape, et respecte `DUKE_STT_SERVER_ENABLED=false` | Test | Vert |
| 5.5 | Smoke manuel sur tenant de dev : créer diagnostic → cliquer "saisir A1" → répondre par texte → répondre par dictée → score calculé | Capture d'écran | Comportement identique à l'ancien flux Duke |
| 5.6 | Vérifier que le widget Duke (nouveau, global Ekylibre) coexiste sans collision JS sur la page `idea_diagnostics/show` | Inspection DOM | Pas de double listener sur `.idea_duke`, pas d'erreur console |

---

## 6. Suppression d'artefacts à valider en fin de Phase 4

Liste de contrôle ASCII à exécuter au shell (depuis la racine du plugin) :

```bash
grep -rn -E "Duke::|D\.webchat|duke_integration|BaseDuke|DukeResponse|new_active_session|webchat_interface" . \
  --include='*.rb' --include='*.haml' --include='*.js' --include='*.scss' --include='*.yml'
# → doit retourner 0 résultat

grep -n "duke" Gemfile idea.gemspec
# → doit retourner 0 résultat

ls app/assets/javascripts/duke_integration.js 2>&1
# → "No such file or directory"
```

---

## 7. Risques & checkpoints

| Risque | Probabilité | Impact | Mitigation |
|---|---|---|---|
| Phase 1.1 révèle un usage de `Duke::Utils::BaseDuke` au-delà de `duke_information_tag` (méthodes de score, état persistant, callbacks `ApplicationCable`) | Moyenne | Bloquant | Arrêt et report en Phase 2 d'un rapatriement étendu |
| Le `_form.html.haml` ou `dashboards/idea.html.haml` réfère encore à Duke | Faible | Moyen | Grep large en Phase 1.1 |
| Le JS Vanilla perd l'a11y / l'animation de l'ancien widget | Moyenne | Faible | Réutiliser les modales Bootstrap Ekylibre — pas de réinvention |
| Le endpoint STT du nouveau Duke nécessite des CORS particuliers pour POST depuis Ekylibre | Faible | Moyen | Tester tôt en Phase 3b ; en repli, recopier les ENV `DUKE_*` côté Ekylibre et exposer le proxy via `stt_config` |
| Les méthodes auto-fill (`a1_2`, `a1_4`, …) cassent à cause de la suppression de `Duke::Utils::BaseDuke` | Faible | Moyen | Phase 1.1 confirme que le mixin n'apporte rien à l'autofill |
| Concurrence avec le widget Duke global sur les attributs `data-*` ou les listeners de clic | Faible | Moyen | Phase 5.6 — vérification explicite |

### Checkpoints

- **Après Phase 1** : revoir l'inventaire ; si > 15 méthodes Duke à rapatrier, ouvrir un ticket de scope.
- **Après Phase 2** : `grep -rn "Duke::" lib/` doit être vide.
- **Après Phase 3 bis** : Web Speech fonctionne sur Chrome, fallback Whisper fonctionne sur Firefox (avec `DUKE_STT_SERVER_ENABLED=true` côté Ekylibre).
- **Après Phase 4** : checklist du §6 entièrement verte.
- **Après Phase 5** : flux complet A1-A5 vérifié manuellement sans Internet (le STT serveur peut être désactivé) ET avec STT serveur activé.

---

## 8. Dépendances inter-tâches

```
[1.1] → [1.2] → [1.3] → [1.4]
                          ↓
                        [2.1] → [2.2] → [2.3] → [2.4] → [2.5]
                                                          ↓
                                       ┌──────────────────┴──────────────────┐
                                       ↓                                     ↓
                                     [3.1] → [3.2]                       [3b.1]
                                       ↓        ↓                           ↓
                                     [3.3] → [3.4] → [3.5] → [3.6]      [3b.2] → [3b.3]
                                                              ↓             ↓
                                                              └──────┬──────┘
                                                                     ↓
                                                                   [4.1] → [4.2] → [4.3]
                                                                                     ↓
                                                                   [5.1] [5.2] [5.3] [5.4] (parallèles)
                                                                                     ↓
                                                                                   [5.5] → [5.6]
```

Charge totale estimée : **8 jours** (Phases 1-5, dictée vocale incluse).

---

## 9. Prochaine action

`/sc:implement` à partir de **Phase 1.1** (audit `Duke::*`). Le résultat de cette tâche conditionne l'effort réel des Phases 2 et 4 ; si l'audit révèle des couplages non triviaux, retourner ici pour ajuster le scope avant d'engager les modifications.
