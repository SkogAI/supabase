#!/bin/bash
set -e

# Label Creation Script for GitHub Repository
# This script creates all predefined labels for the repository

REPO="SkogAI/supabase"

echo "=========================================="
echo "GitHub Label Creation Script"
echo "Repository: $REPO"
echo "=========================================="
echo ""

# Check if gh CLI is available
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "❌ Error: Not authenticated with GitHub"
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Function to create a label (updates if exists)
create_label() {
    local name="$1"
    local color="$2"
    local description="$3"

    echo "Creating label: $name"
    if gh label list --repo "$REPO" --json name --jq '.[] | .name' | grep -Fxq "$name"; then
        gh label edit "$name" \
            --repo "$REPO" \
            --color "$color" \
            --description "$description"
    else
        gh label create "$name" \
            --repo "$REPO" \
            --color "$color" \
            --description "$description"
    fi
}

echo "Creating Priority Labels..."
create_label "high-priority" "d73a4a" "Critical issues that block progress or security concerns"
create_label "medium-priority" "fbca04" "Important but not blocking"
create_label "low-priority" "0e8a16" "Nice to have improvements"
echo ""

echo "Creating Type Labels..."
create_label "bug" "d73a4a" "Something isn't working"
create_label "enhancement" "a2eeef" "New feature or request"
create_label "documentation" "0075ca" "Documentation improvements"
create_label "security" "d73a4a" "Security-related issues"
create_label "devops" "d876e3" "Infrastructure and CI/CD"
create_label "database" "c5def5" "Database-related tasks"
create_label "edge-functions" "bfdadc" "Edge function development"
create_label "testing" "bfd4f2" "Testing improvements"
echo ""

echo "Creating Status Labels..."
create_label "triage" "d876e3" "Needs review and prioritization"
create_label "in-progress" "fbca04" "Currently being worked on"
create_label "blocked" "d73a4a" "Cannot proceed due to dependencies"
create_label "needs-review" "0075ca" "Awaiting code review"
create_label "help-wanted" "008672" "Extra attention is needed"
create_label "good-first-issue" "7057ff" "Good for newcomers"
create_label "duplicate" "cfd3d7" "Issue already exists elsewhere"
create_label "wontfix" "ffffff" "Will not be implemented"
echo ""

echo "Creating Component Labels..."
create_label "storage" "e99695" "Supabase Storage"
create_label "realtime" "f9d0c4" "Supabase Realtime"
create_label "migration" "c5def5" "Database migrations"
create_label "monitoring" "5319e7" "Monitoring and alerting"
create_label "rls" "c5def5" "Row Level Security"
create_label "ci-cd" "d876e3" "CI/CD pipelines"
create_label "infrastructure" "d876e3" "Infrastructure changes"
echo ""

echo "=========================================="
echo "✅ Label creation complete!"
echo "=========================================="
echo ""
echo "View labels at: https://github.com/$REPO/labels"
echo ""
