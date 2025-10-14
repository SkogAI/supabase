# Testing Documentation Index

Quick reference to all testing documentation and resources.

## 🚀 Getting Started

**New to testing this project?** Start here:

1. **[QUICKSTART_TESTING.md](../QUICKSTART_TESTING.md)** - Step-by-step guide to verify all features work
   - Run all tests
   - Verify output
   - Troubleshoot issues

## 📋 Test Issue Management

**Need to create GitHub issues for test coverage?**

1. **[CREATING_TEST_ISSUES.md](CREATING_TEST_ISSUES.md)** - How to create test tracking issues
   - Prerequisites
   - Automated script usage
   - Manual creation
   - Issue management

2. **[PROPOSED_TEST_ISSUES.md](PROPOSED_TEST_ISSUES.md)** - Detailed test specifications
   - 5 comprehensive test issues
   - Test coverage requirements
   - Implementation guidance
   - Success criteria

3. **[create-test-issues.sh](../scripts/create-test-issues.sh)** - Automated script
   ```bash
   ./scripts/create-test-issues.sh
   ```

## 📊 Implementation Summary

**Want to understand what's already implemented?**

- **[TESTING_IMPLEMENTATION_SUMMARY.md](TESTING_IMPLEMENTATION_SUMMARY.md)** - Complete overview
  - What's working
  - Test files location
  - How to run tests
  - Success criteria

## 🧪 Test Types

### Database Tests (SQL)
- **Location**: `tests/` directory
- **Files**:
  - `rls_test_suite.sql` - RLS policy verification
  - `profiles_test_suite.sql` - Profile functionality
  - `storage_test_suite.sql` - Storage operations
  - `storage_buckets_test_suite.sql` - Bucket configuration
- **Run with**: `npm run test:rls`, `npm run test:profiles`, etc.

### Edge Function Tests (Deno/TypeScript)
- **Location**: `supabase/functions/*/test.ts`
- **Files**:
  - `hello-world/test.ts`
  - `health-check/test.ts`
  - `openai-chat/test.ts`
  - `openrouter-chat/test.ts`
- **Run with**: `npm run test:functions`

### Integration Tests
- **Location**: `examples/realtime/`
- **Run with**: `npm run test:realtime`

## 🎯 The 5 Test Issues

When created, these issues track:

| Issue | Focus Area | Test Command |
|-------|-----------|--------------|
| 1 | Profile RLS Policies | `npm run test:rls` |
| 2 | Storage Buckets | `npm run test:storage-buckets` |
| 3 | Realtime Subscriptions | `npm run test:realtime` |
| 4 | Edge Functions | `npm run test:functions` |
| 5 | Integration Testing | `npm run test:integration` |

## 📖 Related Documentation

### Architecture & Implementation
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture overview
- **[RLS_POLICIES.md](RLS_POLICIES.md)** - Row Level Security details
- **[STORAGE.md](STORAGE.md)** - Storage bucket configuration
- **[REALTIME.md](REALTIME.md)** - Realtime subscriptions

### Development
- **[CLAUDE.md](../CLAUDE.md)** - Complete command reference
- **[package.json](../package.json)** - All npm test scripts

### Specific Features
- **[supabase/README.md](../supabase/README.md)** - Supabase configuration
- **[supabase/functions/README.md](../supabase/functions/README.md)** - Edge functions

## ⚡ Quick Commands

```bash
# Start Supabase
npm run db:start

# Run all tests
npm run test:rls
npm run test:profiles  
npm run test:storage-buckets
npm run test:functions
npm run test:realtime

# Create test issues
./scripts/create-test-issues.sh

# View Supabase Studio
open http://localhost:8000

# Stop Supabase
npm run db:stop
```

## 🔍 Finding Specific Information

**Looking for...**
- **Test commands?** → See [QUICKSTART_TESTING.md](../QUICKSTART_TESTING.md)
- **How to create issues?** → See [CREATING_TEST_ISSUES.md](CREATING_TEST_ISSUES.md)
- **Test specifications?** → See [PROPOSED_TEST_ISSUES.md](PROPOSED_TEST_ISSUES.md)
- **What's implemented?** → See [TESTING_IMPLEMENTATION_SUMMARY.md](TESTING_IMPLEMENTATION_SUMMARY.md)
- **Architecture details?** → See [ARCHITECTURE.md](ARCHITECTURE.md)
- **All commands?** → See [CLAUDE.md](../CLAUDE.md)

## 🐛 Troubleshooting

Common issues:
- Tests fail after clone → Run `npm run db:reset`
- Docker not running → Start Docker Desktop
- Supabase not started → Run `npm run db:start`
- Functions not working → Run `npm run functions:serve`

See **[QUICKSTART_TESTING.md](../QUICKSTART_TESTING.md)** for detailed troubleshooting.

---

**Need help?** Check the documentation above or open a GitHub issue.
