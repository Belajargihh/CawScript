--[[
    DiagnosticMovement.lua
    Scan game movement system — cari LocalScripts, Remotes, Humanoid properties
    yang berhubungan dengan movement, jump, speed, gravity, physics.
    
    Jalankan script ini di Delta Executor,
    SCREENSHOT hasilnya dan kirim ke saya.
]]

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local results = {}

-- ═══════════════════════════════════════
-- 1. CHARACTER INFO
-- ═══════════════════════════════════════
table.insert(results, "=== CHARACTER ===")
for _, child in ipairs(char:GetChildren()) do
    local info = child.ClassName .. " > " .. child.Name
    if child:IsA("Humanoid") then
        info = info .. " [WalkSpeed=" .. child.WalkSpeed .. ", JumpPower=" .. child.JumpPower .. ", JumpHeight=" .. child.JumpHeight .. "]"
    elseif child:IsA("BasePart") then
        info = info .. " [Anchored=" .. tostring(child.Anchored) .. ", CanCollide=" .. tostring(child.CanCollide) .. "]"
    elseif child:IsA("ValueBase") then
        info = info .. " = " .. tostring(child.Value)
    end
    table.insert(results, info)
end

-- ═══════════════════════════════════════
-- 2. HUMANOID STATES
-- ═══════════════════════════════════════
table.insert(results, "\n=== HUMANOID STATES ===")
local humanoid = char:FindFirstChildOfClass("Humanoid")
if humanoid then
    table.insert(results, "State: " .. tostring(humanoid:GetState()))
    local states = {
        "Jumping", "Freefall", "Running", "Climbing", 
        "Swimming", "Flying", "Physics", "Dead"
    }
    for _, sName in ipairs(states) do
        local enabled = humanoid:GetStateEnabled(Enum.HumanoidStateType[sName])
        table.insert(results, "  " .. sName .. " = " .. tostring(enabled))
    end
    table.insert(results, "UseJumpPower: " .. tostring(humanoid.UseJumpPower))
    table.insert(results, "AutoRotate: " .. tostring(humanoid.AutoRotate))
    table.insert(results, "PlatformStand: " .. tostring(humanoid.PlatformStand))
else
    table.insert(results, "(Humanoid tidak ditemukan!)")
end

-- ═══════════════════════════════════════
-- 3. WORKSPACE GRAVITY
-- ═══════════════════════════════════════
table.insert(results, "\n=== WORKSPACE ===")
table.insert(results, "Gravity: " .. tostring(workspace.Gravity))

-- ═══════════════════════════════════════
-- 4. BODY MOVERS di Character
-- ═══════════════════════════════════════
table.insert(results, "\n=== BODY MOVERS IN CHARACTER ===")
local foundMovers = false
for _, desc in ipairs(char:GetDescendants()) do
    if desc:IsA("BodyVelocity") or desc:IsA("BodyForce") or desc:IsA("BodyPosition") 
        or desc:IsA("BodyGyro") or desc:IsA("LinearVelocity") or desc:IsA("AlignPosition") then
        table.insert(results, desc.ClassName .. " > " .. desc:GetFullName())
        foundMovers = true
    end
end
if not foundMovers then
    table.insert(results, "(tidak ada)")
end

-- ═══════════════════════════════════════
-- 5. LOCAL SCRIPTS di Character
-- ═══════════════════════════════════════
table.insert(results, "\n=== LOCALSCRIPTS IN CHARACTER ===")
local foundScripts = false
for _, desc in ipairs(char:GetDescendants()) do
    if desc:IsA("LocalScript") then
        table.insert(results, desc.Name .. " [Enabled=" .. tostring(desc.Enabled) .. "] @ " .. desc:GetFullName())
        foundScripts = true
    end
end
if not foundScripts then
    table.insert(results, "(tidak ada)")
end

-- ═══════════════════════════════════════
-- 6. LOCAL SCRIPTS di PlayerScripts
-- ═══════════════════════════════════════
table.insert(results, "\n=== PLAYERSCRIPTS ===")
pcall(function()
    local ps = player:FindFirstChild("PlayerScripts")
    if ps then
        for _, child in ipairs(ps:GetChildren()) do
            local info = child.ClassName .. " > " .. child.Name
            if child:IsA("LocalScript") then
                info = info .. " [Enabled=" .. tostring(child.Enabled) .. "]"
            end
            table.insert(results, info)
            -- 1 level deeper
            for _, sub in ipairs(child:GetChildren()) do
                table.insert(results, "   " .. sub.ClassName .. " > " .. sub.Name)
            end
        end
    else
        table.insert(results, "(tidak ada)")
    end
end)

