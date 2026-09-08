<h1 align="center">🛡️ GitHub Repo Helper</h1>

<p align="center">
  <em>Bash scripts that make sure every local project is actually backed up on GitHub — before your hard drive decides otherwise.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/GitHub_CLI-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub CLI">
  <img src="https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white" alt="Git">
</p>

<p align="center">
  <a href="README.de.md">🇩🇪 Deutsche Version</a>
</p>

---

## 📖 About

A projects folder tends to accumulate work that never made it to a remote. Some
repositories were never pushed, some have uncommitted changes from months ago, and
a few point at the wrong account entirely.

These two scripts find all of that. `github-check.sh` scans a folder of projects
and reports the state of each one against your GitHub account, offering to push
what is missing. `github-upload.sh` handles a single new project from `git init`
to first push.

The goal is backup protection, not repository management: when the disk fails,
nothing should be lost.

## 🛠️ Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| <img src="https://img.shields.io/badge/Bash-4EAA25?style=flat-square&logo=gnubash&logoColor=white" alt="Bash"> Bash | 4.0+ | Associative arrays are required |
| <img src="https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white" alt="Git"> Git | — | Repository state |
| <img src="https://img.shields.io/badge/GitHub_CLI-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub CLI"> GitHub CLI | — | Listing, creating and pushing repositories |

## ✨ Features

- **Batch scanning** — check an entire projects folder in one pass
- **Four distinct statuses** — up to date, dirty, missing, or owned by someone else
- **Interactive** — decide per project whether to push, skip, or stop
- **Foreign-remote detection** — spots repositories pointing at another account
- **Guided upload** — name, visibility, init, commit and push in one flow

## 🚀 Getting Started

### Prerequisites

- **Bash 4.0+** — associative arrays
- **Git**
- **GitHub CLI (`gh`)**, authenticated

### Installing the GitHub CLI

| Platform | Command |
|----------|---------|
| macOS | `brew install gh` |
| Debian / Ubuntu | `sudo apt update && sudo apt install gh` |
| Fedora | `sudo dnf install gh` |
| Windows | `winget install --id GitHub.cli` |

Or download from [cli.github.com](https://cli.github.com/).

### Authentication

```bash
gh auth login
```

Or with a token:

```bash
gh auth login --with-token <<< "ghp_your_token_here"
```

Or as an environment variable:

```bash
export GH_TOKEN="ghp_your_token_here"
```

### Token permissions

| Scope | Required | Purpose |
|-------|----------|---------|
| `repo` | **Yes** | Create, push, list and read private repositories |
| `delete_repo` | Optional | Only if you want `github-upload.sh` to overwrite an existing repository |

### Installation

```bash
git clone https://github.com/cooolinho/github-repo-helper.git
cd github-repo-helper
chmod +x *.sh
```

## 📋 Usage

### 🔍 `github-check.sh` — batch project checker

Scans a folder of project subdirectories and checks each against your GitHub
account.

```bash
./github-check.sh [FOLDER] [--account OWNER]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `FOLDER` | No | Directory containing the projects (default: current directory) |
| `--account OWNER` | No | Override the GitHub username (default: from `gh auth`) |

```bash
./github-check.sh                              # current directory
./github-check.sh ~/projects                   # a specific folder
./github-check.sh ~/projects --account my-user # a specific account
```

#### Statuses

| Status | Meaning |
|--------|---------|
| `[OK]` | On GitHub and up to date |
| `[WARN]` | On GitHub, but with uncommitted files or unpushed commits |
| `[MISSING]` | Not on GitHub — you are prompted to push or skip |
| `[FREMD]` | The remote points at a different GitHub account |

#### Prompts

For every `[MISSING]` project:

- **[P]ush** — create the repository and push
- **[S]kip** — leave it alone
- **[Q]uit** — stop the scan

### ⬆️ `github-upload.sh` — single project uploader

Initializes git and pushes a new project. Works only on directories that are
**not** yet git repositories.

```bash
./github-upload.sh /path/to/project
```

The script will:

1. Ask for a repository name, defaulting to the directory name
2. Ask whether it should be public or private
3. Run `git init` and create an initial commit
4. Create the GitHub repository and push

> ⚠️ If a repository with that name already exists, you are asked to confirm
> before it is **deleted and recreated**. This is the one destructive path in the
> toolset — read the prompt.

## 📁 Project Structure

```
github-repo-helper/
├── github-check.sh    # Batch scanner for a projects folder
└── github-upload.sh   # Single project uploader
```

## 📄 License

Released under the [MIT License](LICENSE).
