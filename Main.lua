--[[
    Main.lua
    Custom UI — 5x5 Grid Target Selector (No Rayfield)
    
    Buka instan, tanpa loading.
    Grid 5x5 untuk pilih target Place+Break relatif ke posisi karakter.
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
local player = Players.LocalPlayer

-- ═══════════════════════════════════════
-- REMOTE HOOK: DETECT ITEM ID
-- ═══════════════════════════════════════

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")

local detectMode = false
local hookSuccess = false
local hookMethod = "none"

-- Fungsi callback yang dipanggil saat detect
local function onDetectPlace(args)
    if detectMode and not AutoPnB.isRunning() then
        if args[2] and type(args[2]) == "number" then
            AutoPnB.ITEM_ID = args[2]
            detectMode = false
        end
    end
end

-- Method 1: hookmetamethod (Delta, Fluxus)
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
        hookMethod = "hookmetamethod"
    end)
end

-- Method 2: getrawmetatable + newcclosure
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
        hookMethod = "rawmetatable"
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
        hookMethod = "hookfunction"
    end)
end

-- ═══════════════════════════════════════
-- WARNA & STYLE
-- ═══════════════════════════════════════

local COLORS = {
    bg          = Color3.fromRGB(20, 20, 30),
    titleBar    = Color3.fromRGB(30, 30, 50),
    cellOff     = Color3.fromRGB(40, 40, 55),
    cellOn      = Color3.fromRGB(0, 180, 80),
    cellPlayer  = Color3.fromRGB(50, 120, 220),
    textWhite   = Color3.fromRGB(255, 255, 255),
    textDim     = Color3.fromRGB(160, 160, 180),
    btnStart    = Color3.fromRGB(0, 160, 70),
    btnStop     = Color3.fromRGB(200, 50, 50),
    btnNormal   = Color3.fromRGB(50, 50, 70),
    accent      = Color3.fromRGB(100, 80, 255),
}

-- ═══════════════════════════════════════
-- BUAT SCREENGUI
-- ═══════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "CawScriptUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player.PlayerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 460)
mainFrame.Position = UDim2.new(0, 20, 0.5, -210)
mainFrame.BackgroundColor3 = COLORS.bg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = mainFrame

-- ═══════════════════════════════════════
-- TITLE BAR (draggable)
-- ═══════════════════════════════════════

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = COLORS.titleBar
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

-- Fix bottom corners of title bar
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 10)
titleFix.Position = UDim2.new(0, 0, 1, -10)
titleFix.BackgroundColor3 = COLORS.titleBar
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -70, 1, 0)
titleText.Position = UDim2.new(0, 12, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "⚒️ CawScript"
titleText.TextColor3 = COLORS.textWhite
titleText.TextSize = 16
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = titleBar

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 25, 0, 25)
minBtn.Position = UDim2.new(1, -60, 0, 5)
minBtn.BackgroundColor3 = COLORS.btnNormal
minBtn.Text = "_"
minBtn.TextColor3 = COLORS.textWhite
minBtn.TextSize = 14
minBtn.Font = Enum.Font.GothamBold
minBtn.BorderSizePixel = 0
minBtn.Parent = titleBar
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundColor3 = COLORS.btnStop
closeBtn.Text = "X"
closeBtn.TextColor3 = COLORS.textWhite
closeBtn.TextSize = 14
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

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Minimize / Close
local minimized = false
local contentFrame -- defined below

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if contentFrame then
        contentFrame.Visible = not minimized
        mainFrame.Size = minimized 
            and UDim2.new(0, 280, 0, 35) 
            or UDim2.new(0, 280, 0, 460)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)

-- ═══════════════════════════════════════
-- CONTENT AREA
-- ═══════════════════════════════════════

