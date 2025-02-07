local L = LibStub("AceLocale-3.0"):NewLocale("EncounterPlanner", "enUS", true)

L = L or {}
L["Encounter Planner"] = true
L["Plan"] = true
L["Import From String"] = true
L["Overwrite Current Plan"] = true
L["New Plan Name:"] = true
L["Overwrite"] = true
L["Import As"] = true
L["Import As New Plan"] = true
L["Intermission"] = true
L["Phase"] = true
L["Changing Boss with Combat Log Event Assignments"] = true
L["The current plan includes combat log event assignments tied to this boss's spells. Choose an option:"] = true
L["1. Convert all assignments to timed assignments for the new boss"] = true
L["2. Replace spells with those of the new boss, matching the closest timing"] = true
L["3. Cancel"] = true
L["Note: Replacing spells may not be reversible and could result in changes if you revert to the original boss."] = true
L["Convert to Timed Assignments"] = true
L["Cancel"] = true
L["Replace Spells"] = true
L["Filter Spells"] = true
L["Add Assignee"] = true
L["Default"] = true
L["No note was loaded due to MRT not being installed."] = true
L["Export"] = true
L["New Plan"] = true
L["Import"] = true
L["From"] = true
L["Create New Plan"] = true
L["From String"] = true
L["Export Current Plan"] = true
L["Delete Current Plan"] = true
L["Delete Plan Confirmation"] = true
L["Are you sure you want to delete the plan"] = true
L["Are you sure you want to overwrite the plan"] = true
L["Boss"] = true
L["Edit Phase Timings"] = true
L["Roster"] = true
L["Current Plan:"] = true
L["Enable Reminders for Plan"] = true
L["Simulate Reminders"] = true
L["Stop Simulating"] = true
L["Send Plan to Group"] = true
L["Delete Assignments Confirmation"] = true
L["Are you sure you want to delete all"] = true
L["assignments for"] = true
L["Error decoding"] = true
L["Error decompressing"] = true
L["Imported"] = true
L["has sent you the plan"] = true
L["Do you wish to accept the plan?"] = true
L["Trusting this character will allow them to send you new plans and update plans they have previously sent you without showing this message."] =
	true
L["Plan Received"] = true
L["Accept and Trust"] = true
L["Reject"] = true
L["Accept without Trusting"] = true
L["Racial"] = true
L["Trinket"] = true
L["Spec"] = true
L["Class"] = true
L["Group Number"] = true
L["1"] = true
L["2"] = true
L["3"] = true
L["4"] = true
L["Role"] = true
L["Damager"] = true
L["Healer"] = true
L["Tank"] = true
L["Everyone"] = true
L["Individual"] = true
L["assignment(s) failed to update"] = true
L["Invalid Boss Spell Count(s)"] = true
L["Invalid Boss Spell ID(s)"] = true
L["Group"] = true
L["Ranged"] = true
L["Melee"] = true
L["No spell cast times found for boss"] = true
L["with spell ID"] = true
L["with spell count"] = true
L["Progress Bar Text"] = true
L["Open Preferences"] = true
L["Left Click"] = true
L["Alt + Left Click"] = true
L["Ctrl + Left Click"] = true
L["Shift + Left Click"] = true
L["Middle Mouse Button"] = true
L["Alt + Middle Mouse Button"] = true
L["Ctrl + Middle Mouse Button"] = true
L["Shift + Middle Mouse Button"] = true
L["Right Click"] = true
L["Alt + Right Click"] = true
L["Ctrl + Right Click"] = true
L["Shift + Right Click"] = true
L["Left"] = true
L["Center"] = true
L["Right"] = true
L["Top Left"] = true
L["Top"] = true
L["Top Right"] = true
L["Right"] = true
L["Bottom Right"] = true
L["Bottom"] = true
L["Left"] = true
L["Bottom Left"] = true
L["Center"] = true
L["None"] = true
L["Monochrome"] = true
L["Outline"] = true
L["Thick Outline"] = true
L["Keybindings"] = true
L["Pan"] = true
L["Pans the timeline to the left and right when holding this key."] = true
L["Timeline"] = true
L["Scroll"] = true
L["Scrolls the timeline up and down."] = true
L["Mouse Scroll"] = true
L["Alt + Mouse Scroll"] = true
L["Ctrl + Mouse Scroll"] = true
L["Shift + Mouse Scroll"] = true
L["Zoom"] = true
L["Zooms in horizontally on the timeline."] = true
L["Add Assignment"] = true
L["Creates a new assignment when this key is pressed when hovering over the timeline."] = true
L["Assignment"] = true
L["Edit Assignment"] = true
L["Opens the assignment editor when this key is pressed when hovering over an assignment spell icon."] = true
L["Duplicate Assignment"] = true
L["Creates a new assignment based on the assignment being hovered over after holding, dragging, and releasing this key."] =
	true
