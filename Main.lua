--[[
    Main.lua
    Custom UI — Sidebar Tabs + 5x5 Grid (No Rayfield)
    
    Tabs:
    1. Auto PnB — Grid target, select item, start/stop
    2. Manager — Coming Soon
    3. Rotasi — Coming Soon
    4. Bot — Coming Soon
]]

-- ═══════════════════════════════════════
-- LOAD DEPENDENCIES
-- ═══════════════════════════════════════

local GITHUB_BASE = "https://raw.githubusercontent.com/Belajargihh/CawScript/main/"

local AutoPnB     = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/AutoPnB.lua"))()
local Antiban      = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/Antiban.lua"))()
local Coordinates  = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/Coordinates.lua"))()

AutoPnB.init(Coordinates, Antiban)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- ═══════════════════════════════════════
-- REMOTE HOOK: DETECT ITEM ID
-- ═══════════════════════════════════════

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")

local detectMode = false
local hookSuccess = false

local function onDetectPlace(args)
    if detectMode and not AutoPnB.isRunning() then
        if args[2] and type(args[2]) == "number" then
            AutoPnB.ITEM_ID = args[2]
            detectMode = false
        end
    end
end

-- Method 1: hookmetamethod
if not hookSuccess then
    pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if getnamecallmethod() == "FireServer" and self == RemotePlace then
                onDetectPlace({...})
            end
            return old(self, ...)
        end))
        hookSuccess = true
    end)
end

-- Method 2: getrawmetatable
if not hookSuccess then
    pcall(function()
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            if getnamecallmethod() == "FireServer" and self == RemotePlace then
                onDetectPlace({...})
            end
            return oldNamecall(self, ...)
        end)
        setreadonly(mt, true)
        hookSuccess = true
    end)
end

-- Method 3: hookfunction
if not hookSuccess then
    pcall(function()
        local oldFire
        oldFire = hookfunction(RemotePlace.FireServer, function(self, ...)
            if self == RemotePlace then
                onDetectPlace({...})
            end
            return oldFire(self, ...)
        end)
        hookSuccess = true
    end)
end

-- ═══════════════════════════════════════
-- WARNA & STYLE
-- ═══════════════════════════════════════

local C = {
    bg          = Color3.fromRGB(18, 18, 28),
    sidebar     = Color3.fromRGB(14, 14, 22),
    sideActive  = Color3.fromRGB(100, 80, 255),
    sideHover   = Color3.fromRGB(35, 35, 50),
    sideText    = Color3.fromRGB(120, 120, 140),
    titleBar    = Color3.fromRGB(24, 24, 38),
    cellOff     = Color3.fromRGB(40, 40, 55),
    cellOn      = Color3.fromRGB(0, 180, 80),
    cellPlayer  = Color3.fromRGB(50, 120, 220),
    white       = Color3.fromRGB(255, 255, 255),
    dim         = Color3.fromRGB(140, 140, 160),
    btnStart    = Color3.fromRGB(0, 160, 70),
    btnStop     = Color3.fromRGB(200, 50, 50),
    btnGrey     = Color3.fromRGB(50, 50, 70),
    accent      = Color3.fromRGB(100, 80, 255),
    comingSoon  = Color3.fromRGB(80, 80, 100),
}

-- ═══════════════════════════════════════
-- SCREENGUI
-- ═══════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "CawScriptUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player.PlayerGui

-- ═══════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════

local SIDEBAR_W = 50
local CONTENT_W = 260
local TOTAL_W = SIDEBAR_W + CONTENT_W
local TOTAL_H = 460

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, TOTAL_W, 0, TOTAL_H)
mainFrame.Position = UDim2.new(0, 20, 0.5, -TOTAL_H / 2)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = gui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

