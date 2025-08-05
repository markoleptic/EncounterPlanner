# [2.0.0](https://github.com/markoleptic/EncounterPlanner/tree/2.0.0) (2025-08-05)

[Full Changelog](https://github.com/markoleptic/EncounterPlanner/compare/v1.2.6...2.0.0)

Content Update

-   Added first 7 bosses of Manaforge Omega.
-   Added all bosses for all Season 3 Mythic+ dungeons.

GUI Updates

-   Boss abilities which have both a cast time and duration effect now show a vertical line where the cast ends and the duration begins.
-   The vertical line time indicator is now clamped to the assignment while dragging.
-   Plans for a dungeon or raid are now sorted by their order of appearance in the instance, with alphabetical sorting as a fallback.
-   Dungeons and raids are now grouped by season in the plan dropdown menu.
-   The arrow icon for nested dropdown menus now updates its color based on whether the menu is enabled or empty.
-   In the New Plan dialog, the plan name field will no longer auto-generate a name when changing the boss if the user has manually edited it.

Bug Fixes

-   Fixed some divide-by-zero errors that could occur when first opening the gui in 11.2.
