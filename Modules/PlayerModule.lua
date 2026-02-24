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
-- MAIN LOOP (HIJACK LOGIC V7)
-- ═══════════════════════════════════════

local _lockY = nil

local function startHijackLoop()
    RunService.Heartbeat:Connect(function(dt)
        local mod = getGameMovementModule()
        if not mod then return end
        
        -- 1. INFINITE JUMP HIJACK
        if PlayerModule.INFINITE_JUMP then
            mod.MaxJump = 999
            mod.RemainingJumps = math.max(mod.RemainingJumps or 0, 1)
        end
        
        -- 2. ZERO GRAVITY / FLY HIJACK (Refined)
        if PlayerModule.ZERO_GRAVITY then
            -- Berhenti jatuh total dengan mengunci posisi Y
            if not mod.Jumping and not mod.Grounded then
                mod.VelocityY = 0
                
                local root = getRoot()
                if root then
                    -- Simpan posisi Y saat mulai melayang
                    if not _lockY then _lockY = root.Position.Y end
                    
                    -- Paksa posisi Y diam di tempat
                    root.CFrame = CFrame.new(root.Position.X, _lockY, root.Position.Z) * root.CFrame.Rotation
                    root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
                end
            else
                -- Jika sedang lompat atau di tanah, jangan lock Y
                _lockY = nil
            end
            workspace.Gravity = 0
        else
            _lockY = nil
        end

        -- 3. SPRINT HIJACK (Smoother)
        if PlayerModule.SPRINT then
            local root = getRoot()
            local hum = getHumanoid()
            if root and hum and hum.MoveDirection.Magnitude > 0 then
                -- Gunakan multiplier yang lebih masuk akal (max 3x)
                local targetSpeed = math.clamp(PlayerModule.SPRINT_SPEED, 16, 50)
                local extraSpeed = (targetSpeed / 13) - 1
                
                if extraSpeed > 0 then
                    -- Pindahkan CFrame secara halus
                    root.CFrame = root.CFrame + (hum.MoveDirection * extraSpeed * 13 * dt)
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
    _lockY = nil
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
        local success, old = pcall(function()
            return hookfunction(RemoteHurt.FireServer, newcclosure(function(self, ...)
                if self == RemoteHurt and PlayerModule.GOD_MODE then return nil end
                -- Use old namecall/metamethod if hookfunction fails or just return original
                -- but for now we expect old to be returned by hookfunction.
                -- However, in some envs hookfunction returns the original func.
            end))
        end)
    end

    startHijackLoop()
    print("[CawScript] PlayerModule V7 (Refined) Initialized!")
end

function PlayerModule.setGodMode(state) PlayerModule.GOD_MODE = state end
function PlayerModule.isGodMode() return PlayerModule.GOD_MODE end

return PlayerModule
