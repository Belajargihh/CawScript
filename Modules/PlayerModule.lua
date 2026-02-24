--[[
    PlayerModule.lua
    Module for Player-related features (God Mode, etc.)
    
    God Mode: Block remote "PlayerHurtMe" agar tidak kena damage
    dari magma, spike, dll.
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

local hookInstalled = false

function PlayerModule.init()
    if not RemoteHurt then
        warn("[CawScript] WARNING: Remote PlayerHurtMe tidak ditemukan! God Mode tidak akan bekerja.")
        return
    end

    if hookInstalled then return end

    -- Method 1: hookfunction langsung ke FireServer remote
    local success1 = pcall(function()
        local oldFire
        oldFire = hookfunction(RemoteHurt.FireServer, newcclosure(function(self, ...)
            if self == RemoteHurt and PlayerModule.GOD_MODE then
                return nil -- Block damage
            end
            return oldFire(self, ...)
        end))
        hookInstalled = true
        print("[CawScript] God Mode hook (hookfunction) installed!")
    end)

    -- Method 2: Fallback pakai namecall hook khusus PlayerHurtMe
    if not hookInstalled then
        pcall(function()
            local mt = getrawmetatable(game)
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                if self == RemoteHurt and getnamecallmethod() == "FireServer" and PlayerModule.GOD_MODE then
                    return nil -- Block damage
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
            hookInstalled = true
            print("[CawScript] God Mode hook (getrawmetatable) installed!")
        end)
    end

    -- Method 3: hookmetamethod sebagai last resort
    if not hookInstalled then
        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                if self == RemoteHurt and getnamecallmethod() == "FireServer" and PlayerModule.GOD_MODE then
                    return nil -- Block damage
                end
                return old(self, ...)
            end))
            hookInstalled = true
            print("[CawScript] God Mode hook (hookmetamethod) installed!")
        end)
    end

    if not hookInstalled then
        warn("[CawScript] WARNING: Gagal install God Mode hook! Semua method gagal.")
    end
end

function PlayerModule.setGodMode(state)
    PlayerModule.GOD_MODE = state
    print("[CawScript] God Mode: " .. (state and "ON" or "OFF"))
end

function PlayerModule.isGodMode()
    return PlayerModule.GOD_MODE
end

return PlayerModule
