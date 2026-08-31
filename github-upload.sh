#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# github-upload.sh
# Ein einfaches Script um ein Projekt zu GitHub hochzuladen.
# Voraussetzung: gh CLI ist installiert und eingeloggt.
# ============================================================

# --- Argument-Check ---
if [ -z "${1:-}" ]; then
  echo "Fehler: Kein Projekt-Pfad angegeben."
  echo "Nutzung: $0 /pfad/zum/projekt"
  exit 1
fi

PROJECT_PATH="$(realpath "$1")"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "Fehler: Das Verzeichnis '$PROJECT_PATH' existiert nicht."
  exit 1
fi

# --- Git-Check ---
if [ -d "$PROJECT_PATH/.git" ]; then
  echo "Fehler: Das Verzeichnis '$PROJECT_PATH' ist bereits ein Git-Repository."
  echo "Dieses Script nur für neue Projekte ohne .git verwenden."
  exit 1
fi

# --- Repo-Name abfragen (Default: Ordnername) ---
DEFAULT_REPO_NAME="$(basename "$PROJECT_PATH")"
read -rp "Repo-Name [$DEFAULT_REPO_NAME]: " REPO_NAME
REPO_NAME="${REPO_NAME:-$DEFAULT_REPO_NAME}"

# --- Sichtbarkeit abfragen (y = public, n = private) ---
read -rp "Soll das Repository public sein? (y/n): " PUBLIC_ANSWER
PUBLIC_ANSWER="${PUBLIC_ANSWER,,}"
if [[ "$PUBLIC_ANSWER" == "y" || "$PUBLIC_ANSWER" == "yes" ]]; then
  VISIBILITY="public"
else
  VISIBILITY="private"
fi
echo "Sichtbarkeit: $VISIBILITY"

# --- Git initialisieren und first commit ---
cd "$PROJECT_PATH"
git init
git add .
git commit -m "Initial commit"

# --- Prüfen ob das Repo schon existiert ---
GIT_USER="$(gh api user -q .login)"
REPO_EXISTS=""
if gh repo view "$GIT_USER/$REPO_NAME" >/dev/null 2>&1; then
  REPO_EXISTS="true"
fi

# --- GitHub-Repo erstellen und pushen ---
echo ""
if [ -n "$REPO_EXISTS" ]; then
  echo "Das Repository '$GIT_USER/$REPO_NAME' existiert bereits!"
  read -rp "Wollen Sie das Repository wirklich überschreiben? (y/n): " OVERWRITE
  OVERWRITE="${OVERWRITE,,}"
  if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "yes" ]]; then
    echo "Abgebrochen."
    exit 1
  fi
  echo "Überschreibe Repository '$GIT_USER/$REPO_NAME'..."
  # Bestehendes Repo löschen und neu anlegen
  gh repo delete "$GIT_USER/$REPO_NAME" --yes
  gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --push
else
  echo "Erstelle GitHub-Repository '$REPO_NAME' ($VISIBILITY)..."
  gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --push
fi

echo ""
echo "Fertig! Repository hochgeladen: https://github.com/$GIT_USER/$REPO_NAME"
