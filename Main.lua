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
local NOCACHE = "?t=" .. tostring(math.floor(tick()))
local VERSION = "v1.2.5" -- Debugging UI Load
print("[CawScript] Current Version: " .. VERSION)

print("[CawScript] Memulai load dependencies...")
local AutoPnB      = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/AutoPnB.lua" .. NOCACHE))()
local Antiban      = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/Antiban.lua" .. NOCACHE))()
local Coordinates  = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/Coordinates.lua" .. NOCACHE))()
local BackpackSync = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/BackpackSync.lua" .. NOCACHE))()
local ClearWorld   = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/ClearWorld.lua" .. NOCACHE))()

print("[CawScript] Initializing modules...")
AutoPnB.init(Coordinates, Antiban)
ClearWorld.init(Antiban)

local ManagerModule = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/ManagerModule.lua" .. NOCACHE))()
ManagerModule.init(Coordinates, Antiban, BackpackSync)

local PlayerModule = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/PlayerModule.lua" .. NOCACHE))()
-- PlayerModule.init() dipanggil setelah hook setup di bawah

local ItemScanner = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/ItemScanner.lua" .. NOCACHE))()

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

print("[CawScript] Hooking remotes...")
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local RemotePlace = Remotes and Remotes:WaitForChild("PlayerPlaceItem", 2)

if not RemotePlace then
    warn("[CawScript] WARNING: Remote PlayerPlaceItem tidak ditemukan! Fitur Auto PnB & Select Item mungkin tidak jalan.")
end

local detectCallback = nil
local hookSuccess = false

local function onDetectPlace(args)
    if detectCallback and not AutoPnB.isRunning() and not ManagerModule.isDropRunning() and not ManagerModule.isCollectRunning() then
        if args[2] and type(args[2]) == "number" then
            detectCallback(args[2])
            detectCallback = nil
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

-- Init PlayerModule SETELAH hook utama selesai
PlayerModule.init()

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

print("[CawScript] Building ScreenGui...")
local gui = Instance.new("ScreenGui")
gui.Name = "KolinUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999

-- Parent ke CoreGui supaya kebal dari game (gak bisa di-destroy/hide)
local guiParent
pcall(function() guiParent = gethui() end)  -- Delta Executor
if not guiParent then
    pcall(function() guiParent = game:GetService("CoreGui") end)
end
if not guiParent then
    guiParent = player.PlayerGui  -- fallback
end
gui.Parent = guiParent

-- ═══════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════

local SIDEBAR_W = 110
local CONTENT_W = 280
local TOTAL_W = SIDEBAR_W + CONTENT_W
local TOTAL_H = 460

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, TOTAL_W, 0, TOTAL_H)
mainFrame.Position = UDim2.new(0, 20, 0.5, -TOTAL_H / 2)
mainFrame.BackgroundColor3 = C.bg
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.ClipsDescendants = true
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
titleText.Text = "🚀 Kolin"
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
    {icon = "🌍", name = "Clear World"},
    {icon = "👤", name = "Player"},
    {icon = "D", name = "Diagnostic"}, -- Simplified icon for compatibility
}

local tabButtons = {}
local tabFrames = {}
local activeTab = 1

-- Create tab buttons
for i, tab in ipairs(tabs) do
    -- Side Button Container (for padding)
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, 0, 0, 40)
    btnContainer.Position = UDim2.new(0, 0, 0, (i - 1) * 42 + 10)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = sidebar
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 1, 0)
    btn.Position = UDim2.new(0, 5, 0, 0)
    btn.BackgroundColor3 = C.sideHover
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.BorderSizePixel = 0
    btn.Parent = btnContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 1, 0)
    icon.Position = UDim2.new(0, 5, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = tab.icon
    icon.TextSize = 18
    icon.TextColor3 = C.sideText
    icon.Font = Enum.Font.GothamBold
    icon.Parent = btn
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 35, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tab.name
    label.TextSize = 12
    label.TextColor3 = C.sideText
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = btn
    
    -- Active indicator (left bar)
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0, 20)
    indicator.Position = UDim2.new(0, -2, 0.5, -10)
    indicator.BackgroundColor3 = C.sideActive
    indicator.BorderSizePixel = 0
    indicator.Visible = (i == 1)
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)
    
    btn.MouseButton1Click:Connect(function()
        activeTab = i
        for j, f in ipairs(tabFrames) do
            f.Visible = (j == i)
        end
        for j, b in ipairs(tabButtons) do
            local ind = b:FindFirstChild("Indicator")
            local ic = b:FindFirstChildWhichIsA("TextLabel")
            local lb = b:FindFirstChild("TextLabel", true)
            if ind then ind.Visible = (j == i) end
            if ic then ic.TextColor3 = (j == i) and C.white or C.sideText end
            if lb then lb.TextColor3 = (j == i) and C.white or C.sideText end
            b.BackgroundTransparency = (j == i) and 0.8 or 1
        end
    end)
    
    tabButtons[i] = btn
end

-- Version Label inside Sidebar (Bottom)
local verLabel = Instance.new("TextLabel")
verLabel.Size = UDim2.new(1, 0, 0, 20)
verLabel.Position = UDim2.new(0, 0, 1, -25)
verLabel.BackgroundTransparency = 1
verLabel.Text = VERSION
verLabel.TextColor3 = C.sideText
verLabel.TextSize = 10
verLabel.Font = Enum.Font.Gotham
verLabel.ZIndex = 2
verLabel.Parent = sidebar

-- Set first tab active
tabButtons[1].BackgroundTransparency = 0.8
tabButtons[1]:FindFirstChildWhichIsA("TextLabel").TextColor3 = C.white
tabButtons[1]:FindFirstChild("TextLabel", true).TextColor3 = C.white

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

local tabPnB = Instance.new("ScrollingFrame")
tabPnB.Size = UDim2.new(1, -10, 1, -10)
tabPnB.Position = UDim2.new(0, 5, 0, 5)
tabPnB.BackgroundTransparency = 1
tabPnB.BorderSizePixel = 0
tabPnB.ScrollBarThickness = 2
tabPnB.Visible = true
tabPnB.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabPnB.CanvasSize = UDim2.new(0, 0, 0, 0)
tabPnB.Parent = contentContainer
tabFrames[1] = tabPnB

local pnbList = Instance.new("UIListLayout")
pnbList.Padding = UDim.new(0, 12)
pnbList.SortOrder = Enum.SortOrder.LayoutOrder
pnbList.Parent = tabPnB

local pnbPadding = Instance.new("UIPadding")
pnbPadding.PaddingLeft = UDim.new(0, 5)
pnbPadding.PaddingRight = UDim.new(0, 5)
pnbPadding.PaddingTop = UDim.new(0, 5)
pnbPadding.PaddingBottom = UDim.new(0, 10)
pnbPadding.Parent = tabPnB

