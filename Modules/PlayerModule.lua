--[[
    PlayerModule.lua
    Module for Player-related features:
    - God Mode (block PlayerHurtMe)
    - Sprint (increase WalkSpeed)
    - Zero Gravity / Fly (float in place)
    - Infinite Jump (jump in mid-air)
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
PlayerModule.SPRINT_SPEED = 32       -- Default sprint speed (normal = 16)
PlayerModule.ZERO_GRAVITY = false
PlayerModule.INFINITE_JUMP = false

local _defaultWalkSpeed = 16
local _bodyVelocity = nil  -- BodyVelocity for zero gravity
local _hookInstalled = false
local _connections = {}     -- Store connections for cleanup

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
-- HELPER: Get character parts
-- ═══════════════════════════════════════

local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid()
    local char = player.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
    local char = player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ═══════════════════════════════════════
-- SPRINT
-- ═══════════════════════════════════════

function PlayerModule.setSprint(state)
    PlayerModule.SPRINT = state
    local humanoid = getHumanoid()
    if humanoid then
        if state then
            _defaultWalkSpeed = humanoid.WalkSpeed
            humanoid.WalkSpeed = PlayerModule.SPRINT_SPEED
        else
            humanoid.WalkSpeed = _defaultWalkSpeed
        end
    end
    print("[CawScript] Sprint: " .. (state and "ON" or "OFF"))
end

function PlayerModule.setSprintSpeed(speed)
    PlayerModule.SPRINT_SPEED = speed
    if PlayerModule.SPRINT then
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = speed
        end
    end
end

-- ═══════════════════════════════════════
-- ZERO GRAVITY / FLY
-- ═══════════════════════════════════════

function PlayerModule.setZeroGravity(state)
    PlayerModule.ZERO_GRAVITY = state
    local rootPart = getRootPart()
    
    if state then
        if rootPart then
            -- Remove old BodyVelocity if exists
            local old = rootPart:FindFirstChild("CawZeroGrav")
            if old then old:Destroy() end
            
            -- Create BodyVelocity to counteract gravity
            local bv = Instance.new("BodyVelocity")
            bv.Name = "CawZeroGrav"
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.MaxForce = Vector3.new(0, math.huge, 0) -- Only Y axis
            bv.P = 1250
            bv.Parent = rootPart
            _bodyVelocity = bv
        end
    else
        -- Remove BodyVelocity to restore gravity
        if _bodyVelocity then
            _bodyVelocity:Destroy()
            _bodyVelocity = nil
        end
        if rootPart then
            local old = rootPart:FindFirstChild("CawZeroGrav")
            if old then old:Destroy() end
        end
    end
    print("[CawScript] Zero Gravity: " .. (state and "ON" or "OFF"))
end

-- ═══════════════════════════════════════
-- INFINITE JUMP
-- ═══════════════════════════════════════

local function setupInfiniteJump()
    local conn = UIS.JumpRequest:Connect(function()
        if PlayerModule.INFINITE_JUMP then
            local humanoid = getHumanoid()
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    table.insert(_connections, conn)
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
    
    -- Keep sprint speed on respawn
    player.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid", 5)
        if humanoid and PlayerModule.SPRINT then
            humanoid.WalkSpeed = PlayerModule.SPRINT_SPEED
        end
        
        -- Re-apply zero gravity on respawn if active
        if PlayerModule.ZERO_GRAVITY then
            task.wait(0.5)
            PlayerModule.setZeroGravity(true)
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
