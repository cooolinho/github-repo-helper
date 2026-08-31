#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# github-check.sh
# Prüft für alle Projekte in einem Ordner, ob sie bereits im
# GitHub-Konto liegen und ob es uncommittete/unpushed Änderungen
# gibt. Fehlende Projekte werden einzeln abgefragt (push/skip).
#
# Zweck: Backup-Schutz - alle lokalen Projekte auf GitHub sichern,
# falls Computer/Festplatte kaputtgehen.
#
# Voraussetzung: gh CLI ist installiert und eingeloggt.
# Nutzung:  $0 [ORDNER] [--account OWNER]
# ============================================================

# --- Argumente parsen ---
BASE=""
GH_USER=""

# Optional: --account OWNER übersteuert das GitHub-Konto.
# Das erste Nicht-Option-Argument ist der Ziel-Ordner.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --account)
      GH_USER="$2"
      shift 2
      ;;
    -h|--help)
      echo "Nutzung: $0 [ORDNER] [--account OWNER]"
      echo "  ORDNER      Ordner mit Projekt-Unterordnern (Default: aktuelles Verzeichnis)"
      echo "  --account   GitHub-Kontoname (Default: aus gh-Login)"
      exit 0
      ;;
    -*)
      echo "Unbekannte Option: $1"
      echo "Nutzung: $0 [ORDNER] [--account OWNER]"
      exit 1
      ;;
    *)
      if [ -z "$BASE" ]; then
        BASE="$1"
      fi
      shift
      ;;
  esac
done
BASE="${BASE:-$PWD}"

# --- Preflight: gh vorhanden & eingeloggt ---
if ! command -v gh >/dev/null 2>&1; then
  echo "Fehler: 'gh' CLI ist nicht installiert."
  echo "Installiere sie über https://cli.github.com/ und logge dich ein."
  exit 1
fi

if [[ -z "$GH_USER" ]]; then
  if ! GH_USER="$(gh api user -q .login 2>/dev/null)"; then
    echo "Fehler: Nicht bei GitHub eingeloggt. Bitte 'gh auth login' ausführen."
    exit 1
  fi
fi
echo "GitHub-Konto: $GH_USER"

# --- Ziel-Ordner validieren ---
BASE="$(realpath "$BASE")"
if [ ! -d "$BASE" ]; then
  echo "Fehler: Das Verzeichnis '$BASE' existiert nicht."
  echo "Nutzung: $0 [ORDNER] [--account OWNER]"
  exit 1
fi

# --- Repo-Liste des Kontos einmalig laden ---
# Alle Repo-Namen des Kontos in ein Assotiative-Array als Set.
declare -A ACCOUNT_REPOS=()
if ACCOUNT_RAW="$(gh repo list "$GH_USER" --limit 1000 --json name --jq '.[].name' 2>/dev/null)"; then
  while IFS= read -r r; do
    [ -n "$r" ] && ACCOUNT_REPOS["$r"]=1
  done <<< "$ACCOUNT_RAW"
fi
echo "Repos im Konto geladen: ${#ACCOUNT_REPOS[@]}"

