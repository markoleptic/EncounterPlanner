# [3.1.0](https://github.com/markoleptic/EncounterPlanner/tree/3.0.1) (2026-27-01)

[Full Changelog](https://github.com/markoleptic/EncounterPlanner/compare/3.0.1...3.1.0)

- Added the ability to manually add spells to the spell database
  - The Cooldown Overrides preferences tab has been renamed to Spells.
  - Added new section to Spells tab: Manually Added Spells
    - Click the + button and type a valid spell ID to add a spell.
    - A spell category and the class/role(s) which can use the spell must be specified. The Core category and your class/role are chosen by default.
    - Spells under the Racial and Consumable categories do not require a class or role.
- Fixed an issue where spell category names were using the English version instead of the localized version.
- Fixed an issue where items would not show as favorited when the assignee was a role, group number, type, or everyone.
