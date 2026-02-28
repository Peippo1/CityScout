# CityScout Roadmap

## V1 – Offline City Phrase Companion

### Must-Have
- Offline phrase browsing for launch cities without network dependency.
- Stable lesson/phrase navigation with predictable back stack behavior.
- Local persistence for required content and user progress markers.
- Seed bootstrap/import flow for initial city content.
- Core CI pipeline that builds and tests `CityScout` on every `dev` push/PR.

### Quality Polish
- Improve loading states and empty-state messaging.
- Remove debug-only logging/noise before release builds.
- Ensure consistent copy, typography, and spacing across primary screens.
- Validate accessibility basics (dynamic type, contrast, VoiceOver labels where applicable).

### Content Scope
- Barcelona seed content.
- Paris seed content.
- Phrase and lesson metadata required for offline learning flow.

### Release Checklist
- V1 must-have features complete and manually verified on simulator.
- No critical navigation regressions in core flows.
- Seed imports verified idempotent and version-gated.
- CI build and test jobs green on `dev`.
- App metadata and release notes prepared for internal distribution.

## V1.1 – Usability Upgrades
- Improve discoverability of key offline features.
- Refine onboarding and first-run guidance.
- Add small UX enhancements driven by early tester feedback.

## V2 – AI-Assisted (Feature-Flagged)
- Introduce AI-assisted features behind runtime feature flags.
- Preserve offline-first baseline when AI/network features are unavailable.
- Add telemetry and guardrails before broader rollout.

## V3 – Travel Planning
- Expand from phrase companion to lightweight itinerary/trip planning.
- Cross-feature planning workflows (places, notes, scheduling).
- Content and architecture scaling for multi-city, longer-trip scenarios.
