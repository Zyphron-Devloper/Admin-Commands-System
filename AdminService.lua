-- Location: ServerScriptService.AdminSystem.AdminService
-- Server-only admin logic for permissions, bans, unbans, kicks, stat edits, and player info.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminSystem"):WaitForChild("Modules"):WaitForChild("AdminConfig"))

local AdminService = {}
local AdminLogger = nil
local actionCooldowns = {}
local listCooldowns = {}

local function trim(text)
    if typeof(text) ~= "string" then
        return ""
    end

    return (text:gsub("^%s*(.-)%s*$", "%1"))
end

local function clipText(text, maxLength)
    text = tostring(text or "")

    if #text > maxLength then
        return string.sub(text, 1, maxLength)
    end

    return text
end

local function isValidPlayer(player)
    return typeof(player) == "Instance"
        and player:IsA("Player")
        and player.Parent == Players
end

local function getConfiguredRank(userId)
    if typeof(userId) ~= "number" then
        return nil
    end

    local rankName = AdminConfig.AdminUserIds[userId]

    if typeof(rankName) == "table" then
        rankName = rankName.Rank
    end

    if typeof(rankName) == "string" and AdminConfig.RankValues[rankName] ~= nil then
        return rankName
    end

    return nil
end

local function getAdminRank(player)
    if not isValidPlayer(player) then
        return nil
    end

    local configuredRank = getConfiguredRank(player.UserId)
    if configuredRank ~= nil then
        return configuredRank
    end

    if RunService:IsStudio() and AdminConfig.AllowStudioTesting then
        return AdminConfig.StudioTestingRank
    end

    return nil
end

local function getRankValue(rankName)
    if typeof(rankName) ~= "string" then
        return 0
    end

    return AdminConfig.RankValues[rankName] or 0
end

local function buildResult(success, message, data)
    return {
        Success = success == true,
        Message = tostring(message or ""),
        Data = data or {},
    }
end

local function safeLog(entry)
    if AdminLogger == nil then
        warn("[AdminService] AdminLogger has not been set.")
        return
    end

    local logged, logError = pcall(function()
        AdminLogger.Log(entry)
    end)

    if not logged then
        warn("[AdminService] Logging failed: " .. tostring(logError))
    end
end

local function logAction(admin, action, targetUserId, reason, duration, success, detail)
    safeLog({
        AdminName = isValidPlayer(admin) and admin.Name or "Unknown",
        AdminUserId = isValidPlayer(admin) and admin.UserId or 0,
        TargetUserId = targetUserId or 0,
        Action = action,
        Reason = reason or "No reason provided",
        Duration = duration or 0,
        Timestamp = os.time(),
        Success = success == true,
        Detail = detail or "",
    })
end

local function checkCooldown(player, cooldownTable)
    if not isValidPlayer(player) then
        return false, "Invalid player"
    end

    local now = os.clock()
    local nextAllowedTime = cooldownTable[player.UserId] or 0

    if now < nextAllowedTime then
        local remaining = math.ceil(nextAllowedTime - now)
        return false, "Please wait " .. tostring(remaining) .. " seconds before trying again."
    end

    cooldownTable[player.UserId] = now + AdminConfig.RemoteCooldownSeconds
    return true, nil
end

local function hasPermission(admin, action, duration)
    local rankName = getAdminRank(admin)
    if rankName == nil then
        return false, "You are not an admin."
    end

    local permissions = AdminConfig.PermissionLevels[rankName]
    if typeof(permissions) ~= "table" or permissions[action] ~= true then
        return false, "Your rank cannot use " .. tostring(action) .. "."
    end

    if action == "Ban" and duration == -1 and permissions.PermanentBan ~= true then
        return false, "Your rank cannot use permanent bans."
    end

    return true, nil
end

local function canAffectTarget(admin, targetUserId)
    local adminRankName = getAdminRank(admin)
    local targetRankName = getConfiguredRank(targetUserId)

    if targetRankName == nil then
        return true, nil
    end

    if getRankValue(targetRankName) >= getRankValue(adminRankName) then
        return false, "You cannot target an admin with equal or higher rank."
    end

    return true, nil
end