-- Posisi Info Section
local infoSection = Instance.new("Frame")
infoSection.Size = UDim2.new(1, 0, 0, 32)
infoSection.BackgroundTransparency = 1
infoSection.LayoutOrder = 1
infoSection.Parent = tabPnB

-- Posisi label
local posLabel = Instance.new("TextLabel")
posLabel.Size = UDim2.new(1, 0, 0, 16)
posLabel.BackgroundTransparency = 1
posLabel.Text = "📍 Posisi: ..."
posLabel.TextColor3 = C.dim
posLabel.TextSize = 12
posLabel.Font = Enum.Font.Gotham
posLabel.TextXAlignment = Enum.TextXAlignment.Left
posLabel.Position = UDim2.new(0, 0, 0, 0)
posLabel.Parent = infoSection

-- Backpack info label
local bpLabel = Instance.new("TextLabel")
bpLabel.Size = UDim2.new(1, 0, 0, 16)
bpLabel.BackgroundTransparency = 1
bpLabel.Text = "🎒 Backpack: ..."
bpLabel.TextColor3 = C.dim
bpLabel.TextSize = 12
bpLabel.Font = Enum.Font.Gotham
bpLabel.TextXAlignment = Enum.TextXAlignment.Left
bpLabel.Position = UDim2.new(0, 0, 0, 16)
bpLabel.Parent = infoSection

-- Item ID display + Select button
local itemRow = Instance.new("Frame")
itemRow.Size = UDim2.new(1, 0, 0, 55)
itemRow.BackgroundTransparency = 1
itemRow.LayoutOrder = 2
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
itemDisplay.TextColor3 = C.dim
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
selectBtn.BackgroundColor3 = C.accent
selectBtn.Text = "🎒 Pilih Item dari Backpack"
selectBtn.Parent = itemRow
Instance.new("UICorner", selectBtn).CornerRadius = UDim.new(0, 6)

-- PnB Picker Frame
local bpPickerPnB = Instance.new("ScrollingFrame")
bpPickerPnB.Size = UDim2.new(1, 0, 0, 0)
bpPickerPnB.Position = UDim2.new(0, 0, 0, 91) -- Di bawah selectBtn
bpPickerPnB.BackgroundColor3 = C.sidebar
bpPickerPnB.BorderSizePixel = 0
bpPickerPnB.ScrollBarThickness = 2
bpPickerPnB.Visible = false
bpPickerPnB.ZIndex = 50
bpPickerPnB.AutomaticCanvasSize = Enum.AutomaticSize.Y
bpPickerPnB.CanvasSize = UDim2.new(0, 0, 0, 0)
bpPickerPnB.Parent = tabPnB
Instance.new("UICorner", bpPickerPnB).CornerRadius = UDim.new(0, 5)

local bpPickerListPnB = Instance.new("UIListLayout")
bpPickerListPnB.Padding = UDim.new(0, 3)
bpPickerListPnB.SortOrder = Enum.SortOrder.LayoutOrder
bpPickerListPnB.Parent = bpPickerPnB

selectBtn.MouseButton1Click:Connect(function()
    -- Toggle picker
    if bpPickerPnB.Visible then
        bpPickerPnB.Visible = false
        bpPickerPnB.Size = UDim2.new(1, 0, 0, 0)
        selectBtn.Text = "🎒 Pilih Item dari Backpack"
        selectBtn.BackgroundColor3 = C.accent
        return
    end
    
    -- Scan backpack
    selectBtn.Text = "⏳ Scanning..."
    BackpackSync.sync()
    
    -- Clear old items
    for _, c in ipairs(bpPickerPnB:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    
    -- Show items found
    local found = 0
    for i = 1, 16 do
        local info = BackpackSync.getSlotInfo(i)
        if info.hasItem and info.imageId ~= "" and info.imageId ~= "rbxassetid://0" then
            found = found + 1
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 28)
            btn.Position = UDim2.new(0, 3, 0, 0)
            btn.BackgroundColor3 = C.cellOff
            btn.Text = "  Slot " .. i .. " — " .. info.count .. "x items"
            btn.TextColor3 = C.white
            btn.TextSize = 11
            btn.Font = Enum.Font.GothamBold
            btn.BorderSizePixel = 0
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i
            btn.ZIndex = 51
            btn.Parent = bpPickerPnB
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                -- Selected this item!
                AutoPnB.ITEM_ID = i
                itemDisplay.Text = tostring(i)
                
                -- Close picker
                bpPickerPnB.Visible = false
                bpPickerPnB.Size = UDim2.new(1, 0, 0, 0)
                selectBtn.Text = "✅ Slot " .. i .. " dipilih"
                selectBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 70)
            end)
        end
    end
    
    if found == 0 then
        selectBtn.Text = "⚠️ Backpack kosong!"
        selectBtn.BackgroundColor3 = C.btnStop
        task.wait(2)
        selectBtn.Text = "🎒 Pilih Item dari Backpack"
        selectBtn.BackgroundColor3 = C.accent
    else
        -- Show picker
        local pickerH = math.min(found * 31, 155)
        bpPickerPnB.Size = UDim2.new(1, 0, 0, pickerH)
        bpPickerPnB.Visible = true
        selectBtn.Text = "❌ Tutup"
        selectBtn.BackgroundColor3 = C.btnStop
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
gridFrame.BackgroundTransparency = 1
gridFrame.LayoutOrder = 3
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
gridHint.Position = UDim2.new(0, 0, 0, 98 + gridTotal + 3)
gridHint.BackgroundTransparency = 1
gridHint.Text = "Klik cell = target PnB"
gridHint.TextColor3 = C.dim
gridHint.TextSize = 10
gridHint.Font = Enum.Font.Gotham
gridHint.LayoutOrder = 4
gridHint.Parent = tabPnB

-- ═══════════════════════════════════════
-- PLACE / BREAK TOGGLES
-- ═══════════════════════════════════════

local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, 0, 0, 24)
toggleRow.BackgroundTransparency = 1
toggleRow.LayoutOrder = 5
toggleRow.Parent = tabPnB

local placeToggle = Instance.new("TextButton")
placeToggle.Size = UDim2.new(0, 125, 0, 24)
placeToggle.Position = UDim2.new(0, 0, 0, 0)
placeToggle.BackgroundColor3 = C.btnStart
placeToggle.Text = "🧱 Place: ON"
placeToggle.TextColor3 = C.white
placeToggle.TextSize = 11
placeToggle.Font = Enum.Font.GothamBold
placeToggle.BorderSizePixel = 0
placeToggle.Parent = toggleRow
Instance.new("UICorner", placeToggle).CornerRadius = UDim.new(0, 6)

local breakToggle = Instance.new("TextButton")
breakToggle.Size = UDim2.new(0, 125, 0, 24)
breakToggle.Position = UDim2.new(1, -125, 0, 0)
breakToggle.BackgroundColor3 = C.btnStart
breakToggle.Text = "⛏️ Break: ON"
breakToggle.TextColor3 = C.white
breakToggle.TextSize = 11
breakToggle.Font = Enum.Font.GothamBold
breakToggle.BorderSizePixel = 0
breakToggle.Parent = toggleRow
Instance.new("UICorner", breakToggle).CornerRadius = UDim.new(0, 6)

