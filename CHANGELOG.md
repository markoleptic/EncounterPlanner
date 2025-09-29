# [2.3.0](https://github.com/markoleptic/EncounterPlanner/tree/2.3.0) (2025-09-28)

[Full Changelog](https://github.com/markoleptic/EncounterPlanner/compare/2.2.1...2.3.0)

-   Improved plan collaboration
    -   Assignments from received plans are now applied as updates to current assignments, rather than overwriting them. Requires the plan be sent to the group once. If there are conflicts, the incoming changes are chosen.
    -   Custom boss phase durations will no longer be cleared when receiving an incoming plan.
    -   Assignment conflicts are now labeled and displayed in the Plan Change Request dialog.
    -   Sections of the Plan Change Request dialog are now collapsible and collapsed by default.
    -   Removed the option to accept changes without sending to group from the Plan Change Request dialog.
    -   Fixed issue where unselecting an entry in the Plan Change Request dialog would not prevent incoming changes from being applied.
-   Added new message reminder setting to control how long messages stay visible: Message Hold Duration.
-   The "Hide or Cancel if Spell on Cooldown" reminder setting has been renamed to "Hide on Spell Cast".
-   Added the ability to override some reminder preferences on a per-assignment basis.
    -   Enable the Reminder Overrides section of the Assignment Editor to enable.
    -   Hide on Spell Cast, Countdown Length, and Message Hold Duration are available for overriding.
    -   Reminder preference overrides are not shared with the group and should be retained when receiving a plan update.
-   Fixed issue where Fortifying Brew was only available for Brewmaster and updated it's category to Personal Defensive.
-   Updated reminder setting tooltips.
