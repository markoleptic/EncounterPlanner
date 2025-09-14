# [2.2.1](https://github.com/markoleptic/EncounterPlanner/tree/2.2.1) (2025-09-14)

[Full Changelog](https://github.com/markoleptic/EncounterPlanner/compare/2.2.0...2.2.1)

-   Added the option to hide spell icons for message reminders. This can be found by navigating to Preferences -> Reminder -> Messages -> Show Icon.
-   Added the option to only show timeline assignments relevant to the player. This can be found by navigating to Preferences -> View -> Only Show Timeline Assignments For Me.
-   Improved behavior for which plan is selected when a plan is deleted.
-   Improved efficiency of reminders.
-   Improved time input handling
    -   Entering fractional values in the minutes field now converts the fraction part into seconds (e.g. 1.5 results in 1:30).
    -   Entering values greater than or equal to 60 in the seconds field now overrides the minutes field (e.g. 90 results in 1:30 regardless of what is in the minutes field).
-   Fixed an issue where OmniCC sometimes wouldn't provide countdown numbers for reminder icons.