placeToggle.MouseButton1Click:Connect(function()
    AutoPnB.ENABLE_PLACE = not AutoPnB.ENABLE_PLACE
    if AutoPnB.ENABLE_PLACE then
        placeToggle.Text = "🧱 Place: ON"
        placeToggle.BackgroundColor3 = C.btnStart
    else
        placeToggle.Text = "🧱 Place: OFF"
        placeToggle.BackgroundColor3 = C.btnGrey
    end
end)

breakToggle.MouseButton1Click:Connect(function()
    AutoPnB.ENABLE_BREAK = not AutoPnB.ENABLE_BREAK
    if AutoPnB.ENABLE_BREAK then
        breakToggle.Text = "⛏️ Break: ON"
        breakToggle.BackgroundColor3 = C.btnStart
    else
        breakToggle.Text = "⛏️ Break: OFF"
        breakToggle.BackgroundColor3 = C.btnGrey
    end
end)

-- ═══════════════════════════════════════
-- CONTROLS
-- ═══════════════════════════════════════

local mainControls = Instance.new("Frame")
mainControls.Size = UDim2.new(1, 0, 0, 28)
mainControls.BackgroundTransparency = 1
mainControls.LayoutOrder = 6
mainControls.Parent = tabPnB

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 125, 1, 0)
startBtn.Position = UDim2.new(0, 0, 0, 0)
startBtn.BackgroundColor3 = C.btnStart
startBtn.Text = "▶  START"
startBtn.TextColor3 = C.white
startBtn.TextSize = 13
startBtn.Font = Enum.Font.GothamBold
startBtn.BorderSizePixel = 0
startBtn.Parent = mainControls
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 7)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0, 125, 1, 0)
stopBtn.Position = UDim2.new(1, -125, 0, 0)
stopBtn.BackgroundColor3 = C.btnStop
stopBtn.Text = "■  STOP"
stopBtn.TextColor3 = C.white
stopBtn.TextSize = 13
stopBtn.Font = Enum.Font.GothamBold
stopBtn.BorderSizePixel = 0
stopBtn.Parent = mainControls
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
local statusSection = Instance.new("Frame")
statusSection.Size = UDim2.new(1, 0, 0, 32)
statusSection.BackgroundTransparency = 1
statusSection.LayoutOrder = 7
statusSection.Parent = tabPnB

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 14)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = C.dim
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusSection

local cycleLabel = Instance.new("TextLabel")
cycleLabel.Size = UDim2.new(1, 0, 0, 14)
cycleLabel.Position = UDim2.new(0, 0, 0, 14)
cycleLabel.BackgroundTransparency = 1
cycleLabel.Text = "Siklus: 0 | Target: 0"
cycleLabel.TextColor3 = C.dim
cycleLabel.TextSize = 11
cycleLabel.Font = Enum.Font.Gotham
cycleLabel.TextXAlignment = Enum.TextXAlignment.Left
cycleLabel.Parent = statusSection

-- Delay slider
local delaySection = Instance.new("Frame")
delaySection.Size = UDim2.new(1, 0, 0, 35)
delaySection.BackgroundTransparency = 1
delaySection.LayoutOrder = 8
delaySection.Parent = tabPnB

local delayLabel = Instance.new("TextLabel")
delayLabel.Size = UDim2.new(1, 0, 0, 14)
delayLabel.BackgroundTransparency = 1
delayLabel.Text = "⏱️ Delay Break: 0.15s"
delayLabel.TextColor3 = C.dim
delayLabel.TextSize = 11
delayLabel.Font = Enum.Font.Gotham
delayLabel.TextXAlignment = Enum.TextXAlignment.Left
delayLabel.Parent = delaySection

local sliderBg = Instance.new("Frame")
sliderBg.Size = UDim2.new(1, 0, 0, 6)
sliderBg.Position = UDim2.new(0, 0, 0, 20)
sliderBg.BackgroundColor3 = C.cellOff
sliderBg.BorderSizePixel = 0
sliderBg.Parent = delaySection
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 3)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(0.075, 0, 1, 0)
sliderFill.BackgroundColor3 = C.accent
sliderFill.BorderSizePixel = 0
sliderFill.Parent = sliderBg
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)

local sliderHit = Instance.new("TextButton")
sliderHit.Size = UDim2.new(1, 0, 1, 10)
sliderHit.Position = UDim2.new(0, 0, 0, -5)
sliderHit.BackgroundTransparency = 1
sliderHit.Text = ""
sliderHit.Parent = sliderBg

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
        AutoPnB.DELAY_BREAK = val
        delayLabel.Text = string.format("⏱️ Delay Break: %.2fs", val)
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        sliderDrag = false
    end
end)

-- ═══════════════════════════════════════
-- TAB 2: MANAGER
-- ═══════════════════════════════════════

local tabManager = Instance.new("ScrollingFrame")
tabManager.Size = UDim2.new(1, -10, 1, -10)
tabManager.Position = UDim2.new(0, 5, 0, 5)
tabManager.BackgroundTransparency = 1
tabManager.BorderSizePixel = 0
tabManager.ScrollBarThickness = 2
tabManager.Visible = false
tabManager.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabManager.CanvasSize = UDim2.new(0, 0, 0, 0)
tabManager.Parent = contentContainer

local managerList = Instance.new("UIListLayout")
managerList.Padding = UDim.new(0, 10)
managerList.SortOrder = Enum.SortOrder.LayoutOrder
managerList.Parent = tabManager

local managerPadding = Instance.new("UIPadding")
managerPadding.PaddingBottom = UDim.new(0, 20)
managerPadding.PaddingLeft = UDim.new(0, 5)
managerPadding.PaddingRight = UDim.new(0, 5)
managerPadding.PaddingTop = UDim.new(0, 5)
managerPadding.Parent = tabManager

local function createSection(name)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 0) -- Height handled by AutomaticSize
    frame.BackgroundColor3 = C.sidebar
    frame.BorderSizePixel = 0
    frame.Parent = tabManager
    frame.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 24)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = name
    title.TextColor3 = C.white
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -20, 0, 0)
    content.Position = UDim2.new(0, 10, 0, 24)
    content.BackgroundTransparency = 1
    content.Parent = frame
    content.AutomaticSize = Enum.AutomaticSize.Y
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = content
    
    -- Padding for bottom
    local pad = Instance.new("UIPadding")
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = content
    
    return content
end

-- --- AUTO DROP SECTION ---
-- --- AUTO DROP SECTION ---
local dropContent = createSection("🗑️ Auto Drop")

local dropItemRow = Instance.new("Frame")
dropItemRow.Size = UDim2.new(1, 0, 0, 24)
dropItemRow.BackgroundTransparency = 1
dropItemRow.Parent = dropContent

