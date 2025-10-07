# SAML Test Results

This directory stores test results from SAML integration testing.

## Usage

Save test results to this directory:

```bash
# Run tests and save results
npm run test:saml > test_results/saml_test_$(date +%Y%m%d_%H%M%S).log

# Or using the script directly
./scripts/test_saml.sh | tee test_results/saml_test_$(date +%Y%m%d_%H%M%S).log
```

## Test Reports

Document detailed test results using the template in `docs/ZITADEL_SAML_TESTING.md`.

Create a markdown file for each test run:

```bash
cp docs/ZITADEL_SAML_TESTING.md test_results/SAML_TEST_RESULTS_$(date +%Y%m%d).md
# Then edit with your test results
```

## Cleanup

Test result files are automatically ignored by git (see `.gitignore`).

You can clean up old test results:

```bash
# Remove results older than 30 days
find test_results -name "*.log" -mtime +30 -delete
```

## Structure

- `*.log` - Console output from test runs
- `SAML_TEST_RESULTS_*.md` - Detailed test reports with analysis

---

**Note**: This directory is for local testing only. Test results are not committed to the repository.
