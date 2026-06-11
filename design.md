# Design Direction

## Purpose

This document defines the visual and interaction design direction for the app.

The app requirements and functionality are described in `overview.md`. This document should only guide the visual design, UX decisions, layout structure, component architecture, and overall product feel.

The goal is to create a polished macOS application that feels fast, elegant, focused, and comfortable for long piano practice sessions.

---

# Design Inspiration

Use the generated UI mockups in the "./design" directory as inspiration, not as a specification.

The mockups should influence:

- Overall visual quality.
- Layout hierarchy.
- Premium look and feel.
- macOS-native experience.
- Visual balance.
- Spacing.
- Typography.
- Light and dark theme direction.
- Focus on sheet music and practice.

Do not recreate the mockups pixel-for-pixel.

The final design should be an original implementation adapted to the actual product requirements described in `overview.md`.

The goal is to capture the same feeling and level of polish, not the exact same interface.

---

# Main Design Goal

The app should feel like a premium native macOS application built specifically for piano practice.

It should be:

- Beautiful.
- Fast.
- Minimal.
- Focused.
- Easy to understand.
- Comfortable for long sessions.
- Professional.
- Responsive.

The application should never feel like a generic web dashboard.

Even if web technologies are used internally, the user experience should feel desktop-first and carefully crafted.

---

# Core Design Principles

## Sheet Music First

The sheet music is the primary focus of the application.

Everything else exists to support the practice experience.

The user should always know:

- Where they are in the piece.
- What note is currently active.
- What they should play next.
- Whether they are playing correctly.

---

## Low Visual Noise

Avoid unnecessary UI elements.

Piano practice requires concentration.

The interface should remain calm, readable, and uncluttered.

Favor simplicity over feature density.

---

## Icon Styling

Display icons on their own, without rounded background shapes, containers, badges, or decorative tiles.

This applies across navigation, cards, controls, settings, and status elements.

Use the icon's color, weight, size, and opacity to communicate hierarchy or state instead of placing it on a rounded background.

---

## Instant Feedback

Feedback should be immediate and obvious.

Correct notes, mistakes, rhythm issues, and progress should be understandable at a glance.

The design should support real-time practice without distracting the user.

---

## Native macOS Feel

The application should feel at home on macOS.

Use native-inspired patterns where appropriate:

- Sidebar navigation.
- Toolbar controls.
- Smooth panels.
- Rounded corners.
- Subtle shadows.
- Clear typography.
- Proper spacing.
- Native light and dark themes.

Avoid excessive visual effects.

The interface should feel refined rather than flashy.

---

# Layout Direction

A strong layout direction is:

- Left sidebar for navigation.
- Large central area for sheet music and practice.
- Bottom area for keyboard visualization and transport controls.
- Right panel for feedback and statistics.

This structure is inspired by the mockups but may be adjusted if a better UX is discovered.

---

# Expandable & Collapsible Layout

Focus during practice is extremely important.

Both side panels should be collapsible and expandable.

Requirements:

- Left sidebar can collapse into an icon-only mode.
- Right feedback panel can be hidden completely.
- Users should be able to maximize score space quickly.
- Visibility preferences should persist between sessions.
- Smooth animations when expanding/collapsing.
- Keyboard shortcuts for panel toggling are encouraged.

The layout should gracefully adapt when panels are hidden.

---

# Focus Mode

Include a dedicated Focus Mode.

When enabled:

- Left sidebar is hidden.
- Right feedback panel is hidden.
- Non-essential controls disappear.
- Sheet music becomes the primary focus.
- The score uses as much screen space as possible.

Focus Mode should be optimized for uninterrupted practice.

---

# Fullscreen Practice Mode

Include a dedicated Fullscreen Mode.

This is not simply a maximized window.

Fullscreen Mode should contain:

- The score occupying almost the entire screen.
- A compact keyboard visualization at the bottom.
- Minimal transport controls.
- Current note indicators.
- Current measure indicators.
- No unnecessary UI.

The goal is to replicate the feeling of practicing from a real score while still benefiting from digital feedback.

---

# Sidebar

The sidebar should provide access to:

- Home.
- Library.
- Recent.
- Favorites.
- Statistics.
- Settings.

During practice it may also contain:

- Current piece.
- Practice section.
- Loop settings.
- Piano connection status.
- Connected devices.

The sidebar should be useful but not visually dominant.

---

# Central Practice Area

The central area is the most important part of the application.

Potential content:

- Piece title.
- Sheet music.
- Current measure highlight.
- Current note highlight.
- Upcoming note indication.
- Playback controls.
- Practice controls.
- Accuracy indicators.

The score should always remain the visual priority.

---

# Feedback Panel

The feedback panel should provide quick insight into the current session.

Potential information:

