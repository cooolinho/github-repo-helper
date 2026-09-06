<h1 align="center">🛡️ GitHub Repo Helper</h1>

<p align="center">
  <em>Bash-Skripte, die sicherstellen, dass jedes lokale Projekt wirklich auf GitHub gesichert ist — bevor deine Festplatte anders entscheidet.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/GitHub_CLI-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub CLI">
  <img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" alt="Git">
</p>

<p align="center">
  <a href="README.md">🇬🇧 English version</a>
</p>

---

## 📖 Über das Projekt

In einem Projektordner sammelt sich mit der Zeit Arbeit an, die es nie zu einem
Remote geschafft hat. Manche Repositories wurden nie gepusht, manche haben
uncommittete Änderungen von vor Monaten, und ein paar zeigen auf das falsche Konto.

Diese beiden Skripte finden das alles. `github-check.sh` scannt einen Projektordner
und meldet den Zustand jedes einzelnen Projekts gegenüber deinem GitHub-Konto — und
bietet an, Fehlendes zu pushen. `github-upload.sh` bringt ein einzelnes neues
Projekt von `git init` bis zum ersten Push.

Es geht um Backup-Sicherheit, nicht um Repository-Verwaltung: Wenn die Platte
ausfällt, soll nichts verloren sein.

## 🛠️ Tech-Stack

| Technologie | Version | Zweck |
|-------------|---------|-------|
| <img src="https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="Bash"> Bash | 4.0+ | Assoziative Arrays werden benötigt |
| <img src="https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white" alt="Git"> Git | — | Repository-Zustand |
| <img src="https://img.shields.io/badge/GitHub_CLI-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub CLI"> GitHub CLI | — | Repositories auflisten, anlegen, pushen |

## ✨ Funktionen

- **Stapel-Prüfung** — ein kompletter Projektordner in einem Durchgang
- **Vier klare Zustände** — aktuell, ungesichert, fehlend oder fremdes Konto
- **Interaktiv** — pro Projekt entscheiden: pushen, überspringen oder abbrechen
- **Fremde Remotes erkennen** — findet Repositories, die auf ein anderes Konto zeigen
- **Geführter Upload** — Name, Sichtbarkeit, Init, Commit und Push in einem Ablauf

## 🚀 Erste Schritte

### Voraussetzungen

- **Bash 4.0+** — wegen assoziativer Arrays
- **Git**
- **GitHub CLI (`gh`)**, authentifiziert

### GitHub CLI installieren

| Plattform | Befehl |
|-----------|--------|
| macOS | `brew install gh` |
| Debian / Ubuntu | `sudo apt update && sudo apt install gh` |
| Fedora | `sudo dnf install gh` |
| Windows | `winget install --id GitHub.cli` |

Oder herunterladen von [cli.github.com](https://cli.github.com/).

### Authentifizierung

```bash
gh auth login
```

Oder mit einem Token:

```bash
gh auth login --with-token <<< "ghp_dein_token_hier"
```

Oder als Umgebungsvariable:

```bash
export GH_TOKEN="ghp_dein_token_hier"
```

### Token-Berechtigungen

| Scope | Nötig | Wofür |
|-------|-------|-------|
| `repo` | **Ja** | Private Repositories anlegen, pushen, auflisten und lesen |
| `delete_repo` | Optional | Nur, wenn `github-upload.sh` ein bestehendes Repository überschreiben soll |

### Installation

```bash
git clone https://github.com/cooolinho/github-repo-helper.git
cd github-repo-helper
chmod +x *.sh
```

## 📋 Verwendung

### 🔍 `github-check.sh` — Projektordner prüfen

Scannt die Unterordner eines Projektordners und gleicht jeden mit deinem
GitHub-Konto ab.

```bash
./github-check.sh [ORDNER] [--account OWNER]
```

| Argument | Nötig | Beschreibung |
|----------|-------|--------------|
| `ORDNER` | Nein | Verzeichnis mit den Projekten (Standard: aktuelles Verzeichnis) |
| `--account OWNER` | Nein | GitHub-Benutzername überschreiben (Standard: aus `gh auth`) |

```bash
./github-check.sh                                # aktuelles Verzeichnis
./github-check.sh ~/projekte                     # bestimmter Ordner
./github-check.sh ~/projekte --account mein-user # bestimmtes Konto
```

#### Zustände

| Status | Bedeutung |
|--------|-----------|
| `[OK]` | Auf GitHub und aktuell |
| `[WARN]` | Auf GitHub, aber mit uncommitteten Dateien oder ungepushten Commits |
| `[MISSING]` | Nicht auf GitHub — du wirst gefragt, ob gepusht werden soll |
| `[FREMD]` | Das Remote zeigt auf ein anderes GitHub-Konto |

#### Abfragen

Bei jedem `[MISSING]`-Projekt:

- **[P]ush** — Repository anlegen und pushen
- **[S]kip** — überspringen
- **[Q]uit** — Prüfung beenden

### ⬆️ `github-upload.sh` — einzelnes Projekt hochladen

Initialisiert Git und pusht ein neues Projekt. Funktioniert nur bei Verzeichnissen,
die **noch kein** Git-Repository sind.

```bash
./github-upload.sh /pfad/zum/projekt
```

Das Skript wird:

1. nach einem Repository-Namen fragen, standardmäßig der Verzeichnisname
2. fragen, ob es öffentlich oder privat sein soll
3. `git init` ausführen und einen ersten Commit anlegen
4. das GitHub-Repository anlegen und pushen

> ⚠️ Existiert bereits ein Repository mit diesem Namen, wirst du um Bestätigung
> gebeten, bevor es **gelöscht und neu angelegt** wird. Das ist der einzige
> destruktive Pfad im Toolset — lies die Abfrage aufmerksam.

## 📁 Projektstruktur

```
github-repo-helper/
├── github-check.sh    # Stapel-Prüfung für einen Projektordner
└── github-upload.sh   # Einzelnes Projekt hochladen
```

## 📄 Lizenz

Veröffentlicht unter der [MIT-Lizenz](LICENSE).
