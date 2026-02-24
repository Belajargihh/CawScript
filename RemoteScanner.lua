--[[
    RemoteScanner.lua
    List all RemoteEvents and RemoteFunctions in ReplicatedStorage.Remotes
]]

local player = game:GetService("Players").LocalPlayer
local results = {}

table.insert(results, "=== REMOTE SCANNER (ReplicatedStorage.Remotes) ===")

local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
if remotes then
    for _, child in ipairs(remotes:GetDescendants()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            table.insert(results, string.format("[%s] %s", child.ClassName, child.Name))
        end
    end
else
    table.insert(results, "ERROR: Folder 'Remotes' tidak ditemukan di ReplicatedStorage")
end

-- Show UI
local gui = Instance.new("ScreenGui")
gui.Name = "RemoteScannerUI"
gui.DisplayOrder = 10001

local parent = pcall(function() return gethui() end) or pcall(function() return game:GetService("CoreGui") end) or player.PlayerGui
gui.Parent = parent

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 400, 0, 450)
bg.Position = UDim2.new(0.5, -200, 0.5, -225)
bg.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
bg.BorderSizePixel = 0
bg.Parent = gui
Instance.new("UICorner", bg)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(100, 50, 150)
title.Text = "📡 Remote Scanner Diagnostic"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.Parent = bg

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -80)
scroll.Position = UDim2.new(0, 10, 0, 40)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, #results * 18)
scroll.Parent = bg

local out = Instance.new("TextLabel")
out.Size = UDim2.new(1, 0, 0, #results * 18)
out.BackgroundTransparency = 1
out.Text = table.concat(results, "\n")
out.TextColor3 = Color3.fromRGB(200, 255, 255)
out.TextSize = 11
out.Font = Enum.Font.Code
out.TextXAlignment = Enum.TextXAlignment.Left
out.TextYAlignment = Enum.TextYAlignment.Top
out.Parent = scroll

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 100, 0, 30)
close.Position = UDim2.new(0.5, -50, 1, -35)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Text = "CLOSE"
close.TextColor3 = Color3.new(1,1,1)
close.Parent = bg
close.MouseButton1Click:Connect(function() gui:Destroy() end)
