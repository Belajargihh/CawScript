--[[
    MovementDiagnostic.lua
    Visible Diagnostic Version
]]

local player = game:GetService("Players").LocalPlayer
local char = player.Character
local hum = char and char:FindFirstChildOfClass("Humanoid")
local hrp = char and char:FindFirstChild("HumanoidRootPart")

-- Create Visible GUI
local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
sg.Name = "DiagUI"
local frame = Instance.new("ScrollingFrame", sg)
frame.Size = UDim2.new(0, 300, 0, 400)
frame.Position = UDim2.new(0.5, -150, 0.5, -200)
frame.BackgroundColor3 = Color3.new(0,0,0)
frame.BackgroundTransparency = 0.5
local list = Instance.new("UIListLayout", frame)

local function logDiag(msg)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, 0, 0, 25)
    lbl.Text = tostring(msg)
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.BackgroundTransparency = 1
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    print("[DIAG] " .. tostring(msg))
end

logDiag("--- MOVEMENT DIAGNOSTIC ---")

if not char then logDiag("ERROR: No Character found!") return end
if not hum then logDiag("ERROR: No Humanoid found!") return end
if not hrp then logDiag("ERROR: No HumanoidRootPart found!") return end

logDiag("State: " .. tostring(hum:GetState()))
logDiag("PlatformStand: " .. tostring(hum.PlatformStand))
logDiag("Sit: " .. tostring(hum.Sit))
logDiag("WalkSpeed: " .. tostring(hum.WalkSpeed))
logDiag("Root Anchored: " .. tostring(hrp.Anchored))

-- Check for anchored parts
local anchoredCount = 0
for _, p in ipairs(char:GetDescendants()) do
    if p:IsA("BasePart") and p.Anchored then
        logDiag("ANCHORED: " .. p.Name)
        anchoredCount = anchoredCount + 1
    end
end
if anchoredCount == 0 then logDiag("No anchored parts found.") end

-- Test MoveTo
logDiag("TESTING MoveTo (10 studs right)...")
local target = hrp.Position + Vector3.new(10, 0, 0)
hum:MoveTo(target)

task.spawn(function()
    local start = tick()
    while tick() - start < 5 do
        task.wait(1)
        local dist = (hrp.Position - target).Magnitude
        logDiag("Dist: " .. math.floor(dist))
        if dist < 3 then 
            logDiag("SUCCESS: Character moved!")
            return 
        end
    end
    logDiag("FAILURE: Still hasn't moved.")
end)
