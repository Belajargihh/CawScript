--[[
    PlayerModule.lua - Versi 6 (Refined Hijack)
    
    HIJACK STRATEGY V6:
    - Sprint: Mengalikan VelocityX di dalam module game
    - Zero Gravity: Hanya mengunci VelocityY jika TIDAK sedang melompat
    - Infinite Jump: Tetap pakai MaxJump hijack
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
PlayerModule.SPRINT_SPEED = 32       -- WalkSpeed target (Roblox default 16)
PlayerModule.ZERO_GRAVITY = false
PlayerModule.INFINITE_JUMP = false

local _gameModule = nil
local _hookInstalled = false

-- ═══════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════

local function getGameMovementModule()
    if _gameModule then return _gameModule end
    local modScript = player.PlayerScripts:FindFirstChild("PlayerMovement", true)
    if modScript and modScript:IsA("ModuleScript") then
        local success, content = pcall(require, modScript)
        if success and typeof(content) == "table" then
            _gameModule = content
            return _gameModule
        end
    end
    return nil
end

local function getRoot()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ═══════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════

local function startHijackLoop()
    RunService.Heartbeat:Connect(function(dt)
        local mod = getGameMovementModule()
        if not mod then return end
        
        -- 1. INFINITE JUMP
        if PlayerModule.INFINITE_JUMP then
            mod.MaxJump = 999
            mod.RemainingJumps = math.max(mod.RemainingJumps or 0, 1)
        end
        
        -- 2. ZERO GRAVITY (Refined)
        -- Hanya kunci VelocityY jika: aktif AND tidak sedang melompat AND sedang di udara
        if PlayerModule.ZERO_GRAVITY then
            if not mod.Jumping and not mod.Grounded then
                mod.VelocityY = 0 -- Berhenti jatuh
            end
            workspace.Gravity = 0
        else
            -- Workspace gravity jangan dipaksa 0 jika OFF
            -- (Tetapi biarkan sistem game sendiri yang handle)
        end

        -- 3. SPRINT HIJACK (VelocityX Multiplier)
        if PlayerModule.SPRINT then
            -- Jika kita terdeteksi sedang bergerak (VelocityX bukan 0)
            if mod.VelocityX and math.abs(mod.VelocityX) > 0.1 then
                local multiplier = PlayerModule.SPRINT_SPEED / 13 -- Base speed game sekitar 13
                mod.VelocityX = mod.VelocityX * multiplier
            end
            
            -- Fallback CFrame shifting jika VelocityX hijack kurang lancar
            local root = getRoot()
            local char = player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.MoveDirection.Magnitude > 0 then
                local extra = (PlayerModule.SPRINT_SPEED / 13) - 1
                if extra > 0 then
                    root.CFrame = root.CFrame + (hum.MoveDirection * extra * 13 * dt)
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- PUBLIC ACTIONS
-- ═══════════════════════════════════════

function PlayerModule.setSprint(state)
    PlayerModule.SPRINT = state
    print("[CawScript] Sprint: " .. (state and "ON" or "OFF"))
end

function PlayerModule.setSprintSpeed(speed)
    PlayerModule.SPRINT_SPEED = speed
end

function PlayerModule.setZeroGravity(state)
    PlayerModule.ZERO_GRAVITY = state
    workspace.Gravity = state and 0 or 196.2
    print("[CawScript] Zero Gravity: " .. (state and "ON" or "OFF"))
end

function PlayerModule.setInfiniteJump(state)
    PlayerModule.INFINITE_JUMP = state
    if not state then
        local mod = getGameMovementModule()
        if mod then mod.MaxJump = 1 end
    end
end

-- ═══════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════

function PlayerModule.init()
    -- God Mode Hook
    local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
    local RemoteHurt = Remotes and Remotes:WaitForChild("PlayerHurtMe", 2)
    if RemoteHurt then
        local old; old = hookfunction(RemoteHurt.FireServer, newcclosure(function(self, ...)
            if self == RemoteHurt and PlayerModule.GOD_MODE then return nil end
            return old(self, ...)
        end))
    end

    startHijackLoop()
    print("[CawScript] PlayerModule V6 (Refined) Initialized!")
end

function PlayerModule.setGodMode(state) PlayerModule.GOD_MODE = state end
function PlayerModule.isGodMode() return PlayerModule.GOD_MODE end

return PlayerModule
