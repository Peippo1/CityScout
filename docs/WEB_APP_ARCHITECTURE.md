# CityScout Web App Architecture

## 1. Product Intent

CityScout is expanding from a native iOS travel companion into a multi-surface product with a shared backend and a web planning layer.

The web app is not a second copy of the iOS app. It is a complementary surface focused on:
- pre-trip planning
- itinerary review and editing
- sharing plans with other people
- lightweight destination exploration when planning on desktop

The iOS app remains the primary in-trip travel companion. It keeps the strongest local-first experience, device-native features, and on-device destination state.

The shared backend remains the source of truth for server-side AI orchestration and common API contracts.

## 2. Why Monorepo For Now

Keep the web app, iOS app, backend, and docs in one repository for the initial expansion phase.

Reasons:
- Shared product logic is still evolving, especially around planning and itinerary semantics.
- The backend API boundary is already shared between surfaces.
- A monorepo keeps contract changes visible across app, web, and backend in one review.
- It reduces duplication in documentation, types, and prompt or response expectations.
- It makes cross-surface debugging easier while the web layer is still small.

Monorepo does not mean shared runtime code by default. It means coordinated delivery with explicit boundaries.

## 3. When To Split Into Separate Repos Later

Consider splitting when the web layer becomes independently staffed or operationally distinct.

Good split signals:
- separate release cadence for web and iOS
- large enough frontend teams that independent CI and ownership are clearer
- stable API contracts with limited cross-surface churn
- the backend is treated as a product platform rather than a tightly coupled app dependency
- different deployment and access controls are needed for mobile and web release workflows

Do not split just because the codebase grows. Split when the operational and organizational cost of one repo outweighs the coordination benefit.

Likely future split:
- `cityscout-ios`
- `cityscout-web`
- `cityscout-backend`

Even after a repo split, keep API contracts versioned and documented in a shared spec layer or generated client artifacts.

## 4. Target Repo Structure

The near-term structure should stay simple and explicit.

```text
CityScout/
├── CityScout/              # Native iOS app
├── backend/                # FastAPI + OpenAI backend
├── web/                    # Next.js web app
├── docs/                   # Product and architecture docs
├── shared/                 # Optional future contract artifacts
└── CityScout.xcodeproj
```

Recommended web substructure:

```text
web/
├── app/
├── components/
├── lib/
├── styles/
├── public/
├── types/
└── tests/
```

Recommended backend-related shared artifacts, if needed later:
- OpenAPI spec exports
- generated TypeScript client types
- schema examples for itinerary and guide responses
- prompt and response contract notes

Avoid creating a large shared UI or business-logic layer. The web app and iOS app should share contracts, not framework-specific implementation details.

## 5. Shared Backend/API Principles

The backend is the shared boundary for AI and planning logic.

Principles:
- OpenAI calls remain server-side only.
- The web app must never talk directly to OpenAI.
- The backend should expose stable, versionable JSON contracts.
- Web and iOS should consume the same response semantics where practical.
- Auth, rate limiting, and request validation belong in the backend, not in the client.
- Frontends should be able to degrade gracefully when the backend is unavailable.
- Any plan or guide content that is expensive to generate should be cacheable or re-creatable from source inputs.

API design expectations:
- keep request and response shapes explicit and documented
- validate inputs tightly at the boundary
- return predictable error codes and error bodies
- keep destination scoping visible in every request that depends on a city
- treat itinerary generation as a server concern, not a browser concern
- version endpoints when a breaking response change is unavoidable

Client contract expectations:
- iOS and web should share the same mental model for destination, itinerary, saved place, and guide objects
- clients should not infer hidden backend behavior
- if the backend needs migration, preserve old shapes until both surfaces have moved

## 6. Web App V1 Scope

The first web release should focus on planning, review, and sharing.

In scope:
- destination selection or destination handoff from a shared link
- itinerary planning and regeneration
- plan review with day sections and editable notes
- shareable itinerary pages or public links
- lightweight saved-place review for planning context
- destination overview pages with high-level city context
- responsive desktop-first layout with good mobile fallback
- sign-in only if it is required for sharing, persistence, or access control

Likely V1 content types:
- destination overview
- one-day itinerary
- saved places used in a plan
- guide-style planning prompt and response history
- share link metadata

Likely V1 interactions:
- generate a plan
- tweak preferences
- regenerate a section or full plan
- copy or share an itinerary
- review map-linked places in a planning view
- save or export a plan for the iOS app

Keep V1 narrow enough that it feels complete for planning, not broad enough to recreate every iOS surface.

## 7. Non-Goals

The first web version should not try to duplicate the entire iOS app.

Non-goals:
- full native parity with iOS navigation and feature depth
- Apple-only features that do not translate well to the web
- replacing SwiftData or the local-first offline model on iOS
- direct OpenAI access from the browser
- complex multi-user collaboration in V1
- a full CMS or admin platform
- a heavyweight public marketing site unless separately planned
- map feature parity with every iOS map interaction

Platform-specific direction:
- iOS continues using Apple MapKit for now.
- Web maps may use Mapbox or Google Maps.
- Do not force identical map implementation across platforms.

## 8. Risks And Mitigations

Risk: scope drift into an iOS clone.
- Mitigation: define the web app as planning and sharing first, then gate features by use case, not by platform parity.

Risk: API contract drift between web and iOS.
- Mitigation: version request and response schemas, add contract tests, and document canonical payloads in `docs/`.

Risk: shared backend changes break one surface.
- Mitigation: preserve backward compatibility, add regression tests, and roll out changes behind feature flags or phased deployments where possible.

Risk: web map provider choice becomes locked too early.
- Mitigation: isolate map rendering behind a web-specific adapter so provider changes do not leak into core planning logic.

Risk: server-side AI cost and latency increase as web traffic grows.
- Mitigation: keep prompts concise, cache deterministic outputs where possible, and add explicit regeneration controls so users do not accidentally create duplicate work.

Risk: security regressions from exposing backend capabilities to the browser.
- Mitigation: keep secrets server-side, use short-lived tokens or session auth where needed, and scope web privileges separately from mobile assumptions.

Risk: duplicated product logic between web and iOS.
- Mitigation: share contracts and domain language, not UI code; centralize canonical data definitions in the backend or docs.

## 9. Implementation Phases

### Phase 0: Architecture and contract definition
- define the web product boundary
- document canonical itinerary, destination, and guide payloads
- decide initial auth and sharing model
- pick the map provider
- define the web app folder structure

### Phase 1: Web shell and backend integration
- scaffold the Next.js app with TypeScript and TailwindCSS
- wire the web app to the shared backend
- implement destination lookup or handoff
- show itinerary generation results in a readable planning layout

### Phase 2: Planning workflow
- add preference editing and regeneration
- add saved-place context and plan review
- add itinerary persistence or retrieval if required for web sessions
- add shareable plan URLs or export actions

### Phase 3: Cross-surface consistency
- align web and iOS terminology and response handling
- add contract tests
- harden error handling and loading states
- verify mobile web fallback behavior

### Phase 4: Product hardening
- add analytics or observability if needed
- add auth and permission controls for sharing
- improve performance, caching, and SEO where relevant
- decide whether the repo should stay monorepo or split by surface

## Decision Rule

If a change helps both iOS and web through the shared API boundary, it belongs in backend contracts or docs first.

If a change is purely presentation or platform-specific, keep it inside the relevant client.

If a change would force one surface to carry the implementation complexity of the other, redesign the boundary instead of sharing code blindly.
