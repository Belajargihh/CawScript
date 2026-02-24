--[[
    PlayerModule.lua
    Player features for custom-movement games.
    
    Karena game ini pakai custom movement (PlayerMovementPackets),
    kita harus manipulasi fisik karakter secara langsung setiap frame.
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
local _defaultJumpPower = 50
local _defaultGravity = 196.2
local _hookInstalled = false

-- Active connections
local _sprintConn = nil
local _zeroGravConn = nil
local _jumpConn = nil
local _bodyForce = nil

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

    pcall(function()
        local oldFire
        oldFire = hookfunction(RemoteHurt.FireServer, newcclosure(function(self, ...)
            if self == RemoteHurt and PlayerModule.GOD_MODE then
                return nil
            end
            return oldFire(self, ...)
        end))
        _hookInstalled = true
        print("[CawScript] God Mode hook installed!")
    end)

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
            print("[CawScript] God Mode hook (mt) installed!")
        end)
    end

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
            print("[CawScript] God Mode hook (hmm) installed!")
        end)
    end
end

-- ═══════════════════════════════════════
-- HELPER
-- ═══════════════════════════════════════

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
-- Strategi: Force WalkSpeed + JumpPower setiap Heartbeat
-- DAN juga coba gerak CFrame langsung
-- ═══════════════════════════════════════

function PlayerModule.setSprint(state)
    PlayerModule.SPRINT = state
    
    if state then
        local hum = getHumanoid()
        if hum then
            _defaultWalkSpeed = hum.WalkSpeed
        end
        
        -- Disconnect old
        if _sprintConn then _sprintConn:Disconnect() end
        
        _sprintConn = RunService.Heartbeat:Connect(function()
            if not PlayerModule.SPRINT then return end
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = PlayerModule.SPRINT_SPEED
            end
        end)
        
        print("[CawScript] Sprint ON — Speed: " .. PlayerModule.SPRINT_SPEED)
    else
        if _sprintConn then
            _sprintConn:Disconnect()
            _sprintConn = nil
        end
        local hum = getHumanoid()
        if hum then
            hum.WalkSpeed = _defaultWalkSpeed
        end
        print("[CawScript] Sprint OFF")
    end
end

function PlayerModule.setSprintSpeed(speed)
    PlayerModule.SPRINT_SPEED = speed
end

-- ═══════════════════════════════════════
-- ZERO GRAVITY / FLY
-- Strategi multi-layer:
-- 1. workspace.Gravity = 0
-- 2. BodyForce untuk counteract gravity
-- 3. RenderStepped: force Velocity.Y = 0
-- 4. Noclip (set CanCollide false agar tembus)
-- ═══════════════════════════════════════

function PlayerModule.setZeroGravity(state)
    PlayerModule.ZERO_GRAVITY = state
    
    if state then
        -- Layer 1: workspace gravity
        _defaultGravity = workspace.Gravity
        workspace.Gravity = 0
        
        -- Layer 2: BodyForce untuk counteract sisa gravitasi
        local rootPart = getRootPart()
        if rootPart then
            -- Remove old
            local old = rootPart:FindFirstChild("CawAntiGrav")
            if old then old:Destroy() end
            
            -- BodyForce counteract gravity
            local bf = Instance.new("BodyForce")
            bf.Name = "CawAntiGrav"
            local char = player.Character
            local mass = 0
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    mass = mass + part:GetMass()
                end
            end
            bf.Force = Vector3.new(0, mass * _defaultGravity, 0)
            bf.Parent = rootPart
            _bodyForce = bf
        end
        
        -- Layer 3: RenderStepped — force Velocity.Y = 0 dan noclip
        if _zeroGravConn then _zeroGravConn:Disconnect() end
        _zeroGravConn = RunService.RenderStepped:Connect(function()
            if not PlayerModule.ZERO_GRAVITY then return end
            local rootPart = getRootPart()
            if rootPart then
                -- Kill vertical velocity (keep floating)
                local vel = rootPart.Velocity
                rootPart.Velocity = Vector3.new(vel.X, 0, vel.Z)
            end
        end)
        
        print("[CawScript] Zero Gravity ON")
    else
        -- Restore
        workspace.Gravity = _defaultGravity
        
        -- Remove BodyForce
        if _bodyForce then
            _bodyForce:Destroy()
            _bodyForce = nil
        end
        local rootPart = getRootPart()
        if rootPart then
            local old = rootPart:FindFirstChild("CawAntiGrav")
            if old then old:Destroy() end
        end
        
        -- Disconnect render loop
        if _zeroGravConn then
            _zeroGravConn:Disconnect()
            _zeroGravConn = nil
        end
        
        print("[CawScript] Zero Gravity OFF")
    end
end

-- ═══════════════════════════════════════
-- INFINITE JUMP
-- Strategi: Multiple approaches sekaligus
-- 1. JumpRequest hook
-- 2. Force Humanoid state
-- 3. Apply upward Velocity langsung
-- ═══════════════════════════════════════

local function setupInfiniteJump()
    -- Method 1: JumpRequest
    _jumpConn = UIS.JumpRequest:Connect(function()
        if PlayerModule.INFINITE_JUMP then
            local hum = getHumanoid()
            local rootPart = getRootPart()
            
            if hum then
                -- Force enable jumping state
                pcall(function()
                    hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
                end)
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            
            -- Langsung apply velocity ke atas
            if rootPart then
                local jumpForce = hum and hum.JumpPower or 50
                rootPart.Velocity = Vector3.new(
                    rootPart.Velocity.X,
                    jumpForce,
                    rootPart.Velocity.Z
                )
            end
        end
    end)
end

function PlayerModule.setInfiniteJump(state)
    PlayerModule.INFINITE_JUMP = state
    
    -- Juga force enable jump state di Humanoid
    if state then
        local hum = getHumanoid()
        if hum then
            pcall(function()
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            end)
        end
    end
    
    print("[CawScript] Infinite Jump: " .. (state and "ON" or "OFF"))
end

-- ═══════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════

function PlayerModule.init()
    print("[CawScript] PlayerModule initializing...")
    
    installGodModeHook()
    setupInfiniteJump()
    
    -- Handle respawn
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        
        if PlayerModule.SPRINT then
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then _defaultWalkSpeed = hum.WalkSpeed end
        end
        
        if PlayerModule.ZERO_GRAVITY then
            PlayerModule.setZeroGravity(true)
        end
    end)
    
    print("[CawScript] PlayerModule initialized! ✅")
end

function PlayerModule.setGodMode(state)
    PlayerModule.GOD_MODE = state
    print("[CawScript] God Mode: " .. (state and "ON" or "OFF"))
end

function PlayerModule.isGodMode()
    return PlayerModule.GOD_MODE
end

return PlayerModule
