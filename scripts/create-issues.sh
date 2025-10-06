#!/bin/bash
set -e

# Issue Creation Script for Supabase Repository
# This script documents the issues that should be created for tracking project tasks

REPO="SkogAI/supabase"

echo "=========================================="
echo "GitHub Issue Creation Script"
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

# Function to create an issue
create_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"
    
    echo "Creating issue: $title"
    # Split labels on commas and build --label arguments
    local label_args=()
    IFS=',' read -ra label_array <<< "$labels"
    for label in "${label_array[@]}"; do
        # Trim whitespace from label
        label="$(echo "$label" | xargs)"
        if [[ -n "$label" ]]; then
            label_args+=(--label "$label")
        fi
    done
    gh issue create \
        --repo "$REPO" \
        --title "$title" \
        --body "$body" \
        "${label_args[@]}" || echo "⚠️  Failed to create issue: $title"
    echo ""
}

# Issue 1: Storage Buckets Configuration
read -r -d '' ISSUE_1_BODY << 'EOF' || true
## Description
Configure Supabase Storage buckets for file uploads and implement appropriate RLS policies.

## Tasks
- [ ] Define storage bucket structure
- [ ] Create buckets for different file types (e.g., avatars, documents, images)
- [ ] Configure bucket policies (public/private)
- [ ] Add RLS policies for storage objects
- [ ] Create upload/download helper functions
- [ ] Add storage documentation
- [ ] Test file upload/download flows

## Acceptance Criteria
- [ ] Storage buckets created and configured
- [ ] RLS policies prevent unauthorized access
- [ ] File upload/download works as expected
- [ ] Documentation updated with storage usage examples

## Priority
Medium - Required for file handling features

## References
- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
- See `SETUP_COMPLETE.md` for initial context
EOF

# Issue 2: Database Performance Monitoring
read -r -d '' ISSUE_2_BODY << 'EOF' || true
## Description
Implement database performance monitoring to track query performance and identify optimization opportunities.

## Tasks
- [ ] Set up pg_stat_statements extension
- [ ] Create monitoring dashboard queries
- [ ] Add slow query logging
- [ ] Identify commonly used queries for indexing
- [ ] Create performance baseline metrics
- [ ] Set up alerting for performance issues
- [ ] Document monitoring procedures

## Acceptance Criteria
- [ ] Performance metrics are being tracked
- [ ] Slow queries are identified and logged
- [ ] Baseline performance documented
- [ ] Optimization recommendations documented

## Priority
Low - Nice to have for production monitoring

