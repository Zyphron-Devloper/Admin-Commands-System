-- Location: ServerScriptService.AdminSystem.AdminServer
-- Connects RemoteEvents/RemoteFunctions to the server-only admin service.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(parent, className, name)
    local existing = parent:FindFirstChild(name)
    if existing then
        if existing.ClassName == className then
            return existing
        end

        existing:Destroy()
    end

    local instance = Instance.new(className)
    instance.Name = name
    instance.Parent = parent
    return instance
end

local ReplicatedAdminSystem = getOrCreate(ReplicatedStorage, "Folder", "AdminSystem")
local Remotes = getOrCreate(ReplicatedAdminSystem, "Folder", "Remotes")

local AdminActionRequest = getOrCreate(Remotes, "RemoteEvent", "AdminActionRequest")
local AdminActionResult = getOrCreate(Remotes, "RemoteEvent", "AdminActionResult")
local RequestPlayerList = getOrCreate(Remotes, "RemoteFunction", "RequestPlayerList")

local ServerAdminSystem = script.Parent
local AdminService = require(ServerAdminSystem:WaitForChild("AdminService"))
local AdminLogger = require(ServerAdminSystem:WaitForChild("AdminLogger"))

AdminService.SetLogger(AdminLogger)

AdminActionRequest.OnServerEvent:Connect(function(player, payload)
    local success, resultOrError = pcall(function()
        return AdminService.HandleAction(player, payload)
    end)

    if success then
        AdminActionResult:FireClient(player, resultOrError)
    else
        warn("[AdminServer] Action failed before result: " .. tostring(resultOrError))
        AdminActionResult:FireClient(player, {
            Success = false,
            Message = "Admin action failed on the server.",
            Data = {},
        })
    end
end)

RequestPlayerList.OnServerInvoke = function(player)
    local success, resultOrError = pcall(function()
        return AdminService.GetPlayerList(player)
    end)

    if success then
        return resultOrError
    end

    warn("[AdminServer] Player list request failed: " .. tostring(resultOrError))
    return {
        IsAdmin = false,
        Players = {},
        Message = "Player list failed on the server.",
    }
end
