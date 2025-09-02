#!/usr/bin/env bash
# plugins/quality/plugin.sh - Code quality and linting plugin
set -Eeuo pipefail
IFS=$'\n\t'

# ===== Quality Check Functions =====
quality_check() {
  echo "🔍 Running code quality checks..."
  local issues=0
  
  # Node.js/JavaScript projects
  if [[ -f "package.json" ]]; then
    echo
    echo "📦 Node.js project detected"
    
    # ESLint
    if [[ -f "eslint.config.js" ]] || [[ -f ".eslintrc.*" ]] || grep -q "eslint" package.json 2>/dev/null; then
      echo "  Running ESLint..."
      if npm run lint 2>/dev/null || npx eslint . 2>/dev/null; then
        echo "  ✓ ESLint passed"
      else
        echo "  ✗ ESLint issues found"
        ((issues++))
      fi
    fi
    
    # Prettier
    if [[ -f ".prettierrc.*" ]] || grep -q "prettier" package.json 2>/dev/null; then
      echo "  Checking Prettier formatting..."
      if npm run format:check 2>/dev/null || npx prettier --check . 2>/dev/null; then
        echo "  ✓ Prettier formatting OK"
      else
        echo "  ⚠ Prettier formatting issues (run 'npm run format' to fix)"
        ((issues++))
      fi
    fi
    
    # TypeScript
    if [[ -f "tsconfig.json" ]]; then
      echo "  Running TypeScript compiler..."
      if npx tsc --noEmit 2>/dev/null; then
        echo "  ✓ TypeScript compilation OK"
      else
        echo "  ✗ TypeScript errors found"
        ((issues++))
      fi
    fi
    
    # Tests
    if grep -q "\"test\":" package.json 2>/dev/null; then
      echo "  Running tests..."
      if npm test 2>/dev/null; then
        echo "  ✓ Tests passed"
      else
        echo "  ✗ Test failures"
        ((issues++))
      fi
    fi
  fi
  
  # Python projects
  if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
    echo
    echo "🐍 Python project detected"
    
    # Flake8
    if command -v flake8 >/dev/null 2>&1; then
      echo "  Running flake8..."
      if flake8 . 2>/dev/null; then
        echo "  ✓ Flake8 passed"
      else
        echo "  ✗ Flake8 issues found"
        ((issues++))
      fi
    fi
    
    # Black (if available)
    if command -v black >/dev/null 2>&1; then
      echo "  Checking Black formatting..."
      if black --check . 2>/dev/null; then
        echo "  ✓ Black formatting OK"
      else
        echo "  ⚠ Black formatting issues (run 'black .' to fix)"
        ((issues++))
      fi
    fi
    
    # pytest
    if command -v pytest >/dev/null 2>&1; then
      echo "  Running pytest..."
      if pytest -q 2>/dev/null; then
        echo "  ✓ Tests passed"
      else
        echo "  ✗ Test failures"
        ((issues++))
      fi
    fi
  fi
  
  # Go projects
  if [[ -f "go.mod" ]]; then
    echo
    echo "🐹 Go project detected"
    
    echo "  Running go vet..."
    if go vet ./... 2>/dev/null; then
      echo "  ✓ Go vet passed"
    else
      echo "  ✗ Go vet issues found"
      ((issues++))
    fi
    
    echo "  Running go fmt..."
    local unformatted="$(gofmt -l . 2>/dev/null || true)"
    if [[ -z "$unformatted" ]]; then
      echo "  ✓ Go formatting OK"
    else
      echo "  ⚠ Go formatting issues in:"
      echo "$unformatted" | sed 's/^/    /'
      ((issues++))
    fi
    
    # Go tests
    if ls *_test.go >/dev/null 2>&1; then
      echo "  Running go test..."
      if go test ./... 2>/dev/null; then
        echo "  ✓ Tests passed"
      else
        echo "  ✗ Test failures"
        ((issues++))
      fi
    fi
  fi
  
  # Rust projects
  if [[ -f "Cargo.toml" ]]; then
    echo
    echo "🦀 Rust project detected"
    
    echo "  Running cargo check..."
    if cargo check --quiet 2>/dev/null; then
      echo "  ✓ Cargo check passed"
    else
      echo "  ✗ Cargo check issues found"
      ((issues++))
    fi
    
    echo "  Running cargo fmt..."
    if cargo fmt --check 2>/dev/null; then
      echo "  ✓ Rust formatting OK"
    else
      echo "  ⚠ Rust formatting issues (run 'cargo fmt' to fix)"
      ((issues++))
    fi
    
    echo "  Running cargo clippy..."
    if cargo clippy --quiet -- -D warnings 2>/dev/null; then
      echo "  ✓ Clippy passed"
    else
      echo "  ✗ Clippy issues found"
      ((issues++))
    fi
  fi
  
  # Shell scripts
  if command -v shellcheck >/dev/null 2>&1; then
    local shell_files="$(find . -name "*.sh" -type f 2>/dev/null | head -20)"
    if [[ -n "$shell_files" ]]; then
      echo
      echo "🐚 Shell scripts detected"
      echo "  Running shellcheck..."
      if echo "$shell_files" | xargs shellcheck 2>/dev/null; then
        echo "  ✓ Shellcheck passed"
      else
        echo "  ✗ Shellcheck issues found"
        ((issues++))
      fi
    fi
  fi
  
  echo
  if [[ $issues -eq 0 ]]; then
    echo "✅ Quality check completed - no issues found!"
  else
    echo "⚠️  Quality check completed with $issues issue(s) found"
    echo "   Run 'sd quality:fix' to automatically fix some issues"
  fi
}

