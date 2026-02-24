--[[
    PlayerModule.lua - Versi 5 (Module Hijack)
    
    HIJACK STRATEGY:
    Kita langsung mengambil data dari module "PlayerMovement" asli game
    dan memanipulasi variabel di dalamnya (MaxJump, VelocityY, dll).
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

local _gameModule = nil      -- Referensi ke module PlayerMovement asli
local _hookInstalled = false
local _connections = {}

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

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════
-- HOOKS
-- ═══════════════════════════════════════

local function installHooks()
    if _hookInstalled then return end
    
    -- God Mode Hook (Damage)
    local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
    local RemoteHurt = Remotes and Remotes:WaitForChild("PlayerHurtMe", 2)
    
    if RemoteHurt then
        pcall(function()
            local oldFire
            oldFire = hookfunction(RemoteHurt.FireServer, newcclosure(function(self, ...)
                if self == RemoteHurt and PlayerModule.GOD_MODE then
                    return nil
                end
                return oldFire(self, ...)
            end))
        end)
    end

    _hookInstalled = true
end

-- ═══════════════════════════════════════
-- MAIN LOOP (HIJACK LOGIC)
-- ═══════════════════════════════════════

local function startHijackLoop()
    RunService.Heartbeat:Connect(function(dt)
        local mod = getGameMovementModule()
        if not mod then return end
        
        -- 1. INFINITE JUMP HIJACK
        if PlayerModule.INFINITE_JUMP then
            mod.MaxJump = 999
            mod.RemainingJumps = 999
        end
        
        -- 2. ZERO GRAVITY / FLY HIJACK
        if PlayerModule.ZERO_GRAVITY then
            -- Paksa VelocityY di dalam module game menjadi 0
            mod.VelocityY = 0
            
            -- Jika sedang tekan spasi, beri sedikit dorongan ke atas (Fly)
            if UIS:IsKeyDown(Enum.KeyCode.Space) then
                mod.VelocityY = 10 -- Naik pelan
            elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                mod.VelocityY = -10 -- Turun pelan
            end
            
            -- Matikan gravitasi global juga
            workspace.Gravity = 0
        end

        -- 3. SPRINT BYPASS (CFrame Shifting)
        -- Tetap pakai CFrame shifting karena module game mungkin tidak punya variabel 'Speed' langsung
        if PlayerModule.SPRINT then
            local root = getRoot()
            local hum = getHumanoid()
            if root and hum and hum.MoveDirection.Magnitude > 0 then
                local extraSpeed = (PlayerModule.SPRINT_SPEED / 16) - 1
                if extraSpeed > 0 then
                    root.CFrame = root.CFrame + (hum.MoveDirection * extraSpeed * 16 * dt)
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
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = state and PlayerModule.SPRINT_SPEED or 16
    end
end

function PlayerModule.setSprintSpeed(speed)
    PlayerModule.SPRINT_SPEED = speed
end

function PlayerModule.setZeroGravity(state)
    PlayerModule.ZERO_GRAVITY = state
    workspace.Gravity = state and 0 or 196.2
    
    -- Reset VelocityY saat dimatikan
    if not state then
        local mod = getGameMovementModule()
        if mod then mod.VelocityY = 0 end
    end
end

function PlayerModule.setInfiniteJump(state)
    PlayerModule.INFINITE_JUMP = state
    
    -- Reset ke default jika dimatikan
    if not state then
        local mod = getGameMovementModule()
        if mod then
            mod.MaxJump = 1
        end
    end
end

-- ═══════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════

function PlayerModule.init()
    installHooks()
    startHijackLoop()
    print("[CawScript] PlayerModule V5 (Hijack) Initialized! ✅")
end

function PlayerModule.setGodMode(state)
    PlayerModule.GOD_MODE = state
end

function PlayerModule.isGodMode()
    return PlayerModule.GOD_MODE
end

return PlayerModule
