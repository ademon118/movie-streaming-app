# Home Screen + Bottom Navigation — Design Spec

**Date:** 2026-07-15  
**App:** Flutter Movie App (`movie_app`)  
**Scope:** UI-only first page pass (mock data; no API)

## Goal

Replace the default Flutter counter template with a dark-cinema **Home** screen inside a **5-tab bottom navigation shell**. Other tabs are placeholders until later page-by-page work. Real TMDB API comes later; this pass uses local mock movies only.

## Decisions (approved)

| Topic | Choice |
|-------|--------|
| First page | Home + bottom nav shell |
| Data | Mock / local sample data only |
| Tabs | Home · Search · Favorites · Categories · Profile |
| Theme | Dark cinema style |
| Architecture | Scaffold + StatefulWidget (`IndexedStack`); no go_router / state-management package yet |

## Out of scope (this pass)

- Splash, onboarding, login/signup
- Movie Details, Actor Details, trailers, reviews
- TMDB (or any) network API client / API keys
- Continue Watching / Recommended rows
- Poster tap → navigate to details
- Auth, favorites persistence, downloads, admin

## Architecture

```
lib/
  main.dart                 # MaterialApp, dark theme, home: MainShell
  theme/app_theme.dart      # Dark cinema ColorScheme + text styles
  data/mock_movies.dart     # Sample Movie lists by section
  models/movie.dart         # id, title, posterUrl, rating, year, genre
  screens/
    main_shell.dart         # Bottom nav (5 tabs), IndexedStack
    home_screen.dart        # Full Home UI
    search_screen.dart      # Placeholder
    favorites_screen.dart   # Placeholder
    categories_screen.dart  # Placeholder
    profile_screen.dart     # Placeholder
  widgets/
    movie_poster_card.dart
    movie_section.dart      # Section title + horizontal ListView
    home_hero_banner.dart   # Featured movie PageView
```

### Shell behavior

- `MainShell` owns `selectedIndex` and renders `NavigationBar` + `IndexedStack`.
- Tab switches do not dispose Home (preserves scroll position).
- Non-Home tabs show a centered icon + label placeholder.
- No nested Navigator for details in this pass.

### Data flow

- `Movie` is a simple immutable model.
- `mock_movies.dart` exposes lists: featured, trending, popular, nowPlaying, upcoming, topRated.
- Home reads mocks directly (no repository/API abstraction required yet; a thin data file is enough so API can replace it later).

## Home UI

1. **Top bar** — app name (left); search icon (right). Search icon may switch to Search tab or be a no-op; prefer switching to Search tab for polish.
2. **Hero banner** — `PageView` of ~3 featured movies: backdrop/poster, title, short tagline, rating chip.
3. **Horizontal sections** (in order):
   - Trending
   - Popular
   - Now Playing
   - Upcoming
   - Top Rated
4. **Poster card** — image (network URL with error → dark gray placeholder), title, small rating.
5. Poster / banner taps: no navigation yet.

## Theme

- Scaffold background: near-black (`#0B0B0F`)
- Surfaces slightly lighter for nav / elevated areas
- Accent: warm amber/gold for ratings and selected nav item (avoid purple Material defaults)
- Text: white primary, soft gray secondary
- Material 3 `NavigationBar`

## Error / edge cases

- Local mock data only → no loading or remote error UI required.
- Image load failure → gray box; title/rating still visible.
- Empty section list → hide section or show nothing (mocks will be non-empty).

## Testing

- Smoke widget test: `MainShell` pumps successfully.
- Assert Home shows at least one known section title (e.g. "Trending").

## Success criteria

- App launches to dark Home inside 5-tab shell.
- Home shows hero + five mock movie rows.
- Switching tabs shows placeholders; returning to Home keeps state.
- No API key or network dependency required for content (images may load from public URLs when online).

## Next pages (later)

Implement separately, one at a time from the shared page list (Search, Favorites, Movie Details, etc.) after Home is done.
