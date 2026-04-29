#Roblox Admin System Format 
This Readme.md is not to be put in Roblox Studio Its just to Tell the Assistant to put these files where they need to be

This is the format for the Roblox Studio Explorer 

###game
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
                UIStroke###

