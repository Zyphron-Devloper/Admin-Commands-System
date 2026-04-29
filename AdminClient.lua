-- Location: StarterGui.AdminPanel.AdminClient
-- Client-side UI for the admin panel. It only sends requests; the server makes every decision.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Remotes = ReplicatedStorage:WaitForChild("AdminSystem"):WaitForChild("Remotes")
local AdminActionRequest = Remotes:WaitForChild("AdminActionRequest")
local AdminActionResult = Remotes:WaitForChild("AdminActionResult")
local RequestPlayerList = Remotes:WaitForChild("RequestPlayerList")

local AdminPanel = script.Parent
local MainFrame = AdminPanel:WaitForChild("MainFrame")
local PlayerNameBox = MainFrame:WaitForChild("PlayerNameBox")
local UserIdBox = MainFrame:WaitForChild("UserIdBox")
local ReasonBox = MainFrame:WaitForChild("ReasonBox")
local DurationBox = MainFrame:WaitForChild("DurationBox")
local SettingNameBox = MainFrame:WaitForChild("SettingNameBox")
local SettingValueBox = MainFrame:WaitForChild("SettingValueBox")
local BanButton = MainFrame:WaitForChild("BanButton")
local UnbanButton = MainFrame:WaitForChild("UnbanButton")
local KickButton = MainFrame:WaitForChild("KickButton")
local ChangeSettingButton = MainFrame:WaitForChild("ChangeSettingButton")
local RefreshPlayersButton = MainFrame:WaitForChild("RefreshPlayersButton")
local PlayerListFrame = MainFrame:WaitForChild("PlayerListFrame")
local ResultLabel = MainFrame:WaitForChild("ResultLabel")
local AdminToggleButton = AdminPanel:WaitForChild("AdminToggleButton")
local PanelScale = MainFrame:FindFirstChildOfClass("UIScale")

local isAdmin = false
local canChangeSetting = false
local requestInProgress = false
local buttons = {BanButton, UnbanButton, KickButton, ChangeSettingButton, RefreshPlayersButton}

local function trim(text)
    if typeof(text) ~= "string" then
        return ""
    end
    return (text:gsub("^%s*(.-)%s*$", "%1"))
end

local function setResult(message, success)
    ResultLabel.Text = tostring(message or "")
    if success == true then
        ResultLabel.TextColor3 = Color3.fromRGB(134, 239, 172)
    elseif success == false then
        ResultLabel.TextColor3 = Color3.fromRGB(252, 165, 165)
    else
        ResultLabel.TextColor3 = Color3.fromRGB(203, 213, 225)
    end
end

local function updateSettingVisibility()
    SettingNameBox.Visible = canChangeSetting
    SettingValueBox.Visible = canChangeSetting
    ChangeSettingButton.Visible = canChangeSetting
end

local function setButtonsEnabled(enabled)
    for _, button in ipairs(buttons) do
        button.Active = enabled
        button.TextTransparency = enabled and 0 or 0.35
    end
end

local function updateScale()
    if PanelScale == nil or workspace.CurrentCamera == nil then
        return
    end
    local viewportSize = workspace.CurrentCamera.ViewportSize
    PanelScale.Scale = math.clamp(math.min(viewportSize.X / 900, viewportSize.Y / 630), 0.55, 1)
end

local function clearPlayerRows()
    for _, child in ipairs(PlayerListFrame:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
end

local function updateCanvasSize()
    local layout = PlayerListFrame:FindFirstChildOfClass("UIListLayout")
    if layout then
        PlayerListFrame.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 18)
    end
end

local function createPlayerRow(playerData, order)
    local row = Instance.new("TextButton")
    row.Name = "Player_" .. tostring(playerData.UserId)
    row.LayoutOrder = order
    row.Size = UDim2.new(1, -4, 0, 54)
    row.BackgroundColor3 = Color3.fromRGB(24, 34, 48)
    row.BorderSizePixel = 0
    row.AutoButtonColor = false
    row.Font = Enum.Font.GothamMedium
    row.TextColor3 = Color3.fromRGB(226, 232, 240)
    row.TextSize = 14
    row.TextXAlignment = Enum.TextXAlignment.Left
    row.TextWrapped = true
    row.Text = playerData.Name .. "  |  " .. tostring(playerData.UserId) .. "\n" .. playerData.DisplayName .. "  |  " .. tostring(playerData.AccountAge) .. " days"
    row.Parent = PlayerListFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = row

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = row

    row.MouseButton1Click:Connect(function()
        PlayerNameBox.Text = playerData.Name
        UserIdBox.Text = tostring(playerData.UserId)
        setResult("Selected " .. playerData.Name .. " | UserId " .. tostring(playerData.UserId), nil)
    end)

    row.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 44, 64)}):Play()
    end)
    row.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(24, 34, 48)}):Play()
    end)
end

local function applyServerAccess(response)
    if typeof(response) ~= "table" or response.IsAdmin ~= true then
        isAdmin = false
        canChangeSetting = false
        MainFrame.Visible = false
        AdminToggleButton.Visible = false
        AdminPanel.Enabled = false
        updateSettingVisibility()
        return false
    end

    isAdmin = true
    canChangeSetting = response.CanChangeSetting == true
    AdminPanel.Enabled = true
    AdminToggleButton.Visible = true
    updateSettingVisibility()
    return true
end

