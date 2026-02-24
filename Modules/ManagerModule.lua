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
            print("[DEBUG] Drop canceled: No item selected")
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
    print("[DEBUG] Magnet loop started - Glide Hunt Mode")
    while Manager._collectRunning do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        
        if root then
            local targetFolder = workspace:FindFirstChild("Drops")
            if targetFolder then
                local items = targetFolder:GetChildren()
                local toCollect = {}
                
                -- 1. Scan targets
                for _, item in ipairs(items) do
                    local itemId = item:GetAttribute("id")
                    if itemId then
                        local pos = item:GetPivot().Position
                        local dist = (pos - root.Position).Magnitude
                        local maxStuds = Manager.COLLECT_RANGE * 4.5
                        
                        if dist <= maxStuds then
                            local shouldCollect = true
                            if Manager.COLLECT_SAPLING_ONLY then
                                local lowerId = tostring(itemId):lower()
                                if not (lowerId:find("sapling") or lowerId:find("seed")) then
                                    shouldCollect = false
                                end
                            end
                            if shouldCollect then
                                table.insert(toCollect, {item = item, pos = item:GetPivot().Position})
                            end
                        end
                    end
                end
                
                -- 2. Glide Hunt: Samperin satu-satu pake gerakan halus (Glide)
                if #toCollect > 0 then
                    local startCF = root.CFrame
                    
                    for _, data in ipairs(toCollect) do
                        if not Manager._collectRunning then break end
                        
                        pcall(function()
                            local targetPos = data.pos
                            -- Glide ke item (3 phase biar gak instan amat)
                            for i = 1, 3 do
                                if not Manager._collectRunning then break end
                                root.CFrame = root.CFrame:Lerp(CFrame.new(targetPos) * root.CFrame.Rotation, i/3)
                                task.wait(0.03)
                            end
                            
                            -- Berhenti sebentar di item (Sangat penting buat registrasi server)
                            task.wait(0.1) 
                        end)
                    end
                    
                    -- Balik ke posisi asal (Glide balik)
                    if Manager._collectRunning then
                        pcall(function()
                            for i = 1, 3 do
                                root.CFrame = root.CFrame:Lerp(startCF, i/3)
                                task.wait(0.03)
                            end
                        end)
                    end
                    
                    print("[MAGNET] Hunt Complete: " .. #toCollect .. " items")
                end
            end
        end
        task.wait(0.5) -- Jeda antar hunting scan
    end
    print("[DEBUG] Magnet loop stopped")
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
