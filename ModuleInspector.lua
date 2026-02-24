--[[
    ModuleInspector.lua
    Script untuk membedah isi ModuleScript game.
    Fokus: PlayerMovement
]]

local player = game:GetService("Players").LocalPlayer
local results = {}

local function deepInspect(name, tbl, level)
    level = level or 0
    local indent = string.rep("  ", level)
    
    if level > 3 then return end -- Batasi kedalaman agar tidak crash

    for k, v in pairs(tbl) do
        local keyStr = tostring(k)
        local valType = typeof(v)
        local valStr = tostring(v)
        
        if valType == "table" then
            table.insert(results, indent .. "[TABLE] " .. keyStr)
            deepInspect(keyStr, v, level + 1)
        elseif valType == "function" then
            table.insert(results, indent .. "[FUNCTION] " .. keyStr)
        else
            table.insert(results, indent .. "[" .. valType:upper() .. "] " .. keyStr .. " = " .. valStr)
        end
    end
end

-- Cari Module
local targetModule = player.PlayerScripts:FindFirstChild("PlayerMovement", true)

if targetModule and targetModule:IsA("ModuleScript") then
    table.insert(results, "=== INSPECTING: " .. targetModule:GetFullName() .. " ===")
    
    local success, content = pcall(require, targetModule)
    if success then
        if typeof(content) == "table" then
            deepInspect("root", content)
        else
            table.insert(results, "Module returned: " .. typeof(content) .. " -> " .. tostring(content))
        end
    else
        table.insert(results, "FAILED TO REQUIRE: " .. tostring(content))
    end
else
    table.insert(results, "Module 'PlayerMovement' tidak ditemukan!")
end

-- Tampilkan UI
local gui = Instance.new("ScreenGui")
gui.Name = "InspectorUI"
gui.DisplayOrder = 9999
local p; pcall(function() p = gethui() end)
if not p then pcall(function() p = game:GetService("CoreGui") end) end
gui.Parent = p or player.PlayerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 400, 0, 500)
bg.Position = UDim2.new(0.5, -200, 0.5, -250)
bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
bg.Parent = gui

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -40)
scroll.Position = UDim2.new(0, 5, 0, 5)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, #results * 18)
scroll.Parent = bg

local output = Instance.new("TextLabel")
output.Size = UDim2.new(1, 0, 0, #results * 18)
output.BackgroundTransparency = 1
output.Text = table.concat(results, "\n")
output.TextColor3 = Color3.fromRGB(255, 255, 100)
output.TextSize = 12
output.Font = Enum.Font.Code
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.Parent = scroll

local close = Instance.new("TextButton")
close.Size = UDim2.new(1, 0, 0, 30)
close.Position = UDim2.new(0, 0, 1, -30)
close.Text = "CLOSE"
close.Parent = bg
close.MouseButton1Click:Connect(function() gui:Destroy() end)

print("Inspection complete. Check screen.")
