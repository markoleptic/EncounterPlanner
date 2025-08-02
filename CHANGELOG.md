# [1.3.0](https://github.com/markoleptic/EncounterPlanner/tree/1.3.0) (2025-07-24)

[Full Changelog](https://github.com/markoleptic/EncounterPlanner/compare/v1.2.6...1.3.0)

-   Added Season 3 Mythic+ dungeons:
    -   Ara Kara
    -   Eco Dome Aldani
    -   Halls of Atonement
    -   Tazavesh: So'leah's Gambit
    -   Tazavesh: Streets of Wonder
    -   The Dawnbreaker
-   Added Manaforge Omega (first 7 bosses)
-   Fixed some divide-by-zero errors that could occur when first opening the gui in 11.2.
-   Boss abilities which have both a cast time and duration effect now show a vertical line where the cast ends and the duration begins.
-   The vertical line indicating the time is now clamped to an assignment when dragging an assignment.
-   Plans for a dungeon or raid are now sorted by their appearance in the instance, falling back to alphabetical.
-   Dungeons and raids are now grouped by season in the plan dropdown menu.
-   The arrow color of a nested dropdown menu is now updated to indicate if the menu is enabled or empty.
-   The plan name line edit in the New Plan dialog will no longer be auto-generated after changing the boss if the line edit has been modified be the user.
