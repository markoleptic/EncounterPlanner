# User Guide

## Introduction

### Console Commands

-   `ep`: Opens the [Main Window](#main-window).
-   `ep options`: Open the [Preferences](#preferences) window.
-   `ep minimap`: Toggles showing the minimap icon.

## Main Window

The **Main Window** is composed of the following:

-   [Menu Bar](#menu-bar)
-   [Current Plan Bar](#current-plan-bar)
-   [Boss Timeline](#boss-timeline)
-   [Assignment Timeline](#assignment-timeline)
-   [Status Bar](#status-bar)

## Menu Bar

### Plan

#### New Plan

Displays the **Create New Plan** dialog.

-   **Boss**: The boss to create the plan for. This can be changed later.
-   **Plan Name**: Unique name for the plan.

#### Duplicate Plan

Duplicates the current plan with a unique name.

#### Import

One of the benefits of using Encounter Planner is not dealing with note syntax anymore, but you can still import notes from other addons or tools such as MRT, Viserio Cooldowns, or Viserio healing spreadsheets:

-   **From MRT**:
    Creates a new plan with a unique name based on the current note in MRT (`VMRT.Note.Text1`).
-   **From String**:
    Displays the **Import From String** dialog. Paste the note into the edit box.
    -   **Overwrite Current Plan**: If checked, the current plan will be overwritten with the note assignment contents.
    -   **New Plan Name**: Unique name for the plan if not overwriting the current plan.

> [!NOTE]  
> Non-assignment lines are saved as [External Text](#external-text) and are included with assignments when exporting.

Each assignment line in a note is composed of a **Time** section, an **Assignments** section, and optionally an **Ignored Text** section.
Text in the **Ignored Text** section must have a dash (`-`) at the end to be ignored.
Both of the following are valid:

-   `[TimeSection][AssignmentsSection]`
-   `[TimeSection][IgnoredText]-[AssignmentsSection]`

The **Time** section determines what triggers an assignment and specifies one of the following:

-   A time relative to the start of the encounter
-   A time relative to a combat log event

> [!NOTE]  
> Phase based assignments are not currently supported. However, combat log event assignments can accomplish the same thing.

**Time Relative to the Start of the Encounter**

`{time:[mm]:[ss]}`

-   **\[mm\]**:
    Minute portion of time. If no seconds are provided, this is assumed as seconds.
-   **\[ss\]**:
    Time in seconds.

**Time relative to a Combat Log Event**

`{time:[mm]:[ss],[EventType]:[SpellID]:[SpellCount]}`

-   **\[mm\]**:
    Minute portion of time. If no seconds are provided, this is assumed as seconds.
-   **\[ss\]**:
    Time in seconds.
-   **\[EventType\]**:
    The type of combat log event:
    -   **`SCC`**: SPELL_CAST_SUCCESS
    -   **`SCS`**: SPELL_CAST_START
    -   **`SAA`**: SPELL_AURA_APPLIED
    -   **`SAR`**: SPELL_AURA_REMOVED
-   **\[SpellID\]**:
    The spell ID associated with the combat log event.
-   **\[SpellCount\]**:
    The number of times the combat log event must occur before the assignment is triggered.
    This can also be considered the occurrence number.
    The first occurrence in an encounter is always 1.

The **Assignments** section is list separated by double spaces (`  `), where each entry is composed of **Assignee(s)** and an **Assignment**.

**Assignee(s)**

This can be a character name, class, role, group, spec, or type. Multiple **Assignee(s)** can be assigned to the same **Assignment** by using commas between them.

-   **Character Name**:
    `[Name]`, where **\[Name\]** is the name of a character. If the realm name is included, there must be a dash (`-`) between the **Time** and **Assignments** sections.
    -   **Target**:
        `[Name]@[TargetName]`
        If the **\[Name\]** has a `@` symbol at the end followed by a **\[TargetName\]**, the assignment is considered a "targeted" assignment.
-   **Class**:
    `class:[Class Name]` where **\[Class Name\]** is one of the 13 classes. Case insensitive with no spaces.
-   **Role**:
    `role:[Role Type]` where **\[Role Type\]** is one of the following (case insensitive):
    -   **`Damager`**, **`Healer`**, or **`Tank`**.
-   **Group**:
    `group:[Group Number]` where **\[Group Number\]** is one of the following:
    -   **`1`**, **`2`**, **`3`**, or **`4`**.
-   **Spec**:
    `spec:[Specialization]` where **\[Specialization\]** is either the name of a specialization (case insensitive) or the specialization ID.
-   **Type**:
    `type:[Combat Type]` where **\[Combat Type\]** is one of the following (case insensitive):

    -   **`Ranged`** or **`Melee`**.

**Assignment**

This is the spell and/or text being assigned to the **Assignee(s)**.

-   **Spell**:
    `{spell:[Spell ID]}` where **\[Spell ID\]** is the ID of the spell being assigned.
-   **Text**:
    `{text}[Text]{/text}` where **\[Text\]** is text you want the assignment to display.

**Examples**

```
{time:75} Markoleptic {spell:235450}{text}Yo{/text}  class:deathknight {spell:51052}
{time:00:40}|cff3ec6eaRandom colored text|r - |cff3ec6eaMarkoleptic|r @|cff3ec6eaMarkoleptic|r {spell:235450}
{time:1:00} Markoleptic {spell:235450}  type:ranged {text}Go to {square}{/text}
{time:1:15,SCS:450483:1} Markoleptic {text}Yo {square}{/text}
{time:45,SCC:450483:2} spec:62 {spell:365350}  spec:fire {spell:190319}
{time:1:00,SCC:450483:2} spec:62,spec:fire,Markoleptic {spell:414660}
{time:1:30,SAR:450483:2} class:evoker {spell:6262}{text}Use Healthstone {6262}{/text}
```

#### Export Current Plan

Displays the **Export** window. This can be used to copy the plan assignments to an MRT note.

#### Delete Current Plan

Displays a confirmation dialog, and if confirmed, deletes the current plan.

### Boss

**Change Boss**:
Selecting a boss from this dropdown menu will do one of the following:

-   If the assignments are all time-based (no combat log event assignments), no dialog is presented and the plan is converted to the new boss.
-   If the plan contains any combat log event assignments, the **Changing Boss with Combat Log Event Assignments** dialog is displayed.
    -   **Convert to Timed Assignments**:
        Converts all assignments in the plan to timed assignments.
        The relative combat log event times will be converted to time from the beginning of the encounter.
        For example, if an assignment is based on a boss spell cast that usually happens 40 seconds into the encounter, and the time for the assignment is 5 seconds, the new time for the assignment will be 45 seconds.
    -   **Replace Spells**:
        Replaces combat log event assignment spells with those of the new boss, using the nearest spells of the new boss.
    -   **Cancel**:
        No changes are made.

> [!CAUTION]  
> **Convert to Timed Assignments** and **Replace Spells** are one-way actions, meaning that converting from boss A to boss B and converting back to boss A will not necessarily restore the original state.

**Edit Phase Timings**:
Displays the **Phase Timing Editor** window, which allows you customize the phase duration and counts of the boss encounter.
These settings are unique to each plan.

-   If bosses only have one phase, the **Custom Count** box will not be editable.
-   Some bosses may have phases in which:
    -   The **Custom Duration** box is not editable (Ulgrax the Devourer Phase 1).
    -   The **Custom Count** box is not editable (All Queen Ansurek phases).
    -   The total boss encounter duration is always capped at 20 minutes.
-   **Reset All to Default**:
    Resets the phase duration and counts to their default values.

**Filter Spells**:
Selecting a boss spell from this dropdown hides it from the boss timeline.
Assignments that rely on the boss spell are not be affected.

### Roster

Clicking this button opens the **Roster Editor**.

-   **Current Plan Roster**:
    The roster that is unique to the plan. To assign players to assignments in the plan, this roster must contain their name.
    The **Add Assignee -> Individual** menu is populated from this list.

    -   **Update From Shared Roster**: Updates class and role information from the **Shared Roster**. Requires roster members be present in both rosters.
    -   **Fill From Shared Roster**: Adds all roster members from the **Shared Roster** into the **Current Plan Roster**, if they are not already present.
    -   **Import Current Party/Raid Group**: Adds all characters in the current party or raid group to the **Current Plan Roster**.

-   **Shared Roster**:
    This roster can be used to populate plan rosters without adding players individually. It is independent of plans.

    -   **Update From Current Plan Roster**: Updates class and role information from the **Current Plan Roster**. Requires roster members be present in both rosters.
    -   **Fill From Shared Roster**: Adds all roster members from the **Current Plan Roster** into the **Shared Roster**, if they are not already present.
    -   **Import Current Party/Raid Group**: Adds all characters in the current party or raid group to the **Shared Roster**.

### Preferences

Clicking this button opens the **Preferences** window.
All of the settings in this menu are independent of plans.

#### Cooldown Overrides

If the cooldown durations obtained using the WoW API don't match reality, you can set custom spell cooldown durations using this menu.
These durations are used in place of the default to draw the [Spell Cooldown Durations](#view), if enabled.

#### Keybindings

**Assignment**:

-   **Add Assignment**:
    Creates a new assignment when this key is pressed when hovering over the timeline.
    Default value is `Left Click`.
-   **Edit Assignment**:
    Opens the [Assignment Editor](#assignment-editor) when this key is pressed when hovering over an assignment spell icon.
    Default value is `Left Click`.
-   **Duplicate Assignment**:
    Creates a new assignment based on the assignment being hovered over after holding, dragging, and releasing this key.
    Default value is `Ctrl + Left Click`.

**Timeline**:

-   **Pan**:
    Pans the timeline to the left and right when holding this key..
    Default value is `Right Click`.
-   **Scroll**:
    Scrolls the timeline up and down.
    Default value is `Mouse Scroll`.
-   **Zoom**:
    Zooms in horizontally on the timeline.
    Default value is `Ctrl + Mouse Scroll`.

#### Reminder

**Enable Reminders**:
Whether to enable reminders for assignments.
If unchecked, this setting overrides any plans with **Enable Reminders for Plan** checked.

**Only Show Reminders For Me**:
Whether to only show assignment reminders that are relevant to you.

> [!CAUTION]  
> You will see all reminders for everyone in the plan if this is not checked.

**Hide or Cancel if Spell on Cooldown**:
If an assignment is a spell and it already on cooldown, the reminder will not be shown.
If the spell is cast during the reminder countdown, it will be cancelled.

**Glow Frame for Targeted Spells**:
Glows the unit frame of the target at the end of the countdown.
If the assignment has a spell ID, the frame will glow until the spell is cast on the target, up to a maximum of 10 seconds.
Otherwise, shows for 5 seconds.

**Countdown Length**:
How far ahead to begin showing reminders.

**Enable Messages**:
Whether to show Messages for assignments.

**Toggle Message Anchor**:
Displays example Messages that can be moved by dragging.

**Message Visibility**:

-   **Expiration Only**: Only shows Messages at expiration time. Messages are displayed for 2 seconds before fading for 1.2 seconds.
-   **With Countdown**: Messages are displayed for the duration of the countdown, including countdown text, before fading for 1.2 seconds.

**Position**:

-   **X**:
    The horizontal offset from the **Relative Anchor Point** to the **Anchor Point**.
-   **Y**:
    The vertical offset from the **Relative Anchor Point** to the **Anchor Point**.

**Message Order**:

-   **Soonest Expiration on Top**:
    Messages are displayed in ascending order, with the message expiring the soonest on top.
-   **Soonest Expiration on Bottom**:
    Messages are displayed in descending order, with the message expiring the soonest on bottom.

**Anchor Point**:
Which spot on the Message container is fixed; Bottom will expand upwards, Top downwards, Left/Right/Center from center.

**Anchor Frame**:
The frame that the Message container is anchored to. Defaults to UIParent (screen).

-   **Choose**:
    Clicking this button will highlight frames you hover over.
    `Left Click` to set the **Anchor Frame**.
    `Right Click` to cancel.

**Relative Anchor Point**:
The anchor point on the frame that the Message container is anchored to.

**Font**:
Font to use for Message text.

**Font Size**:
Font size to use for Message text (8 - 64).

**Font Outline**:
Font outline to use for Message text.

**Text Color**:
Text Color to use for Message text.

**Message Transparency**:
Transparency of Messages (0.0 - 1.0).

**Enable Progress Bars**:
Whether to show Progress Bars for assignments.

**Toggle Progress Bar Anchor**:
Displays example Progress Bars that can be moved by dragging.

**Anchor Point**:
Which spot on the Progress Bar container is fixed; Bottom will expand upwards, Top downwards, Left/Right/Center from center.

**Position**:

-   **X**:
    The horizontal offset from the **Relative Anchor Point** to the **Anchor Point**.
-   **Y**:
    The vertical offset from the **Relative Anchor Point** to the **Anchor Point**.

**Bar Order**:

-   **Soonest Expiration on Top**:
    Messages are displayed in ascending order, with the message expiring the soonest on top.
-   **Soonest Expiration on Bottom**:
    Messages are displayed in descending order, with the message expiring the soonest on bottom.

**Anchor Frame**:
The frame that the Progress Bar container is anchored to. Defaults to UIParent (screen).

-   **Choose**:
    Clicking this button will highlight frames you hover over.
    `Left Click` to set the **Anchor Frame**.
    `Right Click` to cancel.

**Relative Anchor Point**:
The anchor point on the frame that the Progress Bar container is anchored to.

**Font**:
Font to use for Progress Bar text.

**Font Size**:
Font size to use for Progress Bar text (8 - 64).

**Font Outline**:
Font outline to use for Progress Bar text.

**Icon Position**

-   **Left**: Icon on left, text and duration on right.
-   **Right**: Icon on right, text and duration on left.

**Duration Position**:

-   **Left**: Duration to the left of text.
-   **Right**: Duration to the right of text.

**Bar Progress Type**

-   **Fill**: Fills Progress Bars from left to right as the countdown progresses.
-   **Drain**: Drains Progress Bars from right to left as the countdown progresses.

**Bar Size**:
The width and height of Progress Bars.

**Bar Texture**:
The texture to use for the foreground and background of Progress Bars.

**Bar Color**:

-   **Foreground Color**:
    Foreground color for Progress Bars.
-   **Background Color**:
    Background color for Progress Bars.

**Bar Transparency**:
Transparency of Progress Bars (0.0 - 1.0).

**Bar Border**:

-   **Show Border**:
    Whether to show a 1px border around Progress Bars.
-   **Show Icon Border**:
    Whether to show a 1px border around Progress Bar icons.

**Bar Spacing**:
Spacing between Progress Bars (-1 - 100).

**Play Text to Speech at Countdown Start**:
Whether to play text to speech sound at the start of the countdown (i.e. Spell in x seconds).

**Play Text to Speech at Countdown End**:
Whether to play text to speech sound at the end of the countdown (i.e. speak spell or text).

**Text to Speech Voice**:
The voice to use for Text to Speech.

**Text to Speech Volume**:
The volume to use for Text to Speech.

**Play Sound at Countdown Start**:
Whether to play a sound at the start of the countdown.

**Sound to Play at Countdown Start**:
The sound to play at the start of the countdown.

**Play Sound at Countdown End**:
Whether to play a sound at the end of the countdown.

**Sound to Play at Countdown End**:
The sound to play at the end of the countdown.

**Clear Trusted Characters**:
Clears all saved trusted characters.
You will see a confirmation dialog each time a non-trusted character sends a plan to you.

#### View

**Preferred Number of Assignments to Show**:
The assignment timeline will attempt to expand or shrink to show this many rows.

**Preferred Number of Boss Abilities to Show**:
The boss ability timeline will attempt to expand or shrink to show this many rows.

**Timeline Zoom Behavior**:

-   **At cursor**: Zooms in toward the position of your mouse cursor, keeping the area under the cursor in focus.
-   **Middle of timeline**: Zooms in toward the horizontal center of the timeline, keeping the middle of the visible area in focus.

**Assignee Sort Priority**:

-   **Alphabetical**: Alphabetically by assignee name.
-   **First Appearance**: Earliest assignment time.
-   **Role > Alphabetical**: Healers appear first, followed by tanks and dps. Falls back to **Alphabetical**.
-   **Role > First Appearance**: Healers appear first, followed by tanks and dps. Falls back to **First Appearance**.

**Show Spell Cooldown Duration**:
Whether to show textures representing player spell cooldown durations.

#### Profile

**Current Profile**:
The currently active profile, where all plans, rosters, and preferences are saved.

**Reset Profile**:
Displays a confirmation dialog, and if confirmed, resets the **Current Profile** to default.

**New**:
Creates a new empty profile and switches to it.

**Copy From**:
Copies the settings from an existing profile into the **Current Profile**.

**Delete a Profile**:
Displays a confirmation dialog, and if confirmed, deletes the selected profile from the database.

## Current Plan Bar

**Current Plan**:
The currently active plan.
Plans with reminders enabled will display a yellow bell icon next to their name in the dropdown, while plans with reminders disabled will show a desaturated bell icon.

**Designated External Plan**:
Denotes whether the [External Text](#external-text) of the plan should be made available to other addons or WeakAuras.
Each boss must have a unique **Designated External Plan**.

-   Only the group leader needs to have the correct designation.
    When the encounter starts, the group leader will automatically send an addon message to everyone in the group so that everyone has the same [External Text](#external-text).

**Plan Reminders**:
Whether reminders are enabled for the **Current Plan**.
The option is disabled when reminders are disabled globally ([Preferences -> Reminders -> Enable Reminders](#reminder))

**Simulate Reminders**:
Simulates reminders for the **Current Plan**.
Some features may be disabled when simulating.
**Enable Reminders for Plan** and [Preferences -> Reminders -> Enable Reminders](#reminder) must be checked for this to have an effect.

**Send Plan to Group**:
Sends the **Current Plan** to the party or raid group. Requires group leader or group assistant.

-   The person receiving the plan must either approve the plan to receive it or have the sender saved as a trusted character to automatically receive it.
-   If a receiver has not yet decided to accept or reject a plan and they are sent subsequent plans, they are placed in a queue.

### External Text

Clicking this button displays the **External Text Editor**. Lines from an imported note that were not assignments are stored as **External Text**.
**External Text** can be obtained by other addons and WeakAuras using the Encounter Planner API.

## Boss Timeline

**Boss Abilities** are listed on the left-hand side, with **Boss Ability Cast Bars** drawn on the timeline to the right.
Each occurrence of a **Boss Ability Cast Bar** increases the **Spell Count** for that spell.

-   Hovering over a **Boss Ability** icon displays its tooltip.
-   Hovering over a **Boss Ability Cast Bar** highlights the bar with a yellow outline and any assignments referencing it (combat log event assignments only).
-   Dashed yellow vertical lines mark phase transitions, with text indicating the next phase. Typically, the spell nearest the line triggers the transition.

## Assignment Timeline

**Assignees** are listed on the left, with **Assignment Spell Icons** drawn on the timeline to the right.

-   Click the dropdown arrow beside an **Assignee** to collapse or expand their view:
    -   **Collapsed**: Displays all spells in one row without cooldown duration textures.
    -   **Expanded**: Shows each spell on a separate row with cooldown duration textures (if [enabled](#view)).
-   Use **Collapse All** and **Expand All** buttons to adjust all assignees at once.

**Quick Actions**:

-   **Add an assignment**: Left-click anywhere on the timeline.
-   **Duplicate an assignment**: `Ctrl + Drag` an **Assignment Spell Icon**.
-   **Adjust assignment time**: Drag an **Assignment Spell Icon**.
-   **Select an assignment**: Click its icon to open the [Assignment Editor](#assignment-editor).
    A yellow outline indicates selection. If the assignment is a combat log event assignment, the **Boss Ability Cast Bar** it references is highlighted.

**Assignee Management**:

-   **Swap Assignee**: Transfers all assignments to a selected assignee.
-   **Delete Assignee**: Displays a confirmation dialog, and if confirmed, deletes all assignments for the assignee.
-   **Delete Spell Assignments**: Displays a confirmation dialog, and if confirmed, deletes assignments for a specific spell.

### Assignment Editor

**Trigger**:
Defines what activates an assignment.

-   **Fixed Time**: Triggered at a set time from the encounter start.
-   **Combat Log Event**:
    Triggered by specific combat events:
    -   **Spell Cast Success** (SPELL_CAST_SUCCESS)
    -   **Spell Cast Start** (SPELL_CAST_START)
    -   **Spell Aura Applied** (SPELL_AURA_APPLIED)
    -   **Spell Aura Removed** (SPELL_AURA_REMOVED)

**Time**:

-   For **Fixed Time**, this is from encounter start.
-   For **Combat Log Event** this is from the event time.

**Assignee**:
To whom the assignment is assigned to:

-   **Class**, **Group Number**, **Individual**, **Role**, **Spec**, **Type**, or **Everyone**.
-   **Individual** is disabled if there are no members in the [Current Plan Roster](#roster).

**Spell**:
If checked, the assignment will be associated with a spell.
This doesn't do anything other than update the default text.

**Target**:
If enabled, highlights the target's raid frame at assignment time.

**Text**:
Text to display on Reminders (Messages and Progress Bars).

-   If left blank, text is filled by default:

    -   If the assignment has a **Spell**, the spell icon and spell name are added.
    -   If the assignment has a **Target**, the target's name is added.

-   Icons can be inserted into text by using the syntax `{[icon]}`, where `[icon]` can be a raid marker name (English only), a class name, a spell ID, or a spell name (spotty):

    -   `{Death Knight} go to {star}`
        -   `{Death Knight}` replaced with class icon
        -   `{star}` replaced with star icon
    -   `{Mage} cast {31661}`
        -   `{Mage}` replaced with class icon
        -   `{31661}` replaced with spell icon for Dragon's Breath
    -   `{Mage} cast {Dragon's Breath}`
        -   `{Mage}` replaced with class icon
        -   `{Dragon's Breath}` is not replaced for some reason
    -   `{Mage} cast {Mass Barrier}` Works
        -   `{Mage}` replaced with class icon
        -   `{star}` replaced with Mass Barrier icon

**Preview**:
Displays a preview of the **Text** that will be shown on Reminders (Messages and Progress Bars).

**Delete Assignment**:
Deletes the assignment without confirmation.

## Status Bar

The **Status Bar** communicates major changes and warnings.

-   **Plan Sharing**:

    -   Received a plan from another player.
    -   Sent a plan to other players.
    -   Confirmed plan receipt by # players.
    -   Updated a matching plan after receiving one from another player.
    -   Imported a plan as unique due to a name conflict after receiving it from another player.
    -   Changed the Designated External Plan after receiving one from another player while in a raid group.

-   **Assignment Importing**:

    -   Failed to import assignments due to invalid assignees.
    -   Converted assignments to timed assignments due to:
        -   Invalid assignment type.
        -   Invalid combat log event type.
        -   Invalid combat log event spell ID.
        -   Combat log event spell ID from a boss different from the majority.
    -   Assigned different spell counts due to invalid combat log event spell counts.

-   **Assignment Management and Visibility**:

    -   Deleted assignments from a plan.
    -   Hidden assignments may exist due to starting after the encounter ends.
        -   Resolved hidden assignments.
    -   Detected overlapping assignments.
    -   Failed to update assignments (unexpected behavior).