contentFrame = Instance.new("Frame")
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -20, 1, -45)
contentFrame.Position = UDim2.new(0, 10, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

-- ═══════════════════════════════════════
-- POSISI LABEL
-- ═══════════════════════════════════════

local posLabel = Instance.new("TextLabel")
posLabel.Size = UDim2.new(1, 0, 0, 18)
posLabel.Position = UDim2.new(0, 0, 0, 0)
posLabel.BackgroundTransparency = 1
posLabel.Text = "📍 Posisi: ..."
posLabel.TextColor3 = COLORS.textDim
posLabel.TextSize = 13
posLabel.Font = Enum.Font.Gotham
posLabel.TextXAlignment = Enum.TextXAlignment.Left
posLabel.Parent = contentFrame

-- ═══════════════════════════════════════
-- ITEM ID
-- ═══════════════════════════════════════

local itemFrame = Instance.new("Frame")
itemFrame.Size = UDim2.new(1, 0, 0, 60)
itemFrame.Position = UDim2.new(0, 0, 0, 22)
itemFrame.BackgroundTransparency = 1
itemFrame.Parent = contentFrame

local itemLabel = Instance.new("TextLabel")
itemLabel.Size = UDim2.new(0, 80, 0, 24)
itemLabel.BackgroundTransparency = 1
itemLabel.Text = "🧱 Item ID:"
itemLabel.TextColor3 = COLORS.textDim
itemLabel.TextSize = 13
itemLabel.Font = Enum.Font.Gotham
itemLabel.TextXAlignment = Enum.TextXAlignment.Left
itemLabel.Parent = itemFrame

local itemDisplay = Instance.new("TextLabel")
itemDisplay.Size = UDim2.new(0, 60, 0, 24)
itemDisplay.Position = UDim2.new(0, 85, 0, 0)
itemDisplay.BackgroundColor3 = COLORS.cellOff
itemDisplay.Text = "2"
itemDisplay.TextColor3 = COLORS.textWhite
itemDisplay.TextSize = 14
itemDisplay.Font = Enum.Font.GothamBold
itemDisplay.BorderSizePixel = 0
itemDisplay.Parent = itemFrame
Instance.new("UICorner", itemDisplay).CornerRadius = UDim.new(0, 6)

-- Select Item button (baris sendiri, full width)
local selectBtn = Instance.new("TextButton")
selectBtn.Size = UDim2.new(1, 0, 0, 28)
selectBtn.Position = UDim2.new(0, 0, 0, 30)
selectBtn.BorderSizePixel = 0
selectBtn.TextSize = 13
selectBtn.Font = Enum.Font.GothamBold
selectBtn.TextColor3 = COLORS.textWhite
selectBtn.Parent = itemFrame
Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)

if hookSuccess then
    selectBtn.BackgroundColor3 = COLORS.accent
    selectBtn.Text = "🔍 Select Item — Klik lalu Place 1 blok"
else
    selectBtn.BackgroundColor3 = COLORS.cellOff
    selectBtn.Text = "⚠️ Hook gagal — ketik ID manual di atas"
end

selectBtn.MouseButton1Click:Connect(function()
    if not hookSuccess then return end
    if detectMode then
        detectMode = false
        selectBtn.BackgroundColor3 = COLORS.accent
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
local CELL_SIZE = 42
local CELL_GAP = 4
local gridTotalSize = GRID_SIZE * CELL_SIZE + (GRID_SIZE - 1) * CELL_GAP

local gridFrame = Instance.new("Frame")
gridFrame.Name = "Grid"
gridFrame.Size = UDim2.new(0, gridTotalSize, 0, gridTotalSize)
gridFrame.Position = UDim2.new(0.5, -gridTotalSize / 2, 0, 90)
gridFrame.BackgroundTransparency = 1
gridFrame.Parent = contentFrame

local gridCells = {} -- Store cell references

for row = 0, GRID_SIZE - 1 do
    for col = 0, GRID_SIZE - 1 do
        local dx = col - 2  -- offset X: -2 to +2
        local dy = 2 - row  -- offset Y: +2 to -2 (atas = positif)
        local isCenter = (dx == 0 and dy == 0)
        
        local cell = Instance.new("TextButton")
        cell.Name = "Cell_" .. dx .. "_" .. dy
        cell.Size = UDim2.new(0, CELL_SIZE, 0, CELL_SIZE)
        cell.Position = UDim2.new(0, col * (CELL_SIZE + CELL_GAP), 0, row * (CELL_SIZE + CELL_GAP))
        cell.BorderSizePixel = 0
        cell.TextSize = 11
        cell.Font = Enum.Font.Gotham
        cell.AutoButtonColor = not isCenter
        cell.Parent = gridFrame
        
        Instance.new("UICorner", cell).CornerRadius = UDim.new(0, 6)
        
        if isCenter then
            -- Player cell
            cell.BackgroundColor3 = COLORS.cellPlayer
            cell.Text = "ME"
            cell.TextColor3 = COLORS.textWhite
        else
            -- Target cell
            cell.BackgroundColor3 = COLORS.cellOff
            cell.Text = ""
            cell.TextColor3 = COLORS.textWhite
            
            local active = false
            
            cell.MouseButton1Click:Connect(function()
                active = not active
                if active then
                    cell.BackgroundColor3 = COLORS.cellOn
                    cell.Text = "✓"
                    AutoPnB.addTarget(dx, dy)
                else
                    cell.BackgroundColor3 = COLORS.cellOff
                    cell.Text = ""
                    AutoPnB.removeTarget(dx, dy)
                end
            end)
        end
        
        gridCells[dx .. "," .. dy] = cell
    end
end

-- Grid label
local gridLabel = Instance.new("TextLabel")
gridLabel.Size = UDim2.new(0, gridTotalSize, 0, 16)
gridLabel.Position = UDim2.new(0.5, -gridTotalSize / 2, 0, 90 + gridTotalSize + 4)
gridLabel.BackgroundTransparency = 1
gridLabel.Text = "Klik cell untuk set target PnB"
gridLabel.TextColor3 = COLORS.textDim
gridLabel.TextSize = 11
gridLabel.Font = Enum.Font.Gotham
gridLabel.Parent = contentFrame

-- ═══════════════════════════════════════
-- CONTROLS: START / STOP
-- ═══════════════════════════════════════

local controlY = 90 + gridTotalSize + 24

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.48, 0, 0, 32)
startBtn.Position = UDim2.new(0, 0, 0, controlY)
startBtn.BackgroundColor3 = COLORS.btnStart
startBtn.Text = "▶  START"
startBtn.TextColor3 = COLORS.textWhite
startBtn.TextSize = 14
startBtn.Font = Enum.Font.GothamBold
startBtn.BorderSizePixel = 0
startBtn.Parent = contentFrame
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 8)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.48, 0, 0, 32)
stopBtn.Position = UDim2.new(0.52, 0, 0, controlY)
stopBtn.BackgroundColor3 = COLORS.btnStop
stopBtn.Text = "■  STOP"
stopBtn.TextColor3 = COLORS.textWhite
stopBtn.TextSize = 14
stopBtn.Font = Enum.Font.GothamBold
stopBtn.BorderSizePixel = 0
stopBtn.Parent = contentFrame
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