L["Reminder"] = true
L["Enable Reminders"] = true
L["Whether to enable reminders for assignments."] = true
L["Only Show Reminders For Me"] = true
L["Whether to only show assignment reminders that are relevant to you."] = true
L["Hide or Cancel if Spell on Cooldown"] = true
L["If an assignment is a spell and it already on cooldown, the reminder will not be shown. If the spell is cast during the reminder countdown, it will be cancelled."] =
	true
L["Hide or Cancel on Phase Change"] = true
L["Reminders associated with combat log events in a certain phase will be cancelled or hidden when the phase transitions."] =
	true
L["Reminder Advance Notice"] = true
L["How far ahead of assignment time to begin showing reminders."] = true
L["Enable Messages"] = true
L["Whether to show Messages for assignments."] = true
L["Messages"] = true
L["Toggle Message Anchor"] = true
L["Message Visibility"] = true
L["When to show Messages only at expiration or show them for the duration of the countdown."] = true
L["Expiration Only"] = true
L["With Countdown"] = true
L["Anchor Point"] = true
L['Anchor point of the Message frame, or the "spot" on the Message frame that will be placed relative to another frame.'] =
	true
L["Anchor Frame"] = true
L["The frame that the Message frame is anchored to. Defaults to UIParent (screen)."] = true
L["Relative Anchor Point"] = true
L["The anchor point on the frame that the Message frame is anchored to."] = true
L["Position"] = true
L["X"] = true
L["Y"] = true
L["The horizontal offset from the Relative Anchor Point on the Anchor Frame to the Anchor Point."] = true
L["The vertical offset from the Relative Anchor Point on the Anchor Frame to the Anchor Point."] = true
L["Font"] = true
L["Font to use for Message text."] = true
L["Font Size"] = true
L["Font size to use for Message text (8 - 48)."] = true
L["Font Outline"] = true
L["Font outline to use for Message text."] = true
L["Text Color"] = true
L["Text color to use for Message text."] = true
L["Alpha"] = true
L["Transparency of Messages (0.0 - 1.0)."] = true
L["Enable Progress Bars"] = true
L["Whether to show Progress Bars for assignments."] = true
L["Progress Bars"] = true
L["Toggle Progress Bar Anchor"] = true
L['Anchor point of the Progress Bars frame, or the "spot" on the Progress Bars frame that will be placed relative to another frame.'] =
	true
L["The frame that the Progress Bars frame is anchored to. Defaults to UIParent (screen)."] = true
L["The anchor point on the frame that the Progress Bars frame is anchored to."] = true
L["Font to use for Progress Bar text."] = true
L["Font size to use for Progress Bar text."] = true
L["Font outline to use for Progress Bar text."] = true
L["Alignment of Progress Bar text."] = true
L["Alignment of Progress Bar duration text."] = true
L["Bar Texture"] = true
L["The texture to use for the Progress Bar foreground and background."] = true
L["Bar Width"] = true
L["The width of Progress Bars."] = true
L["Bar Progress Type"] = true
L["Whether to fill or drain Progress Bars."] = true
L["Fill"] = true
L["Drain"] = true
L["Icon Position"] = true
L["Which side to place the icon for Progress Bars."] = true
L["Transparency of Progress Bars (0.0 - 1.0)."] = true
L["Color"] = true
L["Foreground color for Progress Bars."] = true
L["Background color for Progress Bars."] = true
L["Foreground"] = true
L["Background"] = true
L["Border"] = true
L["Show Border"] = true
L["Show Icon Border"] = true
L["Whether to show a 1px border around Progress Bars."] = true
L["Whether to show a 1px border around Progress Bar icons."] = true
L["Spacing"] = true
L["Spacing between Progress Bars (-1 - 100)."] = true
L["Play Text to Speech at Advance Notice"] = true
L["Whether to play text to speech sound at advance notice time (i.e. Spell in x seconds)."] = true
L["Text to Speech"] = true
L["Play Text to Speech at Assignment Time"] = true
L["Whether to play text to speech sound at assignment time (i.e. Spell in x seconds)."] = true
L["Text to Speech Voice"] = true
L["The voice to use for Text to Speech"] = true
L["Text to Speech Volume"] = true
L["The volume to use for Text to Speech"] = true
L["Sound"] = true
L["Play Sound at Advance Notice"] = true
L["Sound to Play at Advance Notice"] = true
L["Whether to play a sound at advance notice time."] = true
L["The sound to play at advance notice time."] = true
L["Play Sound at Assignment Time"] = true
L["Sound to Play at Assignment Time"] = true
L["Whether to play a sound at assignment time."] = true
L["The sound to play at assignment time."] = true
L["Clear Trusted Characters"] = true
L["Other"] = true
L["Clears all saved trusted characters. You will see a confirmation dialogue each time a non-trusted character sends a plan to you."] =
	true
