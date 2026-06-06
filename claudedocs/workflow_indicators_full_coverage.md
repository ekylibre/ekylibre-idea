# Workflow — Construction des indicateurs IDEA manquants

> Scope: étendre `ekylibre-idea` de **5 indicateurs (A1-A5)** à la **couverture complète des 53 indicateurs** spécifiés par IDEA4 (Dimension A : A1-A19, Dimension B : B1-B23, Dimension C : C1-C11).
>
> Source documentaire : `/home/djoulin/Téléchargements/idea/` — `Tableau de référence IDEA_2021_08_17.xlsx` + 3 PDFs de spécification par dimension.

## État d'avancement (mis à jour à chaque session)

| Phase | Description | État | Tests |
|---|---|---|---:|
| 0 | Refonte modèle YAML (`config/indicators.yml`, registry, instigator) | ✅ | 19 |
| 1 | 48 stubs + UI 3 dimensions | ✅ | 5 |
| 2 (générique) | Wizard générique + i18n auto-générée des 220 questions | ✅ | (couvert) |
| 3 | Dim C précise (PDF) — C1-C11 avec PdD/TES/SA/EB/SI | ✅ | 22 |
| 4 | Dim B précise (PDF) — B1-B23 check-list IDEA4 | ✅ | 42 |
| 5+6 | UX globale + score global IDEA + doc + tests | ✅ | 6 |
| A6-A19 | Dim A complète (PDF) — AUT_N, PPHM, CEDI, EPE, conditionnel élevage | ✅ | 18 |
| **Total tests** | | | **147 runs / 438 assertions / 0 failures** |

**Couverture : 53/53 indicateurs IDEA4 implémentés** avec formules conformes aux PDFs de spécification.

### Reste à faire (hors plugin)

- **Autofill ERP** : connecter A8/A11/A16/A18 et C1-C3/C8/C10-C11 à `accountancy` + `interventions` + `registered_phytosanitary_products`
- **Smoke E2E manuel** sur tenant démo
- **Comparaison expert IDEA** pour calibration
- **Export PDF** du diagnostic via Printer Ekylibre

---

> **Document de planification** — la suite décrit l'analyse initiale (cartographie 53 indicateurs, ampleur estimée, stratégies envisagées) qui a guidé la mise en œuvre. Conservé pour traçabilité.

---

## 1. Cartographie de l'écart

### 1.1 État actuel vs cible

| Dimension | Indicateurs cibles | Items | Implémenté | Reste |
|---|---|---|---|---|
| **A** Agro-écologique | A1-A19 (19) | 263 | **A1-A5 (5)** | **A6-A19 (14)** |
| **B** Socio-territoriale | B1-B23 (23) | 153 | 0 | **B1-B23 (23)** |
| **C** Économique | C1-C11 (11) | 34 | 0 | **C1-C11 (11)** |
| **Total** | **53** | **450** | **5 (9,4 %)** | **48 (90,6 %)** |