local dropItemDisplay = Instance.new("TextLabel")
dropItemDisplay.Size = UDim2.new(0, 50, 0, 22)
dropItemDisplay.BackgroundColor3 = C.cellOff
dropItemDisplay.Text = "1"
dropItemDisplay.TextColor3 = C.dim
dropItemDisplay.TextSize = 13
dropItemDisplay.Font = Enum.Font.GothamBold
dropItemDisplay.BorderSizePixel = 0
dropItemDisplay.Parent = dropItemRow
Instance.new("UICorner", dropItemDisplay).CornerRadius = UDim.new(0, 5)

local dropSelectBtn = Instance.new("TextButton")
dropSelectBtn.Size = UDim2.new(1, -60, 0, 22)
dropSelectBtn.Position = UDim2.new(0, 60, 0, 0)
dropSelectBtn.BackgroundColor3 = C.accent
dropSelectBtn.Text = "🎒 Scan & Pilih Item"
dropSelectBtn.TextColor3 = C.white
dropSelectBtn.TextSize = 11
dropSelectBtn.Font = Enum.Font.GothamBold
dropSelectBtn.BorderSizePixel = 0
dropSelectBtn.Parent = dropItemRow
Instance.new("UICorner", dropSelectBtn).CornerRadius = UDim.new(0, 5)

-- Picker frame (hidden, shows items from backpack)
local pickerFrame = Instance.new("ScrollingFrame")
pickerFrame.Size = UDim2.new(1, 0, 0, 0)  -- starts collapsed
pickerFrame.BackgroundColor3 = C.sidebar
pickerFrame.BorderSizePixel = 0
pickerFrame.ScrollBarThickness = 2
pickerFrame.Visible = false
pickerFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
pickerFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
pickerFrame.Parent = dropContent
Instance.new("UICorner", pickerFrame).CornerRadius = UDim.new(0, 5)
pickerFrame.LayoutOrder = 10

local pickerList = Instance.new("UIListLayout")
pickerList.Padding = UDim.new(0, 3)
pickerList.SortOrder = Enum.SortOrder.LayoutOrder
pickerList.Parent = pickerFrame

dropSelectBtn.MouseButton1Click:Connect(function()
    -- Toggle picker
    if pickerFrame.Visible then
        pickerFrame.Visible = false
        pickerFrame.Size = UDim2.new(1, 0, 0, 0)
        dropSelectBtn.Text = "🎒 Scan & Pilih Item"
        dropSelectBtn.BackgroundColor3 = C.accent
        return
    end
    
    -- Scan backpack
    dropSelectBtn.Text = "⏳ Scanning..."
    BackpackSync.sync()
    
    -- Clear old items
    for _, c in ipairs(pickerFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    
    -- Show items found
    local found = 0
    for i = 1, 16 do
        local info = BackpackSync.getSlotInfo(i)
        if info.hasItem and info.imageId ~= "" and info.imageId ~= "rbxassetid://0" then
            found = found + 1
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 28)
            btn.Position = UDim2.new(0, 3, 0, 0)
            btn.BackgroundColor3 = C.cellOff
            btn.Text = "  Slot " .. i .. " — " .. info.count .. "x items"
            btn.TextColor3 = C.white
            btn.TextSize = 11
            btn.Font = Enum.Font.GothamBold
            btn.BorderSizePixel = 0
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.LayoutOrder = i
            btn.Parent = pickerFrame
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseButton1Click:Connect(function()
                -- Selected this item!
                ManagerModule.DROP_ITEM_ID = i
                ManagerModule.DROP_IMAGE_ID = info.imageId
                dropItemDisplay.Text = "Slot " .. i
                
                -- Close picker
                pickerFrame.Visible = false
                pickerFrame.Size = UDim2.new(1, 0, 0, 0)
                dropSelectBtn.Text = "✅ Slot " .. i .. " dipilih"
                dropSelectBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 70)
            end)
        end
    end
    
    if found == 0 then
        dropSelectBtn.Text = "⚠️ Backpack kosong!"
        dropSelectBtn.BackgroundColor3 = C.btnStop
        task.wait(2)
        dropSelectBtn.Text = "🎒 Scan & Pilih Item"
        dropSelectBtn.BackgroundColor3 = C.accent
    else
        -- Show picker
        local pickerH = math.min(found * 31, 120)
        pickerFrame.Size = UDim2.new(1, 0, 0, pickerH)
        pickerFrame.Visible = true
        dropSelectBtn.Text = "❌ Tutup"
        dropSelectBtn.BackgroundColor3 = C.btnStop
    end
end)

-- Amount Slider
local amtRow = Instance.new("Frame")
amtRow.Size = UDim2.new(1, 0, 0, 36)
amtRow.BackgroundTransparency = 1
amtRow.Parent = dropContent

local amtLabel = Instance.new("TextLabel")
amtLabel.Size = UDim2.new(1, 0, 0, 20)
amtLabel.Position = UDim2.new(0, 0, 0, 0)
amtLabel.BackgroundTransparency = 1
amtLabel.Text = "Jumlah Drop: 1"
amtLabel.TextColor3 = C.dim
amtLabel.TextSize = 11
amtLabel.Font = Enum.Font.Gotham
amtLabel.TextXAlignment = Enum.TextXAlignment.Left
amtLabel.Parent = amtRow

local amtSliderBg = Instance.new("Frame")
amtSliderBg.Size = UDim2.new(1, 0, 0, 6)
amtSliderBg.Position = UDim2.new(0, 0, 0, 22)
amtSliderBg.BackgroundColor3 = C.cellOff
amtSliderBg.BorderSizePixel = 0
amtSliderBg.Parent = amtRow
Instance.new("UICorner", amtSliderBg).CornerRadius = UDim.new(0, 3)

local amtSliderFill = Instance.new("Frame")
amtSliderFill.Size = UDim2.new(0.01, 0, 1, 0)
amtSliderFill.BackgroundColor3 = C.accent
amtSliderFill.BorderSizePixel = 0
amtSliderFill.Parent = amtSliderBg
Instance.new("UICorner", amtSliderFill).CornerRadius = UDim.new(0, 3)

local amtSliderHit = Instance.new("TextButton")
amtSliderHit.Size = UDim2.new(1, 0, 1, 0)
amtSliderHit.BackgroundTransparency = 1
amtSliderHit.ZIndex = 5
amtSliderHit.Text = ""
amtSliderHit.Parent = amtSliderBg

local amtDragging = false
amtSliderHit.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        amtDragging = true
    end
end)
UIS.InputChanged:Connect(function(input)
    if amtDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local rel = math.clamp((input.Position.X - amtSliderBg.AbsolutePosition.X) / amtSliderBg.AbsoluteSize.X, 0, 1)
        amtSliderFill.Size = UDim2.new(rel, 0, 1, 0)
        local val = math.max(math.floor(rel * 200), 1)
        ManagerModule.DROP_AMOUNT = val
        amtLabel.Text = "Jumlah Drop: " .. val
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        amtDragging = false
    end
end)

