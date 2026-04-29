-- Location: ReplicatedStorage.AdminSystem.Modules.AdminConfig
-- Stores admin permissions and safety limits for the admin system.
-- Server scripts use the full config. Client requires return a stripped safe table.

local RunService = game:GetService("RunService")

local AdminConfig = {}

-- Trusted admin UserIds. Always use UserIds for permissions.
-- Rank names must be: "Owner", "SeniorAdmin", or "Moderator".
AdminConfig.AdminUserIds = {
    -- AlwaysBeAKing
    [3258500526] = "Owner",
}

-- Studio testing helper. Turn this off before publishing if you only want listed admins.
AdminConfig.AllowStudioTesting = true
AdminConfig.StudioTestingRank = "Owner"

AdminConfig.RankValues = {
    Moderator = 1,
    SeniorAdmin = 2,
    Owner = 3,
}

AdminConfig.PermissionLevels = {
    Owner = {
        Ban = true,
        PermanentBan = true,
        Unban = true,
        Kick = true,
        ChangeStat = true,
        ChangeSetting = true,
        ViewInfo = true,
    },

    SeniorAdmin = {
        Ban = true,
        PermanentBan = true,
        Unban = true,
        Kick = true,
        ChangeStat = true,
        ChangeSetting = true,
        ViewInfo = true,
    },

    Moderator = {
        Ban = true,
        PermanentBan = false,
        Unban = false,
        Kick = true,
        ChangeStat = false,
        ChangeSetting = false,
        ViewInfo = true,
    },
}

-- -1 means the rank may use permanent bans. Other values are max seconds.
AdminConfig.MaxBanDurationSeconds = {
    Owner = -1,
    SeniorAdmin = -1,
    Moderator = 86400,
}

-- true means Roblox should also apply bans to suspected alt accounts.
-- BanAsync uses ExcludeAltAccounts, so the service passes not AltAccountBanningEnabled.
AdminConfig.AltAccountBanningEnabled = true
AdminConfig.ApplyBansToUniverse = true

-- Only these leaderstats can be changed by the admin service.
AdminConfig.AllowedStats = {
    Cash = true,
    Coins = true,
    Wins = true,
    Level = true,
    XP = true,
}

-- Only Owner and SeniorAdmin can change these live character settings.
AdminConfig.AllowedCharacterSettings = {
    WalkSpeed = {Min = 0, Max = 100},
    JumpPower = {Min = 0, Max = 200},
    JumpHeight = {Min = 0, Max = 50},
    MaxHealth = {Min = 1, Max = 1000},
    Health = {Min = 0, Max = 1000},
}

AdminConfig.RemoteCooldownSeconds = 1
AdminConfig.MaxReasonLength = 400
AdminConfig.MaxPrivateReasonLength = 1000
AdminConfig.DefaultBanDurationSeconds = 3600
AdminConfig.DataStoreName = "AdminActionLogsV1"

-- Never return the admin list to a client that accidentally requires this module.
if RunService:IsClient() then
    return {
        ClientSafe = true,
    }
end

return AdminConfig
