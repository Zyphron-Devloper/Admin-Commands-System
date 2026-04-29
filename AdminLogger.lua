-- Location: ServerScriptService.AdminSystem.AdminLogger
-- Logs every admin action to Output and tries to save it to DataStore.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AdminConfig = require(ReplicatedStorage:WaitForChild("AdminSystem"):WaitForChild("Modules"):WaitForChild("AdminConfig"))

local AdminLogger = {}
local logStore = nil
local dataStoreReady, dataStoreOrError = pcall(function()
    return DataStoreService:GetDataStore(AdminConfig.DataStoreName)
end)

if dataStoreReady then
    logStore = dataStoreOrError
else
    print("[AdminLog] DataStore unavailable in this test session; logs will print only. " .. tostring(dataStoreOrError))
end

local function cleanText(value)
    if typeof(value) == "string" then
        return value
    end

    return tostring(value)
end

local function buildLogLine(entry)
    return "[AdminLog] "
        .. "timestamp=" .. cleanText(entry.Timestamp)
        .. " | action=" .. cleanText(entry.Action)
        .. " | admin=" .. cleanText(entry.AdminName) .. "(" .. cleanText(entry.AdminUserId) .. ")"
        .. " | targetUserId=" .. cleanText(entry.TargetUserId)
        .. " | reason=" .. cleanText(entry.Reason)
        .. " | duration=" .. cleanText(entry.Duration)
        .. " | success=" .. cleanText(entry.Success)
        .. " | detail=" .. cleanText(entry.Detail)
end

function AdminLogger.Log(entry)
    if typeof(entry) ~= "table" then
        warn("[AdminLog] Tried to log a non-table entry.")
        return false
    end

    entry.Timestamp = entry.Timestamp or os.time()
    entry.Action = entry.Action or "Unknown"
    entry.AdminName = entry.AdminName or "Unknown"
    entry.AdminUserId = entry.AdminUserId or 0
    entry.TargetUserId = entry.TargetUserId or 0
    entry.Reason = entry.Reason or "No reason provided"
    entry.Duration = entry.Duration or 0
    entry.Success = entry.Success == true
    entry.Detail = entry.Detail or ""

    print(buildLogLine(entry))

    if logStore == nil then
        print("[AdminLog] DataStore unavailable; printed log only.")
        return false
    end

    local key = tostring(entry.Timestamp) .. "_" .. tostring(entry.AdminUserId) .. "_" .. tostring(math.random(100000, 999999))
    local saved, dataStoreError = pcall(function()
        logStore:SetAsync(key, entry)
    end)

    if not saved then
        warn("[AdminLog] DataStore save failed: " .. tostring(dataStoreError))
    end

    return saved
end

return AdminLogger
