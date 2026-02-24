--[[
    ItemScanner.lua
    Module for scanning and displaying all items in the world (Drops & Placed).
]]

local ItemScanner = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ═══════════════════════════════════════
-- DATA & MAPPING
-- ═══════════════════════════════════════

-- Item database (ID -> Name) based on items.json + common name guesses
local ITEM_MAP_NAME = {
    [2] = "Dirt Block",
    [4] = "Dirt",
    [5] = "Stone Sapling",
    [6] = "Stone Block",
    [7] = "Wood Block",
    [8] = "Wood Sapling",
    [9] = "Sand Block",
    [10] = "Sand Sapling",
    [11] = "Glass Block",
    [12] = "Obsidian Block",
    [13] = "Obsidian Sapling",
    [14] = "Lava Block",
    [15] = "Lava Sapling",
}

-- String to Name mapping for highlights/tiles
local STRING_MAP = {
    ["magma"] = "Magma Block",
    ["dirt"] = "Dirt Block",
    ["stone"] = "Stone Block",
    ["sand"] = "Sand Block",
    ["wood"] = "Wood Block",
}

local SPRITE_SHEET = "rbxassetid://77870053743502"

-- ═══════════════════════════════════════
-- SCAN LOGIC
-- ═══════════════════════════════════════

function ItemScanner.scan()
    local counts = {
        drops = {},
        placed = {},
        total = {}
    }
    
    local function addCount(tbl, id, amt)
        id = tostring(id):lower()
        tbl[id] = (tbl[id] or 0) + (amt or 1)
        counts.total[id] = (counts.total[id] or 0) + (amt or 1)
    end
    
    -- 1. Scan Drops
    local drops = workspace:FindFirstChild("Drops")
    if drops then
        for _, item in ipairs(drops:GetChildren()) do
            local id = item:GetAttribute("id")
            if id then
                addCount(counts.drops, id, 1)
            end
        end
    end
    
    -- 2. Scan Placed (Tiles)
    -- Tiles might be Parts or Models or Highlights
    local tiles = workspace:FindFirstChild("Tiles")
    if tiles then
        for _, tile in ipairs(tiles:GetChildren()) do
            -- Some use Name, some use Attributes
            local id = tile:GetAttribute("id") or tile.Name:lower()
            if id ~= "shadow" and id ~= "" then
                addCount(counts.placed, id, 1)
            end
        end
    end
    
    -- 3. Scan TileHighlights (for ghost/extra info)
    local highlights = workspace:FindFirstChild("TileHighlights")
    if highlights then
        for _, h in ipairs(highlights:GetChildren()) do
            local id = h:GetAttribute("id")
            if id then
                addCount(counts.placed, id, 1)
            end
        end
    end
    
    return counts
end

-- ═══════════════════════════════════════
-- UI POPUP
-- ═══════════════════════════════════════

local activePopup = nil

function ItemScanner.showPopup(guiParent)
    if activePopup then activePopup:Destroy() end
    
    local counts = ItemScanner.scan()
    
    local frame = Instance.new("Frame")
    frame.Name = "ScannerPopup"
    frame.Size = UDim2.new(0, 320, 0, 400)
    frame.Position = UDim2.new(0.5, -160, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 38)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = guiParent
    activePopup = frame
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    title.Text = "🔍 World Item Scanner"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 5)
    close.BackgroundTransparency = 1
    close.Text = "✕"
    close.TextColor3 = Color3.new(1,1,1)
    close.TextSize = 18
    close.Font = Enum.Font.GothamBold
    close.Parent = frame
    close.MouseButton1Click:Connect(function() frame:Destroy() end)
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -60)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Parent = frame
    
    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Header: Summary
    local totalCount = 0
    for _, num in pairs(counts.total) do totalCount = totalCount + num end
    
    local summary = Instance.new("TextLabel")
    summary.Size = UDim2.new(1, 0, 0, 20)
    summary.BackgroundTransparency = 1
    summary.Text = "Terdeteksi " .. totalCount .. " objek di map"
    summary.TextColor3 = Color3.fromRGB(150, 150, 180)
    summary.TextSize = 12
    summary.Font = Enum.Font.Gotham
    summary.Parent = scroll
    
    -- Build list
    local sorted = {}
    for id, num in pairs(counts.total) do
        table.insert(sorted, {id = id, count = num})
    end
    table.sort(sorted, function(a,b) return a.count > b.count end)
    
    for _, data in ipairs(sorted) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 45)
        row.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
        row.Parent = scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
        
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 35, 0, 35)
        icon.Position = UDim2.new(0, 5, 0, 5)
        icon.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        icon.Image = SPRITE_SHEET
        icon.Parent = row
        Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 4)
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, -100, 0, 20)
        nameLabel.Position = UDim2.new(0, 45, 0, 5)
        nameLabel.BackgroundTransparency = 1
        local displayName = STRING_MAP[data.id] or ITEM_MAP_NAME[tonumber(data.id)] or data.id:upper()
        nameLabel.Text = displayName
        nameLabel.TextColor3 = Color3.new(1,1,1)
        nameLabel.TextSize = 13
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = row
        
        local detail = Instance.new("TextLabel")
        detail.Size = UDim2.new(1, -100, 0, 15)
        detail.Position = UDim2.new(0, 45, 0, 23)
        detail.BackgroundTransparency = 1
        local dropNum = counts.drops[data.id] or 0
        local placedNum = counts.placed[data.id] or 0
        detail.Text = string.format("Placed: %d | Drops: %d", placedNum, dropNum)
        detail.TextColor3 = Color3.fromRGB(120, 120, 150)
        detail.TextSize = 10
        detail.TextXAlignment = Enum.TextXAlignment.Left
        detail.Font = Enum.Font.Gotham
        detail.Parent = row
        
        local countBadge = Instance.new("TextLabel")
        countBadge.Size = UDim2.new(0, 50, 1, 0)
        countBadge.Position = UDim2.new(1, -55, 0, 0)
        countBadge.BackgroundTransparency = 1
        countBadge.Text = data.count .. "x"
        countBadge.TextColor3 = Color3.fromRGB(0, 180, 80)
        countBadge.TextSize = 14
        countBadge.Font = Enum.Font.GothamBold
        countBadge.Parent = row
    end
    
    -- Draggable
    local dragging, dragInput, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

return ItemScanner