-- ═══════════════════════════════════════
-- 7. REMOTES — Cari yang berhubungan movement/jump/speed
-- ═══════════════════════════════════════
table.insert(results, "\n=== MOVEMENT-RELATED REMOTES ===")
pcall(function()
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    if remotes then
        for _, child in ipairs(remotes:GetDescendants()) do
            local name = child.Name:lower()
            if name:find("move") or name:find("jump") or name:find("speed") 
                or name:find("walk") or name:find("run") or name:find("fly")
                or name:find("grav") or name:find("sprint") or name:find("dash")
                or name:find("player") or name:find("packet") or name:find("phys")
                or name:find("teleport") or name:find("tp") or name:find("position") then
                table.insert(results, child.ClassName .. " > " .. child:GetFullName())
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- 8. SEMUA REMOTES di folder Remotes (full list)
-- ═══════════════════════════════════════
table.insert(results, "\n=== ALL REMOTES (full list) ===")
pcall(function()
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    if remotes then
        for _, child in ipairs(remotes:GetChildren()) do
            local info = child.ClassName .. " > " .. child.Name
            if #child:GetChildren() > 0 then
                info = info .. " [" .. #child:GetChildren() .. " children]"
            end
            table.insert(results, info)
        end
    end
end)

-- ═══════════════════════════════════════
-- 9. MODULES DI REPLICATED STORAGE
-- ═══════════════════════════════════════
table.insert(results, "\n=== MODULES IN REPLICATED ===")
pcall(function()
    local rs = game:GetService("ReplicatedStorage")
    for _, desc in ipairs(rs:GetDescendants()) do
        if desc:IsA("ModuleScript") then
            local name = desc.Name:lower()
            if name:find("move") or name:find("char") or name:find("control") 
                or name:find("player") or name:find("physics") or name:find("input")
                or name:find("jump") or name:find("walk") or name:find("camera") then
                table.insert(results, desc.ClassName .. " > " .. desc:GetFullName())
            end
        end
    end
end)

-- ═══════════════════════════════════════
-- 10. TEST: Coba ubah properties langsung
-- ═══════════════════════════════════════
table.insert(results, "\n=== LIVE TEST ===")

-- Test WalkSpeed
pcall(function()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local before = hum.WalkSpeed
        hum.WalkSpeed = 100
        task.wait(0.1)
        local after = hum.WalkSpeed
        table.insert(results, "WalkSpeed: " .. before .. " -> set 100 -> now " .. after)
        hum.WalkSpeed = before -- restore
    end
end)

-- Test Gravity
pcall(function()
    local before = workspace.Gravity
    workspace.Gravity = 0
    task.wait(0.1)
    local after = workspace.Gravity
    table.insert(results, "Gravity: " .. before .. " -> set 0 -> now " .. after)
    workspace.Gravity = before -- restore
end)

-- Test Jump
pcall(function()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        local before = hum.JumpPower
        hum.JumpPower = 200
        task.wait(0.1)
        local after = hum.JumpPower
        table.insert(results, "JumpPower: " .. before .. " -> set 200 -> now " .. after)
        hum.JumpPower = before -- restore
    end
end)

-- ═══════════════════════════════════════
-- TAMPILKAN DI LAYAR
-- ═══════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "DiagMovementUI"
gui.DisplayOrder = 9999

local guiParent
pcall(function() guiParent = gethui() end)
if not guiParent then pcall(function() guiParent = game:GetService("CoreGui") end) end
if not guiParent then guiParent = player.PlayerGui end
gui.Parent = guiParent

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 420, 0, 550)
bg.Position = UDim2.new(0.5, -210, 0.5, -275)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
bg.BorderSizePixel = 0
bg.Parent = gui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(220, 120, 0)
title.Text = "🔍 Movement Diagnostic — SCREENSHOT INI!"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = bg
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -70)
scroll.Position = UDim2.new(0, 5, 0, 35)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, #results * 16)
scroll.Parent = bg

local output = Instance.new("TextLabel")
output.Size = UDim2.new(1, -10, 0, #results * 16)
output.Position = UDim2.new(0, 5, 0, 0)
output.BackgroundTransparency = 1
output.Text = table.concat(results, "\n")
output.TextColor3 = Color3.fromRGB(200, 255, 200)
output.TextSize = 11
output.Font = Enum.Font.Code
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = true
output.Parent = scroll

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -20, 0, 28)
closeBtn.Position = UDim2.new(0, 10, 1, -34)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "TUTUP"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bg
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

print("[CawScript] Movement Diagnostic selesai! Cek layar game.")