-- ═══════════════════════════════════════
-- TITLE BAR
-- ═══════════════════════════════════════

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = C.titleBar
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = C.titleBar
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -70, 1, 0)
titleText.Position = UDim2.new(0, SIDEBAR_W + 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "CawScript"
titleText.TextColor3 = C.white
titleText.TextSize = 14
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Minimize
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -52, 0, 5)
minBtn.BackgroundColor3 = C.btnGrey
minBtn.Text = "_"
minBtn.TextColor3 = C.white
minBtn.TextSize = 12
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -26, 0, 5)
closeBtn.BackgroundColor3 = C.btnStop
closeBtn.Text = "X"
closeBtn.TextColor3 = C.white
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Draggable
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ═══════════════════════════════════════
-- SIDEBAR
-- ═══════════════════════════════════════

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -32)
sidebar.Position = UDim2.new(0, 0, 0, 32)
sidebar.BackgroundColor3 = C.sidebar
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = UDim.new(0, 10)
sideCorner.Parent = sidebar

local sideFix = Instance.new("Frame")
sideFix.Size = UDim2.new(1, 0, 0, 10)
sideFix.Position = UDim2.new(0, 0, 0, 0)
sideFix.BackgroundColor3 = C.sidebar
sideFix.BorderSizePixel = 0
sideFix.Parent = sidebar

local sideFix2 = Instance.new("Frame")
sideFix2.Size = UDim2.new(0, 10, 1, 0)
sideFix2.Position = UDim2.new(1, -10, 0, 0)
sideFix2.BackgroundColor3 = C.sidebar
sideFix2.BorderSizePixel = 0
sideFix2.Parent = sidebar

-- Tab definitions
local tabs = {
    {icon = "⚒️", name = "Auto PnB"},
    {icon = "📦", name = "Manager"},
    {icon = "🔄", name = "Rotasi"},
    {icon = "🤖", name = "Bot"},
}

local tabButtons = {}
local tabFrames = {}
local activeTab = 1

-- Create tab buttons
for i, tab in ipairs(tabs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, SIDEBAR_W)
    btn.Position = UDim2.new(0, 0, 0, (i - 1) * SIDEBAR_W)
    btn.BackgroundTransparency = 1
    btn.Text = tab.icon
    btn.TextSize = 20
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = C.sideText
    btn.BorderSizePixel = 0
    btn.Parent = sidebar
    
    -- Active indicator (left bar)
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0, 24)
    indicator.Position = UDim2.new(0, 0, 0.5, -12)
    indicator.BackgroundColor3 = C.sideActive
    indicator.BorderSizePixel = 0
    indicator.Visible = (i == 1)
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)
    
    btn.MouseButton1Click:Connect(function()
        -- Switch tab
        activeTab = i
        for j, f in ipairs(tabFrames) do
            f.Visible = (j == i)
        end
        for j, b in ipairs(tabButtons) do
            local ind = b:FindFirstChild("Indicator")
            if ind then ind.Visible = (j == i) end
            b.TextColor3 = (j == i) and C.white or C.sideText
        end
    end)
    
    tabButtons[i] = btn
end

-- Set first tab active
tabButtons[1].TextColor3 = C.white

-- ═══════════════════════════════════════
-- CONTENT CONTAINER
-- ═══════════════════════════════════════

local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(0, CONTENT_W, 1, -32)
contentContainer.Position = UDim2.new(0, SIDEBAR_W, 0, 32)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

-- Minimize / Close
local minimized = false

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    sidebar.Visible = not minimized
    contentContainer.Visible = not minimized
    mainFrame.Size = minimized
        and UDim2.new(0, TOTAL_W, 0, 32)
        or UDim2.new(0, TOTAL_W, 0, TOTAL_H)
end)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- ═══════════════════════════════════════
-- HELPER: Create Coming Soon page
-- ═══════════════════════════════════════