local dropToggle = Instance.new("TextButton")
dropToggle.Size = UDim2.new(1, 0, 0, 26)
dropToggle.Position = UDim2.new(0, 0, 0, 0) -- Position handled by UIListLayout
dropToggle.LayoutOrder = 100 -- Always at bottom
dropToggle.BackgroundColor3 = C.btnGrey
dropToggle.Text = "OFF"
dropToggle.TextColor3 = C.white
dropToggle.TextSize = 12
dropToggle.Font = Enum.Font.GothamBold
dropToggle.ZIndex = 10
dropToggle.Parent = dropContent
Instance.new("UICorner", dropToggle).CornerRadius = UDim.new(0, 6)

dropToggle.MouseButton1Click:Connect(function()
    print("[DEBUG] Auto Drop Button Clicked!")
    if ManagerModule.isDropRunning() then
        print("[DEBUG] Stopping Auto Drop")
        ManagerModule.stopDrop()
        dropToggle.Text = "OFF"
        dropToggle.BackgroundColor3 = C.btnGrey
    else
        print("[DEBUG] Starting Auto Drop")
        ManagerModule.startDrop()
        dropToggle.Text = "ON"
        dropToggle.BackgroundColor3 = C.btnStart
    end
end)

-- --- AUTO COLLECT (MAGNET) SECTION ---
local collectContent = createSection("🚜 Auto Collect Item")

-- Menghapus input Blok ID dan Sapling ID yang tidak relevan untuk Magnet
-- Langsung ke Slider Radius

-- Range Slider
local magSliderFrame = Instance.new("Frame")
magSliderFrame.Size = UDim2.new(1, 0, 0, 30)
magSliderFrame.BackgroundTransparency = 1
magSliderFrame.LayoutOrder = 1
magSliderFrame.Parent = collectContent

local rangeLabel = Instance.new("TextLabel")
rangeLabel.Size = UDim2.new(1, 0, 0, 16)
rangeLabel.Position = UDim2.new(0, 0, 0, 0)
rangeLabel.BackgroundTransparency = 1
rangeLabel.Text = "Magnet Radius: 2 Grid"
rangeLabel.TextColor3 = C.dim
rangeLabel.TextSize = 11
rangeLabel.Font = Enum.Font.Gotham
rangeLabel.TextXAlignment = Enum.TextXAlignment.Left
rangeLabel.Parent = magSliderFrame

local rangeSliderBg = Instance.new("Frame")
rangeSliderBg.Size = UDim2.new(1, 0, 0, 4)
rangeSliderBg.Position = UDim2.new(0, 0, 0, 18)
rangeSliderBg.BackgroundColor3 = C.cellOff
rangeSliderBg.BorderSizePixel = 0
rangeSliderBg.Parent = magSliderFrame
Instance.new("UICorner", rangeSliderBg).CornerRadius = UDim.new(0, 2)

local rangeSliderFill = Instance.new("Frame")
rangeSliderFill.Size = UDim2.new(0.5, 0, 1, 0)
rangeSliderFill.BackgroundColor3 = C.accent
rangeSliderFill.BorderSizePixel = 0
rangeSliderFill.Parent = rangeSliderBg
Instance.new("UICorner", rangeSliderFill).CornerRadius = UDim.new(0, 2)

local rangeSliderHit = Instance.new("TextButton")
rangeSliderHit.Size = UDim2.new(1, 0, 0, 12)
rangeSliderHit.Position = UDim2.new(0, 0, 0, 14)
rangeSliderHit.BackgroundTransparency = 1
rangeSliderHit.Text = ""
rangeSliderHit.Parent = magSliderFrame

local rangeDrag = false
rangeSliderHit.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        rangeDrag = true
    end
end)
UIS.InputChanged:Connect(function(input)
    if rangeDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local rel = math.clamp((input.Position.X - rangeSliderBg.AbsolutePosition.X) / rangeSliderBg.AbsoluteSize.X, 0, 1)
        rangeSliderFill.Size = UDim2.new(rel, 0, 1, 0)
        local val = math.max(math.floor(rel * 5), 1) -- 1 to 5 grids
        ManagerModule.COLLECT_RANGE = val
        rangeLabel.Text = "Magnet Radius: " .. val .. " Grid"
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        rangeDrag = false
    end
end)

local sapToggleRow = Instance.new("Frame")
sapToggleRow.Size = UDim2.new(1, 0, 0, 24)
sapToggleRow.BackgroundTransparency = 1
sapToggleRow.LayoutOrder = 2
sapToggleRow.Parent = collectContent

local sapLabel = Instance.new("TextLabel")
sapLabel.Size = UDim2.new(1, -50, 1, 0)
sapLabel.BackgroundTransparency = 1
sapLabel.Text = "🌱 Sapling / Seed Only"
sapLabel.TextColor3 = C.dim
sapLabel.TextSize = 11
sapLabel.Font = Enum.Font.Gotham
sapLabel.TextXAlignment = Enum.TextXAlignment.Left
sapLabel.Parent = sapToggleRow

local sapToggle = Instance.new("TextButton")
sapToggle.Size = UDim2.new(0, 45, 0, 20)
sapToggle.Position = UDim2.new(1, -45, 0, 2)
sapToggle.BackgroundColor3 = C.cellOff
sapToggle.Text = "OFF"
sapToggle.TextColor3 = C.white
sapToggle.TextSize = 10
sapToggle.Font = Enum.Font.GothamBold
sapToggle.ZIndex = 10
sapToggle.Parent = sapToggleRow
Instance.new("UICorner", sapToggle).CornerRadius = UDim.new(0, 4)

sapToggle.MouseButton1Click:Connect(function()
    print("[DEBUG] Sapling Filter Clicked")
    ManagerModule.COLLECT_SAPLING_ONLY = not ManagerModule.COLLECT_SAPLING_ONLY
    sapToggle.Text = ManagerModule.COLLECT_SAPLING_ONLY and "ON" or "OFF"
    sapToggle.BackgroundColor3 = ManagerModule.COLLECT_SAPLING_ONLY and C.accent or C.cellOff
end)

local collectToggle = Instance.new("TextButton")
collectToggle.Size = UDim2.new(1, 0, 0, 26)
collectToggle.BackgroundTransparency = 0
collectToggle.LayoutOrder = 3
collectToggle.BackgroundColor3 = C.btnGrey
collectToggle.Text = "OFF"
collectToggle.TextColor3 = C.white
collectToggle.TextSize = 12
collectToggle.Font = Enum.Font.GothamBold
collectToggle.ZIndex = 10
collectToggle.Parent = collectContent
Instance.new("UICorner", collectToggle).CornerRadius = UDim.new(0, 6)