local function refreshPlayers()
    if not isAdmin then
        return
    end
    setResult("Loading players...", nil)
    local success, response = pcall(function()
        return RequestPlayerList:InvokeServer()
    end)
    if not success or not applyServerAccess(response) then
        setResult("Could not load player list.", false)
        return
    end

    clearPlayerRows()
    if typeof(response.Players) == "table" then
        for index, playerData in ipairs(response.Players) do
            createPlayerRow(playerData, index)
        end
    end
    updateCanvasSize()
    setResult(response.Message or "Players loaded.", true)
end

local function sendPayload(payload, loadingText)
    if not isAdmin or requestInProgress then
        return
    end
    requestInProgress = true
    setButtonsEnabled(false)
    setResult(loadingText, nil)
    AdminActionRequest:FireServer(payload)
end

local function sendAction(actionName)
    sendPayload({
        Action = actionName,
        TargetName = trim(PlayerNameBox.Text),
        TargetUserId = trim(UserIdBox.Text),
        Reason = trim(ReasonBox.Text),
        Duration = trim(DurationBox.Text),
    }, "Processing " .. actionName .. "...")
end

local function sendChangeSetting()
    if not canChangeSetting then
        setResult("Only Owner/Admin can change jump, speed, and health.", false)
        return
    end
    local settingName = trim(SettingNameBox.Text)
    local settingValue = trim(SettingValueBox.Text)
    if settingName == "" or settingValue == "" then
        setResult("Enter a setting name and value first.", false)
        return
    end
    sendPayload({
        Action = "ChangeSetting",
        TargetName = trim(PlayerNameBox.Text),
        TargetUserId = trim(UserIdBox.Text),
        Reason = trim(ReasonBox.Text),
        SettingName = settingName,
        SettingValue = settingValue,
    }, "Changing " .. settingName .. "...")
end

local function sendChangeStatRequest()
    local statName = trim(ReasonBox.Text)
    local newValue = trim(DurationBox.Text)
    if statName == "" or newValue == "" then
        setResult("For stat edits, put stat name in Reason and value in Duration.", false)
        return
    end
    sendPayload({
        Action = "ChangeStat",
        TargetName = trim(PlayerNameBox.Text),
        TargetUserId = trim(UserIdBox.Text),
        Reason = "Changed stat from admin panel",
        StatName = statName,
        NewValue = newValue,
    }, "Processing ChangeStat...")
end

local function addHover(button, normalColor, hoverColor)
    button.MouseEnter:Connect(function()
        if button.Active then
            TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = hoverColor}):Play()
        end
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.12), {BackgroundColor3 = normalColor}):Play()
    end)
end

BanButton.MouseButton1Click:Connect(function() sendAction("Ban") end)
UnbanButton.MouseButton1Click:Connect(function() sendAction("Unban") end)
KickButton.MouseButton1Click:Connect(function() sendAction("Kick") end)
ChangeSettingButton.MouseButton1Click:Connect(sendChangeSetting)
RefreshPlayersButton.MouseButton1Click:Connect(refreshPlayers)

AdminToggleButton.MouseButton1Click:Connect(function()
    if isAdmin then
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then
            refreshPlayers()
        end
    end
end)

AdminActionResult.OnClientEvent:Connect(function(result)
    requestInProgress = false
    setButtonsEnabled(true)
    if typeof(result) ~= "table" then
        setResult("Server returned an invalid result.", false)
        return
    end
    setResult(result.Message, result.Success)
    if result.Success == true then
        task.delay(0.5, refreshPlayers)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F2 then
        if isAdmin then
            MainFrame.Visible = not MainFrame.Visible
            if MainFrame.Visible then refreshPlayers() end
        end
    elseif input.KeyCode == Enum.KeyCode.Return then
        local holdingControl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        if holdingControl and MainFrame.Visible then
            sendChangeStatRequest()
        end
    end
end)

addHover(BanButton, Color3.fromRGB(190, 48, 67), Color3.fromRGB(220, 70, 90))
addHover(UnbanButton, Color3.fromRGB(22, 163, 74), Color3.fromRGB(34, 197, 94))
addHover(KickButton, Color3.fromRGB(217, 119, 6), Color3.fromRGB(245, 158, 11))
addHover(ChangeSettingButton, Color3.fromRGB(124, 58, 237), Color3.fromRGB(139, 92, 246))
addHover(RefreshPlayersButton, Color3.fromRGB(37, 99, 235), Color3.fromRGB(59, 130, 246))

MainFrame.Visible = false
AdminToggleButton.Visible = false
updateSettingVisibility()
setButtonsEnabled(true)
updateScale()

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local startupSuccess, startupResponse = pcall(function()
    return RequestPlayerList:InvokeServer()
end)

if startupSuccess and applyServerAccess(startupResponse) then
    MainFrame.Visible = true
    clearPlayerRows()
    if typeof(startupResponse.Players) == "table" then
        for index, playerData in ipairs(startupResponse.Players) do
            createPlayerRow(playerData, index)
        end
    end
    updateCanvasSize()
    if canChangeSetting then
        setResult("Owner/Admin tools ready. You can change WalkSpeed and JumpPower.", nil)
    else
        setResult("Moderator tools ready. Movement settings are hidden.", nil)
    end
else
    isAdmin = false
    canChangeSetting = false
    MainFrame.Visible = false
    AdminToggleButton.Visible = false
    AdminPanel.Enabled = false
    updateSettingVisibility()
end
