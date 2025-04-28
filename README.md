# Encounter Planner

Encounter Planner is an assignment planning and reminder tool for mythic dungeon and mythic raid boss encounters.

It is designed to be easy to use while providing a feature set you would expect from a website.
Timers for all bosses in Liberation of Undermine and Season 2 Mythic+ dungeons are included.

If you encounter bugs, unexpected behavior, inaccurate timers, or have any suggestions, please let me know in the [Encounter Planner Discord](https://discord.gg/9bmH43JSzy) and I will do my best to fix or improve it.

**[API](https://github.com/markoleptic/EncounterPlanner/wiki/API)**

**[User Guide](https://github.com/markoleptic/EncounterPlanner/wiki/User-Guide)**

## Features

**Plans**

-   Encounter Planners uses _plans_ to store assignments.
-   Import notes from other sources such as MRT, Viserio, or plain text.
-   Export plans from Encounter Planner to plain text.
-   Create any number of plans per boss; Your shared raid plan and personal plan can both be active so you receive reminders from both.
-   Plans can be swapped between bosses, even if they contain combat log event assignments.
-   Each plan has its own roster that can be populated quickly from a shared roster or from your group.
-   Players with group lead or assistant roles can easily share plans with others in the raid or party.

**Boss Timeline**

-   Bosses are designed in such a way that you can customize the length of phases and boss ability casts are added, removed, shortened, or extended to match.
    If the boss has repeating phases, you can also customize the number of repeats.
-   Hover over boss ability bars to highlight all assignments associated with them.
-   Choose how many rows are shown and completely hide the abilities you don't care about.

**Assignments**

-   Collapse spells by assignee for a compact view or expand them to view cooldown durations and charges. Customize cooldown durations and charges if they don't match reality, or hide cooldowns altogether.
-   Add an assignment by left-clicking anywhere on the assignment timeline.
-   Duplicate assignments by control-dragging an assignment spell icon.
-   Change the time of an assignment by dragging an assignment spell icon.
-   Edit the assignment trigger, spell, text, target, and more by clicking the assignment spell icon.
-   Swap all assignments between assignees by clicking the reassign button.

**Reminders**

-   The reminder system is highly configurable and includes over 60 individual settings, which operate independently of plans.
-   Receive visual cues for assignments with progress bars, messages, and/or icons.
-   Receive auditory cues using text to speech and sounds.
-   Target frames automatically receive a glow border for targeted assignments.
-   Simulate reminders for plan from the main window.

**Other**

-   **In Game Tutorial**: The optional interactive tutorial walks you through the key features of Encounter Planner.
-   **Extensive User Guide**: Every part of the addon is documented.
-   **Validation System**: Assignments failed to import? Any issues you should be aware of are logged to a small window at the bottom of the main window. They are automatically resolved if possible.

## FAQ

What is the performance like?

-   Memory Usage: Above average. This is due to the boss ability tables, boss spell cast tables, plans, assignments, etc.
-   CPU Usage: Low.
    In raids, reminders typically require 0.1ms of a frame and less if there are no combat log event assignments active.
    In dungeons, typically 0.05ms or less of a frame.
    The GUI should never have any noticeable lag with the exception of resizing the main window.

Can I use Encounter Planner if the rest of my raid does not?

-   Yes, you can create assignments and reminders for just yourself and it will not interfere with other addons or WeakAuras.

I only care about creating or editing assignments, can reminders be disabled?

-   Yes, reminders can be disabled globally or on a per-plan basis.

Can I use Encounter Planner with Viserio/Kaze/MRT?

-   Yes, you can import the current MRT Note or import plain text in note-like format, and export it back to plain text.
    However, it is possible that other sources choose to include spells that I have not chosen to include.
    The validation system will kick in if this is the case.

What if I have other text in the Note besides assignments?

-   Non-assignment text is preserved and included in the export string.

Can other addons or WeakAuras get the Encounter Planner plan/note like they do with the MRT Note?

-   Yes, there is an [API](https://github.com/markoleptic/EncounterPlanner/wiki/API) that can be used to get non-assignment text.
    However, they have to actually use it.

How do I know which assignment type to use?

-   Prefer using timed assignments when possible.
    Combat log event assignments should be used when timed assignments would be unreliable, such as when a boss phase is triggered by percent health.
    Every spell of every boss is limited to only combat log event types that will actually occur.
    When adding an assignment in a boss phase that is triggered by something other than time, a curated ability and combat log event type is automatically chosen.
