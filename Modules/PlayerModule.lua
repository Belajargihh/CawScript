--[[
    PlayerModule.lua - Versi 4 (CFrame Bypass)
    
    Karena game ini menggunakan custom movement handler yang mengabaikan 
    properti Humanoid (WalkSpeed/Gravity), kita akan menggunakan 
    manipulasi CFrame dan Velocity secara paksa.
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
PlayerModule.SPRINT_SPEED = 32       -- Nilai ini akan jadi multiplier CFrame
PlayerModule.ZERO_GRAVITY = false
PlayerModule.INFINITE_JUMP = false

local _hookInstalled = false
local _connections = {}

-- ═══════════════════════════════════════
-- REMOTE REFERENCES
-- ═══════════════════════════════════════

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local RemoteHurt = Remotes and Remotes:WaitForChild("PlayerHurtMe", 2)
local RemoteMoveProp = Remotes and Remotes:WaitForChild("PlayerSetMovementProperty", 2)

-- ═══════════════════════════════════════
-- HOOKS
-- ═══════════════════════════════════════

local function installHooks()
    if _hookInstalled then return end
    
    -- 1. God Mode Hook (Damage)
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
    
    -- 2. Movement Property Hook (Anti-Slow/Anti-Reset)
    -- Jika server mencoba meriset posisi atau speed kita lewat remote ini
    if RemoteMoveProp then
        pcall(function()
            local oldFire
            oldFire = hookfunction(RemoteMoveProp.FireServer, newcclosure(function(self, ...)
                if PlayerModule.SPRINT or PlayerModule.ZERO_GRAVITY then
                    -- Mungkin kita perlu blokir jika ini menyebabkan rubberband
                    -- return nil 
                end
                return oldFire(self, ...)
            end))
        end)
    end

    _hookInstalled = true
end

-- ═══════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════

local function getRoot()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

-- ═══════════════════════════════════════
-- CORE LOOP (Heartbeat)
-- Menggunakan manipulasi fisik langsung yang menembus script custom
-- ═══════════════════════════════════════

local function startMovementLoop()
    RunService.Heartbeat:Connect(function(dt)
        local root = getRoot()
        local hum = getHumanoid()
        if not root or not hum then return end

        -- 1. SPRINT BYPASS (CFrame Shifting)
        if PlayerModule.SPRINT and hum.MoveDirection.Magnitude > 0 then
            -- Hitung berapa banyak kita harus 'dorong' CFrame-nya
            -- SPRINT_SPEED di sini bertindak sebagai multiplier tambahan
            local extraSpeed = (PlayerModule.SPRINT_SPEED / 16) - 1
            if extraSpeed > 0 then
                root.CFrame = root.CFrame + (hum.MoveDirection * extraSpeed * 16 * dt)
            end
        end

        -- 2. ZERO GRAVITY / FLY BYPASS
        if PlayerModule.ZERO_GRAVITY then
            -- Matikan gravitasi secara paksa tiap frame
            local velocity = root.Velocity
            root.Velocity = Vector3.new(velocity.X, 0, velocity.Z)
            
            -- Lock posisi Y supaya melayang sempurna
            -- Kecuali jika sedang lompat manual
            if not UIS:IsKeyDown(Enum.KeyCode.Space) then
                -- Kita bisa tambahkan sedikit gaya angkat jika perlu
                -- root.Velocity = Vector3.new(velocity.X, 0.5, velocity.Z)
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- PUBLIC ACTIONS
-- ═══════════════════════════════════════

function PlayerModule.setSprint(state)
    PlayerModule.SPRINT = state
    -- Kita juga tetap set WalkSpeed sebagai layer dasar
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = state and PlayerModule.SPRINT_SPEED or 16
    end
    print("[CawScript] Sprint: " .. (state and "ON" or "OFF"))
end

function PlayerModule.setSprintSpeed(speed)
    PlayerModule.SPRINT_SPEED = speed
end

function PlayerModule.setZeroGravity(state)
    PlayerModule.ZERO_GRAVITY = state
    -- Set workspace gravity juga sebagai layer dasar
    workspace.Gravity = state and 0 or 196.2
    print("[CawScript] Zero Gravity: " .. (state and "ON" or "OFF"))
end

function PlayerModule.setInfiniteJump(state)
    PlayerModule.INFINITE_JUMP = state
end

-- ═══════════════════════════════════════
-- INITIALIZATION
-- ═══════════════════════════════════════

function PlayerModule.init()
    installHooks()
    startMovementLoop()
    
    -- Infinite Jump Logic
    UIS.JumpRequest:Connect(function()
        if PlayerModule.INFINITE_JUMP then
            local hum = getHumanoid()
            local root = getRoot()
            if hum and root then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                -- Langsung inject velocity ke atas
                root.Velocity = Vector3.new(root.Velocity.X, hum.JumpPower * 1.5, root.Velocity.Z)
            end
        end
    end)
    
    print("[CawScript] PlayerModule V4 (Bypass) Initialized!")
end

function PlayerModule.setGodMode(state)
    PlayerModule.GOD_MODE = state
end

function PlayerModule.isGodMode()
    return PlayerModule.GOD_MODE
end

return PlayerModule