local function parseUserIdField(value)
    if typeof(value) == "string" then
        value = trim(value)

        if value == "" then
            return nil, nil
        end

        value = tonumber(value)
    end

    if value == nil then
        return nil, nil
    end

    if typeof(value) ~= "number" or value < 1 or math.floor(value) ~= value then
        return nil, "UserId must be a positive whole number."
    end

    return value, nil
end

local function resolveTarget(payload)
    if typeof(payload) ~= "table" then
        return nil, "Invalid request payload."
    end

    local requestedUserId, userIdError = parseUserIdField(payload.TargetUserId)
    if userIdError ~= nil then
        return nil, userIdError
    end

    if requestedUserId ~= nil then
        local onlinePlayer = Players:GetPlayerByUserId(requestedUserId)
        if onlinePlayer ~= nil then
            return {
                UserId = requestedUserId,
                Name = onlinePlayer.Name,
                Player = onlinePlayer,
            }, nil
        end

        local lookupSuccess, usernameOrError = pcall(function()
            return Players:GetNameFromUserIdAsync(requestedUserId)
        end)

        if lookupSuccess and typeof(usernameOrError) == "string" then
            return {
                UserId = requestedUserId,
                Name = usernameOrError,
                Player = nil,
            }, nil
        end

        return nil, "Target UserId could not be verified."
    end

    local targetName = trim(payload.TargetName)
    if targetName == "" then
        return nil, "Enter a username or UserId."
    end

    local onlineByName = Players:FindFirstChild(targetName)
    if onlineByName ~= nil and onlineByName:IsA("Player") then
        return {
            UserId = onlineByName.UserId,
            Name = onlineByName.Name,
            Player = onlineByName,
        }, nil
    end

    local nameLookupSuccess, userIdOrError = pcall(function()
        return Players:GetUserIdFromNameAsync(targetName)
    end)

    if not nameLookupSuccess or typeof(userIdOrError) ~= "number" then
        return nil, "Username lookup failed. Check the spelling or use UserId."
    end

    return {
        UserId = userIdOrError,
        Name = targetName,
        Player = Players:GetPlayerByUserId(userIdOrError),
    }, nil
end

local function getRequiredReason(payload)
    local reason = trim(payload.Reason)

    if reason == "" then
        return nil, "Reason is required."
    end

    return clipText(reason, AdminConfig.MaxReasonLength), nil
end

local function parseBanDuration(admin, value)
    if typeof(value) == "string" then
        value = trim(value)

        if value == "" then
            value = AdminConfig.DefaultBanDurationSeconds
        else
            value = tonumber(value)
        end
    end

    if value == nil then
        value = AdminConfig.DefaultBanDurationSeconds
    end

    if typeof(value) ~= "number" or math.floor(value) ~= value then
        return nil, "Duration must be a whole number of seconds."
    end

    if value ~= -1 and value <= 0 then
        return nil, "Duration must be positive seconds, or -1 for permanent."
    end

    local rankName = getAdminRank(admin)
    local maxDuration = AdminConfig.MaxBanDurationSeconds[rankName]

    if value == -1 then
        if maxDuration ~= -1 then
            return nil, "Your rank cannot create permanent bans."
        end

        return value, nil
    end

    if typeof(maxDuration) == "number" and maxDuration ~= -1 and value > maxDuration then
        return nil, "Your rank cannot ban longer than " .. tostring(maxDuration) .. " seconds."
    end

    return value, nil
end