collectToggle.MouseButton1Click:Connect(function()
    print("[DEBUG] Magnet Button Clicked!")
    if ManagerModule.isCollectRunning() then
        print("[DEBUG] Stopping Magnet")
        ManagerModule.stopCollect()
        collectToggle.Text = "OFF"
        collectToggle.BackgroundColor3 = C.btnGrey
    else
        print("[DEBUG] Starting Magnet")
        ManagerModule.startCollect()
        collectToggle.Text = "ON"
        collectToggle.BackgroundColor3 = C.btnStart
    end
end)

-- Store tab 2 frame
tabFrames[2] = tabManager

-- ═══════════════════════════════════════
-- TAB 3, 4: COMING SOON
-- ═══════════════════════════════════════

tabFrames[3] = createComingSoonTab(contentContainer, "Rotasi")
tabFrames[4] = createComingSoonTab(contentContainer, "Bot")

-- ═══════════════════════════════════════
-- TAB 5: CLEAR WORLD
-- ═══════════════════════════════════════
local tabClear = Instance.new("ScrollingFrame")
tabClear.Size = UDim2.new(1, -10, 1, -10)
tabClear.Position = UDim2.new(0, 5, 0, 5)
tabClear.BackgroundTransparency = 1
tabClear.BorderSizePixel = 0
tabClear.ScrollBarThickness = 2
tabClear.Visible = false
tabClear.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabClear.CanvasSize = UDim2.new(0, 0, 0, 0)
tabClear.Parent = contentContainer
tabFrames[5] = tabClear

local clearList = Instance.new("UIListLayout")
clearList.Padding = UDim.new(0, 15)
clearList.SortOrder = Enum.SortOrder.LayoutOrder
clearList.Parent = tabClear

local clearPadding = Instance.new("UIPadding")
clearPadding.PaddingLeft = UDim.new(0, 5)
clearPadding.PaddingRight = UDim.new(0, 5)
clearPadding.PaddingTop = UDim.new(0, 10)
clearPadding.Parent = tabClear

local clearHeader = Instance.new("TextLabel")
clearHeader.Size = UDim2.new(1, 0, 0, 24)
clearHeader.BackgroundTransparency = 1
clearHeader.Text = "🌍 Clear World Automator"
clearHeader.TextColor3 = C.white
clearHeader.TextSize = 14
clearHeader.Font = Enum.Font.GothamBold
clearHeader.TextXAlignment = Enum.TextXAlignment.Left
clearHeader.Parent = tabClear

local clearDesc = Instance.new("TextLabel")
clearDesc.Size = UDim2.new(1, 0, 0, 32)
clearDesc.BackgroundTransparency = 1
clearDesc.Text = "Menghancurkan semua blok di world (X: 0-100, Y: 0-60). Gunakan Magnet untuk hasil maksimal."
clearDesc.TextColor3 = C.dim
clearDesc.TextSize = 10
clearDesc.Font = Enum.Font.Gotham
clearDesc.TextWrapped = true
clearDesc.TextXAlignment = Enum.TextXAlignment.Left
clearDesc.Parent = tabClear

-- Progress Section
local progFrame = Instance.new("Frame")
progFrame.Size = UDim2.new(1, 0, 0, 50)
progFrame.BackgroundTransparency = 1
progFrame.Parent = tabClear

local progLabel = Instance.new("TextLabel")
progLabel.Size = UDim2.new(1, 0, 0, 20)
progLabel.BackgroundTransparency = 1
progLabel.Text = "Progress: 0%"
progLabel.TextColor3 = C.white
progLabel.TextSize = 12
progLabel.Font = Enum.Font.GothamBold
progLabel.Parent = progFrame

local progBg = Instance.new("Frame")
progBg.Size = UDim2.new(1, 0, 0, 10)
progBg.Position = UDim2.new(0, 0, 0, 25)
progBg.BackgroundColor3 = C.cellOff
progBg.BorderSizePixel = 0
progBg.Parent = progFrame
Instance.new("UICorner", progBg).CornerRadius = UDim.new(0, 5)

local progFill = Instance.new("Frame")
progFill.Size = UDim2.new(0, 0, 1, 0)
progFill.BackgroundColor3 = C.accent
progFill.BorderSizePixel = 0
progFill.Parent = progBg
Instance.new("UICorner", progFill).CornerRadius = UDim.new(0, 5)

local clearStatus = Instance.new("TextLabel")
clearStatus.Size = UDim2.new(1, 0, 0, 14)
clearStatus.Position = UDim2.new(0, 0, 0, 40)
clearStatus.BackgroundTransparency = 1
clearStatus.Text = "Status: Idle"
clearStatus.TextColor3 = C.dim
clearStatus.TextSize = 11
clearStatus.Font = Enum.Font.Gotham
clearStatus.Parent = progFrame

-- Buttons
local clearBtnRow = Instance.new("Frame")
clearBtnRow.Size = UDim2.new(1, 0, 0, 32)
clearBtnRow.BackgroundTransparency = 1
clearBtnRow.Parent = tabClear

local startClearBtn = Instance.new("TextButton")
startClearBtn.Size = UDim2.new(0, 125, 1, 0)
startClearBtn.Position = UDim2.new(0, 0, 0, 0)
startClearBtn.BackgroundColor3 = C.btnStart
startClearBtn.Text = "▶ START CLEAR"
startClearBtn.TextColor3 = C.white
startClearBtn.TextSize = 12
startClearBtn.Font = Enum.Font.GothamBold
startClearBtn.Parent = clearBtnRow
Instance.new("UICorner", startClearBtn).CornerRadius = UDim.new(0, 6)

local stopClearBtn = Instance.new("TextButton")
stopClearBtn.Size = UDim2.new(0, 125, 1, 0)
stopClearBtn.Position = UDim2.new(1, -125, 0, 0)
stopClearBtn.BackgroundColor3 = C.btnStop
stopClearBtn.Text = "■ STOP"
stopClearBtn.TextColor3 = C.white
stopClearBtn.TextSize = 12
stopClearBtn.Font = Enum.Font.GothamBold
stopClearBtn.Parent = clearBtnRow
Instance.new("UICorner", stopClearBtn).CornerRadius = UDim.new(0, 6)

startClearBtn.MouseButton1Click:Connect(function()
    ClearWorld.start()
end)

stopClearBtn.MouseButton1Click:Connect(function()
    ClearWorld.stop()
end)

-- ═══════════════════════════════════════
-- TAB 6: PLAYER
-- ═══════════════════════════════════════
local tabPlayer = Instance.new("ScrollingFrame")
tabPlayer.Size = UDim2.new(1, -10, 1, -10)
tabPlayer.Position = UDim2.new(0, 5, 0, 5)
tabPlayer.BackgroundTransparency = 1
tabPlayer.BorderSizePixel = 0
tabPlayer.ScrollBarThickness = 2
tabPlayer.Visible = false
tabPlayer.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabPlayer.CanvasSize = UDim2.new(0, 0, 0, 0)
tabPlayer.Parent = contentContainer
tabFrames[6] = tabPlayer

