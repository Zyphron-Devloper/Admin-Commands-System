--[[
Roblox Studio Format for the Admin Project


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
                    UICorner
                    UIPadding
                    UIStroke
                UserIdBox (TextBox)
                    UICorner
                    UIPadding
                    UIStroke
                ReasonBox (TextBox)
                    UICorner
                    UIPadding
                    UIStroke
                DurationBox (TextBox)
                    UICorner
                    UIPadding
                    UIStroke
                BanButton (TextButton)
                    UICorner
                    UIStroke
                UnbanButton (TextButton)
                    UICorner
                    UIStroke
                KickButton (TextButton)
                    UICorner
                    UIStroke
                SettingNameBox (TextBox)
                    UICorner
                    UIPadding
                    UIStroke
                SettingValueBox (TextBox)
                    UICorner
                    UIPadding
                    UIStroke
                ChangeSettingButton (TextButton)
                    UICorner
                    UIStroke
                RefreshPlayersButton (TextButton)
                    UICorner
                    UIStroke
                PlayerListFrame (ScrollingFrame)
                    UICorner
                    UIListLayout
                    UIPadding
                    UIStroke
                ResultLabel (TextLabel)
                    UICorner
                    UIStroke
                PanelScale (UIScale)
                UISizeConstraint
                UICorner
                UIStroke
            AdminClient (LocalScript)
            AdminToggleButton (TextButton)
                UICorner
                UIStroke

note this script is optional to be put in the Roblox Studio its just made to tell the Roblox AI for putting these things where they need to be

use this prompt for it
Create a complete Roblox admin panel system.

Goal:
Make a secure server-authoritative admin panel UI. Trusted admins can ban, unban, kick, view players, and change safe character settings like WalkSpeed, JumpPower, JumpHeight, MaxHealth, and Health.

Create this exact Explorer structure:

ReplicatedStorage
- AdminSystem
  - Remotes
    - AdminActionRequest (RemoteEvent)
    - AdminActionResult (RemoteEvent)
    - RequestPlayerList (RemoteFunction)
  - Modules
    - AdminConfig (ModuleScript)

ServerScriptService
- AdminSystem
  - AdminLogger (ModuleScript)
  - AdminService (ModuleScript)
  - AdminServer (Script)

StarterGui
- AdminPanel (ScreenGui)
  - AdminClient (LocalScript)
  - AdminToggleButton (TextButton)
  - MainFrame (Frame)
    - TitleLabel (TextLabel)
    - PlayerNameBox (TextBox)
    - UserIdBox (TextBox)
    - ReasonBox (TextBox)
    - DurationBox (TextBox)
    - BanButton (TextButton)
    - UnbanButton (TextButton)
    - KickButton (TextButton)
    - SettingNameBox (TextBox)
    - SettingValueBox (TextBox)
    - ChangeSettingButton (TextButton)
    - RefreshPlayersButton (TextButton)
    - PlayerListFrame (ScrollingFrame)
    - ResultLabel (TextLabel)

Admin rules:
- Add AlwaysBeAKing as Owner.
- AlwaysBeAKing UserId is 3258500526.
- Store admins by UserId, not username.
- Owner can ban, unban, kick, change stats, and change settings.
- SeniorAdmin can ban, unban, kick, change stats, and change settings.
- Moderator can only kick and temporary ban.
- Moderators cannot change WalkSpeed, JumpPower, JumpHeight, MaxHealth, or Health.
- Admins cannot target another admin with equal or higher rank.
- Admins can change their own character settings.

Security:
- Never trust the client.
- Client only sends requests.
- Server validates admin rank, target UserId, reason, duration, cooldowns, and permissions.
- Use RemoteEvents and RemoteFunctions.
- BanAsync, UnbanAsync, Kick, username lookup, and DataStore logging must use pcall.
- Use Players:BanAsync and Players:UnbanAsync only on the server.
- Do not use free model admin commands.
- Do not use HTTP webhooks.
- Do not expose the full admin list to the client.

Ban behavior:
- Ban supports username or UserId.
- Reason is required.
- Duration is seconds.
- Duration -1 means permanent ban, only Owner and SeniorAdmin.
- Use Players:BanAsync with UserIds, Duration, DisplayReason, PrivateReason, ExcludeAltAccounts, and ApplyToUniverse.

UI:
- Dark modern admin panel.
- Hidden from non-admins.
- Owner/Admin sees it after pressing Play.
- Add an ADMIN toggle button.
- Press F2 to open/close.
- Include player list.
- Selecting a player fills username and UserId boxes.
- Add buttons for Ban, Unban, Kick, Change Setting, Refresh Players.
- Add SettingNameBox and SettingValueBox for WalkSpeed/JumpPower/etc.
- Add rounded corners, strokes, padding, UIScale, and clean spacing.

Logging:
- Log every action to Output.
- Include admin name, admin UserId, target UserId, action type, reason, duration, timestamp, success/failure.
- Try saving logs to DataStore, but do not break if DataStore is unavailable.

Allowed character settings:
- WalkSpeed: 0 to 100
- JumpPower: 0 to 200
- JumpHeight: 0 to 50
- MaxHealth: 1 to 1000
- Health: 0 to 1000

Setup note:
- Enable Players.BanningEnabled if needed.
- Publish the place before testing real Roblox bans.
- Studio testing may behave differently from live servers.

Important:
Actually create the UI objects and scripts in Explorer. Do not only explain the code.

]]