startBtn.MouseButton1Click:Connect(function()
    if not AutoPnB.isRunning() then
        AutoPnB.start()
    end
end)

stopBtn.MouseButton1Click:Connect(function()
    AutoPnB.stop()
end)

-- ═══════════════════════════════════════
-- STATUS LABELS
-- ═══════════════════════════════════════

local statusY = controlY + 38

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 16)
statusLabel.Position = UDim2.new(0, 0, 0, statusY)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = COLORS.textDim
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = contentFrame

local cycleLabel = Instance.new("TextLabel")
cycleLabel.Size = UDim2.new(1, 0, 0, 16)
cycleLabel.Position = UDim2.new(0, 0, 0, statusY + 18)
cycleLabel.BackgroundTransparency = 1
cycleLabel.Text = "Siklus: 0 | Target: 0"
cycleLabel.TextColor3 = COLORS.textDim
cycleLabel.TextSize = 12
cycleLabel.Font = Enum.Font.Gotham
cycleLabel.TextXAlignment = Enum.TextXAlignment.Left
cycleLabel.Parent = contentFrame

-- ═══════════════════════════════════════
-- DELAY SLIDER
-- ═══════════════════════════════════════

local delayY = statusY + 42

local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(1, 0, 0, 16)
delayLabel.Position = UDim2.new(0, 0, 0, delayY)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "Delay Siklus: 0.30s"
delayLabel.TextColor3 = COLORS.textDim
delayLabel.TextSize = 12
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = contentFrame

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, 0, 0, 8)
sliderBg.Position = UDim2.new(0, 0, 0, delayY + 20)
sliderBg.BackgroundColor3 = COLORS.cellOff
sliderBg.BorderSizePixel = 0
sliderBg.Parent = contentFrame
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 4)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.15, 0, 1, 0)  -- 0.3 out of 2.0 = 0.15
sliderFill.BackgroundColor3 = COLORS.accent
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 4)

local sliderBtn = Instance.new("TextButton")
sliderBtn.Size = UDim2.new(1, 0, 0, 20)
sliderBtn.Position = UDim2.new(0, 0, 0, delayY + 14)
sliderBtn.BackgroundTransparency = 1
sliderBtn.Text = ""
sliderBtn.Parent = contentFrame

local sliderDragging = false

sliderBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = true
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local relX = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        relX = math.clamp(relX, 0, 1)
        sliderFill.Size = UDim2.new(relX, 0, 1, 0)
        
        local delayVal = math.floor(relX * 200) / 100  -- 0.00 to 2.00
        delayVal = math.max(delayVal, 0.05)
        AutoPnB.DELAY_CYCLE = delayVal
        delayLabel.Text = string.format("Delay Siklus: %.2fs", delayVal)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDragging = false
    end
end)

-- ═══════════════════════════════════════
-- REAL-TIME UPDATE LOOP
-- ═══════════════════════════════════════

spawn(function()
    while gui and gui.Parent do
        -- Update posisi
        local gx, gy = Coordinates.getGridPosition()
        if gx then
            posLabel.Text = "📍 Posisi: X=" .. gx .. "  Y=" .. gy
        end
        
        -- Update item display dari detection
        itemDisplay.Text = tostring(AutoPnB.ITEM_ID)
        if hookSuccess and not detectMode then
            selectBtn.BackgroundColor3 = COLORS.accent
            selectBtn.Text = "🔍 Select Item — Klik lalu Place 1 blok"
        end
        
        -- Update status
        statusLabel.Text = "Status: " .. AutoPnB.getStatus()
        cycleLabel.Text = "Siklus: " .. AutoPnB.getCycleCount() .. " | Target: " .. AutoPnB.getTargetCount()
        
        -- Update button colors based on running state
        if AutoPnB.isRunning() then
            startBtn.BackgroundColor3 = COLORS.btnNormal
            stopBtn.BackgroundColor3 = COLORS.btnStop
        else
            startBtn.BackgroundColor3 = COLORS.btnStart
            stopBtn.BackgroundColor3 = COLORS.btnNormal
        end
        
        task.wait(0.5)
    end
end)