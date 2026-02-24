--[[
    ItemScanner.lua
    Module for scanning and displaying all items in the world (Drops & Placed).
    RECURSIVE VERSION - Robust against nested models.
]]

local ItemScanner = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ═══════════════════════════════════════
-- DATA & MAPPING
-- ═══════════════════════════════════════

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

local STRING_MAP = {
    ["magma"] = "Magma Block",
    ["dirt"] = "Dirt Block",
    ["stone"] = "Stone Block",
    ["sand"] = "Sand Block",
    ["wood"] = "Wood Block",
    ["obsidian"] = "Obsidian Block",
    ["lava"] = "Lava Block",
}

local SPRITE_SHEET = "rbxassetid://77870053743502"

-- ═══════════════════════════════════════
-- SCAN LOGIC
-- ═══════════════════════════════════════

function ItemScanner.scan()
    print("[ITEMSCAN] Memulai deep scan...")
    local counts = {
        drops = {},
        placed = {},
        total = {}
    }
    
    local function addCount(tbl, id, amt)
        if not id then return end
        id = tostring(id):lower()
        if id == "" or id == "shadow" then return end
        
        tbl[id] = (tbl[id] or 0) + (amt or 1)
        counts.total[id] = (counts.total[id] or 0) + (amt or 1)
    end
    
    -- Heuristic: Cari folder-folder penting
    local folderDrops = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Items")
    local folderTiles = workspace:FindFirstChild("Tiles") or workspace:FindFirstChild("Map")
    local folderHighlights = workspace:FindFirstChild("TileHighlights")
    
    -- 1. Scan Drops (Recursive)
    if folderDrops then
        print("[ITEMSCAN] Scanning Drops in: " .. folderDrops.Name)
        for _, item in ipairs(folderDrops:GetDescendants()) do
            local id = item:GetAttribute("id")
            if id then
                addCount(counts.drops, id, 1)
            end
        end
    end
    
    -- 2. Scan Placed / Tiles (Recursive)
    if folderTiles then
        print("[ITEMSCAN] Scanning Tiles in: " .. folderTiles.Name)
        for _, tile in ipairs(folderTiles:GetDescendants()) do
            local id = tile:GetAttribute("id")
            -- Filter part name jika tidak ada ID
            if not id and (tile:IsA("Part") or tile:IsA("MeshPart")) then
                local n = tile.Name:lower()
                if not n:find("part") and not n:find("base") and n ~= "" and n ~= "shadow" then
                    id = n
                end
            end
            
            if id then
                addCount(counts.placed, id, 1)
            end
        end
    end
    
    -- 3. Scan Highlights (Recursive)
    if folderHighlights then
        print("[ITEMSCAN] Scanning Highlights in: " .. folderHighlights.Name)
        for _, h in ipairs(folderHighlights:GetDescendants()) do
            local id = h:GetAttribute("id")
            if id then
                addCount(counts.placed, id, 1)
            end
        end
    end
    
    local foundAny = false
    local t = 0
    for k, v in pairs(counts.total) do
        foundAny = true
        t = t + v
    end
    print("[ITEMSCAN] Scan selesai. Total item unik: " .. (foundAny and t or 0))
    
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
    frame.Size = UDim2.new(0, 320, 0, 420)
    frame.Position = UDim2.new(0.5, -160, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 38)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = guiParent
    activePopup = frame
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)
    
    -- Shadow Effect (Subtle)
    local shadow = Instance.new("Frame", frame)
    shadow.Size = UDim2.new(1, 4, 1, 4)
    shadow.Position = UDim2.new(0, -2, 0, -2)
    shadow.BackgroundColor3 = Color3.new(0,0,0)
    shadow.BackgroundTransparency = 0.8
    shadow.ZIndex = -1
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    title.Text = "🔍 World Item Scanner"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 32, 0, 32)
    close.Position = UDim2.new(1, -38, 0, 6)
    close.BackgroundTransparency = 1
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(200, 200, 200)
    close.TextSize = 20
    close.Font = Enum.Font.GothamBold
    close.Parent = frame
    close.MouseButton1Click:Connect(function() frame:Destroy() end)
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -100)
    scroll.Position = UDim2.new(0, 10, 0, 55)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 80, 255)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Parent = frame
    
    local list = Instance.new("UIListLayout", scroll)
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Update Footer logic
    local function renderItems()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end
        
        local totalCount = 0
        local sorted = {}
        for id, num in pairs(counts.total) do
            table.insert(sorted, {id = id, count = num})
            totalCount = totalCount + num
        end
        table.sort(sorted, function(a,b) return a.count > b.count end)
        
        local summary = Instance.new("TextLabel")
        summary.Size = UDim2.new(1, 0, 0, 24)
        summary.BackgroundTransparency = 1
        summary.Text = string.format("Terdeteksi %d objek di map (%d jenis unik)", totalCount, #sorted)
        summary.TextColor3 = Color3.fromRGB(150, 150, 180)
        summary.TextSize = 12
        summary.Font = Enum.Font.Gotham
        summary.Parent = scroll
        
        if #sorted == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 100)
            empty.BackgroundTransparency = 1
            empty.Text = "World terlihat sepi...\n(Gagal menemukan Item/Tiles)"
            empty.TextColor3 = Color3.fromRGB(100, 100, 120)
            empty.TextSize = 14
            empty.Font = Enum.Font.Gotham
            empty.Parent = scroll
        end
        
        for _, data in ipairs(sorted) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 48)
            row.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            row.Parent = scroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
            
            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0, 36, 0, 36)
            icon.Position = UDim2.new(0, 6, 0, 6)
            icon.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            icon.Image = SPRITE_SHEET
            icon.Parent = row
            Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 6)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -110, 0, 22)
            nameLabel.Position = UDim2.new(0, 50, 0, 6)
            nameLabel.BackgroundTransparency = 1
            local displayName = STRING_MAP[data.id] or ITEM_MAP_NAME[tonumber(data.id)] or data.id:upper()
            nameLabel.Text = displayName
            nameLabel.TextColor3 = Color3.new(1,1,1)
            nameLabel.TextSize = 13
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = row
            
            local detail = Instance.new("TextLabel")
            detail.Size = UDim2.new(1, -110, 0, 16)
            detail.Position = UDim2.new(0, 50, 0, 26)
            detail.BackgroundTransparency = 1
            local dropNum = counts.drops[data.id] or 0
            local placedNum = counts.placed[data.id] or 0
            detail.Text = string.format("Placed: %d | Drop: %d", placedNum, dropNum)
            detail.TextColor3 = Color3.fromRGB(130, 130, 160)
            detail.TextSize = 10
            detail.TextXAlignment = Enum.TextXAlignment.Left
            detail.Font = Enum.Font.Gotham
            detail.Parent = row
            
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 60, 1, 0)
            badge.Position = UDim2.new(1, -65, 0, 0)
            badge.BackgroundTransparency = 1
            badge.Text = data.count .. "x"
            badge.TextColor3 = Color3.fromRGB(100, 255, 150)
            badge.TextSize = 15
            badge.Font = Enum.Font.GothamBold
            badge.TextXAlignment = Enum.TextXAlignment.Right
            badge.Parent = row
        end
    end
    
    -- Refresh Button at bottom
    local refresh = Instance.new("TextButton")
    refresh.Size = UDim2.new(1, -40, 0, 32)
    refresh.Position = UDim2.new(0, 20, 1, -42)
    refresh.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
    refresh.Text = "🔄 REFRESH SCAN"
    refresh.TextColor3 = Color3.new(1,1,1)
    refresh.TextSize = 12
    refresh.Font = Enum.Font.GothamBold
    refresh.Parent = frame
    Instance.new("UICorner", refresh).CornerRadius = UDim.new(0, 8)
    
    refresh.MouseButton1Click:Connect(function()
        refresh.Text = "⏳ SCANNING..."
        task.wait(0.1)
        counts = ItemScanner.scan()
        renderItems()
        refresh.Text = "🔄 REFRESH SCAN"
    end)
    
    renderItems()
    
    -- Draggable logic
    local dragging, dragStart, startPos
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