local playerList = Instance.new("UIListLayout")
playerList.Padding = UDim.new(0, 8)
playerList.SortOrder = Enum.SortOrder.LayoutOrder
playerList.Parent = tabPlayer

-- Helper: Create a toggle row
local function createPlayerToggle(parent, icon, label, order, onToggle)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 36)
    frame.BackgroundColor3 = C.sidebar
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = icon .. " " .. label
    lbl.TextColor3 = C.white
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 55, 0, 22)
    toggle.Position = UDim2.new(1, -65, 0.5, -11)
    toggle.BackgroundColor3 = C.btnGrey
    toggle.Text = "OFF"
    toggle.TextColor3 = C.white
    toggle.TextSize = 11
    toggle.Font = Enum.Font.GothamBold
    toggle.BorderSizePixel = 0
    toggle.Parent = frame
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)
    
    local isOn = false
    toggle.MouseButton1Click:Connect(function()
        isOn = not isOn
        onToggle(isOn)
        if isOn then
            toggle.Text = "ON"
            toggle.BackgroundColor3 = C.btnStart
        else
            toggle.Text = "OFF"
            toggle.BackgroundColor3 = C.btnGrey
        end
    end)
    
    return frame, toggle
end

-- Title
local playerTitle = Instance.new("TextLabel")
playerTitle.Size = UDim2.new(1, -10, 0, 22)
playerTitle.BackgroundTransparency = 1
playerTitle.Text = "👤 Player Controls"
playerTitle.TextColor3 = C.white
playerTitle.TextSize = 14
playerTitle.Font = Enum.Font.GothamBold
playerTitle.TextXAlignment = Enum.TextXAlignment.Left
playerTitle.LayoutOrder = 0
playerTitle.Parent = tabPlayer

-- 1. God Mode
createPlayerToggle(tabPlayer, "🛡️", "God Mode", 1, function(state)
    PlayerModule.setGodMode(state)
end)

-- 2. Sprint + Speed Slider
local sprintFrame, sprintToggle = createPlayerToggle(tabPlayer, "🏃", "Sprint", 2, function(state)
    PlayerModule.setSprint(state)
end)

-- Sprint Speed Slider
local sprintSliderFrame = Instance.new("Frame")
sprintSliderFrame.Size = UDim2.new(1, -10, 0, 40)
sprintSliderFrame.BackgroundColor3 = C.sidebar
sprintSliderFrame.BorderSizePixel = 0
sprintSliderFrame.LayoutOrder = 3
sprintSliderFrame.Parent = tabPlayer
Instance.new("UICorner", sprintSliderFrame).CornerRadius = UDim.new(0, 8)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 18)
speedLabel.Position = UDim2.new(0, 10, 0, 2)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: 32"
speedLabel.TextColor3 = C.dim
speedLabel.TextSize = 11
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = sprintSliderFrame

local speedSliderBg = Instance.new("Frame")
speedSliderBg.Size = UDim2.new(1, -20, 0, 5)
speedSliderBg.Position = UDim2.new(0, 10, 0, 24)
speedSliderBg.BackgroundColor3 = C.cellOff
speedSliderBg.BorderSizePixel = 0
speedSliderBg.Parent = sprintSliderFrame
Instance.new("UICorner", speedSliderBg).CornerRadius = UDim.new(0, 3)

local speedSliderFill = Instance.new("Frame")
speedSliderFill.Size = UDim2.new(0.32, 0, 1, 0)
speedSliderFill.BackgroundColor3 = C.accent
speedSliderFill.BorderSizePixel = 0
speedSliderFill.Parent = speedSliderBg
Instance.new("UICorner", speedSliderFill).CornerRadius = UDim.new(0, 3)

local speedSliderHit = Instance.new("TextButton")
speedSliderHit.Size = UDim2.new(1, 0, 0, 16)
speedSliderHit.Position = UDim2.new(0, 10, 0, 18)
speedSliderHit.BackgroundTransparency = 1
speedSliderHit.Text = ""
speedSliderHit.Parent = sprintSliderFrame

local speedDrag = false
speedSliderHit.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        speedDrag = true
    end
end)
UIS.InputChanged:Connect(function(input)
    if speedDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local rel = math.clamp((input.Position.X - speedSliderBg.AbsolutePosition.X) / speedSliderBg.AbsoluteSize.X, 0, 1)
        speedSliderFill.Size = UDim2.new(rel, 0, 1, 0)
        local val = math.max(math.floor(rel * 100), 16)
        PlayerModule.setSprintSpeed(val)
        speedLabel.Text = "Speed: " .. val
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        speedDrag = false
    end
end)

-- 3. Zero Gravity / Fly
createPlayerToggle(tabPlayer, "🪶", "Zero Gravity", 4, function(state)
    PlayerModule.setZeroGravity(state)
end)

-- 4. Infinite Jump
createPlayerToggle(tabPlayer, "🦘", "Infinite Jump", 5, function(state)
    PlayerModule.setInfiniteJump(state)
end)

-- ═══════════════════════════════════════
-- TAB 7: DIAGNOSTIC
-- ═══════════════════════════════════════
local tabDiag = Instance.new("ScrollingFrame")
tabDiag.Size = UDim2.new(1, -10, 1, -10)
tabDiag.Position = UDim2.new(0, 5, 0, 5)
tabDiag.BackgroundTransparency = 1
tabDiag.BorderSizePixel = 0
tabDiag.ScrollBarThickness = 2
tabDiag.Visible = false
tabDiag.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabDiag.CanvasSize = UDim2.new(0, 0, 0, 0)
tabDiag.Parent = contentContainer
tabFrames[7] = tabDiag

local diagList = Instance.new("UIListLayout")
diagList.Padding = UDim.new(0, 10)
diagList.SortOrder = Enum.SortOrder.LayoutOrder
diagList.Parent = tabDiag

local diagPadding = Instance.new("UIPadding")
diagPadding.PaddingLeft = UDim.new(0, 5)
diagPadding.PaddingRight = UDim.new(0, 5)
diagPadding.PaddingTop = UDim.new(0, 10)
diagPadding.PaddingBottom = UDim.new(0, 10)
diagPadding.Parent = tabDiag

local diagTitle = Instance.new("TextLabel")
diagTitle.Size = UDim2.new(1, 0, 0, 20)
diagTitle.BackgroundTransparency = 1
diagTitle.Text = "Diag: System Diagnostic"
diagTitle.TextColor3 = C.white
diagTitle.TextSize = 14
diagTitle.Font = Enum.Font.GothamBold
diagTitle.TextXAlignment = Enum.TextXAlignment.Left
diagTitle.LayoutOrder = 1
diagTitle.Parent = tabDiag

-- --- LOG TERMINAL AREA ---
local termFrame = Instance.new("Frame")
termFrame.Size = UDim2.new(1, 0, 0, 150)
termFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
termFrame.BorderSizePixel = 0
termFrame.LayoutOrder = 2
termFrame.Parent = tabDiag
Instance.new("UICorner", termFrame).CornerRadius = UDim.new(0, 8)

