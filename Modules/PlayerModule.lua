--[[
    PlayerModule.lua
    Module for Player-related features (God Mode, etc.)
]]

local PlayerModule = {}

-- State
PlayerModule.GOD_MODE = false

-- Remote reference
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local RemoteHurt = Remotes and Remotes:WaitForChild("PlayerHurtMe", 2)

-- ═══════════════════════════════════════
-- HOOKING LOGIC
-- ═══════════════════════════════════════

function PlayerModule.init()
    if not RemoteHurt then
        warn("[CawScript] WARNING: Remote PlayerHurtMe tidak ditemukan! God Mode tidak akan bekerja.")
        return
    end

    -- Hook metamethod to block FireServer to PlayerHurtMe
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()

        if method == "FireServer" and self == RemoteHurt then
            if PlayerModule.GOD_MODE then
                -- Block the damage request
                return nil
            end
        end

        return oldNamecall(self, ...)
    end))

    print("[CawScript] PlayerModule: God Mode hook installed.")
end

function PlayerModule.setGodMode(state)
    PlayerModule.GOD_MODE = state
    print("[CawScript] God Mode is now: " .. (state and "ON" or "OFF"))
end

function PlayerModule.isGodMode()
    return PlayerModule.GOD_MODE
end

return PlayerModule