local function createComingSoonTab(parent, tabName)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 1, -10)
    frame.Position = UDim2.new(0, 10, 0, 5)
    frame.BackgroundTransparency = 1
    frame.Visible = false
    frame.Parent = parent
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(1, 0, 0, 50)
    icon.Position = UDim2.new(0, 0, 0.3, -40)
    icon.BackgroundTransparency = 1
    icon.Text = "🚧"
    icon.TextSize = 40
    icon.Font = Enum.Font.GothamBold
    icon.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.Position = UDim2.new(0, 0, 0.3, 15)
    title.BackgroundTransparency = 1
    title.Text = tabName
    title.TextColor3 = C.white
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 20)
    sub.Position = UDim2.new(0, 0, 0.3, 42)
    sub.BackgroundTransparency = 1
    sub.Text = "Coming Soon"
    sub.TextColor3 = C.comingSoon
    sub.TextSize = 14
    sub.Font = Enum.Font.Gotham
    sub.Parent = frame
    
    return frame
end

-- ═══════════════════════════════════════
-- TAB 1: AUTO PnB
-- ═══════════════════════════════════════

local tabPnB = Instance.new("Frame")
tabPnB.Size = UDim2.new(1, -20, 1, -10)
tabPnB.Position = UDim2.new(0, 10, 0, 5)
tabPnB.BackgroundTransparency = 1
tabPnB.Visible = true
tabPnB.Parent = contentContainer

-- Posisi label
local posLabel = Instance.new("TextLabel")
posLabel.Size = UDim2.new(1, 0, 0, 16)
posLabel.BackgroundTransparency = 1
posLabel.Text = "📍 Posisi: ..."
posLabel.TextColor3 = C.dim
posLabel.TextSize = 12
posLabel.Font = Enum.Font.Gotham
posLabel.TextXAlignment = Enum.TextXAlignment.Left
posLabel.Parent = tabPnB

-- Item ID display + Select button
local itemRow = Instance.new("Frame")
itemRow.Size = UDim2.new(1, 0, 0, 55)
itemRow.Position = UDim2.new(0, 0, 0, 20)
itemRow.BackgroundTransparency = 1
itemRow.Parent = tabPnB

local itemLabel = Instance.new("TextLabel")
itemLabel.Size = UDim2.new(0, 70, 0, 22)
itemLabel.BackgroundTransparency = 1
itemLabel.Text = "🧱 Item:"
itemLabel.TextColor3 = C.dim
itemLabel.TextSize = 12
itemLabel.Font = Enum.Font.Gotham
itemLabel.TextXAlignment = Enum.TextXAlignment.Left
itemLabel.Parent = itemRow

local itemDisplay = Instance.new("TextLabel")
itemDisplay.Size = UDim2.new(0, 50, 0, 22)
itemDisplay.Position = UDim2.new(0, 70, 0, 0)
itemDisplay.BackgroundColor3 = C.cellOff
itemDisplay.Text = "2"
itemDisplay.TextColor3 = C.white
itemDisplay.TextSize = 13
itemDisplay.Font = Enum.Font.GothamBold
itemDisplay.BorderSizePixel = 0
itemDisplay.Parent = itemRow
Instance.new("UICorner", itemDisplay).CornerRadius = UDim.new(0, 5)

local selectBtn = Instance.new("TextButton")
selectBtn.Size = UDim2.new(1, 0, 0, 26)
selectBtn.Position = UDim2.new(0, 0, 0, 26)
selectBtn.BorderSizePixel = 0
selectBtn.TextSize = 12
selectBtn.Font = Enum.Font.GothamBold
selectBtn.TextColor3 = C.white
selectBtn.Parent = itemRow
Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)

if hookSuccess then
    selectBtn.BackgroundColor3 = C.accent
    selectBtn.Text = "🔍 Select Item — Klik lalu Place 1 blok"
else
    selectBtn.BackgroundColor3 = C.cellOff
    selectBtn.Text = "⚠️ Hook gagal"
end

