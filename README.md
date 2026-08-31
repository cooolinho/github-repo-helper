# GitHub Repo Helper

A set of Bash scripts to manage your local projects on GitHub. The main goal is **backup protection** — ensure every local project is pushed to GitHub so you don't lose data if your hard drive fails.

> **Deutsche Version:** [README.de.md](README.de.md)

## Prerequisites

### 1. Install the GitHub CLI

The scripts require the [GitHub CLI (`gh`)](https://cli.github.com/). Install it for your platform:

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

Or download from: https://cli.github.com/

### 2. Authenticate with GitHub

Log in to your GitHub account using the CLI:

```bash
gh auth login
```

Follow the interactive prompts to choose your authentication method (browser or token).

### 3. Personal Access Token (PAT) — Required Permissions

If you prefer to use a Personal Access Token instead of browser-based login, create one at https://github.com/settings/tokens with the following scopes:

| Scope | Required | Purpose |
|-------|----------|---------|
| `repo` | **Yes** | Full control of private repositories — create, push, list, and delete repos |
| `delete_repo` | Optional | Only needed if you want `github-upload.sh` to overwrite existing repos |

Set the token via:

```bash
gh auth login --with-token <<< "ghp_your_token_here"
```

Or set it as an environment variable:

```bash
export GH_TOKEN="ghp_your_token_here"
```

### 4. Requirements

- **Bash 4.0+** (for associative arrays)
- **Git**
- **GitHub CLI (`gh`)** — authenticated

---

## Scripts

### `github-check.sh` — Batch Project Checker

Scans a folder of project subdirectories and checks each one against your GitHub account. Reports which projects are on GitHub, which have uncommitted/unpushed changes, and which are missing.

#### Usage

```bash
./github-check.sh [FOLDER] [--account OWNER]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `FOLDER` | No | Directory containing project subdirectories (default: current directory) |
| `--account OWNER` | No | Override GitHub username (default: auto-detected from `gh auth`) |

#### Examples

**Check all projects in the current directory:**

```bash
./github-check.sh
```

**Check all projects in a specific folder:**

```bash
./github-check.sh ~/projects
```

**Check against a specific GitHub account:**

```bash
./github-check.sh ~/projects --account my-username
```

#### Output Statuses

| Status | Meaning |
|--------|---------|
| `[OK]` | Project is on GitHub and up to date |
| `[WARN]` | Project is on GitHub but has uncommitted files or unpushed commits |
| `[MISSING]` | Project is not on GitHub (interactive prompt to push or skip) |
| `[FREMD]` | Remote points to a different GitHub account (foreign) |

#### Interactive Prompts

For each `[MISSING]` project, you'll be prompted:

- **[P]ush** — Create the repo on GitHub and push
- **[S]kip** — Skip this project
- **[Q]uit** — Stop checking

---

### `github-upload.sh` — Single Project Uploader

A simple script to initialize git and push a new project to GitHub. Only works on directories that are **not** yet git repositories.

#### Usage

```bash
./github-upload.sh /path/to/project
```

#### Examples

**Upload a new project:**

```bash
./github-upload.sh ~/projects/my-new-app
```

The script will:

1. Prompt for a repository name (defaults to the directory name)
2. Ask if the repo should be public or private
3. Initialize git, create an initial commit
4. Create the GitHub repository and push

> **Note:** If a repository with the same name already exists on GitHub, you'll be asked to confirm before it is deleted and recreated.

---

## License

MIT
