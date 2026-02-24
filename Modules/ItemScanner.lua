--[[
    ItemScanner.lua
    Module for scanning and displaying all items in the world (Drops & Placed).
    V3 - Data-Driven with Ultra Logging.
]]

local ItemScanner = {}
ItemScanner.VERSION = "V3"

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ═══════════════════════════════════════
-- DATA & MAPPING
-- ═══════════════════════════════════════

local STRING_MAP = {
    ["bedrock"] = "Bedrock",
    ["dirt"] = "Dirt Block",
    ["dirt_background"] = "Dirt Background",
    ["stone"] = "Stone Block",
    ["sand"] = "Sand Block",
    ["wood"] = "Wood Block",
    ["magma"] = "Magma Block",
    ["lava"] = "Lava Block",
    ["obsidian"] = "Obsidian Block",
    ["dirt_sapling"] = "Dirt Sapling",
    ["stone_sapling"] = "Stone Sapling",
    ["wood_sapling"] = "Wood Sapling",
    ["sand_sapling"] = "Sand Sapling",
}

local SPRITE_SHEET = "rbxassetid://77870053743502"

-- ═══════════════════════════════════════
-- SCAN LOGIC
-- ═══════════════════════════════════════

function ItemScanner.scan()
    print("[ITEMSCAN] ["..ItemScanner.VERSION.."] Memulai Scan...")
    local counts = {
        drops = {},
        placed = {},
        bg = {},
        total = {}
    }
    
    local totalFound = 0
    
    local function addCount(tbl, id, amt)
        if not id or id == "" or id == "none" or id == "air" then return end
        id = tostring(id):lower()
        
        tbl[id] = (tbl[id] or 0) + (amt or 1)
        counts.total[id] = (counts.total[id] or 0) + (amt or 1)
        totalFound = totalFound + (amt or 1)
    end
    
    -- 1. Scan Placed Blocks (WorldTiles)
    local worldTilesMod = ReplicatedStorage:FindFirstChild("WorldTiles")
    if worldTilesMod then
        print("[ITEMSCAN] Reading WorldTiles database...")
        local ok, data = pcall(require, worldTilesMod)
        if ok and type(data) == "table" then
            local rowCount = 0
            for x, row in pairs(data) do
                if type(row) == "table" then
                    rowCount = rowCount + 1
                    for y, cell in pairs(row) do
                        if type(cell) == "table" then
                            -- Foreground
                            if cell[1] and cell[1] ~= "" then
                                addCount(counts.placed, cell[1], 1)
                            end
                            -- Background
                            if cell[2] and cell[2] ~= "" then
                                addCount(counts.bg, cell[2], 1)
                            end
                        end
                    end
                end
            end
            print("[ITEMSCAN] Selesai baca WorldTiles. Ada " .. rowCount .. " baris data.")
        else
            warn("[ITEMSCAN] Gagal require WorldTiles: " .. tostring(data))
        end
    else
        warn("[ITEMSCAN] WorldTiles tidak ditemukan di ReplicatedStorage!")
    end
    
    -- 2. Scan Drops (Ground Items)
    local folderDrops = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Items")
    if folderDrops then
        print("[ITEMSCAN] Scanning Drops folder...")
        local dropCount = 0
        for _, item in ipairs(folderDrops:GetDescendants()) do
            local id = item:GetAttribute("id") or item:GetAttribute("ItemId")
            if id then
                addCount(counts.drops, id, 1)
                dropCount = dropCount + 1
            end
        end
        print("[ITEMSCAN] Selesai scan Drops. Ditemukan " .. dropCount .. " item.")
    end
    
    print("[ITEMSCAN] Total Scan Selesai: " .. totalFound .. " objek ditemukan.")
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
    frame.Size = UDim2.new(0, 360, 0, 480)
    frame.Position = UDim2.new(0.5, -180, 0.5, -240)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = guiParent
    activePopup = frame
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 15)
    
    -- Version Tag
    local vTag = Instance.new("TextLabel", frame)
    vTag.Size = UDim2.new(0, 40, 0, 20)
    vTag.Position = UDim2.new(0, 10, 0, 10)
    vTag.BackgroundTransparency = 1
    vTag.Text = ItemScanner.VERSION
    vTag.TextColor3 = Color3.fromRGB(100, 100, 150)
    vTag.TextSize = 10
    vTag.Font = Enum.Font.GothamBold
    vTag.ZIndex = 5
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 55)
    title.BackgroundColor3 = Color3.fromRGB(24, 24, 38)
    title.Text = "🔍 World Item Scanner"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 15)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 32, 0, 32)
    close.Position = UDim2.new(1, -42, 0, 11)
    close.BackgroundTransparency = 1
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(255, 100, 100)
    close.TextSize = 22
    close.Font = Enum.Font.GothamBold
    close.Parent = frame
    close.MouseButton1Click:Connect(function() frame:Destroy() end)
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -120)
    scroll.Position = UDim2.new(0, 10, 0, 65)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.Parent = frame
    
    Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 8)
    
    local function renderItems()
        for _, c in ipairs(scroll:GetChildren()) do
            if not c:IsA("UIListLayout") then c:Destroy() end
        end
        
        local totalCount = 0
        local sorted = {}
        for id, num in pairs(counts.total) do
            table.insert(sorted, {id = id, count = num})
            totalCount = totalCount + num
        end
        table.sort(sorted, function(a,b) return a.count > b.count end)
        
        local summary = Instance.new("TextLabel")
        summary.Size = UDim2.new(1, 0, 0, 20)
        summary.BackgroundTransparency = 1
        summary.Text = string.format("Scan Selesai: %d objek | %d jenis unik", totalCount, #sorted)
        summary.TextColor3 = Color3.fromRGB(150, 150, 200)
        summary.TextSize = 12
        summary.Font = Enum.Font.Gotham
        summary.Parent = scroll
        
        if #sorted == 0 then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.new(1, 0, 0, 150)
            empty.BackgroundTransparency = 1
            empty.Text = "0 OBJEK DITEMUKAN\n(Cek F9 untuk detail error)"
            empty.TextColor3 = Color3.fromRGB(255, 100, 100)
            empty.TextSize = 14
            empty.Font = Enum.Font.GothamBold
            empty.Parent = scroll
        end
        
        for _, data in ipairs(sorted) do
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 50)
            row.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
            row.Parent = scroll
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
            
            local icon = Instance.new("ImageLabel")
            icon.Size = UDim2.new(0, 38, 0, 38)
            icon.Position = UDim2.new(0, 6, 0, 6)
            icon.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
            icon.Image = SPRITE_SHEET
            icon.Parent = row
            Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 8)
            
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(1, -120, 0, 22)
            nameLabel.Position = UDim2.new(0, 55, 0, 6)
            nameLabel.BackgroundTransparency = 1
            local displayName = STRING_MAP[data.id] or data.id:gsub("_", " "):gsub("^%l", string.upper)
            nameLabel.Text = displayName
            nameLabel.TextColor3 = Color3.new(1,1,1)
            nameLabel.TextSize = 14
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = row
            
            local detail = Instance.new("TextLabel")
            detail.Size = UDim2.new(1, -120, 0, 16)
            detail.Position = UDim2.new(0, 55, 0, 26)
            detail.BackgroundTransparency = 1
            local p = counts.placed[data.id] or 0
            local d = counts.drops[data.id] or 0
            local b = counts.bg[data.id] or 0
            local meta = {}
            if p > 0 then table.insert(meta, "FG:"..p) end
            if b > 0 then table.insert(meta, "BG:"..b) end
            if d > 0 then table.insert(meta, "Drop:"..d) end
            detail.Text = table.concat(meta, " | ")
            detail.TextColor3 = Color3.fromRGB(150, 150, 180)
            detail.TextSize = 11
            detail.TextXAlignment = Enum.TextXAlignment.Left
            detail.Font = Enum.Font.Gotham
            detail.Parent = row
            
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.new(0, 65, 1, 0)
            badge.Position = UDim2.new(1, -70, 0, 0)
            badge.BackgroundTransparency = 1
            badge.Text = data.count .. "x"
            badge.TextColor3 = Color3.fromRGB(0, 255, 150)
            badge.TextSize = 16
            badge.Font = Enum.Font.GothamBold
            badge.TextXAlignment = Enum.TextXAlignment.Right
            badge.Parent = row
        end
    end
    
    local refresh = Instance.new("TextButton")
    refresh.Size = UDim2.new(1, -40, 0, 40)
    refresh.Position = UDim2.new(0, 20, 1, -50)
    refresh.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    refresh.Text = "🔄 REFRESH DATABASE"
    refresh.TextColor3 = Color3.new(1,1,1)
    refresh.TextSize = 13
    refresh.Font = Enum.Font.GothamBold
    refresh.Parent = frame
    Instance.new("UICorner", refresh).CornerRadius = UDim.new(0, 10)
    
    refresh.MouseButton1Click:Connect(function()
        refresh.Text = "⏳ SCANNING DATABASE..."
        task.wait(0.1)
        counts = ItemScanner.scan()
        renderItems()
        refresh.Text = "🔄 REFRESH DATABASE"
    end)
    
    renderItems()
    
    -- Draggable
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

return ItemScanner