L["Preferred Number of Assignments to Show"] = true
L["The assignment timeline will attempt to expand or shrink to show this many rows."] = true
L["Preferred Number of Boss Abilities to Show"] = true
L["The boss ability timeline will attempt to expand or shrink to show this many rows."] = true
L["Timeline Zoom Center"] = true
L["Where to center the zoom when zooming in on the timeline."] = true
L["At cursor"] = true
L["Middle of timeline"] = true
L["Assignment Sort Priority"] = true
L["Sorts the rows of the assignment timeline."] = true
L["Alphabetical"] = true
L["First Appearance"] = true
L["Role > Alphabetical"] = true
L["Role > First Appearance"] = true
L["Show Spell Cooldown Duration"] = true
L["Creates a new assignment based on the assignment being hovered over after holding, dragging, and releasing this key."] =
	true
L["Current Profile"] = true
L["Profile"] = true
L["Select the currently active profile."] = true
L["Reset Profile"] = true
L["Reset the current profile to default."] = true
L["Are you sure you want to reset"] = true
L["New"] = true
L["Create a new empty profile."] = true
L["Copy From"] = true
L["Copy the settings from an existing profile into the currently active profile."] = true
L["Delete a Profile"] = true
L["Delete a profile from the database."] = true
L["Are you sure you want to delete"] = true
L["View"] = true
L["None"] = true
L["Unknown"] = true
L["Text"] = true
L["Text:"] = true
L["Text Alignment"] = true
L["Duration Alignment"] = true
L["Assignment Editor"] = true
L["Combat Log Event"] = true
L["Fixed Time"] = true
L["Trigger:"] = true
L["Spell"] = true
L["Spell:"] = true
L["Count:"] = true
L["Type:"] = true
L["Time:"] = true
L["Recent"] = true
L["Preview:"] = true
L["Delete Assignment"] = true
L["Target?"] = true
L["Okay"] = true
L["Cancel"] = true
L["Confirmation"] = true
L["Preferences"] = true
L["Phase"] = true
L["Default Duration"] = true
L["Custom Duration"] = true
L["Reset All to Default"] = true
L["Phase Timing Editor"] = true
L["Cast spell or something"] = true
L["Current Plan Roster"] = true
L["Roster Editor"] = true
L["Import Current Party/Raid Group"] = true
L["Fill from Shared Roster"] = true
L["Update from Shared Roster"] = true
L["Shared Roster"] = true
L["Current Plan Roster"] = true
L["Update from Current Plan Roster"] = true
L["Fill from Current Plan Roster"] = true
L["Glows the unit frame of the target at assignment time. If the assignment has a spell ID, the frame will glow until the spell is cast on the target, up to a maximum of 10 seconds. Otherwise, shows for 5 seconds."] =
	true
L["Glow Frame for Targeted Spells"] = true
L["Duplicate Plan"] = true
L["Create"] = true
L["in"] = true
L["Boss:"] = true
L["Plan Name:"] = true
L["Create New Plan"] = true
L["Change Boss"] = true
L["Edit Current Plan Roster"] = true
L["Edit Shared Roster"] = true
L["Overwrite Plan Confirmation"] = true
L["Default Count"] = true
L["Custom Count"] = true
L["Total"] = true
L["Default Cooldown"] = true
L["Custom Cooldown"] = true
L["Cooldown Overrides"] = true
L["Override the default cooldown of player spells."] = true
L["Failed to import"] = true
L["assignments"] = true
L["assignment"] = true
L["Invalid assignee name or role"] = true
L["assignments were defaulted to timed assignments"] = true
L["assignment was defaulted to a timed assignment"] = true
L["Invalid assignment type"] = true
L["Invalid combat log event type"] = true
L["Invalid combat log event spell ID"] = true
L["Invalid spell count"] = true
L["assignments had their spell counts replaced"] = true
L["assignment had its spell count replaced"] = true
L["Invalid spell count has been assigned the value"] = true
L["Wrong boss"] = true
L["Sending plan"] = true
L["Plan sent"] = true
L["Received plan"] = true
L["from"] = true
L["Plan received by"] = true
L["player"] = true
L["players"] = true
L["Use /ep minimap to show the minimap icon again."] = true
L["Left-Click|r to toggle showing the main window."] = true
L["Right-Click|r to open the options menu."] = true
L["Middle-Click|r to hide this icon."] = true
L["Updated matching plan"] = true
L["Imported plan as"] = true
L["Changed the primary plan to"] = true
L["Primary Plan"] = true
L["External Text"] = true
L["External Text Editor"] = true