quality_fix() {
  echo "🔧 Attempting to fix code quality issues..."
  
  # Node.js/JavaScript projects
  if [[ -f "package.json" ]]; then
    # Prettier
    if [[ -f ".prettierrc.*" ]] || grep -q "prettier" package.json 2>/dev/null; then
      echo "  Fixing Prettier formatting..."
      npm run format 2>/dev/null || npx prettier --write . 2>/dev/null || true
    fi
    
    # ESLint with --fix
    if [[ -f "eslint.config.js" ]] || [[ -f ".eslintrc.*" ]] || grep -q "eslint" package.json 2>/dev/null; then
      echo "  Running ESLint --fix..."
      npx eslint --fix . 2>/dev/null || true
    fi
  fi
  
  # Python projects
  if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    # Black
    if command -v black >/dev/null 2>&1; then
      echo "  Running Black formatter..."
      black . 2>/dev/null || true
    fi
    
    # isort (if available)
    if command -v isort >/dev/null 2>&1; then
      echo "  Running isort..."
      isort . 2>/dev/null || true
    fi
  fi
  
  # Go projects
  if [[ -f "go.mod" ]]; then
    echo "  Running go fmt..."
    go fmt ./... 2>/dev/null || true
    
    # go mod tidy
    echo "  Running go mod tidy..."
    go mod tidy 2>/dev/null || true
  fi
  
  # Rust projects
  if [[ -f "Cargo.toml" ]]; then
    echo "  Running cargo fmt..."
    cargo fmt 2>/dev/null || true
  fi
  
  echo "✅ Auto-fix completed. Run 'sd quality:check' to verify."
}

quality_report() {
  local output_file="${1:-quality_report.md}"
  
  echo "📊 Generating quality report..."
  
  cat > "$output_file" << EOF
# Code Quality Report

Generated: $(date)
Project: $(basename "$PWD")

## Summary

EOF
  
  # Project detection
  echo "## Project Type" >> "$output_file"
  echo >> "$output_file"
  
  if [[ -f "package.json" ]]; then
    echo "- Node.js/JavaScript project" >> "$output_file"
    local pkg_name="$(jq -r '.name // "unknown"' package.json 2>/dev/null || echo "unknown")"
    local pkg_version="$(jq -r '.version // "unknown"' package.json 2>/dev/null || echo "unknown")"
    echo "  - Package: $pkg_name@$pkg_version" >> "$output_file"
  fi
  
  if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    echo "- Python project" >> "$output_file"
  fi
  
  if [[ -f "go.mod" ]]; then
    echo "- Go project" >> "$output_file"
    local go_mod="$(head -1 go.mod 2>/dev/null | cut -d' ' -f2 || echo "unknown")"
    echo "  - Module: $go_mod" >> "$output_file"
  fi
  
  if [[ -f "Cargo.toml" ]]; then
    echo "- Rust project" >> "$output_file"
  fi
  
  echo >> "$output_file"
  
  # File counts
  echo "## File Statistics" >> "$output_file"
  echo >> "$output_file"
  
  local total_files="$(find . -type f | wc -l)"
  local code_files="$(find . -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.sh" | wc -l)"
  local total_lines="$(find . -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.sh" | xargs wc -l 2>/dev/null | tail -n1 | awk '{print $1}' || echo "0")"
  
  echo "- Total files: $total_files" >> "$output_file"
  echo "- Code files: $code_files" >> "$output_file"
  echo "- Total lines of code: $total_lines" >> "$output_file"
  
  echo >> "$output_file"
  echo "## Tools Used" >> "$output_file"
  echo >> "$output_file"
  
  # List available tools
  for tool in eslint prettier flake8 black go golangci-lint cargo shellcheck; do
    if command -v "$tool" >/dev/null 2>&1; then
      echo "- ✓ $tool" >> "$output_file"
    else
      echo "- ✗ $tool (not installed)" >> "$output_file"
    fi
  done
  
  echo >> "$output_file"
  echo "## Recommendations" >> "$output_file"
  echo >> "$output_file"
  echo "1. Run \`sd quality:check\` regularly" >> "$output_file"
  echo "2. Set up pre-commit hooks for automated checks" >> "$output_file"
  echo "3. Configure CI/CD to run quality checks" >> "$output_file"
  echo "4. Consider adding missing tools for comprehensive coverage" >> "$output_file"
  
  sd_log "Quality report generated: $output_file"
  
  # Show first few lines
  echo
  echo "Report preview:"
  head -n 20 "$output_file" | sed 's/^/  /'
}

