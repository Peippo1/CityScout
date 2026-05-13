# Skill: UX Polish

## Purpose
Apply CityScout's visual and interaction standards consistently when building or refining web UI. The design language is calm, premium, and restrained — it should feel editorial, not like a dashboard.

## When to use
- Building new components or pages in `web/`.
- Refining loading states, error messages, or empty states.
- Reviewing UI changes for consistency with the existing design system.

---

## Visual language

**Palette (Tailwind custom tokens):**
- `text-city-ink` — primary text
- `text-city-muted` — secondary text, labels, captions
- `bg-city-background` / `bg-white/55` — panel backgrounds
- `border-city-border` — all borders
- Accent: `bg-city-ink` (dark fill for active states)

**Typography:**
- Labels: `text-xs uppercase tracking-[0.24em]` — used for section headers, metadata
- Body: `text-sm leading-6` — primary readable text
- Headings: `font-editorial text-4xl sm:text-5xl leading-[0.98]` — page-level only
- Do not introduce new font weights or sizes without a clear reason.

**Panels:**
- Use `<Surface>` (`web/components/surface.tsx`) for bordered content areas.
- Use `rounded-2xl` for cards, `rounded-3xl` for prominent panels, `rounded-full` for pills and buttons.
- Prefer `bg-white/55` or `bg-white/60` for card fills to maintain layered translucency.

**Spacing:** use Tailwind spacing scale consistently; `space-y-5` between form fields, `gap-8` between major sections.

---

## States

### Loading
- Show a cycling progress message panel — not a spinner alone.
- Cycle through 2–3 messages every ~1.8 s using `setInterval` + `useEffect`.
- Include a simple step indicator (thin `h-0.5` bars progressing left to right).
- Use `aria-live="polite"` on the changing text for accessibility.
- Never show fake percentages.

```tsx
<div className="flex items-center gap-3">
  <span className="h-2.5 w-2.5 animate-pulse rounded-full bg-city-ink" />
  <p className="text-sm font-medium text-city-ink" aria-live="polite">{currentMessage}</p>
</div>
```

### Error
- Use `bg-rose-50/80 border-rose-300` for the error container.
- Show a calm headline ("Could not generate itinerary") and one plain-English sentence.
- Include the `request_id` for support in a de-emphasised caption.
- Never show raw error codes, stack traces, or HTTP status numbers to the user.
- Log technical details to `console.error` only.

### Empty
- Use a dashed border (`border-dashed border-city-border`) for the placeholder area.
- Briefly explain what will appear here when the user acts.
- Show skeleton structure (e.g. Morning/Afternoon/Evening placeholder cards) so the layout doesn't feel broken.

### Success / result
- Render structured content, not raw text.
- Group related items (e.g. stops by time period) with section headers.
- Badges for metadata: `rounded-full border border-city-border bg-white/60 px-3 py-1 text-xs`.
- Provide a clipboard copy action where the output is portable text.

---

## Interaction patterns

### Buttons
- Primary: `border border-city-ink bg-city-ink text-white hover:bg-white hover:text-city-ink` rounded-full, full-width in forms.
- Secondary: `border border-city-border bg-white/60 hover:border-city-ink/30 hover:text-city-ink` rounded-full.
- Pill toggles (travel style): same secondary style, active state uses primary fill.
- Always include `disabled:cursor-not-allowed disabled:opacity-60` on async-triggered buttons.
- Always include `focus-visible:ring-2 focus-visible:ring-city-ink/15 focus-visible:ring-offset-2`.

### Copy to clipboard
```typescript
navigator.clipboard.writeText(text).then(() => {
  setCopied(true);
  setTimeout(() => setCopied(false), 2000);
}).catch(() => { /* silent — clipboard not available */ });
```
Show "Copied" for 2 seconds then revert. No extra dependencies.

### Forms
- Provide sensible defaults that demonstrate the product (e.g. destination: "Paris").
- Label every field. Use `text-xs uppercase tracking-[0.24em] text-city-muted` for label text.
- Inputs: `rounded-2xl border border-city-border bg-white/75 px-4 py-3 text-base`.
- Textarea: add `resize-none` to prevent layout breaks.

---

## Alpha notices

When the product is in alpha/beta:
```tsx
<div className="rounded-2xl border border-amber-200/70 bg-amber-50/60 px-4 py-3 text-sm leading-6 text-amber-900/80">
  CityScout is in public alpha. Itineraries are AI-assisted and should be checked before travel.
</div>
```
- Tone: honest and helpful, not alarming.
- Placement: top of the relevant page/workspace, above main content.

---

## Anti-patterns

- Raw API error codes or status numbers visible in the UI.
- Spinner-only loading states with no progress context.
- Modals or overlays for errors that could be inline.
- Adding emojis, animations, or decorative elements not already in the design language.
- Hardcoding colours outside the Tailwind token system.
- Making components wider or taller than necessary for their content.

---

## Definition of success
- The feature matches the calm, premium aesthetic of the existing `/plan` page.
- All three states (loading, error, success) are handled and visually consistent.
- No raw error codes or technical language reaches the user.
- Accessibility: interactive elements have visible focus rings; dynamic content uses `aria-live`.
- `npm run build` passes with no type errors.