Répartition des **450 items** selon leur source :
- **201 items autofill** (calculables depuis l'ERP) : ratio dépendant du module Ekylibre concerné
- **215 items wizard** (saisie utilisateur via questionnaire)
- **34 items "donnée IDEA"** (constantes bibliographiques / abaques)

### 1.2 Inventaire détaillé par indicateur manquant

Source : `Tableau de référence IDEA_2021_08_17.xlsx`, onglet `Comparaison_IDEAEky`.

#### Dimension A — restant (14 indicateurs, 177 items)

| ID | Items | Auto | Wizard | Libellé |
|---|---:|---:|---:|---|
| A6 | 10 | 3 | 7 | Autonomie en énergie, matériaux, matériels, semences et plants |
| A7 | 5 | 5 | 0 | Autonomie alimentaire de l'élevage |
| A8 | 12 | 12 | 0 | Autonomie en azote |
| A9 | 3 | 1 | 2 | Sobriété dans l'usage de l'eau |
| A10 | 3 | 3 | 0 | Sobriété dans l'utilisation du phosphore |
| A11 | 19 | 12 | 7 | Sobriété dans la consommation en énergie |
| A12 | 13 | 3 | 10 | Raisonner l'utilisation de l'eau |
| A13 | 9 | 5 | 4 | Favoriser la fertilité du sol |
| A14 | 6 | 3 | 3 | Maintenir l'efficacité de la protection sanitaire |
| A15 | 5 | 2 | 3 | Sécuriser la disponibilité des moyens de production |
| **A16** | **50** | **42** | **8** | Réduction de l'impact des pratiques sur la qualité de l'eau |
| A17 | 5 | 2 | 3 | Réduction de l'impact des pratiques sur la qualité de l'air |
| A18 | 26 | 21 | 5 | Atténuation de l'effet sur le changement climatique |
| A19 | 11 | 4 | 7 | Réduire l'usage des produits phytosanitaires |

#### Dimension B — entièrement à créer (23 indicateurs, 153 items)

| ID | Items | Auto | Wizard | Libellé |
|---|---:|---:|---:|---|
| B1 | 4 | 2 | 2 | Production alimentaire de l'exploitation |
| B2 | 3 | 2 | 1 | Contribution à l'équilibre alimentaire mondial |
| B3 | 5 | 1 | 4 | Démarche de qualité de la production alimentaire |
| B4 | 9 | 0 | 9 | Limitation des pertes et gaspillages |
| B5 | 3 | 0 | 3 | Liens sociaux, hédoniques et culturels à l'alimentation |
| B6 | 2 | 0 | 2 | Engagement dans des démarches environnementales contractualisées |
| B7 | 3 | 0 | 3 | Services marchands au territoire |
| B8 | 4 | 1 | 3 | Valorisation par circuits courts ou de proximité |
| B9 | 15 | 5 | 10 | Valorisation des ressources locales |
| B10 | 8 | 0 | 8 | Valorisation et qualité du patrimoine |
| B11 | 4 | 0 | 4 | Accessibilité de l'espace |
| B12 | 10 | 0 | 10 | Gestion des déchets non organiques |
| B13 | 2 | 0 | 2 | Réseaux d'innovation et mutualisation du matériel |
| B14 | 9 | 1 | 8 | Contribution à l'emploi et gestion du salariat |
| B15 | 5 | 0 | 5 | Mutualisation du travail |
| B16 | 5 | 0 | 5 | Intensité et qualité au travail |
| B17 | 13 | 0 | 13 | Accueil, hygiène et sécurité au travail |
| B18 | 3 | 0 | 3 | Formation |
| B19 | 6 | 0 | 6 | Implication sociale territoriale et solidarités |
| B20 | 3 | 0 | 3 | Démarche de transparence |
| B21 | 1 | 0 | 1 | Qualité de vie |
| B22 | 2 | 0 | 2 | Isolement |
| **B23** | **34** | **1** | **33** | Bien-être animal |

#### Dimension C — entièrement à créer (11 indicateurs, 34 items)

| ID | Items | Auto | Wizard | Libellé |
|---|---:|---:|---:|---|
| C1 | 6 | 5 | 1 | Capacité économique |
| C2 | 3 | 3 | 0 | Capacité de remboursement |
| C3 | 3 | 3 | 0 | Endettement structurel |
| C4 | 2 | 0 | 2 | Diversification productive |
| C5 | 3 | 1 | 2 | Diversification et relations contractuelles |
| C6 | 2 | 1 | 1 | Sensibilité aux aides à la production |
| C7 | 1 | 0 | 1 | Contribution des revenus extérieurs |
| C8 | 3 | 3 | 0 | Transmissibilité économique |
| C9 | 4 | 0 | 4 | Pérennité probable |
| C10 | 5 | 5 | 0 | Efficience brute du processus productif |
| C11 | 2 | 2 | 0 | Sobriété en intrants |

---

## 2. Constats architecturaux et changements de structure

### 2.1 Le modèle actuel ne tient pas tel quel

`Idea::Indicators` (`lib/idea/indicators.rb`) est aujourd'hui :
- Une simple `class` avec 4 méthodes (`functional_diversity_attributes`, `item_values_count`, `components`, `scripted_components`)
- Un seul `group` valeur — `'functional_diversity'` — utilisé partout
- 5 entrées hard-codées
- Une `NATURE_MAP` (38 entrées actuellement A1-A4)

Passer à 53 indicateurs implique :
- Un **registre structuré** plutôt que 4 méthodes hardcoded
- Une notion de **dimension** (`A`, `B`, `C`) et probablement de **sous-thème** (alimentation, social, économique, énergie, etc.)
- Une `NATURE_MAP` ~10× plus volumineuse → externalisée en YAML
- Un mapping `id_input → method_for_autofill` extrait du tableau Excel

### 2.2 Le composant `Idea::Components::*` reste valide mais explose en volume

Le pattern composant (un fichier `.rb` par indicateur avec `next_question`, `update_global_score`, et N méthodes calculatrices `aN_M`) **est conservé** — il fonctionne pour A1-A5 et passe à l'échelle. Mais :
- On passe de 5 fichiers à 53 fichiers (`lib/idea/components/a6.rb` … `c11.rb`)
- Beaucoup contiennent du code redondant (boilerplate `initialize`, `reset_indicator`, `update_global_score`) → extraire dans le `Base`
- Les méthodes calculatrices `aN_M` accèdent à des données ERP qui n'existent peut-être pas (cf. § 3 ci-dessous)

### 2.3 Le dashboard `show.html.haml` doit changer de structure

Actuel : une seule `cobble :functional_diversity` qui liste les 5 indicateurs A1-A5.

Cible : **3 cobbles** ou **un cobble avec 3 onglets** :
- Dimension A — Agro-écologique
- Dimension B — Socio-territoriale
- Dimension C — Économique

Avec :
- Score par dimension agrégé
- Score global IDEA (somme/moyenne pondérée)
- Vue résultats détaillée par dimension (réutilisable pour export PDF)

### 2.4 Migrations DB potentiellement nécessaires

À investiguer en Phase 0 :
- Le modèle `IdeaDiagnosticItem` a-t-il un champ `dimension` ou doit-on s'en sortir avec `group` (string libre) ?
- Le champ `treshold` est-il suffisant pour exprimer les pondérations IDEA4 (qui sont souvent en %) ?
- Le `IdeaDiagnosticResult` actuel suffit-il pour agréger par dimension ?

Le tableau Excel et les PDFs des dimensions doivent être lus pour confirmer.

---

## 3. Disponibilité des données ERP — risque majeur

Beaucoup d'items "autofill" requièrent des données qui **n'existent pas nécessairement** dans Ekylibre aujourd'hui. Échantillon des dépendances :

| Indicateur | Données ERP requises | Module Ekylibre |
|---|---|---|
| A8 (12 autofill, 0 wizard) | Quantités d'azote épandues, fixation symbiotique, balance azotée | `interventions` + traitements |
| A11 (12 autofill) | Consommation énergétique (fioul, électricité, gaz) | `interventions` + comptabilité énergie |
| **A16** (42 autofill !) | Phytosanitaires utilisés, doses, IFT | `registered_phytosanitary_products` + `interventions` |
| A18 (21 autofill) | Émissions GES, séquestration carbone | À créer ex nihilo |
| B14 (1 autofill) | Salariés, contrats, heures travaillées | Module RH/payroll |
| B23 (1 autofill) | Pratiques élevage détaillées | À créer ex nihilo |
| C1-C3 (11 autofill) | EBE, annuités LMT, dotations amortissements | `accountancy` module |
| C10 (5 autofill) | EBE / produit brut | `accountancy` |

**Conséquence** : l'autofill ne fonctionnera réellement que pour les indicateurs dont la donnée source est déjà capturée dans l'ERP. Pour les autres :
- Soit le calcul retourne `nil` et le score reste incomputable
- Soit on bascule l'item en `wizard` (saisie manuelle utilisateur)

→ Phase 0 doit faire un **audit de disponibilité données** indicateur par indicateur.

---

## 4. Stratégie d'attaque

### 4.1 Options envisagées

| Stratégie | Description | Coût | Risque |
|---|---|---|---|
| **A — Big bang** | Tout livrer d'un coup (53 indicateurs, refonte modèle + UI + tests) | 8-12 mois | Énorme — code mort tant que rien n'est testé en prod |
| **B — Par dimension** | Livrer Dim A complète, puis C, puis B | 6-9 mois | Modéré — chaque dimension est livrable indépendamment |
| **C — Stubs + activation progressive** ✅ | Phase 1 : 48 composants stubs (terminal immédiat, score 0, autofill mock). Phases 2+ : activer indicateur par indicateur | 4-8 mois | Faible — UI complète tôt, progrès visible et testé |
| **D — Par batch métier** | Énergie (A6, A11, A18) → Eau (A9, A12, A16, A17) → Sol (A13) → … | 6-9 mois | Modéré — bonne cohérence métier, coordination plus complexe |

**Choix retenu** : **Stratégie C** (stubs + activation progressive).
- Bénéfice immédiat : l'utilisateur voit les 53 indicateurs dès la Phase 1
- Permet de prioriser au fil de l'eau (selon retours utilisateur, disponibilité données ERP, etc.)
- Tests unitaires faisables par indicateur sans bloquer le reste
- Chaque indicateur activé est une PR autonome

### 4.2 Critères de priorisation post-Phase 1

L'ordre d'activation des 48 indicateurs (Phases 2+) sera déterminé par :
1. **Ratio autofill / wizard** — privilégier les autofill (moins de saisie pour l'utilisateur)
2. **Disponibilité des données ERP** — A16 et C1-C3 nécessitent des intégrations dédiées
3. **Importance dans le score global IDEA** — certains indicateurs pèsent plus
4. **Demande utilisateur** — feedback à collecter après Phase 1

Première tranche probable (à valider) : **A7, A8, A10, A11, A13, A14, A15, A17, A18** (Dim A indicateurs avec autofill majoritaire et données ERP partiellement disponibles), puis **C2, C3, C8, C10, C11** (Dim C purement comptable).

---

## 5. Plan d'exécution

### Phase 0 — Refonte modèle + audit données (5-8 jours)

| # | Tâche | Sortie | Validation |
|---|---|---|---|
| 0.1 | Extraire l'inventaire Excel en YAML versionné dans le plugin | `db/indicators.yml` avec, par indicateur : `id`, `dimension`, `label`, `treshold`, `items: [{id, nature, source, formula_hint}]` | Round-trip YAML/Excel cohérent |
| 0.2 | Refondre `Idea::Indicators` en registry qui parse `db/indicators.yml` au boot | API publique : `Idea::Indicators.all`, `.by_dimension('A')`, `.find('A6')`, `.nature_for('A6_03')` | Tous les helpers actuels (`scripted_components`, `nature_for`, etc.) continuent de fonctionner |
| 0.3 | Refondre `DiagnosticInstigator` pour instigager les 53 indicateurs (pas seulement A1-A5) | Tous les `IdeaDiagnosticItem` créés, tous les `IdeaDiagnosticItemValue` placeholders | Création de diagnostic crée 53 items |
| 0.4 | Auditer la disponibilité des données ERP pour chaque item autofill (cf. § 3) | Matrice "indicateur × donnée × état (disponible / partiel / absent)" dans `claudedocs/idea_data_audit.md` | Tableau exhaustif |
| 0.5 | Décider du modèle de dimension : champ `dimension` sur `IdeaDiagnosticItem` ou agrégation côté Ruby ? | Décision documentée + migration si nécessaire | Pas de breaking change sur les diagnostics existants |
| 0.6 | Étendre la nomenclature i18n : `idea.dimensions.A/B/C.label`, `idea.indicators.A6.label`, `idea.questions.A6_03` (placeholders) | `config/locales/fra/action.yml` étendu | Pas de "Translation missing" sur les 53 indicateurs |

**Checkpoint Phase 0** : aucune régression sur A1-A5 ; 53 indicateurs visibles dans la base avec score `nil`.

### Phase 1 — Stubs pour les 48 indicateurs manquants (4-6 jours)

| # | Tâche | Sortie | Validation |
|---|---|---|---|
| 1.1 | Templater 48 composants `Idea::Components::A6 … C11` (boilerplate `initialize`/`reset_indicator`/`update_global_score` extrait dans `Base`) | 48 `.rb` files + `lib/idea.rb` require chain mise à jour | Tous les composants se chargent sans erreur |
| 1.2 | Chaque stub : `next_question` retourne `Idea::Question.terminal`, `compute_score` retourne `nil` (pas de scoring fictif) | Composants minimaux | Wizard ouvert sur un indicateur stub → ferme immédiatement |
| 1.3 | Étendre `NATURE_MAP` avec les natures déclarées dans `db/indicators.yml` | Map complète des ~400 items | `Idea::Indicators.nature_for('B17_03')` retourne la bonne valeur |
| 1.4 | Étendre `scripted_components` (ou supprimer cette notion au profit de `has_questions?(indicator)`) | Liste de tous les indicateurs ayant ≥ 1 item wizard | Bouton wizard masqué sur les indicateurs full-autofill |
| 1.5 | Refondre `show.html.haml` : 3 onglets/cobbles A/B/C avec tableau de scores | Vue mise à jour | UI fonctionnelle, scores `-` pour les stubs |
| 1.6 | Tests unitaires : chaque stub instanciable, retourne terminal, ne crash pas | `test/lib/idea/components/*_test.rb` | Couverture 100 % du boilerplate |

**Checkpoint Phase 1** : 53 indicateurs visibles, 5 fonctionnels, 48 inertes (score `-`, pas de questionnaire).

### Phase 2 — Activer Dimension A (A6-A19) — 14 indicateurs (15-20 jours)

Pour chaque indicateur A_k (k=6..19) :

| # | Tâche | Sortie | Validation |
|---|---|---|---|
| 2.k.1 | Lire la spec PDF Dimension A § A_k pour comprendre la formule de score IDEA | Notes dans `claudedocs/idea_specs/A_k.md` | Compréhension validée |
| 2.k.2 | Implémenter les méthodes calculatrices `a_k_M` (M=01..N) selon la spec — uniquement pour les items dont la donnée ERP est disponible (cf. audit Phase 0.4) | Méthodes dans `lib/idea/components/a_k.rb` | Tests unitaires sur valeurs synthétiques |
| 2.k.3 | Implémenter `next_question` pour les items wizard de A_k | Méthode + sentence i18n dans `fra/action.yml` sous `idea.questions.A_k_M` | Smoke manuel : ouvrir wizard A_k, répondre, score calculé |
| 2.k.4 | Implémenter `compute_score` et `computable?` selon la formule IDEA4 | Méthodes privées | Round-trip diagnostic → score conforme à un exemple IDEA |
| 2.k.5 | Tests unitaires couvrant chaque branche de `next_question` et `compute_score` | `test/lib/idea/components/a_k_test.rb` | 100 % branches couvertes |

**Estimation par indicateur** :
- Indicateurs avec ≤ 5 items et 0 wizard : 0,5-1 jour (A7, A10) → 1,5 jour total
- Indicateurs avec ≤ 10 items mix autofill/wizard : 1-2 jours (A6, A9, A12-A15, A17) → 10-14 jours
- Indicateurs lourds avec score complexe : 2-3 jours (A8, A11, A18, A19) → 8-12 jours
- **A16** (50 items, IFT phytosanitaire) : **3-5 jours seul** + dépendance forte au `lexicon` phytosanitaire d'Ekylibre

Sous-total Phase 2 : **~25-35 jours-homme** selon disponibilité données.

### Phase 3 — Activer Dimension C (C1-C11) — 11 indicateurs (10-15 jours)

Dépendance majeure : **module `accountancy` d'Ekylibre** pour C1, C2, C3, C8, C10, C11 (EBE, annuités, dotations, etc.).

| Sous-batch | Indicateurs | Pré-requis | Effort |
|---|---|---|---|
| Comptable pur | C1, C2, C3, C8, C10, C11 | Accountancy disponible | 1-2j × 6 = 8-12j |
| Subventions | C4, C5, C6 | Données aides PAC + contrats | 1-2j × 3 = 3-6j |
| Économique qualitatif | C7, C9 | Wizard pur | 0,5j × 2 = 1j |

Sous-total Phase 3 : **~12-19 jours**.

### Phase 4 — Activer Dimension B (B1-B23) — 23 indicateurs (20-30 jours)

Dimension la plus longue : 140 items wizard, peu d'autofill, nombreuses dépendances RH/sociales/territoriales hors scope ERP standard.

| Sous-batch | Indicateurs | Caractère | Effort |
|---|---|---|---|
| Alimentaire | B1-B5 | Mix wizard + données activités | 4-6j |
| Territorial | B6-B12 | Wizard pur, formulaires longs | 6-8j |
| Travail/RH | B13-B19 | Wizard pur, nécessite peut-être module payroll | 5-8j |
| Bien-être animal | **B23** (34 items) | Wizard complet, **très détaillé** | 5-7j seul |
| Divers | B20-B22 | Wizard court | 1-2j |

Sous-total Phase 4 : **~21-31 jours**.

### Phase 5 — UX globale + reporting (5-8 jours)

| # | Tâche | Sortie |
|---|---|---|
| 5.1 | Vue résultats IDEA complète (dashboard récap 3 dimensions, radar charts) | Nouveau `IdeaDiagnosticResult#show` |
| 5.2 | Export PDF du diagnostic IDEA | Réutiliser le système d'impression Ekylibre |
| 5.3 | Pondération inter-indicateurs selon la grille IDEA4 (à confirmer avec les PDFs) | Formule centrale dans `Idea::Indicators.global_score(diagnostic)` |
| 5.4 | Documentation utilisateur : guide de saisie par dimension | README + section in-app |

### Phase 6 — Validation + non-régression (3-5 jours)

| # | Tâche | Validation |
|---|---|---|
| 6.1 | Tests unitaires complets : 53 composants × N branches | Couverture > 80 % |
| 6.2 | Smoke E2E sur tenant demo : créer diagnostic, parcourir les 3 dimensions, valider scores | Capture vidéo |
| 6.3 | Tests contrôleur : `next_question` et `answer` couvrent tous les indicateurs | Vert |
| 6.4 | Comparaison avec un diagnostic IDEA réel (fourni par un expert) | Écart < 5 % sur le score global |

---

## 6. Effort total + jalons

| Phase | Description | Effort (jours-homme) |
|---|---|---:|
| 0 | Refonte modèle + audit données | 5-8 |
| 1 | Stubs pour 48 indicateurs | 4-6 |
| 2 | Activer Dim A (A6-A19) | 25-35 |
| 3 | Activer Dim C (C1-C11) | 12-19 |
| 4 | Activer Dim B (B1-B23) | 21-31 |
| 5 | UX globale + reporting | 5-8 |
| 6 | Validation | 3-5 |
| **Total** | | **75-112 jours-homme** |

À pleine vitesse (1 dev solo) : **~4 à 6 mois**.
Avec 2 devs en parallèle après Phase 1 : **~3 à 4 mois**.

---

## 7. Risques majeurs

| Risque | Probabilité | Impact | Mitigation |
|---|---:|---:|---|
| Données ERP absentes pour les items autofill (cf. § 3) | **Élevée** | Bloquant pour le score | Phase 0.4 audit explicite. Pour les manquantes : basculer en wizard (perte d'UX), ou créer des modules ERP dédiés (hors scope plugin) |
| Spec IDEA4 ambigüe ou non couverte par les PDFs | Moyenne | Score calculé incorrect | Tester chaque indicateur contre un cas concret validé par un expert IDEA |
| Refonte UI (3 dimensions) casse l'UX actuel d'A1-A5 | Faible | Régression visible | Tests visuels avant/après ; possibilité de feature-flag |
| Migration `IdeaDiagnosticItem` (ajout dimension) casse les diagnostics existants | Moyenne | Données utilisateur | Migration backward-compatible + script de remplissage |
| 50 items pour A16 → composant trop lourd | Moyenne | Difficulté de maintenance | Décomposer en sous-modules (eau de surface / eau souterraine / produits) |
| 34 items pour B23 → questionnaire interminable | Moyenne | Abandon utilisateur | Découpage en sous-thèmes, sauvegarde progressive |
| Formules de score IDEA4 nécessitent des constantes bibliographiques | Élevée | Score calculé erroné | Lire les PDFs + référencer toutes les constantes dans `db/idea_constants.yml` |
| Travail concurrent sur le plugin par d'autres devs | Moyenne | Conflits Git | Une PR par indicateur, branche `idea-coverage` long-lived |

---

## 8. Checkpoints de décision

- **Après Phase 0.4** (audit données) : décider quels items autofill sont réalisables vs basculés en wizard. Si **> 30 %** des items autofill nécessitent des données ERP absentes, alerter et reconsidérer la priorité.
- **Après Phase 1** : montrer les 53 indicateurs inertes à un utilisateur métier → valider l'organisation 3 dimensions + l'UX dashboard.
- **Après Phase 2** (Dim A complète) : tester un diagnostic agronomique sur le tenant demo → comparer avec un diagnostic IDEA papier.
- **Après Phase 3** (Dim C) : vérifier la cohérence des scores économiques avec les soldes intermédiaires du tenant.
- **Avant Phase 5** : décider de la stratégie de pondération inter-indicateurs (somme simple, moyenne pondérée, grille IDEA4 exacte).

---

## 9. Livrables intermédiaires possibles

Le découpage permet de livrer en production des **MVPs successifs** sans attendre la fin :

| MVP | Contenu | Effort cumulé |
|---|---|---|
| **MVP 0** | Phase 0+1 livrées : 53 indicateurs visibles, A1-A5 actifs, reste inerte | 9-14j |
| **MVP 1** | + Dim A complète | 34-49j |
| **MVP 2** | + Dim C complète | 46-68j |
| **MVP 3** | + Dim B complète + UX | 67-104j |
| **MVP final** | + Validation + doc | 70-110j |

Chaque MVP est déployable et apporte une valeur incrémentale.

---

## 10. Prochaine action

`/sc:implement` à partir de **Phase 0.1** (extraction de l'inventaire Excel en YAML versionné). Ce livrable conditionne tout le reste : sans inventaire structuré, on ne peut ni générer les stubs (Phase 1), ni cartographier les besoins (Phase 0.4), ni i18n (Phase 0.6).

L'audit de disponibilité ERP (Phase 0.4) doit être fait **en parallèle** dès Phase 0.1 — c'est le facteur déterminant pour le scope final et les priorités de Phase 2+.