local function getBanHistoryNote(userId)
    local success, pagesOrError = pcall(function()
        return Players:GetBanHistoryAsync(userId)
    end)

    if not success then
        return "Ban history unavailable: " .. tostring(pagesOrError)
    end

    local pageSuccess, currentPageOrError = pcall(function()
        return pagesOrError:GetCurrentPage()
    end)

    if not pageSuccess or typeof(currentPageOrError) ~= "table" then
        return "Ban history loaded, current page unavailable."
    end

    return "Ban history current page entries: " .. tostring(#currentPageOrError)
end

local function handleBan(admin, payload)
    local reason, reasonError = getRequiredReason(payload)
    if reasonError ~= nil then
        return buildResult(false, reasonError)
    end

    local duration, durationError = parseBanDuration(admin, payload.Duration)
    if durationError ~= nil then
        return buildResult(false, durationError)
    end

    local permitted, permissionError = hasPermission(admin, "Ban", duration)
    if not permitted then
        return buildResult(false, permissionError)
    end

    local target, targetError = resolveTarget(payload)
    if targetError ~= nil then
        return buildResult(false, targetError)
    end

    local canAffect, affectError = canAffectTarget(admin, target.UserId)
    if not canAffect then
        logAction(admin, "Ban", target.UserId, reason, duration, false, affectError)
        return buildResult(false, affectError)
    end

    local displayReason = clipText(reason, AdminConfig.MaxReasonLength)
    local privateReason = clipText(
        "Admin " .. admin.Name .. " (" .. tostring(admin.UserId) .. ") banned " .. tostring(target.UserId)
        .. " | Reason: " .. reason
        .. " | " .. getBanHistoryNote(target.UserId),
        AdminConfig.MaxPrivateReasonLength
    )

    local banConfig = {
        UserIds = {target.UserId},
        Duration = duration,
        DisplayReason = displayReason,
        PrivateReason = privateReason,
        ExcludeAltAccounts = not AdminConfig.AltAccountBanningEnabled,
        ApplyToUniverse = AdminConfig.ApplyBansToUniverse,
    }

    local success, banError = pcall(function()
        Players:BanAsync(banConfig)
    end)

    logAction(admin, "Ban", target.UserId, reason, duration, success, success and "BanAsync succeeded." or tostring(banError))

    if not success then
        return buildResult(false, "Ban failed: " .. tostring(banError))
    end

    return buildResult(true, "Banned " .. target.Name .. " (" .. tostring(target.UserId) .. ").")
end

local function handleUnban(admin, payload)
    local reason, reasonError = getRequiredReason(payload)
    if reasonError ~= nil then
        return buildResult(false, reasonError)
    end

    local permitted, permissionError = hasPermission(admin, "Unban", 0)
    if not permitted then
        return buildResult(false, permissionError)
    end

    local target, targetError = resolveTarget(payload)
    if targetError ~= nil then
        return buildResult(false, targetError)
    end

    local unbanConfig = {
        UserIds = {target.UserId},
        ApplyToUniverse = AdminConfig.ApplyBansToUniverse,
    }

    local success, unbanError = pcall(function()
        Players:UnbanAsync(unbanConfig)
    end)

    logAction(admin, "Unban", target.UserId, reason, 0, success, success and "UnbanAsync succeeded." or tostring(unbanError))

    if not success then
        return buildResult(false, "Unban failed: " .. tostring(unbanError))
    end

    return buildResult(true, "Unbanned " .. target.Name .. " (" .. tostring(target.UserId) .. ").")
end

local function handleKick(admin, payload)
    local reason, reasonError = getRequiredReason(payload)
    if reasonError ~= nil then
        return buildResult(false, reasonError)
    end

    local permitted, permissionError = hasPermission(admin, "Kick", 0)
    if not permitted then
        return buildResult(false, permissionError)
    end

    local target, targetError = resolveTarget(payload)
    if targetError ~= nil then
        return buildResult(false, targetError)
    end

    local canAffect, affectError = canAffectTarget(admin, target.UserId)
    if not canAffect then
        logAction(admin, "Kick", target.UserId, reason, 0, false, affectError)
        return buildResult(false, affectError)
    end

    local targetPlayer = target.Player or Players:GetPlayerByUserId(target.UserId)
    if targetPlayer == nil then
        logAction(admin, "Kick", target.UserId, reason, 0, false, "Target is not in this server.")
        return buildResult(false, "Kick failed: target is not in this server.")
    end

    local success, kickError = pcall(function()
        targetPlayer:Kick(clipText(reason, AdminConfig.MaxReasonLength))
    end)

    logAction(admin, "Kick", target.UserId, reason, 0, success, success and "Kick succeeded." or tostring(kickError))

    if not success then
        return buildResult(false, "Kick failed: " .. tostring(kickError))
    end

    return buildResult(true, "Kicked " .. target.Name .. " (" .. tostring(target.UserId) .. ").")
end

function AdminService.ChangeStat(admin, targetUserId, statName, newValue, reason)
    reason = trim(reason)
    if reason == "" then
        return buildResult(false, "Reason is required.")
    end

    local permitted, permissionError = hasPermission(admin, "ChangeStat", 0)
    if not permitted then
        return buildResult(false, permissionError)
    end

    if typeof(targetUserId) ~= "number" or targetUserId < 1 or math.floor(targetUserId) ~= targetUserId then
        return buildResult(false, "Target UserId is invalid.")
    end

    local canAffect, affectError = canAffectTarget(admin, targetUserId)
    if not canAffect then
        logAction(admin, "ChangeStat", targetUserId, reason, 0, false, affectError)
        return buildResult(false, affectError)
    end

    statName = trim(statName)
    if statName == "" or AdminConfig.AllowedStats[statName] ~= true then
        logAction(admin, "ChangeStat", targetUserId, reason, 0, false, "Blocked or missing stat name: " .. tostring(statName))
        return buildResult(false, "That stat is not allowed to be changed.")
    end

    local numericValue = tonumber(newValue)
    if numericValue == nil then
        logAction(admin, "ChangeStat", targetUserId, reason, 0, false, "New value is not a number.")
        return buildResult(false, "New stat value must be a number.")
    end

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer == nil then
        logAction(admin, "ChangeStat", targetUserId, reason, 0, false, "Target is not in this server.")
        return buildResult(false, "Target must be in this server to edit leaderstats.")
    end

    local leaderstats = targetPlayer:FindFirstChild("leaderstats")
    if typeof(leaderstats) ~= "Instance" then
        logAction(admin, "ChangeStat", targetUserId, reason, 0, false, "leaderstats folder missing.")
        return buildResult(false, "Target has no leaderstats folder.")
    end

    local stat = leaderstats:FindFirstChild(statName)
    if typeof(stat) ~= "Instance" then
        logAction(admin, "ChangeStat", targetUserId, reason, 0, false, "Requested stat does not exist.")
        return buildResult(false, "That stat does not exist on the target.")
    end

    local success, statError = pcall(function()
        if stat:IsA("IntValue") then
            stat.Value = math.floor(numericValue)
        elseif stat:IsA("NumberValue") then
            stat.Value = numericValue
        else
            error("Stat must be an IntValue or NumberValue.")
        end
    end)

    logAction(admin, "ChangeStat", targetUserId, reason, 0, success, success and ("Set " .. statName .. " to " .. tostring(numericValue)) or tostring(statError))

    if not success then
        return buildResult(false, "ChangeStat failed: " .. tostring(statError))
    end

    return buildResult(true, "Updated " .. statName .. " for " .. targetPlayer.Name .. ".")
end

function AdminService.ChangeSetting(admin, targetUserId, settingName, newValue, reason)
    reason = trim(reason)
    if reason == "" then
        reason = "Changed character setting"
    end

    local permitted, permissionError = hasPermission(admin, "ChangeSetting", 0)
    if not permitted then
        return buildResult(false, permissionError)
    end

    if typeof(targetUserId) ~= "number" or targetUserId < 1 or math.floor(targetUserId) ~= targetUserId then
        return buildResult(false, "Target UserId is invalid.")
    end

    -- Admins may change their own character settings, but not other admins with equal/higher rank.
    if targetUserId ~= admin.UserId then
        local canAffect, affectError = canAffectTarget(admin, targetUserId)
        if not canAffect then
            logAction(admin, "ChangeSetting", targetUserId, reason, 0, false, affectError)
            return buildResult(false, affectError)
        end
    end

    settingName = trim(settingName)
    local settingRules = AdminConfig.AllowedCharacterSettings[settingName]
    if typeof(settingRules) ~= "table" then
        logAction(admin, "ChangeSetting", targetUserId, reason, 0, false, "Blocked setting: " .. tostring(settingName))
        return buildResult(false, "That setting is only available to Owner/Admin and must be allowed.")
    end

    local numericValue = tonumber(newValue)
    if numericValue == nil then
        return buildResult(false, "Setting value must be a number.")
    end

    if numericValue < settingRules.Min or numericValue > settingRules.Max then
        return buildResult(false, settingName .. " must be between " .. tostring(settingRules.Min) .. " and " .. tostring(settingRules.Max) .. ".")
    end

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer == nil then
        return buildResult(false, "Target must be in this server to change character settings.")
    end

    local character = targetPlayer.Character
    if typeof(character) ~= "Instance" then
        return buildResult(false, "Target character is not ready.")
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if typeof(humanoid) ~= "Instance" then
        return buildResult(false, "Target humanoid is missing.")
    end

    local success, settingError = pcall(function()
        if settingName == "WalkSpeed" then
            humanoid.WalkSpeed = numericValue
        elseif settingName == "JumpPower" then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = numericValue
        elseif settingName == "JumpHeight" then
            humanoid.UseJumpPower = false
            humanoid.JumpHeight = numericValue
        elseif settingName == "MaxHealth" then
            humanoid.MaxHealth = numericValue
            if humanoid.Health > numericValue then
                humanoid.Health = numericValue
            end
        elseif settingName == "Health" then
            humanoid.Health = math.clamp(numericValue, 0, humanoid.MaxHealth)
        end
    end)

    logAction(admin, "ChangeSetting", targetUserId, reason, 0, success, success and ("Set " .. settingName .. " to " .. tostring(numericValue)) or tostring(settingError))

    if not success then
        return buildResult(false, "ChangeSetting failed: " .. tostring(settingError))
    end

    return buildResult(true, "Set " .. settingName .. " to " .. tostring(numericValue) .. " for " .. targetPlayer.Name .. ".")
end

local function handleChangeSetting(admin, payload)
    local target, targetError = resolveTarget(payload)
    if targetError ~= nil then
        return buildResult(false, targetError)
    end

    return AdminService.ChangeSetting(admin, target.UserId, payload.SettingName, payload.SettingValue, payload.Reason)
end

local function handleChangeStat(admin, payload)
    local target, targetError = resolveTarget(payload)
    if targetError ~= nil then
        return buildResult(false, targetError)
    end

    return AdminService.ChangeStat(admin, target.UserId, payload.StatName, payload.NewValue, payload.Reason)
end

function AdminService.SetLogger(loggerModule)
    AdminLogger = loggerModule
end

function AdminService.IsAdmin(player)
    return getAdminRank(player) ~= nil
end

function AdminService.HandleAction(admin, payload)
    if not AdminService.IsAdmin(admin) then
        return buildResult(false, "You are not an admin.")
    end

    local allowedByCooldown, cooldownMessage = checkCooldown(admin, actionCooldowns)
    if not allowedByCooldown then
        return buildResult(false, cooldownMessage)
    end

    if typeof(payload) ~= "table" then
        return buildResult(false, "Invalid request.")
    end

    local action = trim(payload.Action)

    if action == "Ban" then
        return handleBan(admin, payload)
    elseif action == "Unban" then
        return handleUnban(admin, payload)
    elseif action == "Kick" then
        return handleKick(admin, payload)
    elseif action == "ChangeStat" then
        return handleChangeStat(admin, payload)
    elseif action == "ChangeSetting" then
        return handleChangeSetting(admin, payload)
    end

    return buildResult(false, "Unknown admin action.")
end

function AdminService.GetPlayerList(admin)
    local adminRankName = getAdminRank(admin)
    local permissions = adminRankName and AdminConfig.PermissionLevels[adminRankName] or nil
    local canChangeSetting = typeof(permissions) == "table" and permissions.ChangeSetting == true

    if not AdminService.IsAdmin(admin) then
        return {
            IsAdmin = false,
            Players = {},
            Message = "Not an admin.",
        }
    end

    local allowedByCooldown, cooldownMessage = checkCooldown(admin, listCooldowns)
    if not allowedByCooldown then
        return {
            IsAdmin = true,
            Players = {},
            Message = cooldownMessage,
        }
    end

    local playerList = {}

    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(playerList, {
            Name = player.Name,
            DisplayName = player.DisplayName,
            UserId = player.UserId,
            AccountAge = player.AccountAge,
        })
    end

    table.sort(playerList, function(left, right)
        return left.Name:lower() < right.Name:lower()
    end)

    return {
        IsAdmin = true,
        Rank = adminRankName,
        CanChangeSetting = canChangeSetting,
        Players = playerList,
        Message = "Loaded " .. tostring(#playerList) .. " players.",
    }
end

Players.PlayerRemoving:Connect(function(player)
    if isValidPlayer(player) then
        actionCooldowns[player.UserId] = nil
        listCooldowns[player.UserId] = nil
    end
end)

return AdminService
