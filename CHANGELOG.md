# [2.0.4](https://github.com/markoleptic/EncounterPlanner/tree/2.0.4) (2025-08-09)

[Full Changelog](https://github.com/markoleptic/EncounterPlanner/compare/2.0.3...2.0.4)

-   The Change Boss dialog now only presents one option for converting. The current plan is duplicated, and assignments are converted based on the phase in which they occur for the new boss.
-   The conversion uses the same rules as when adding a new assignment by clicking the timeline. This should result in a more consistent experience with more realistic combat log event spells being assigned.
-   Fixed issue where assignments with time greater than the duration of the new boss would not respect the nearest combat log event.
-   Fixed issue where timeline assignments could hold invalid data after converting to a new boss.