# --- Hilfsfunktion: Existiert Repo owner/name im Konto? ---
repo_exists() {
  local name="$1"
  # Set-Lookup; Fallback auf gh-Frage, falls das Set leer ist (API-Page-Fehler).
  if [[ ${#ACCOUNT_REPOS[@]} -gt 0 ]]; then
    [[ -n "${ACCOUNT_REPOS[$name]:-}" ]]
  else
    gh repo view "$GH_USER/$name" >/dev/null 2>&1
  fi
}

# --- GitHub-URL parsen: gibt "owner/name" zurück oder leer ---
parse_github_ref() {
  local url="$1" out="" name=""
  # git@github.com:owner/name.git   oder
  # https://github.com/owner/name.git
  if [[ "$url" =~ ^git@github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
    :
  elif [[ "$url" =~ ^https?://github\.com/([^/]+)/([^/]+)(\.git)?$ ]]; then
    :
  else
    printf '%s' ""
    return
  fi
  name="${BASH_REMATCH[2]}"
  name="${name%.git}"
  printf '%s/%s' "${BASH_REMATCH[1]}" "$name"
}

# --- Git-Zustand eines Projekts ermitteln ---
# Liefert über globale Variablen:
#   GIT_NUM_DIRTY = Anzahl uncommitteter Dateien (0 = sauber)
#   GIT_AHEAD     = Anzahl unpushed Commits (-1 = kein Upstream)
git_state() {
  local d="$1"
  GIT_NUM_DIRTY=0
  GIT_AHEAD=-1

  # Uncommittete Dateien zählen
  if [[ -d "$d/.git" ]]; then
    local dirty
    if dirty="$(git -C "$d" status --porcelain 2>/dev/null)"; then
      [ -n "$dirty" ] && GIT_NUM_DIRTY="$(wc -l <<< "$dirty")"
      GIT_NUM_DIRTY="${GIT_NUM_DIRTY//[[:space:]]/}"
      [ -z "$GIT_NUM_DIRTY" ] && GIT_NUM_DIRTY=0
    fi
  fi

  # Unpushed Commits (ahead) via upstream; ohne Upstream aber mit origin-Remote
  # gilt: alle lokalen Commits sind (noch) nicht auf GitHub gepusht.
  if [[ -d "$d/.git" ]]; then
    if git -C "$d" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
      local ahead
      if ahead="$(git -C "$d" rev-list --left-right --count HEAD...'@{u}' 2>/dev/null)"; then
        # Format: "ahead\tbehind"
        ahead="${ahead%%$'\t'*}"
        ahead="${ahead//[[:space:]]/}"
        GIT_AHEAD="${ahead:-0}"
      fi
    elif [ -n "$(git -C "$d" config --get remote.origin.url 2>/dev/null || true)" ]; then
      # Remote vorhanden, aber kein Upstream gesetzt → lokale Commits unpushed
      local n
      if n="$(git -C "$d" rev-list --count HEAD 2>/dev/null || true)"; then
        n="${n//[[:space:]]/}"
        [ -n "$n" ] && GIT_AHEAD="$n"
      fi
      [ "$GIT_AHEAD" -eq -1 ] && GIT_AHEAD=0
    fi
  fi
}

# --- Zähler für die Zusammenfassung ---
declare -i CNT_OK=0 CNT_DIRTY=0 CNT_AHEAD=0 CNT_MISSING=0
declare -i CNT_PUSHED=0 CNT_SKIPPED=0 CNT_FOREIGN=0

echo ""
echo "=== Prüfe Projekte in: $BASE ==="
echo ""

# --- Jedes Projekt (Unterordner) durchgehen ---
shopt -s nullglob
for dir in "$BASE"/*/; do
  dir="${dir%/}"
  PROJ="$(basename "$dir")"

  # Symlinks/physische Dateien ignorieren → nur echte Verzeichnisse
  [ -d "$dir" ] || continue

  # --- Remote + Existenz bestimmen ---
  REMOTE_REF=""          # "owner/name" falls GitHub-Remote
  REMOTE_FOREIGN=""      # "owner" falls Remote gehört aber fremd
  IS_REPO=0              # hat .git
  REMOTE_NAME=""         # Repo-Name (ohne owner) zum Existenz-Check

  if [[ -d "$dir/.git" ]]; then
    IS_REPO=1
    local_url="$(git -C "$dir" config --get remote.origin.url 2>/dev/null || true)"
    if [ -n "$local_url" ]; then
      parsed="$(parse_github_ref "$local_url")"
      if [ -n "$parsed" ]; then
        owner="${parsed%%/*}"
        name="${parsed#*/}"
        REMOTE_NAME="$name"
        if [ "$owner" = "$GH_USER" ]; then
          REMOTE_REF="$parsed"
        else
          REMOTE_FOREIGN="$owner"
        fi
      fi
    fi
  fi

  # Existenz im Konto
  EXISTS=0
  if [ -n "$REMOTE_NAME" ]; then
    repo_exists "$REMOTE_NAME" && EXISTS=1
  elif [ -n "$REMOTE_REF" ]; then
    repo_exists "${REMOTE_REF#*/}" && EXISTS=1
  else
    # Kein GitHub-Remote: Repo-Name = Ordnername falls selber gehostet
    repo_exists "$PROJ" && EXISTS=1
  fi

  # --- Git-Zustand ---
  GIT_NUM_DIRTY=0; GIT_AHEAD=-1
  if [ "$IS_REPO" -eq 1 ]; then
    git_state "$dir"
  fi

  # --- Status klassifizieren & ausgeben ---
  if [[ -n "$REMOTE_FOREIGN" ]]; then
    printf '%-9s %-28s -> fremdes Konto: %s/%s\n' "[FREMD]" "$PROJ" "$REMOTE_FOREIGN" "${REMOTE_NAME:-$PROJ}"
    CNT_FOREIGN+=1
  elif [ "$EXISTS" -eq 1 ]; then
    if [ "$IS_REPO" -eq 1 ] && { [ "$GIT_NUM_DIRTY" -gt 0 ] || [ "$GIT_AHEAD" -gt 0 ]; }; then
      if [ "$GIT_NUM_DIRTY" -gt 0 ] && [ "$GIT_AHEAD" -gt 0 ]; then
        printf '%-9s %-28s -> auf GitHub    %s Datei(en) uncommitted, %s unpushed\n' \
          "[WARN]" "$PROJ" "$GIT_NUM_DIRTY" "$GIT_AHEAD"
        CNT_DIRTY+=1; CNT_AHEAD+=1
      elif [ "$GIT_NUM_DIRTY" -gt 0 ]; then
        printf '%-9s %-28s -> auf GitHub    %s Datei(en) uncommitted\n' "[WARN]" "$PROJ" "$GIT_NUM_DIRTY"
        CNT_DIRTY+=1
      else
        # Nur unpushed Commits (keine uncommitted Dateien) → nachfragen,
        # ob die vorhandenen Commits gepusht werden sollen.
        printf '%-9s %-28s -> auf GitHub    %s unpushed Commit(s)\n' "[WARN]" "$PROJ" "$GIT_AHEAD"
        CNT_AHEAD+=1
        while true; do
          read -rp "  [P]ushen | [S]kip | [Q]uit: " ans
          case "${ans,,}" in
            p|push)
              if git -C "$dir" push >/dev/null 2>&1; then
                printf '%-9s %-28s -> gepusht\n' "[OK]" "$PROJ"
              else
                echo "    Fehler beim Pushen."
              fi
              break
              ;;
            s|skip|"")
              echo "    Übersprungen."
              break
              ;;
            q|quit)
              echo "    Abgebrochen."
              break 2
              ;;
            *)
              echo "    Bitte p, s oder q eingeben."
              ;;
          esac
        done
      fi
    else
      printf '%-9s %-28s -> auf GitHub    sauber\n' "[OK]" "$PROJ"
      CNT_OK+=1
    fi
  else
    # Nicht auf GitHub → einzeln abfragen
    printf '%-9s %-28s -> NICHT auf GitHub' "[MISSING]" "$PROJ"
    [ "$IS_REPO" -eq 0 ] && printf '   (kein Git-Repo)'
    printf '\n'
    CNT_MISSING+=1

    while true; do
      read -rp "  [P]ushen (neu anlegen, public/private) | [S]kip | [Q]uit: " ans
      case "${ans,,}" in
        p|push)
          # --- Neu anlegen + pushen ---
          if [ "$IS_REPO" -eq 0 ]; then
            echo "    Git initialisieren in '$PROJ'..."
            git -C "$dir" init >/dev/null 2>&1
            echo "    Initial commit..."
            git -C "$dir" add .
            git -C "$dir" commit -m "Initial commit" >/dev/null 2>&1
          elif [ -z "$REMOTE_NAME" ]; then
            echo "    (Projekt hat bereits ein Git-Repo, nur kein GitHub-Remote)"
            # Leeres Git-Repo (git init ohne Commit) bekommt einen Initial-Commit,
            # sonst kann kein Branch gepusht werden.
            ncommits="$(git -C "$dir" rev-list --count HEAD 2>/dev/null || true)"
            ncommits="${ncommits//[[:space:]]/}"
            if [ -z "$ncommits" ] || [ "$ncommits" -eq 0 ]; then
              echo "    Leeres Git-Repo - lege Initial-Commit an..."
              git -C "$dir" add .
              git -C "$dir" commit -m "Initial commit" >/dev/null 2>&1 || true
            fi
          fi

          # Sichtbarkeit abfragen (wie github-upload.sh)
          read -rp "    Repo-Name [$PROJ]: " repo_name_inp
          repo_name_inp="${repo_name_inp:-$PROJ}"
          read -rp "    Soll das Repository public sein? (y/n): " pub
          pub="${pub,,}"
          if [[ "$pub" == "y" || "$pub" == "yes" ]]; then
            vis="public"
          else
            vis="private"
          fi
          echo "    Lege an: $GH_USER/$repo_name_inp ($vis)"
          gh repo create "$repo_name_inp" "--$vis" --source="$dir" --remote=origin --push || {
            echo "    Fehler beim Anlegen/Pushen. Überspringe."
            CNT_SKIPPED+=1
            break
          }
          ACCOUNT_REPOS["$repo_name_inp"]=1
          CNT_PUSHED+=1
          printf '%-9s %-28s -> NEU angelegt und gepusht\n' "[OK]" "$PROJ"
          break
          ;;
        s|skip|"")
          echo "    Übersprungen."
          CNT_SKIPPED+=1
          break
          ;;
        q|quit)
          echo "    Abgebrochen."
          # Zusammenfassung trotzdem anzeigen
          break 2
          ;;
        *)
          echo "    Bitte p, s oder q eingeben."
          ;;
      esac
    done
  fi
done

# --- Zusammenfassung ---
echo ""
echo "=== Zusammenfassung ==="
echo "  auf GitHub & sauber:        $CNT_OK"
echo "  mit uncommitted Dateien:    $CNT_DIRTY"
echo "  mit unpushed Commits:       $CNT_AHEAD"
echo "  NICHT auf GitHub:           $CNT_MISSING   (davon gepusht: $CNT_PUSHED, übersprungen: $CNT_SKIPPED)"
echo "  fremdes Konto:              $CNT_FOREIGN"
