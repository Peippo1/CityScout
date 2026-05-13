# Skill: Testing Standards

## Purpose
Define the minimum acceptable test coverage for each surface and guide correct test patterns for CityScout. Tests are the signal that a change is safe to ship — they must not be skipped, hollowed out, or written to pass trivially.

## When to use
- Adding or modifying a route handler, component, or backend service.
- Reviewing whether a change is ready to merge.
- Writing tests for a new feature.

---

## Backend (pytest)

**Run:** `cd backend && python -m pytest`

### Minimum coverage for a route handler

| Case | Required |
|---|---|
| Valid request returns expected shape | Yes |
| Missing required field returns 422 | Yes |
| Wrong or missing shared secret returns 401 | Yes |
| Rate limit exceeded returns 429 | Yes |
| Backend/OpenAI failure returns 503 or 500 | Yes |
| Health check remains stable | Yes |

### Patterns
- Use the fixtures in `backend/tests/conftest.py` — do not create new global state.
- Do not mock the FastAPI app itself; test the actual route handlers using `TestClient`.
- Mock only OpenAI calls (via `unittest.mock.patch`) to avoid real API calls in CI.
- Assert both the status code and the JSON response shape.
- Include `request_id` assertions where relevant.

### Anti-patterns
- Testing that a mock returns a mock (vacuous tests that prove nothing).
- Skipping the rate-limit test because it seems slow.
- Writing only the happy path.

---

## Web (Vitest + Testing Library)

**Run:** `cd web && npm test`

### Minimum coverage for a route handler

| Case | Required |
|---|---|
| Non-POST returns 405 | Yes |
| Invalid body returns 422 | Yes |
| Valid request forwarded with secret | Yes |
| Backend 5xx mapped to structured error | Yes |
| Rate limit returns 429 | Yes |
| Timeout returns 504 `upstream_timeout` | Yes |
| Missing env vars returns 500 `proxy_misconfigured` | Yes |

### Minimum coverage for a React component

| Case | Required |
|---|---|
| Renders initial state correctly | Yes |
| Shows loading state while async call is pending | Yes |
| Shows friendly error on API failure | Yes |
| Shows result after successful call | Yes |
| Key interactive elements (copy, submit) work | Yes |

### Patterns
```typescript
// Mock the api module
vi.mock("@/lib/api", () => ({
  ApiError: class ApiError extends Error { ... },
  planItinerary: vi.fn(),
}));

// Use findByText / waitFor for async state changes
expect(await screen.findByText(/Building your city plan/i)).toBeInTheDocument();

// Always clear mocks in beforeEach
beforeEach(() => { vi.clearAllMocks(); });
```

### Anti-patterns
- Importing and calling `planItinerary` in tests without mocking it (would call real fetch).
- Testing only the render with no interaction.
- Asserting on implementation details (internal state, component names) instead of rendered output.
- Skipping the error state test.

---

## iOS (XCTest / xcodebuild)

**Run:**
```bash
xcodebuild -project CityScout.xcodeproj -scheme CityScout \
  -configuration Debug -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" clean build
```

- The primary iOS test signal is a clean build. Unit tests live in `CityScoutTests/`.
- Do not break the build to add new features. Always confirm the simulator build passes.
- UI tests live in `CityScoutUITests/` — keep them stable; do not delete them.

---

## Cross-surface

- Never delete an existing test without replacing its coverage.
- Never modify a test to make it pass without fixing the underlying issue.
- Tests run in CI on every push — a failing test blocks the merge.
- If you need to add a test for behaviour that isn't there yet, write the test first, confirm it fails, then implement.

---

## Definition of success
- `npm test` reports all tests passing with no skips.
- `python -m pytest` reports all tests passing.
- No test has been modified solely to pass without fixing the code under test.
- New routes and components have the minimum required coverage listed above.