- Overall accuracy.
- Correct notes.
- Mistakes.
- Missed notes.
- Extra notes.
- Rhythm score.
- Tempo.
- Session statistics.
- Streaks.
- Time practiced.

The information should be easy to scan.

Avoid overwhelming users with too many metrics.

---

# Piano Visualization

The keyboard view should help users understand what is expected and what is being played.

Potential indicators:

- Correct notes.
- Wrong notes.
- Missed notes.
- Upcoming notes.
- Pressed keys.
- Pedal information.

The keyboard should feel responsive and visually clean.

The keyboard should not dominate the interface.

The score should always remain the primary focus.

---

# No Score Editing Features

This application is focused on practicing piano, not creating or editing sheet music.

Do not design the interface around:

- Score editing.
- Note editing.
- Composition tools.
- Music notation creation workflows.

If editing capabilities ever exist in the future, they should remain secondary.

The primary workflow is:

Import score → Practice → Improve

Not:

Create score → Edit score

---

# Light Theme

The light theme should feel:

- Clean.
- Premium.
- Airy.
- Modern.

Use:

- Soft backgrounds.
- Subtle separators.
- Gentle shadows.
- High readability.
- Minimal color usage.

Accent colors should primarily indicate interaction and feedback.

Avoid an overly sterile appearance.

---

# Dark Theme

The dark theme should feel:

- Focused.
- Elegant.
- Professional.

Use:

- Deep neutral backgrounds.
- Clear panel separation.
- High score readability.
- Subtle highlights.
- Controlled accent colors.

Avoid making the application look like a gaming interface.

---

# Color System

Colors should communicate meaning.

Suggested usage:

- Purple: active state, current position, primary actions.
- Green: success, correct notes, connected status.
- Red: mistakes and incorrect notes.
- Orange or yellow: warnings and missed notes.
- Neutral grays: secondary UI.

Use color intentionally.

Avoid excessive saturation.

---

# Typography

Typography should be:

- Clear.
- Modern.
- Readable.
- Consistent.

Maintain strong hierarchy and spacing.

Avoid decorative fonts in the interface.

The score itself should remain visually distinct from the surrounding UI.

---

# Multi-Device Experience

Connecting additional devices should be effortless.

The interface should support:

- QR pairing.
- Short pairing codes.
- Session sharing.
- Connected device management.

Users should never need networking knowledge.

The experience should feel similar to modern device pairing workflows.

---

# Design System

Create a proper design system from the beginning.

Do not hardcode:

- Colors.
- Font sizes.
- Spacing values.
- Border radii.
- Shadows.
- Animation timings.
- Layout dimensions.

Instead, define reusable design tokens and theme variables.

Changing a theme should require minimal code changes.

---

# Theme Architecture

Light and dark themes should be implemented through shared theme variables.

Avoid duplicated styling between themes.

The architecture should allow future theme customization without large rewrites.

Themes should be easy to evolve over time.

---

# Reusable Components

Build the UI from reusable components.

Avoid giant files.

Examples:

- Sidebar.
- Feedback panel.
- Score container.
- Keyboard visualization.
- Practice toolbar.
- Statistics cards.
- Session summary views.
- Device pairing dialogs.
- Settings panels.
- Tempo controls.

Components should be modular, composable, and maintainable.

---

# Maintainability

Prioritize maintainability.

Avoid:

- Giant component files.
- Duplicated styles.
- Repeated layout logic.
- Tight coupling between screens.

Prefer:

- Small focused components.
- Shared design tokens.
- Shared layout primitives.
- Consistent design patterns.

The codebase should remain easy to extend.

---

# Empty States

Empty states should be useful and informative.

## No score loaded

Provide actions such as:

- Import score.
- Open library.
- Try sample score.

## No piano connected

Show:

- Current status.
- Simple connection instructions.

## No history available

Explain what information will appear after practicing.

Empty states should always guide the user toward the next action.

---

# Performance Perception

The UI should make the application feel extremely fast.

Guidelines:

- Avoid layout shifts.
- Minimize unnecessary animations.
- Keep transitions short.
- Prioritize responsiveness.
- Avoid blocking interactions.
- Keep practice mode lightweight.

During active practice, responsiveness is more important than visual effects.

---

# What To Avoid

Avoid:

- Copying the generated mockups exactly.
- Generic dashboard designs.
- Excessive visual complexity.
- Too many colors.
- Tiny controls.
- Hidden important actions.
- Excessive animations.
- Distracting gradients.
- Childish gamification.
- UI that competes with the sheet music.

---

# Final Expectation

The final design should be inspired by the generated macOS light and dark mockups while remaining an original implementation.

The user should immediately understand:

1. What piece they are practicing.
2. Where they are in the score.
3. What they should play next.
4. Whether they are playing correctly.
5. How the session is progressing.
6. How to connect another device if desired.

The design should prioritize clarity, speed, focus, maintainability, and exceptional user experience above everything else.