selectBtn.MouseButton1Click:Connect(function()
    if not hookSuccess then return end
    if detectMode then
        detectMode = false
        selectBtn.BackgroundColor3 = C.accent
        selectBtn.Text = "🔍 Select Item — Klik lalu Place 1 blok"
    else
        detectMode = true
        selectBtn.BackgroundColor3 = Color3.fromRGB(220, 160, 0)
        selectBtn.Text = "⏳ Menunggu... Place 1 blok sekarang!"
    end
end)

-- ═══════════════════════════════════════
-- 5x5 GRID
-- ═══════════════════════════════════════

local GRID_SIZE = 5
local CELL_SIZE = 38
local CELL_GAP = 3
local gridTotal = GRID_SIZE * CELL_SIZE + (GRID_SIZE - 1) * CELL_GAP

local gridFrame = Instance.new("Frame")
gridFrame.Size = UDim2.new(0, gridTotal, 0, gridTotal)
gridFrame.Position = UDim2.new(0.5, -gridTotal / 2, 0, 82)
gridFrame.BackgroundTransparency = 1
gridFrame.Parent = tabPnB

for row = 0, GRID_SIZE - 1 do
    for col = 0, GRID_SIZE - 1 do
        local dx = col - 2
        local dy = 2 - row
        local isCenter = (dx == 0 and dy == 0)
        
        local cell = Instance.new("TextButton")
        cell.Size = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE)
        cell.Position = UDim2.new(0, col * (CELL_SIZE + CELL_GAP), 0, row * (CELL_SIZE + CELL_GAP))
        cell.BorderSizePixel = 0
        cell.TextSize = 10
        cell.Font = Enum.Font.Gotham
        cell.AutoButtonColor = not isCenter
        cell.Parent = gridFrame
        Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 5)
        
        if isCenter then
            cell.BackgroundColor3 = C.cellPlayer
            cell.Text = "ME"
            cell.TextColor3 = C.white
        else
            cell.BackgroundColor3 = C.cellOff
            cell.Text = ""
            cell.TextColor3 = C.white
            local active = false
            
            cell.MouseButton1Click:Connect(function()
                active = not active
                if active then
                    cell.BackgroundColor3 = C.cellOn
                    cell.Text = "✓"
                    AutoPnB.addTarget(dx, dy)
                else
                    cell.BackgroundColor3 = C.cellOff
                    cell.Text = ""
                    AutoPnB.removeTarget(dx, dy)
                end
            end)
        end
    end
end

-- Grid hint
local gridHint = Instance.new("TextLabel")
gridHint.Size = UDim2.new(1, 0, 0, 14)
gridHint.Position = UDim2.new(0, 0, 0, 82 + gridTotal + 3)
gridHint.BackgroundTransparency = 1
gridHint.Text = "Klik cell = target PnB"
gridHint.TextColor3 = C.dim
gridHint.TextSize = 10
gridHint.Font = Enum.Font.Gotham
gridHint.Parent = tabPnB

-- ═══════════════════════════════════════
-- CONTROLS
-- ═══════════════════════════════════════

local ctrlY = 82 + gridTotal + 22

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.48, 0, 0, 28)
startBtn.Position = UDim2.new(0, 0, 0, ctrlY)
startBtn.BackgroundColor3 = C.btnStart
startBtn.Text = "▶  START"
startBtn.TextColor3 = C.white
startBtn.TextSize = 13
startBtn.Font = Enum.Font.GothamBold
startBtn.BorderSizePixel = 0
startBtn.Parent = tabPnB
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 7)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.48, 0, 0, 28)
stopBtn.Position = UDim2.new(0.52, 0, 0, ctrlY)
stopBtn.BackgroundColor3 = C.btnStop
stopBtn.Text = "■  STOP"
stopBtn.TextColor3 = C.white
stopBtn.TextSize = 13
stopBtn.Font = Enum.Font.GothamBold
stopBtn.BorderSizePixel = 0
stopBtn.Parent = tabPnB
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 7)

