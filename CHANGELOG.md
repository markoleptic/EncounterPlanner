# [v1.2.0](https://github.com/markoleptic/EncounterPlanner/tree/v1.2.0) (2025-04-26)

[Full Changelog](https://github.com/markoleptic/EncounterPlanner/compare/v1.1.1...v1.2.0)

Spell Charge Tracking

-   The assignment timeline now tracks spell charges based on your current talents. If you change talents, the timeline will update accordingly.
-   A spell regenerating a charge is indicated by a dashed green line.
-   Spells which do not use charges are not affected.

Timeline Improvements

-   Cooldown textures no longer prevent you from adding an assignment by clicking on the timeline.
-   Cooldown textures no longer cause visual disruption when zooming in and out, scrolling, or dragging assignments. In other words, it should always appear to be fixed in the same place.
-   Fixed an issue where the current time text and line would linger after clicking and releasing an assignment.
-   The current time text and line is now shown immediately after clicking an assignment.

Preferences Menu

-   Custom spell charges can now be specified in the Cooldown Overrides tab.
-   Renamed the "Default Cooldown" and "Custom Cooldown" columns of the Cooldown Overrides table to "Default Duration" and "Custom Duration".
-   Renamed the "Show Spell Cooldown Duration" setting in the View tab to "Show Spell Cooldown Duration and Charges".
