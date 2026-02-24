--[[
    ManagerModule.lua
    Auto Drop & Auto Collect — Smart drop with Popup Nuker

    Features:
    - Silent Drop (fires PlayerDrop then UIPromptEvent)
    - Popup Nuker (actively destroys game's confirmation UI)
]]

local Manager = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Antiban
local Coordinates
local BackpackSync

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local Managers = game:GetService("ReplicatedStorage"):WaitForChild("Managers", 5)

local RemotePrompt, RemotePlace, RemoteFist, RemoteDrop

if Remotes then
    RemotePlace = Remotes:FindFirstChild("PlayerPlaceItem")
    RemoteFist  = Remotes:FindFirstChild("PlayerFist")
    RemoteDrop  = Remotes:FindFirstChild("PlayerDrop")
end

if Managers then
    local UIManager = Managers:FindFirstChild("UIManager")
    if UIManager then
        RemotePrompt = UIManager:FindFirstChild("UIPromptEvent")
    end
end

-- ═══════════════════════════════════════
-- CONFIG: AUTO DROP
-- ═══════════════════════════════════════
Manager.DROP_ITEM_ID    = 1
Manager.DROP_IMAGE_ID   = ""
Manager.DROP_AMOUNT     = 1
Manager.DROP_DELAY      = 2
Manager._dropRunning    = false
Manager._dropThread     = nil

-- ═══════════════════════════════════════
-- CONFIG: AUTO COLLECT
-- ═══════════════════════════════════════
Manager.COLLECT_BLOCK_ID   = 1
Manager.COLLECT_SAPLING_ID = 1
Manager.COLLECT_RANGE      = 2
Manager.COLLECT_DELAY      = 0.3
Manager.COLLECT_SAPLING_ONLY = false
Manager._collectRunning    = false
Manager._collectThread     = nil

-- ═══════════════════════════════════════
-- POPUP NUKER & HUD PERSISTENCE
-- Hancurkan UI game yang ganggu & paksa HUD tetep ada
-- ═══════════════════════════════════════

local PERSISTENT_GUIS = {} -- Simpan mana yang harus tetep nongol

local function destroyPopupsAndForceHUD()
    pcall(function()
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then return end
        
        for _, g in ipairs(pg:GetChildren()) do
            if g:IsA("ScreenGui") and g.Name ~= "KolinUI" then
                -- 1. NUKER: Hancurkan popup drop
                local isDropUI = false
                for _, child in ipairs(g:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        local t = (child.Text or ""):lower()
                        if t:find("drop") or t:find("how many") or t:find("confirm") then
                            isDropUI = true
                            break
                        end
                    end
                end
                
                if isDropUI then
                    g:Destroy()
                elseif PERSISTENT_GUIS[g] then
                    -- 2. PERSISTENCE: Paksa HUD tetep enabled
                    if g.Enabled == false then
                        g.Enabled = true
                    end
                end
            end
        end
    end)
end

-- Ambil snapshot state UI sekarang (mana yang lagi nongol)
local function recordHUDState()
    PERSISTENT_GUIS = {}
    pcall(function()
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, g in ipairs(pg:GetChildren()) do
            if g:IsA("ScreenGui") and g.Name ~= "KolinUI" and g.Enabled == true then
                -- Jangan persist popup drop itu sendiri
                local isDropUI = false
                for _, child in ipairs(g:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        local t = (child.Text or ""):lower()
                        if t:find("drop") or t:find("how many") then
                            isDropUI = true
                            break
                        end
                    end
                end
                if not isDropUI then
                    PERSISTENT_GUIS[g] = true
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- SMART AUTO DROP LOOP
-- ═══════════════════════════════════════

local function dropLoop()
    -- Record mana UI yang harusnya ada
    recordHUDState()

    -- Start a background nuker + HUD keeper during the loop
    task.spawn(function()
        while Manager._dropRunning do
            destroyPopupsAndForceHUD()
            task.wait(0.05) -- Cek 20x per detik
        end
    end)

    while Manager._dropRunning do
        if not RemotePrompt or not RemoteDrop then
            Manager._dropRunning = false
            warn("[Manager] Auto Drop gagal: Remote tidak ditemukan")
            break
        end

        if Manager.DROP_IMAGE_ID == "" then
            Manager._dropRunning = false
            warn("[Manager] Auto Drop gagal: Item belum dipilih")
            break
        end

        -- SYNC: cari slot yang punya item dengan image yang sama
        local slotNum, count = nil, 0
        if BackpackSync then
            slotNum, count = BackpackSync.findSlotByImage(Manager.DROP_IMAGE_ID)
        end

        if slotNum and count >= Manager.DROP_AMOUNT then
            -- Item ditemukan & jumlah cukup
            
            -- 1. Fire PlayerDrop biar server siap (ini munculin popup di game)
            pcall(function()
                RemoteDrop:FireServer(Manager.DROP_ITEM_ID)
            end)
            
            -- Langsung hapus & paksa HUD nongol
            destroyPopupsAndForceHUD()
            
            -- 2. Kasih jeda sangat singkat agar server process PlayerDrop
            task.wait(0.05)
            
            -- 3. Fire confirm (ini harusnya nutup popup juga secara logic server)
            pcall(function()
                RemotePrompt:FireServer({
                    ButtonAction = "drp",
                    Inputs = {
                        amt = tostring(Manager.DROP_AMOUNT)
                    }
                })
            end)
            
            -- Hapus lagi & paksa HUD nongol buat jaga-jaga
            destroyPopupsAndForceHUD()
            
        elseif not slotNum then
            Manager._dropRunning = false
            warn("[Manager] Auto Drop berhenti: Item habis / tidak ditemukan")
            break
        end

        task.wait(Manager.DROP_DELAY)
    end
end

-- ═══════════════════════════════════════
-- IMAGE CAPTURE
-- ═══════════════════════════════════════
function Manager.captureItemImage(itemId)
    Manager.DROP_ITEM_ID = itemId
    if not BackpackSync then return end
    task.wait(0.3)
    BackpackSync.sync()
    local slots = BackpackSync.findSlotsWithItems()
    if #slots > 0 then
        local info = BackpackSync.getSlotInfo(slots[1])
        Manager.DROP_IMAGE_ID = info.imageId
    end
end

-- ═══════════════════════════════════════
-- AUTO COLLECT LOOP
-- ═══════════════════════════════════════

-- ═══════════════════════════════════════
-- AUTO COLLECT (MAGNET) LOOP
-- ═══════════════════════════════════════

local function magnetLoop()
    while Manager._collectRunning do
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root then
            -- Cari item di workspace (Scan Folder khusus atau Root)
            local itemsFolder = workspace:FindFirstChild("Items") or workspace:FindFirstChild("Drops")
            local targetFolder = itemsFolder or workspace
            
            for _, item in ipairs(targetFolder:GetChildren()) do
                if not Manager._collectRunning then break end
                
                -- Deteksi item: BasePart/Model yang bukan Map/Player
                if (item:IsA("BasePart") or item:IsA("Model")) and item.Name ~= player.Name and item.Name ~= "Terrain" then
                    
                    -- Cek metadata/attribute (itemID, Count, dll)
                    local isItem = item:GetAttribute("itemID") or item:GetAttribute("Count") or item:FindFirstChild("TouchInterest")
                    
                    -- Heuristic tambahan berdasarkan nama
                    local name = item.Name:lower()
                    if not isItem and (name:find("item") or name:find("block") or name:find("sapling") or name:find("seed")) then
                        isItem = true
                    end

                    if isItem then
                        local pos = item:GetPivot().Position
                        local dist = (pos - root.Position).Magnitude
                        
                        -- Grid-based Radius (1 grid = 4.5 studs)
                        local maxStuds = Manager.COLLECT_RANGE * 4.5
                        
                        if dist <= maxStuds then
                            -- Filter Sapling Only jika aktif
                            local shouldCollect = true
                            if Manager.COLLECT_SAPLING_ONLY then
                                local isSapling = name:find("sapling") or name:find("seed") or item:GetAttribute("IsSapling")
                                if not isSapling then
                                    shouldCollect = false
                                end
                            end

                            if shouldCollect then
                                -- Teleport item ke player (Magnet)
                                pcall(function()
                                    if item:IsA("BasePart") then
                                        item.CFrame = root.CFrame
                                    else
                                        item:PivotTo(root.CFrame)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
        task.wait(Manager.COLLECT_DELAY)
    end
end

-- ═══════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════

function Manager.init(coords, antiban, bpSync)
    Coordinates = coords
    Antiban = antiban
    BackpackSync = bpSync
end

function Manager.startDrop()
    if Manager._dropRunning then return end
    if Manager.DROP_IMAGE_ID == "" then
        warn("[Manager] Pilih item dulu sebelum Auto Drop!")
        return
    end
    Manager._dropRunning = true
    Manager._dropThread = task.spawn(dropLoop)
end

function Manager.stopDrop()
    Manager._dropRunning = false
end

function Manager.isDropRunning()
    return Manager._dropRunning
end

function Manager.startCollect()
    if Manager._collectRunning then return end
    Manager._collectRunning = true
    Manager._collectThread = task.spawn(magnetLoop)
end

function Manager.stopCollect()
    Manager._collectRunning = false
end

function Manager.isCollectRunning()
    return Manager._collectRunning
end

return Manager
