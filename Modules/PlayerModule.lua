--[[
    PlayerModule.lua
    Module for Player-related features:
    - God Mode (block PlayerHurtMe)
    - Sprint (force WalkSpeed setiap frame)
    - Zero Gravity (workspace.Gravity = 0)
    - Infinite Jump (JumpRequest + ChangeState)
    
    NOTE: Game ini pakai custom movement (PlayerMovementPackets),
    jadi kita harus paksa properti Humanoid setiap frame
    agar game tidak override balik.
]]

local PlayerModule = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ═══════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════

PlayerModule.GOD_MODE = false
PlayerModule.SPRINT = false
PlayerModule.SPRINT_SPEED = 32
PlayerModule.ZERO_GRAVITY = false
PlayerModule.INFINITE_JUMP = false

local _defaultWalkSpeed = 16
local _defaultGravity = 196.2   -- Default Roblox gravity
local _hookInstalled = false
local _connections = {}

-- ═══════════════════════════════════════
-- REMOTE REFERENCES
-- ═══════════════════════════════════════

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local RemoteHurt = Remotes and Remotes:WaitForChild("PlayerHurtMe", 2)

-- ═══════════════════════════════════════
-- GOD MODE HOOK
-- ═══════════════════════════════════════

local function installGodModeHook()
    if not RemoteHurt then
        warn("[CawScript] WARNING: Remote PlayerHurtMe tidak ditemukan!")
        return
    end
    if _hookInstalled then return end

    -- Method 1: hookfunction
    pcall(function()
        local oldFire
        oldFire = hookfunction(RemoteHurt.FireServer, newcclosure(function(self, ...)
            if self == RemoteHurt and PlayerModule.GOD_MODE then
                return nil
            end
            return oldFire(self, ...)
        end))
        _hookInstalled = true
        print("[CawScript] God Mode hook (hookfunction) installed!")
    end)

    -- Method 2: getrawmetatable
    if not _hookInstalled then
        pcall(function()
            local mt = getrawmetatable(game)
            local oldNamecall = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = newcclosure(function(self, ...)
                if self == RemoteHurt and getnamecallmethod() == "FireServer" and PlayerModule.GOD_MODE then
                    return nil
                end
                return oldNamecall(self, ...)
            end)
            setreadonly(mt, true)
            _hookInstalled = true
            print("[CawScript] God Mode hook (getrawmetatable) installed!")
        end)
    end

    -- Method 3: hookmetamethod
    if not _hookInstalled then
        pcall(function()
            local old
            old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                if self == RemoteHurt and getnamecallmethod() == "FireServer" and PlayerModule.GOD_MODE then
                    return nil
                end
                return old(self, ...)
            end))
            _hookInstalled = true
            print("[CawScript] God Mode hook (hookmetamethod) installed!")
        end)
    end

    if not _hookInstalled then
        warn("[CawScript] WARNING: Semua God Mode hook method gagal!")
    end
end

-- ═══════════════════════════════════════
-- HELPER
-- ═══════════════════════════════════════

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════
-- SPRINT — Force WalkSpeed setiap frame
-- ═══════════════════════════════════════

local _sprintConn = nil

function PlayerModule.setSprint(state)
    PlayerModule.SPRINT = state
    
    if state then
        -- Simpan default speed
        local hum = getHumanoid()
        if hum then
            _defaultWalkSpeed = hum.WalkSpeed
        end
        
        -- Force WalkSpeed setiap frame supaya game gak bisa override
        if _sprintConn then _sprintConn:Disconnect() end
        _sprintConn = RunService.Heartbeat:Connect(function()
            if not PlayerModule.SPRINT then return end
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = PlayerModule.SPRINT_SPEED
            end
        end)
    else
        -- Disconnect loop dan restore speed
        if _sprintConn then
            _sprintConn:Disconnect()
            _sprintConn = nil
        end
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = _defaultWalkSpeed
        end
    end
    print("[CawScript] Sprint: " .. (state and "ON" or "OFF"))
end

function PlayerModule.setSprintSpeed(speed)
    PlayerModule.SPRINT_SPEED = speed
end

-- ═══════════════════════════════════════
-- ZERO GRAVITY — Ubah workspace.Gravity
-- ═══════════════════════════════════════

function PlayerModule.setZeroGravity(state)
    PlayerModule.ZERO_GRAVITY = state
    
    if state then
        _defaultGravity = workspace.Gravity
        workspace.Gravity = 0
    else
        workspace.Gravity = _defaultGravity
    end
    print("[CawScript] Zero Gravity: " .. (state and "ON" or "OFF"))
end

-- ═══════════════════════════════════════
-- INFINITE JUMP — Jump kapan saja
-- ═══════════════════════════════════════

local _jumpConn = nil

local function setupInfiniteJump()
    _jumpConn = UIS.JumpRequest:Connect(function()
        if PlayerModule.INFINITE_JUMP then
            local hum = getHumanoid()
            if hum then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    table.insert(_connections, _jumpConn)
end

function PlayerModule.setInfiniteJump(state)
    PlayerModule.INFINITE_JUMP = state
    print("[CawScript] Infinite Jump: " .. (state and "ON" or "OFF"))
end

-- ═══════════════════════════════════════
-- INIT & PUBLIC API
-- ═══════════════════════════════════════

function PlayerModule.init()
    installGodModeHook()
    setupInfiniteJump()
    
    -- Handle respawn
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        
        -- Re-apply sprint jika aktif
        if PlayerModule.SPRINT then
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                _defaultWalkSpeed = hum.WalkSpeed
            end
            -- Sprint loop sudah jalan terus, jadi otomatis apply
        end
        
        -- Re-apply zero gravity
        if PlayerModule.ZERO_GRAVITY then
            workspace.Gravity = 0
        end
    end)
    
    print("[CawScript] PlayerModule initialized!")
end

function PlayerModule.setGodMode(state)
    PlayerModule.GOD_MODE = state
    print("[CawScript] God Mode: " .. (state and "ON" or "OFF"))
end

function PlayerModule.isGodMode()
    return PlayerModule.GOD_MODE
end

return PlayerModule