startBtn.MouseButton1Click:Connect(function()
    if not AutoPnB.isRunning() then
        AutoPnB.start()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    AutoPnB.stop()
end)

-- Status
local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 14)
statusLabel.Position = UDim2.new(0, 0, 0, ctrlY + 32)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = C.dim
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = tabPnB

local cycleLabel = Instance.new("TextLabel")
cycleLabel.Size = UDim2.new(1, 0, 0, 14)
cycleLabel.Position = UDim2.new(0, 0, 0, ctrlY + 46)
cycleLabel.BackgroundTransparency = 1
cycleLabel.Text = "Siklus: 0 | Target: 0"
cycleLabel.TextColor3 = C.dim
cycleLabel.TextSize = 11
cycleLabel.Font = Enum.Font.Gotham
cycleLabel.TextXAlignment = Enum.TextXAlignment.Left
cycleLabel.Parent = tabPnB

-- Delay slider
local delayY = ctrlY + 64

local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(1, 0, 0, 14)
delayLabel.Position = UDim2.new(0, 0, 0, delayY)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "Delay: 0.30s"
delayLabel.TextColor3 = C.dim
delayLabel.TextSize = 11
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = tabPnB

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, 0, 0, 6)
sliderBg.Position = UDim2.new(0, 0, 0, delayY + 16)
sliderBg.BackgroundColor3 = C.cellOff
sliderBg.BorderSizePixel = 0
sliderBg.Parent = tabPnB
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 3)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.15, 0, 1, 0)
sliderFill.BackgroundColor3 = C.accent
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)

local sliderHit = Instance.new("TextButton")
sliderHit.Size = UDim2.new(1, 0, 0, 18)
sliderHit.Position = UDim2.new(0, 0, 0, delayY + 10)
sliderHit.BackgroundTransparency = 1
sliderHit.Text = ""
sliderHit.Parent = tabPnB

local sliderDrag = false
sliderHit.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDrag = true
    end
end)
UIS.InputChanged:Connect(function(input)
    if sliderDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local rel = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        local val = math.max(math.floor(rel * 200) / 100, 0.05)
        AutoPnB.DELAY_CYCLE = val
        delayLabel.Text = string.format("Delay: %.2fs", val)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDrag = false
    end
end)

-- Store tab 1 frame
tabFrames[1] = tabPnB

-- ═══════════════════════════════════════
-- TAB 2, 3, 4: COMING SOON
-- ═══════════════════════════════════════

tabFrames[2] = createComingSoonTab(contentContainer, "Manager")
tabFrames[3] = createComingSoonTab(contentContainer, "Rotasi")
tabFrames[4] = createComingSoonTab(contentContainer, "Bot")

-- ═══════════════════════════════════════
-- REAL-TIME UPDATE LOOP
-- ═══════════════════════════════════════

spawn(function()
    while gui and gui.Parent do
        local gx, gy = Coordinates.getGridPosition()
        if gx then
            posLabel.Text = "📍 Posisi: X=" .. gx .. "  Y=" .. gy
        end
        
        itemDisplay.Text = tostring(AutoPnB.ITEM_ID)
        if hookSuccess and not detectMode then
            selectBtn.BackgroundColor3 = C.accent
            selectBtn.Text = "🔍 Select Item — Klik lalu Place 1 blok"
        end
        
        statusLabel.Text = "Status: " .. AutoPnB.getStatus()
        cycleLabel.Text = "Siklus: " .. AutoPnB.getCycleCount() .. " | Target: " .. AutoPnB.getTargetCount()
        
        if AutoPnB.isRunning() then
            startBtn.BackgroundColor3 = C.btnGrey
            stopBtn.BackgroundColor3 = C.btnStop
        else
            startBtn.BackgroundColor3 = C.btnStart
            stopBtn.BackgroundColor3 = C.btnGrey
        end
        
        task.wait(0.5)
    end
end)