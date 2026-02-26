# Workflow IA — Guide pratique

## Stack d'outils

| Outil | Rôle | Lien |
|-------|------|------|
| **Ghostty** | Terminal rapide et minimaliste | [github.com/ghostty-org/ghostty](https://github.com/ghostty-org/ghostty) |
| **Claude Code** | Agent IA principal (Anthropic) | [github.com/anthropics/claude-code](https://github.com/anthropics/claude-code) |
| **GitHub CLI** | Gestion des PRs, commits, repos | [github.com/cli/cli](https://github.com/cli/cli) |
| **Sentry CLI** | Monitoring et gestion des erreurs | [https://github.com/getsentry/cli](https://github.com/getsentry/cli) |
| **Linear CLI** | Gestion des issues et projets | [https://github.com/schpet/linear-cli](https://github.com/schpet/linear-cli) |

J'utilise aussi ponctuellement **Codex** (OpenAI), **OpenCode** et **Gemini CLI** selon les cas d'usage.

## Skills globaux

Les skills globaux sont disponibles dans tous les projets. Ils servent à des tâches transversales qui ne dépendent pas d'une codebase spécifique.

### `brainstorm`

Aide à structurer une réflexion sur une idée. Génère des bullet points, des schémas et pose des questions pour challenger le concept.

**Cas d'usage :** explorer une nouvelle feature, évaluer une approche technique, préparer une discussion d'équipe.

### `learn`

Aide à comprendre un sujet, un package ou un outil. Génère des explications progressives avec des exemples concrets.

**Cas d'usage :** découvrir un nouveau package Laravel, comprendre une API tierce, monter en compétence sur un sujet.

### `compare`

Compare plusieurs outils ou packages de manière structurée (fonctionnalités, performances, maintenance, communauté).

**Cas d'usage :** choisir entre deux packages, évaluer des alternatives à un outil existant.

### `daily`

Liste tout ce qui a été fait la veille : PRs GitHub et issues Linear.

**Cas d'usage :** préparer un daily standup en 10 secondes.

### `retro`

Même principe que `daily` mais sur les 2 dernières semaines.

**Cas d'usage :** préparer une rétrospective, rédiger un status update.

### `document`

Génère un document Markdown à partir d'une feature, un package, un ticket Linear ou une PR.

**Cas d'usage :** documenter une feature livrée, créer une spec technique, générer de la doc pour l'équipe.

## Scripts Bash

J'utilise 3 scripts Bash au quotidien. Ils peuvent être lancés manuellement par le développeur ou automatiquement par Claude Code.

### `ship` — Commit, PR & Push

Automatise tout le flow de livraison en suivant toujours le même format :
1. Crée le commit avec un message conventionnel
2. Crée la PR sur GitHub avec description, labels, etc.
3. Push la branche

Utilise **GitHub CLI** (`gh`).

### `pr` — Gestion de la PR courante

Gère la PR associée à la branche actuelle (vérifier le statut, mettre à jour, merger, etc.).

Utilise **GitHub CLI** (`gh`).

### `fix` — Gestion des erreurs Sentry

Workflow complet de gestion des erreurs de production :
1. Checker les erreurs remontées par Sentry
2. Les archiver si non pertinentes
3. Créer un ticket Linear et une branche pour les traiter

Utilise **Sentry CLI**, **Linear CLI** et **GitHub CLI**.

## Git Worktrees

Les [git worktrees](https://git-scm.com/docs/git-worktree) permettent d'avoir plusieurs branches checkout en même temps dans des dossiers séparés, sans avoir à cloner le repo plusieurs fois. Concrètement, chaque worktree est un dossier indépendant avec sa propre branche, mais ils partagent tous le même historique git.

Je les utilise dans deux cas : quand je dois corriger plusieurs erreurs Sentry en parallèle (un worktree par fix), ou quand Claude Code travaille sur un ticket Linear long — ça me permet de garder mon repo principal libre pour continuer à faire autre chose pendant ce temps.

```bash
# Créer un worktree sur une nouvelle branche
git worktree add ../carjudge-fix-auth fix/auth-error

# Lister les worktrees actifs
git worktree list

# Supprimer un worktree après merge
git worktree remove ../carjudge-fix-auth
```

## Plugins Claude Code

Les plugins ajoutent des capacités spécialisées à Claude Code.

| Plugin | Rôle |
|--------|------|
| `code-review` | Revue de code automatisée |
| `feature-dev` | Aide au développement de features |
| `frontend-design` | Assistance sur le design frontend |
| `laravel-simplifier` | Simplification et refactoring Laravel |
| `php-lsp` | Intégration du Language Server Protocol PHP |
| `typescript-lsp` | Intégration du Language Server Protocol Typescript |
| `ralph-loop` | Boucle d'itération automatisée |

[https://github.com/anthropics/claude-plugins-official/tree/main/plugins](https://github.com/anthropics/claude-plugins-official/tree/main/plugins)

## Counselors — Multi-agents en parallèle

[Counselors](https://github.com/aarondfrancis/counselors) permet de dispatcher un même prompt à plusieurs agents IA (Claude Code, Codex, Gemini, Amp) en parallèle et de collecter leurs réponses dans un dossier structuré. Pas de MCP, pas de clés API supplémentaires — il appelle directement les CLIs installés localement. Utile pour obtenir un second avis technique, comparer des approches ou faire une code review multi-modèles. Il s'intègre dans Claude Code via un slash command `/counselors`.

## MCP (Model Context Protocol)

Quatre serveurs MCP sont configurés mais **désactivés par défaut** car rarement nécessaires. Ils peuvent être activés ponctuellement si besoin.

| MCP | Usage |
|-----|-------|
| **Sentry** | Consulter les erreurs directement depuis Claude |
| **Linear** | Accéder aux issues et projets |
| **Figma** | Récupérer des designs et specs |
| **Pencil** | Génération de maquettes |

Les MCP sont utiles quand on a besoin de contexte enrichi sans quitter Claude Code, mais les CLIs couvrent 90% des besoins au quotidien.

## Workflow type — Du ticket à la PR

```
  Issue Linear           Claude Code              GitHub
  ───────────           ───────────              ──────
       │                     │                      │
       │  1. Contexte        │                      │
       ├────────────────────►│                      │
       │     (skill projet)  │                      │
       │                     │                      │
       │  2. Plan            │                      │
       │◄────────────────────┤                      │
       │     (mode Plan)     │                      │
       │                     │                      │
       │  3. Validation      │                      │
       ├────────────────────►│                      │
       │                     │                      │
       │  4. Développement   │                      │
       │                     ├─────────────────────►│
       │                     │   5. ship            │
       │                     │   (commit + PR)      │
       │                     │                      │
       │  6. Link PR ◄───────┼──────────────────────┤
       │                     │                      │
```

1. Le ticket Linear donne le contexte (specs, acceptance criteria)
2. Claude Code propose un plan de développement
3. On valide ou ajuste le plan
4. Claude Code développe en suivant le plan
5. Le script `ship` gère le commit, la PR et le push
6. La PR est automatiquement liée au ticket Linear

## Pourquoi ce setup

- **Tout dans le terminal** — Pas de context switching entre des fenêtres. Ghostty est rapide, Claude Code tourne dedans, les CLIs font le reste.
- **Mode Plan** — On garde le contrôle. L'IA propose, le développeur valide.
- **Skills réutilisables** — Les tâches répétitives sont automatisées une seule fois et utilisables par toute l'équipe.
- **Scripts standardisés** — Le format des commits, PRs et la gestion des erreurs est identique quel que soit le développeur.
- **CLIs > MCP** — Les CLIs sont plus fiables, plus rapides et suffisent pour 90% des cas. Les MCP restent disponibles en backup.

## Exemples d'utilisation

### Implémenter un ticket Linear

Copier l'ID d'une issue Linear (app ou CLI), puis dans Claude Code : `Implement linear issue DOTO-1234`. Claude développe, on review, on ship.

> Ce flow manuel est voué à disparaître au profit d'un script `implement` similaire à `fix`.

### Corriger une erreur Sentry (manuel)

Copier l'URL ou l'ID d'une issue Sentry, puis dans Claude Code : `Fix sentry issue PROJ-A1B2`. Claude corrige, on review, on ship.

> Déjà remplacé par le script `fix` dans la plupart des cas.

### Corriger une erreur Sentry (script)

Lancer le script `fix`, sélectionner un ticket Sentry dans la liste, Claude corrige et crée la PR. Il ne reste qu'à review.

### Traiter des tickets en chaîne avec Ralph

Lancer Ralph sur un projet — il traite les tickets les uns après les autres de manière autonome. On review la ou les PRs à la fin.

### Créer un projet

Expliquer le projet à Claude ou brainstormer avec lui. Il invoque le skill pour créer le projet Linear (structure, etc.), puis on continue généralement avec le découpage en tickets.

### Créer un ticket

Même principe que pour un projet, mais pour une seule issue : on explique le besoin, Claude crée le ticket avec les specs et acceptance criteria.