## References
- [PostgreSQL Performance](https://www.postgresql.org/docs/current/monitoring-stats.html)
- See `DEVOPS.md` for related workflows
EOF

# Issue 3: Realtime Subscriptions Configuration
read -r -d '' ISSUE_3_BODY << 'EOF' || true
## Description
Configure Supabase Realtime for tables that need live updates and subscriptions.

## Tasks
- [ ] Identify tables that need realtime updates
- [ ] Enable realtime on required tables
- [ ] Configure publication settings
- [ ] Create example subscription code
- [ ] Test realtime updates
- [ ] Add realtime to edge functions (if needed)
- [ ] Document realtime patterns and best practices

## Acceptance Criteria
- [ ] Realtime enabled on appropriate tables
- [ ] Subscriptions working correctly
- [ ] Example code provided
- [ ] Performance impact assessed
- [ ] Documentation updated

## Priority
Low - Optional feature for real-time updates

## References
- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- See `SETUP_COMPLETE.md` for context
EOF

# Issue 4: Expand RLS Policies for Production
read -r -d '' ISSUE_4_BODY << 'EOF' || true
## Description
Review and expand Row Level Security policies for production use cases.

## Tasks
- [ ] Review existing RLS policies in `docs/RLS_POLICIES.md`
- [ ] Identify additional security requirements
- [ ] Add policies for new tables (as they're created)
- [ ] Test policies with different user scenarios
- [ ] Audit policies for edge cases
- [ ] Document any policy changes
- [ ] Run comprehensive RLS test suite

## Acceptance Criteria
- [ ] All tables have appropriate RLS policies
- [ ] Policies tested with real-world scenarios
- [ ] No data leakage or unauthorized access
- [ ] Security audit passed
- [ ] Documentation updated

## Priority
High - Critical for production security

## References
- See `docs/RLS_POLICIES.md` for existing policies
- See `docs/RLS_TESTING.md` for testing guide
- Run tests with: `npm run test:rls`
EOF

# Issue 5: Edge Functions - Production Examples
read -r -d '' ISSUE_5_BODY << 'EOF' || true
## Description
Create production-ready edge function examples beyond the hello-world template.

## Tasks
- [ ] Create example: API webhook handler
- [ ] Create example: Data processing function
- [ ] Create example: Email notification function
- [ ] Create example: File processing function
- [ ] Add comprehensive error handling
- [ ] Add rate limiting examples
- [ ] Document best practices
- [ ] Add integration tests for each example

## Acceptance Criteria
- [ ] At least 3 production-ready examples created
- [ ] Each example has tests
- [ ] Documentation covers common use cases
- [ ] Error handling demonstrates best practices
- [ ] Performance considerations documented

## Priority
Medium - Helpful for developers building features

## References
- See `supabase/functions/README.md` for current documentation
- See `supabase/functions/hello-world/` for example structure
EOF

# Issue 6: GitHub Actions Secrets Configuration
read -r -d '' ISSUE_6_BODY << 'EOF' || true
## Description
Configure required GitHub Actions secrets for CI/CD workflows to function properly.

## Required Secrets
The following secrets must be configured in GitHub Settings → Secrets and variables → Actions:

- `SUPABASE_ACCESS_TOKEN` - For Supabase CLI authentication
- `SUPABASE_PROJECT_ID` - Your project ID
- `SUPABASE_DB_PASSWORD` - Database password for remote connections

## Tasks
- [ ] Obtain Supabase access token
- [ ] Find project ID from Supabase dashboard
- [ ] Set database password (if not already set)
- [ ] Add all secrets to GitHub
- [ ] Test deployment workflow
- [ ] Test migration validation workflow
- [ ] Verify all workflows can authenticate
- [ ] Document secret rotation process

## Acceptance Criteria
- [ ] All required secrets configured
- [ ] CI/CD workflows passing
- [ ] Deployments working
- [ ] Documentation updated with secret management info

## Priority
High - Required for CI/CD to work

## References
- See `DEVOPS.md` section "Required GitHub Secrets"
- [Supabase Access Tokens](https://supabase.com/dashboard/account/tokens)
EOF

# Issue 7: Testing Framework Enhancement
read -r -d '' ISSUE_7_BODY << 'EOF' || true
## Description
Enhance the testing framework with additional test coverage and CI integration.

## Tasks
- [ ] Add integration tests for database operations
- [ ] Add end-to-end tests for critical flows
- [ ] Set up test coverage reporting
- [ ] Add performance tests
- [ ] Create test data factories
- [ ] Add API endpoint tests
- [ ] Configure automated test runs in CI
- [ ] Document testing guidelines

## Acceptance Criteria
- [ ] Test coverage > 80% for critical paths
- [ ] Integration tests running in CI
- [ ] Test documentation complete
- [ ] Performance benchmarks established
- [ ] Tests pass consistently

## Priority
Medium - Important for code quality

## References
- See `tests/README.md` for current test setup
- See `.github/workflows/` for CI configuration
EOF

# Issue 8: Custom Database Schemas Enhancement
read -r -d '' ISSUE_8_BODY << 'EOF' || true
## Description
Review and enhance custom database schemas, enums, and composite types.

## Tasks
- [ ] Review existing custom types in `SCHEMA_ORGANIZATION.md`
- [ ] Identify additional types needed for the application
- [ ] Create enums for status fields
- [ ] Create composite types for complex data
- [ ] Add validation functions
- [ ] Document all custom types
- [ ] Add migration for new types
- [ ] Update TypeScript type generation

## Acceptance Criteria
- [ ] Custom types properly organized
- [ ] All types documented
- [ ] Types used consistently across schema
- [ ] TypeScript types generated correctly
- [ ] Migration tested

## Priority
Medium - Helps with data consistency

## References
- See `SCHEMA_ORGANIZATION.md` for existing types
- See `supabase/migrations/` for current schema
EOF

# Issue 9: Documentation Review and Updates
read -r -d '' ISSUE_9_BODY << 'EOF' || true
## Description
Comprehensive review and update of all project documentation.

## Tasks
- [ ] Review README.md for accuracy
- [ ] Update DEVOPS.md with any new workflows
- [ ] Review all docs/ files for outdated information
- [ ] Add missing API documentation
- [ ] Create developer onboarding guide
- [ ] Add troubleshooting guides
- [ ] Update code examples
- [ ] Add architecture diagrams

## Acceptance Criteria
- [ ] All documentation reviewed and updated
- [ ] No broken links
- [ ] Examples tested and working
- [ ] Onboarding guide complete
- [ ] Architecture documented

## Priority
Medium - Important for team collaboration

## References
- All `.md` files in repository
- See `docs/` directory
EOF

# Issue 10: Security Audit and Hardening
read -r -d '' ISSUE_10_BODY << 'EOF' || true
## Description
Perform comprehensive security audit and implement hardening measures.

## Tasks
- [ ] Review all RLS policies for vulnerabilities
- [ ] Audit environment variable usage
- [ ] Check for hardcoded secrets
- [ ] Review CORS configuration
- [ ] Test authentication flows
- [ ] Review edge function security
- [ ] Set up security scanning alerts
- [ ] Document security best practices
- [ ] Create incident response plan

## Acceptance Criteria
- [ ] Security audit completed
- [ ] All vulnerabilities addressed
- [ ] Security checklist created
- [ ] Automated security scanning enabled
- [ ] Team trained on security practices

## Priority
High - Critical for production deployment

## References
- See `SETUP_COMPLETE.md` Security Checklist
- See `.github/workflows/security-scan.yml`
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
EOF

# Issue 11: Backup and Recovery Procedures
read -r -d '' ISSUE_11_BODY << 'EOF' || true
## Description
Implement comprehensive backup and recovery procedures for production database.

## Tasks
- [ ] Review Supabase backup features
- [ ] Set up automated backup schedule
- [ ] Test backup restoration process
- [ ] Document backup procedures
- [ ] Create disaster recovery plan
- [ ] Set up backup monitoring
- [ ] Test point-in-time recovery
- [ ] Document RTO and RPO targets

## Acceptance Criteria
- [ ] Automated backups configured
- [ ] Restore process tested and documented
- [ ] Recovery time objectives met
- [ ] Disaster recovery plan complete
- [ ] Team trained on procedures

## Priority
High - Critical for production

## References
- See `.github/workflows/backup.yml`
- [Supabase Backups](https://supabase.com/docs/guides/platform/backups)
EOF

# Issue 12: Monitoring and Alerting Setup
read -r -d '' ISSUE_12_BODY << 'EOF' || true
## Description
Set up comprehensive monitoring and alerting for the Supabase infrastructure.

## Tasks
- [ ] Configure uptime monitoring
- [ ] Set up performance monitoring
- [ ] Create alert rules for critical issues
- [ ] Set up log aggregation
- [ ] Configure notification channels
- [ ] Create monitoring dashboard
- [ ] Document alerting procedures
- [ ] Test alert notifications

## Acceptance Criteria
- [ ] Monitoring dashboard operational
- [ ] Alerts configured for critical metrics
- [ ] Notification channels working
- [ ] Team aware of alerting procedures
- [ ] False positive rate minimized

## Priority
Medium - Important for production operations

## References
- See `DEVOPS.md` for workflow monitoring
- Supabase dashboard for built-in monitoring
EOF

# Ask for confirmation before creating issues
echo "This script will create 12 GitHub issues for tracking project tasks."
echo ""
read -p "Do you want to proceed? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Creating issues..."
echo ""

# Create all issues
create_issue "Configure Storage Buckets" "$ISSUE_1_BODY" "enhancement,storage"
create_issue "Database Performance Monitoring" "$ISSUE_2_BODY" "enhancement,database,monitoring"
create_issue "Configure Realtime Subscriptions" "$ISSUE_3_BODY" "enhancement,realtime"
create_issue "Expand RLS Policies for Production" "$ISSUE_4_BODY" "security,database,high-priority"
create_issue "Edge Functions - Production Examples" "$ISSUE_5_BODY" "enhancement,edge-functions"
create_issue "Configure GitHub Actions Secrets" "$ISSUE_6_BODY" "devops,high-priority"
create_issue "Testing Framework Enhancement" "$ISSUE_7_BODY" "enhancement,testing"
create_issue "Custom Database Schemas Enhancement" "$ISSUE_8_BODY" "enhancement,database"
create_issue "Documentation Review and Updates" "$ISSUE_9_BODY" "documentation"
create_issue "Security Audit and Hardening" "$ISSUE_10_BODY" "security,high-priority"
create_issue "Backup and Recovery Procedures" "$ISSUE_11_BODY" "devops,high-priority"
create_issue "Monitoring and Alerting Setup" "$ISSUE_12_BODY" "devops,monitoring"

echo ""
echo "=========================================="
echo "✅ Issue creation complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review created issues at: https://github.com/$REPO/issues"
echo "2. Assign priorities and milestones"
echo "3. Assign team members to issues"
echo "4. Start working on high-priority items"
echo ""
