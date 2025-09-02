#!/usr/bin/env bash
# plugins/git/plugin.sh - Git integration plugin
set -Eeuo pipefail
IFS=$'\n\t'

# ===== Git Integration Functions =====
git_smart_commit() {
  if ! command -v git >/dev/null 2>&1; then
    sd_die "Git not available"
  fi
  
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    sd_die "Not in a git repository"
  fi
  
  # Check if there are staged changes
  if ! git diff --cached --quiet; then
    local diff_summary="$(git diff --cached --stat)"
    local files_changed="$(echo "$diff_summary" | wc -l)"
    
    sd_log "Staged changes detected ($files_changed files)"
    
    # Generate AI commit message via bridge
    local prompt="Generate a concise git commit message for these changes:

\`\`\`
$diff_summary
\`\`\`

Rules:
- Use conventional commit format (feat:, fix:, docs:, etc.)
- Keep under 50 characters for subject line
- Be specific about what changed
- No generic messages like 'update files'"
    
    sd_log "Generating commit message via AI..."
    local ai_message="$(echo "$prompt" | sd_bridge_send 2>/dev/null | head -n1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
    
    if [[ -n "$ai_message" && "$ai_message" != "Error:"* ]]; then
      echo "Proposed commit message:"
      echo "  $ai_message"
      echo
      read -r -p "Use this message? [Y/n] " confirm
      
      if [[ "$confirm" =~ ^[Nn]$ ]]; then
        read -r -p "Enter commit message: " ai_message
      fi
      
      if [[ -n "$ai_message" ]]; then
        git commit -m "$ai_message"
        sd_log "Commit created successfully"
      else
        sd_warn "Empty commit message, aborting"
      fi
    else
      sd_warn "AI message generation failed, falling back to manual input"
      read -r -p "Enter commit message: " manual_message
      [[ -n "$manual_message" ]] && git commit -m "$manual_message"
    fi
  else
    sd_warn "No staged changes found. Use 'git add' first."
  fi
}

git_status_enhanced() {
  if ! command -v git >/dev/null 2>&1; then
    sd_die "Git not available"
  fi
  
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    sd_die "Not in a git repository"
  fi
  
  echo "=== Git Status ==="
  git status --short --branch
  echo
  
  # Show recent commits
  echo "=== Recent Commits ==="
  git log --oneline -5
  echo
  
  # Show remote info
  echo "=== Remote Info ==="
  local remote="$(git remote -v | head -n1 | awk '{print $2}')"
  [[ -n "$remote" ]] && echo "Remote: $remote" || echo "No remote configured"
  
  # Show stash info
  local stash_count="$(git stash list | wc -l)"
  [[ "$stash_count" -gt 0 ]] && echo "Stashes: $stash_count"
}

git_smart_push() {
  if ! command -v git >/dev/null 2>&1; then
    sd_die "Git not available"
  fi
  
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    sd_die "Not in a git repository"
  fi
  
  local branch="$(git branch --show-current)"
  local remote="$(git remote | head -n1)"
  
  [[ -n "$remote" ]] || sd_die "No remote configured"
  
  # Check if branch exists on remote
  if git ls-remote --heads "$remote" "$branch" | grep -q "$branch"; then
    git push "$remote" "$branch"
  else
    echo "Branch '$branch' doesn't exist on remote '$remote'"
    read -r -p "Create remote branch and push? [Y/n] " confirm
    [[ "$confirm" =~ ^[Nn]$ ]] || git push -u "$remote" "$branch"
  fi
}

git_cleanup() {
  if ! command -v git >/dev/null 2>&1; then
    sd_die "Git not available"
  fi
  
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    sd_die "Not in a git repository"
  fi
  
  echo "=== Git Cleanup ==="
  
  # Prune remote tracking branches
  echo "Pruning remote tracking branches..."
  git remote prune origin 2>/dev/null || true
  
  # List merged branches
  local merged_branches="$(git branch --merged | grep -v '\*\|main\|master\|develop' | xargs)"
  if [[ -n "$merged_branches" ]]; then
    echo "Merged branches found:"
    echo "$merged_branches" | tr ' ' '\n' | sed 's/^/  /'
    echo
    read -r -p "Delete merged branches? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "$merged_branches" | xargs git branch -d
      sd_log "Merged branches deleted"
    fi
  else
    echo "No merged branches to clean up"
  fi
  
  # Garbage collection
  echo "Running git gc..."
  git gc --quiet
  
  sd_log "Git cleanup complete"
}

git_init_repo() {
  local repo_name="${1:-$(basename "$PWD")}"
  
  if git rev-parse --git-dir >/dev/null 2>&1; then
    sd_warn "Already in a git repository"
    return 0
  fi
  
  echo "Initializing git repository: $repo_name"
  git init
  
  # Create .gitignore if it doesn't exist
  if [[ ! -f .gitignore ]]; then
    cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.env
.env.*

# Logs
*.log
logs/

# Runtime
*.pid
*.pid.*

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Build
dist/
build/
*.tgz
EOF
    echo "Created .gitignore"
  fi
  
  # Create README if it doesn't exist
  if [[ ! -f README.md ]]; then
    cat > README.md << EOF
# $repo_name

Description of your project here.

## Setup

\`\`\`bash
# Installation instructions
\`\`\`

## Usage

\`\`\`bash
# Usage examples
\`\`\`
EOF
    echo "Created README.md"
  fi
  
  git add .gitignore README.md
  git commit -m "Initial commit"
  
  sd_log "Repository initialized successfully"
}

# ===== Register Commands =====
sd_register "git:commit" "AI-generated commit messages" git_smart_commit
sd_register "git:status" "Enhanced git status with recent commits" git_status_enhanced
sd_register "git:push" "Smart push with remote branch creation" git_smart_push
sd_register "git:cleanup" "Clean up merged branches and run gc" git_cleanup
sd_register "git:init" "Initialize repository with templates" git_init_repo