quality_setup() {
  echo "⚙️  Setting up quality tools for this project..."
  
  # Node.js setup
  if [[ -f "package.json" ]] && ! grep -q "eslint" package.json 2>/dev/null; then
    read -r -p "Install ESLint and Prettier? [Y/n] " confirm
    if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
      npm install --save-dev eslint prettier @eslint/js 2>/dev/null || true
      echo "  ✓ ESLint and Prettier installed"
      
      # Create basic eslint config if not exists
      if [[ ! -f "eslint.config.js" ]] && [[ ! -f ".eslintrc.*" ]]; then
        cat > eslint.config.js << 'EOF'
import js from "@eslint/js";

export default [
  js.configs.recommended,
  {
    files: ["**/*.js", "**/*.mjs"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "module"
    },
    rules: {
      "no-console": "warn",
      "no-unused-vars": ["error", { "argsIgnorePattern": "^_" }]
    }
  }
];
EOF
        echo "  ✓ Created eslint.config.js"
      fi
      
      # Create prettier config if not exists
      if [[ ! -f ".prettierrc.*" ]]; then
        cat > .prettierrc.json << 'EOF'
{
  "semi": true,
  "singleQuote": false,
  "trailingComma": "es5",
  "printWidth": 100
}
EOF
        echo "  ✓ Created .prettierrc.json"
      fi
      
      # Add scripts to package.json if not exists
      local pkg_content="$(cat package.json)"
      if ! echo "$pkg_content" | grep -q '"lint"'; then
        local new_content="$(echo "$pkg_content" | jq '.scripts.lint = "eslint ."')"
        echo "$new_content" > package.json
      fi
      if ! echo "$pkg_content" | grep -q '"format"'; then
        local new_content="$(cat package.json | jq '.scripts.format = "prettier --write ."')"
        echo "$new_content" > package.json
      fi
      echo "  ✓ Added npm scripts"
    fi
  fi
  
  # Python setup
  if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
    if ! command -v flake8 >/dev/null 2>&1 || ! command -v black >/dev/null 2>&1; then
      read -r -p "Install Python quality tools (flake8, black)? [Y/n] " confirm
      if [[ ! "$confirm" =~ ^[Nn]$ ]]; then
        pip install flake8 black isort 2>/dev/null || echo "  ⚠ Failed to install Python tools"
      fi
    fi
    
    # Create .flake8 if not exists
    if [[ ! -f ".flake8" ]] && [[ ! -f "setup.cfg" ]]; then
      cat > .flake8 << 'EOF'
[flake8]
max-line-length = 88
extend-ignore = E203, W503
EOF
      echo "  ✓ Created .flake8 config"
    fi
  fi
  
  echo "✅ Quality tools setup completed"
  echo "   Run 'sd quality:check' to verify configuration"
}

# ===== Register Commands =====
sd_register "quality:check" "Multi-language code quality check" quality_check
sd_register "quality:fix" "Auto-fix formatting issues" quality_fix
sd_register "quality:report" "Generate quality report" quality_report
sd_register "quality:setup" "Setup quality tools for project" quality_setup
