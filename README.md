# Roblox Admin System Export

This folder is the Codex-side index for the Roblox Studio admin system built in `Place1`.

The actual live scripts are inside Roblox Studio at these Explorer paths:

```text
ReplicatedStorage.AdminSystem.Modules.AdminConfig
ServerScriptService.AdminSystem.AdminLogger
ServerScriptService.AdminSystem.AdminService
ServerScriptService.AdminSystem.AdminServer
StarterGui.AdminPanel.AdminClient
```

Open Roblox Studio's Explorer and select each object above to view or edit the real script source.

## Full Explorer Tree

```text
game
    ReplicatedStorage
        AdminSystem
            Remotes
                AdminActionRequest (RemoteEvent)
                AdminActionResult (RemoteEvent)
                RequestPlayerList (RemoteFunction)
            Modules
                AdminConfig (ModuleScript)

    ServerScriptService
        AdminSystem
            AdminLogger (ModuleScript)
            AdminService (ModuleScript)
            AdminServer (Script)

    StarterGui
        AdminPanel (ScreenGui)
            MainFrame (Frame)
                TitleLabel (TextLabel)
                PlayerNameBox (TextBox)
                UserIdBox (TextBox)
                ReasonBox (TextBox)
                DurationBox (TextBox)
                BanButton (TextButton)
                UnbanButton (TextButton)
                KickButton (TextButton)
                SettingNameBox (TextBox)
                SettingValueBox (TextBox)
                ChangeSettingButton (TextButton)
                RefreshPlayersButton (TextButton)
                PlayerListFrame (ScrollingFrame)
                ResultLabel (TextLabel)
                PanelScale (UIScale)
                UISizeConstraint
                UICorner
                UIStroke
            AdminClient (LocalScript)
            AdminToggleButton (TextButton)
```

## What Each Script Does

- `AdminConfig`: Stores trusted admin UserIds, ranks, permissions, ban limits, allowed stats, and allowed character settings.
- `AdminLogger`: Prints every admin action and attempts DataStore logging when available.
- `AdminService`: Server-only logic for ban, unban, kick, player list, stat edits, speed/jump/health changes, cooldowns, and validation.
- `AdminServer`: Connects RemoteEvents and RemoteFunctions to `AdminService`.
- `AdminClient`: Handles the admin UI only; it never bans, kicks, or changes players directly.

## Current Admin

```lua
-- AlwaysBeAKing
[3258500526] = "Owner"
```

## Owner/Admin Character Settings

Only `Owner` and `SeniorAdmin` can use these:

```text
WalkSpeed
JumpPower
JumpHeight
MaxHealth
Health
```

Moderators cannot see or use the setting controls.
