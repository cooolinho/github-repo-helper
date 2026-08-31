# GitHub Repo Helper

Ein Satz von Bash-Skripten zur Verwaltung lokaler Projekte auf GitHub. Das Hauptziel ist **Datensicherung** — stelle sicher, dass jedes lokale Projekt auf GitHub gepusht wird, damit keine Daten verloren gehen, falls die Festplatte ausfällt.

> **English version:** [README.md](README.md)

## Voraussetzungen

### 1. GitHub CLI installieren

Die Skripten benötigen die [GitHub CLI (`gh`)](https://cli.github.com/). Installation für deine Plattform:

**macOS (Homebrew):**

```bash
brew install gh
```

**Linux (Debian/Ubuntu):**

```bash
sudo apt update
sudo apt install gh
```

**Linux (Fedora):**

```bash
sudo dnf install gh
```

**Windows (winget):**

```powershell
winget install --id GitHub.cli
```

Oder downloaden unter: https://cli.github.com/

### 2. Bei GitHub anmelden

Melde dich mit der CLI bei deinem GitHub-Konto an:

```bash
gh auth login
```

Folge den interaktiven Anweisungen, um deine bevorzugte Authentifizierungsmethode zu wählen (Browser oder Token).

### 3. Personal Access Token (PAT) — Benötigte Berechtigungen

Falls du stattdessen ein Personal Access Token verwenden möchtest, erstelle eines unter https://github.com/settings/tokens mit den folgenden Berechtigungen:

| Scope | Erforderlich | Zweck |
|-------|-------------|-------|
| `repo` | **Ja** | Volle Kontrolle über private Repositories — Erstellen, Pushen, Auflöschen und Löschen von Repos |
| `delete_repo` | Optional | Nur benötigt, wenn `github-upload.sh` bestehende Repos überschreiben soll |

Token setzen via:

```bash
gh auth login --with-token <<< "ghp_dein_token_hier"
```

Oder als Umgebungsvariable setzen:

```bash
export GH_TOKEN="ghp_dein_token_hier"
```

### 4. Anforderungen

- **Bash 4.0+** (für assoziative Arrays)
- **Git**
- **GitHub CLI (`gh`)** — authentifiziert

---

## Skripten

### `github-check.sh` — Stapel-Prüfung aller Projekte

Durchsucht einen Ordner mit Projekt-Unterordnern und prüft jedes einzelne gegen dein GitHub-Konto. Berichtet, welche Projekte auf GitHub liegen, welche uncommittete/unpushed Änderungen haben und welche fehlen.

#### Nutzung

```bash
./github-check.sh [ORDNER] [--account OWNER]
```

| Argument | Erforderlich | Beschreibung |
|----------|-------------|--------------|
| `ORDNER` | Nein | Verzeichnis mit Projekt-Unterordnern (Standard: aktuelles Verzeichnis) |
| `--account OWNER` | Nein | GitHub-Kontoname überschreiben (Standard: automatisch erkannt aus `gh auth`) |

#### Beispiele

**Alle Projekte im aktuellen Verzeichnis prüfen:**

```bash
./github-check.sh
```

**Alle Projekte in einem bestimmten Ordner prüfen:**

```bash
./github-check.sh ~/projects
```

**Gegen ein bestimmtes GitHub-Konto prüfen:**

```bash
./github-check.sh ~/projects --account mein-benutzername
```

#### Status-Ausgaben

| Status | Bedeutung |
|--------|-----------|
| `[OK]` | Projekt liegt auf GitHub und ist aktuell |
| `[WARN]` | Projekt liegt auf GitHub, hat aber uncommittete Dateien oder unpushed Commits |
| `[MISSING]` | Projekt liegt nicht auf GitHub (interaktive Aufforderung zum Pushen oder Überspringen) |
| `[FREMD]` | Remote zeigt auf ein anderes GitHub-Konto (fremd) |

#### Interaktive Aufforderungen

Für jedes `[MISSING]`-Projekt wirst du gefragt:

- **[P]ushen** — Repository auf GitHub anlegen und pushen
- **[S]kip** — Projekt überspringen
- **[Q]uit** — Prüfung abbrechen

---

### `github-upload.sh` — Einzelnes Projekt hochladen

Ein einfaches Skript zum Initialisieren von Git und Hochladen eines neuen Projekts auf GitHub. Funktioniert nur mit Verzeichnissen, die **noch kein** Git-Repository sind.

#### Nutzung

```bash
./github-upload.sh /pfad/zum/projekt
```

#### Beispiele

**Ein neues Projekt hochladen:**

```bash
./github-upload.sh ~/projects/meine-neue-app
```

Das Skript:

1. Fragt nach einem Repository-Namen (Standard: Verzeichnisname)
2. Fragt, ob das Repository public oder private sein soll
3. Initialisiert Git, erstellt einen Initial-Commit
4. Erstellt das GitHub-Repository und pusht

> **Hinweis:** Falls ein Repository mit demselben Namen bereits auf GitHub existiert, wirst du nach einer Bestätigung gefragt, bevor es gelöscht und neu erstellt wird.

---

## Lizenz

MIT