local termScroll = Instance.new("ScrollingFrame")
termScroll.Size = UDim2.new(1, -10, 1, -10)
termScroll.Position = UDim2.new(0, 5, 0, 5)
termScroll.BackgroundTransparency = 1
termScroll.BorderSizePixel = 0
termScroll.ScrollBarThickness = 2
termScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
termScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
termScroll.Parent = termFrame

local termText = Instance.new("TextLabel")
termText.Size = UDim2.new(1, 0, 0, 0)
termText.AutomaticSize = Enum.AutomaticSize.Y
termText.BackgroundTransparency = 1
termText.Text = "--- Terminal Ready ---"
termText.TextColor3 = Color3.fromRGB(0, 255, 100)
termText.TextSize = 10
termText.Font = Enum.Font.Code
termText.TextXAlignment = Enum.TextXAlignment.Left
termText.TextYAlignment = Enum.TextYAlignment.Top
termText.TextWrapped = true
termText.Parent = termScroll

local function diagLog(msg)
    local timestamp = os.date("%H:%M:%S")
    termText.Text = termText.Text .. "\n[" .. timestamp .. "] " .. tostring(msg)
    termScroll.CanvasPosition = Vector2.new(0, termScroll.AbsoluteCanvasSize.Y)
end
_G.DiagnosticLog = diagLog

-- --- BUTTONS ROW ---
local bRow = Instance.new("Frame")
bRow.Size = UDim2.new(1, 0, 0, 26)
bRow.BackgroundTransparency = 1
bRow.LayoutOrder = 3
bRow.Parent = tabDiag

local clrBtn = Instance.new("TextButton")
clrBtn.Size = UDim2.new(0.5, -5, 1, 0)
clrBtn.BackgroundColor3 = C.btnGrey
clrBtn.Text = "🗑️ CLEAR LOG"
clrBtn.TextColor3 = C.white
clrBtn.TextSize = 11
clrBtn.Font = Enum.Font.GothamBold
clrBtn.Parent = bRow
Instance.new("UICorner", clrBtn).CornerRadius = UDim.new(0, 6)
clrBtn.MouseButton1Click:Connect(function() termText.Text = "--- Log Cleared ---" end)

local cpyBtn = Instance.new("TextButton")
cpyBtn.Size = UDim2.new(0.5, -5, 1, 0)
cpyBtn.Position = UDim2.new(0.5, 5, 0, 0)
cpyBtn.BackgroundColor3 = C.accent
cpyBtn.Text = "📋 COPY LOG"
cpyBtn.TextColor3 = C.white
cpyBtn.TextSize = 11
cpyBtn.Font = Enum.Font.GothamBold
cpyBtn.Parent = bRow
Instance.new("UICorner", cpyBtn).CornerRadius = UDim.new(0, 6)
cpyBtn.MouseButton1Click:Connect(function()
    setclipboard(termText.Text)
    cpyBtn.Text = "COPIED! ✅"
    task.wait(1.5)
    cpyBtn.Text = "📋 COPY LOG"
end)

-- --- TOOLS LIST ---
local toolsSection = Instance.new("Frame")
toolsSection.Size = UDim2.new(1, 0, 0, 0)
toolsSection.AutomaticSize = Enum.AutomaticSize.Y
toolsSection.BackgroundTransparency = 1
toolsSection.LayoutOrder = 4
toolsSection.Parent = tabDiag

local tList = Instance.new("UIListLayout")
tList.Padding = UDim.new(0, 6)
tList.Parent = toolsSection

local function createToolBtn(name, desc, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = C.sidebar
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.Parent = toolsSection
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    
    local n = Instance.new("TextLabel")
    n.Size = UDim2.new(1, -20, 0, 18)
    n.Position = UDim2.new(0, 10, 0, 4)
    n.BackgroundTransparency = 1
    n.Text = name
    n.TextColor3 = C.white
    n.TextSize = 12
    n.Font = Enum.Font.GothamBold
    n.TextXAlignment = Enum.TextXAlignment.Left
    n.Parent = btn
    
    local d = Instance.new("TextLabel")
    d.Size = UDim2.new(1, -20, 0, 14)
    d.Position = UDim2.new(0, 10, 0, 20)
    d.BackgroundTransparency = 1
    d.Text = desc
    d.TextColor3 = C.dim
    d.TextSize = 10
    d.Font = Enum.Font.Gotham
    d.TextXAlignment = Enum.TextXAlignment.Left
    d.Parent = btn
    
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

createToolBtn("📦 Deep Scan Items", "Scan workspace folders for items/drops", function()
    diagLog("Starting Deep Scan Items...")
    loadstring(game:HttpGet(GITHUB_BASE .. "DiagnosticItems.lua" .. NOCACHE))()
end)

createToolBtn("💎 Gem Spy", "Hook network to spy gem transactions", function()
    diagLog("Enabling Gem Spy...")
    loadstring(game:HttpGet(GITHUB_BASE .. "DiagnosticGems.lua" .. NOCACHE))()
end)

createToolBtn("👣 Movement Spy", "Spy on movement related remotes", function()
    diagLog("Enabling Movement Spy...")
    loadstring(game:HttpGet(GITHUB_BASE .. "MovementSpy.lua" .. NOCACHE))()
end)

createToolBtn("📜 General Diagnostic", "Quick overview of player & inventory", function()
    diagLog("Running General Diagnostic...")
    loadstring(game:HttpGet(GITHUB_BASE .. "Diagnostic.lua" .. NOCACHE))()
end)

createToolBtn("🔍 World Item Scan", "Open advanced scanner popup", function()
    diagLog("Opening World Item Scanner popup...")
    if ItemScanner then
        ItemScanner.showPopup(gui)
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
        
        -- Update backpack info
        if BackpackSync then
            bpLabel.Text = BackpackSync.getSummary()
        end
        
        -- Update PnB Tab
        if activeTab == 1 then
            itemDisplay.Text = tostring(AutoPnB.ITEM_ID)
            statusLabel.Text = "Status: " .. AutoPnB.getStatus()
            cycleLabel.Text = "Siklus: " .. AutoPnB.getCycleCount() .. " | Target: " .. AutoPnB.getTargetCount()
            
        -- Update Clear World Tab
        elseif activeTab == 5 then
            local progress = ClearWorld.getProgress()
            progLabel.Text = "Progress: " .. progress .. "%"
            progFill.Size = UDim2.new(progress / 100, 0, 1, 0)
            clearStatus.Text = "Status: " .. ClearWorld.getStatus()
            
            if ClearWorld.isRunning() then
                startClearBtn.BackgroundColor3 = C.btnGrey
                stopClearBtn.BackgroundColor3 = C.btnStop
            else
                startClearBtn.BackgroundColor3 = C.btnStart
                stopClearBtn.BackgroundColor3 = C.btnGrey
            end
        end
        
        task.wait(0.5)
    end
end)

print("[CawScript] UI Berhasil dimuat! ✅")