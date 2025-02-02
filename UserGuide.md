# User Guide

## Introduction

### Console Commands

## Menu Bar

### Plan

**New Plan**:

**Duplicate Plan**:

#### Import

One of the benefits of using Encounter Planner is not dealing with note syntax anymore, but you can still import notes from other addons or tools such as MRT, Viserio Cooldowns, or Viserio healing spreadsheets.

**From MRT**:

**From String**:

Each line in a note is composed of a **Time** section, an **Assignments** section, and optionally an **Ignored Text** section.
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
    The first occurrence in an encounter will always be 1.

The **Assignments** section is list separated by double spaces (`  `), where each entry is composed of **Assignment Unit(s)** and an **Assignment**.

**Assignment Unit(s)**

This can be a character name, class, role, group, spec, or type. Multiple **Assignment Unit(s)** can be assigned to the same **Assignment** by using commas between them.

-   **Character Name**:
    `[Name]`, where **\[Name\]** is the name of a character. If the realm name is included, there must be a dash (`-`) between the **Time** and **Assignments** sections.
    -   **Target**:
        `[Name]@[TargetName]`
        If the **\[Name\]** has a `@` symbol at the end followed by a **\[TargetName\]**, the assignment will be considered a "targeted" assignment.
-   **Class**:
    `class:[Class Name]` where **\[Class Name\]** is one of the 13 classes. Case insensitive with no spaces.
-   **Role**:
    `role:[Role Type]` where **\[Role Type\]** is one of the following (case insensitive):
    -   **`Damager`**
    -   **`Healer`**
    -   **`Tank`**
-   **Group**:
    `group:[Group Number]` where **\[Group Number\]** is one of the following:
    -   **`1`**
    -   **`2`**
    -   **`3`**
    -   **`4`**
-   **Spec**:
    `spec:[Specialization]` where **\[Specialization\]** is either the name of a specialization (case insensitive) or the specialization ID.
-   **Type**:
    `type:[Combat Type]` where **\[Combat Type\]** is one of the following (case insensitive):

    -   **`Ranged`**
    -   **`Melee`**

**Assignment**

This is the spell and/or text being assigned to the **Assignment Unit(s)**.

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

#### Delete Current Plan

### Boss

#### Change Boss

#### Edit Phase Timings

#### Filter Spells

### Roster

#### Edit Current Plan Roster

#### Edit Shared Roster

### Preferences

#### Cooldown Overrides

#### Keybindings

#### Reminder

#### View

#### Profile

### Current Plan Bar

**Current Plan**:

**Enable Reminders for Plan**:

**Simulate Reminders**:

**Send Plan to Group**:

## Boss Timeline

## Assignment Timeline

### Assignment

#### Swap Assignee

### Assignment Editor

## Status Bar
