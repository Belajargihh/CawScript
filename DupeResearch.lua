-- DupeResearch SIMPLE (Copy DropSpy format yang sudah terbukti jalan)
print("[DUPE] START")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "DupeSimple"
gui.ResetOnSpawn = false
gui.DisplayOrder = 99999

local guiParent
pcall(function() guiParent = gethui() end)
if not guiParent then pcall(function() guiParent = game:GetService("CoreGui") end) end
if not guiParent then guiParent = player:WaitForChild("PlayerGui", 5) end
gui.Parent = guiParent

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 300)
Main.Position = UDim2.new(0.5, -140, 0.5, -150)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = gui
Instance.new("UICorner", Main)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
Title.Text = "🧪 Dupe Research"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Main
Instance.new("UICorner", Title)

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -10, 1, -120)
Scroll.Position = UDim2.new(0, 5, 0, 40)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local termText = Instance.new("TextLabel")
termText.Size = UDim2.new(1, 0, 0, 0)
termText.AutomaticSize = Enum.AutomaticSize.Y
termText.BackgroundTransparency = 1
termText.Text = "--- LOG ---"
termText.TextColor3 = Color3.fromRGB(0, 255, 100)
termText.TextSize = 10
termText.Font = Enum.Font.Code
termText.TextXAlignment = Enum.TextXAlignment.Left
termText.TextYAlignment = Enum.TextYAlignment.Top
termText.TextWrapped = true
termText.Parent = Scroll

local function log(msg)
    termText.Text = termText.Text .. "\n" .. tostring(msg)
    Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
    print("[DUPE] " .. tostring(msg))
end

-- Remotes (no wait)
local RS = game:GetService("ReplicatedStorage")
local RemoteDrop, RemotePrompt

pcall(function() RemoteDrop = RS.Remotes.PlayerDrop end)
pcall(function() RemotePrompt = RS.Managers.UIManager.UIPromptEvent end)

log("PlayerDrop: " .. tostring(RemoteDrop ~= nil))
log("UIPromptEvent: " .. tostring(RemotePrompt ~= nil))

-- Button 1: SPOOF
local Btn1 = Instance.new("TextButton")
Btn1.Size = UDim2.new(1, -10, 0, 30)
Btn1.Position = UDim2.new(0, 5, 1, -75)
Btn1.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
Btn1.Text = "🔥 SPOOF (Slot 1, Amt 999)"
Btn1.TextColor3 = Color3.new(1,1,1)
Btn1.Font = Enum.Font.GothamBold
Btn1.TextSize = 11
Btn1.Parent = Main
Instance.new("UICorner", Btn1)

Btn1.MouseButton1Click:Connect(function()
    if not RemoteDrop or not RemotePrompt then return log("ERR: Remote missing") end
    log("Firing Spoof...")
    RemoteDrop:FireServer(1)
    task.wait(0.15)
    RemotePrompt:FireServer({ ButtonAction = "drp", Inputs = { amt = "999" } })
    log("SENT! Cek tanah.")
end)

-- Button 2: LAG SPAM
local Btn2 = Instance.new("TextButton")
Btn2.Size = UDim2.new(1, -10, 0, 30)
Btn2.Position = UDim2.new(0, 5, 1, -40)
Btn2.BackgroundColor3 = Color3.fromRGB(100, 50, 180)
Btn2.Text = "⚡ LAG SPAM (5x Slot 1)"
Btn2.TextColor3 = Color3.new(1,1,1)
Btn2.Font = Enum.Font.GothamBold
Btn2.TextSize = 11
Btn2.Parent = Main
Instance.new("UICorner", Btn2)

Btn2.MouseButton1Click:Connect(function()
    if not RemoteDrop or not RemotePrompt then return log("ERR: Remote missing") end
    log("Firing 5x Spam...")
    for i = 1,5 do RemoteDrop:FireServer(1) task.wait(0.02) end
    task.wait(0.05)
    for i = 1,5 do RemotePrompt:FireServer({ ButtonAction = "drp", Inputs = { amt = "1" } }) end
    log("DONE! Cek tanah.")
end)

log("READY. Taruh item di Slot 1.")
print("[DUPE] SETUP OK")
