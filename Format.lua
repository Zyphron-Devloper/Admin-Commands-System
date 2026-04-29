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

Create a Roblox admin panel UI and scripts exactly from these Lua files and object paths.

Use this Explorer structure:

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
    - TitleLabel
    - PlayerNameBox
    - UserIdBox
    - ReasonBox
    - DurationBox
    - BanButton
    - UnbanButton
    - KickButton
    - SettingNameBox
    - SettingValueBox
    - ChangeSettingButton
    - RefreshPlayersButton
    - PlayerListFrame
    - ResultLabel

Important:
- Put the exact script source from my files into the matching scripts.
- Set AlwaysBeAKing / UserId 3258500526 as Owner in AdminConfig.
- AdminPanel should be visible for Owner/Admin after pressing Play.
- Add rounded corners, dark style, strokes, padding, and UIScale.
- The client must only send requests.
- Ban/kick/settings must happen on the server.
- Do not create a command bar admin system.
- Do not use free model admin.
]]
