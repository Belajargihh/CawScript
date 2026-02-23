--[[
    ManagerModule.lua
    Auto Drop & Auto Collect — Smart drop, NO popup

    Key: Skip PlayerDrop (causes popup), langsung fire UIPromptEvent confirm
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
Manager._collectRunning    = false
Manager._collectThread     = nil

-- ═══════════════════════════════════════
-- SMART AUTO DROP LOOP
-- Skip PlayerDrop → langsung UIPromptEvent confirm
-- No popup, no UI hide
-- ═══════════════════════════════════════

local function dropLoop()
    while Manager._dropRunning do
        if not RemotePrompt then
            Manager._dropRunning = false
            warn("[Manager] Auto Drop gagal: UIPromptEvent tidak ditemukan")
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
            -- Item ditemukan & jumlah cukup → LANGSUNG CONFIRM (skip popup!)
            -- Fire PlayerDrop dulu biar server siap
            pcall(function()
                RemoteDrop:FireServer(Manager.DROP_ITEM_ID)
            end)
            
            -- Kasih jeda sangat singkat agar server process PlayerDrop
            task.wait(0.05)
            
            -- Fire confirm
            pcall(function()
                RemotePrompt:FireServer({
                    ButtonAction = "drp",
                    Inputs = {
                        amt = tostring(Manager.DROP_AMOUNT)
                    }
                })
            end)
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

local function collectLoop()
    while Manager._collectRunning do
        local px, py = Coordinates.getGridPosition()
        if px then
            local r = Manager.COLLECT_RANGE
            for dx = -r, r do
                for dy = -r, r do
                    if not Manager._collectRunning then break end
                    if not RemoteFist or not RemotePlace then
                        Manager._collectRunning = false
                        break
                    end
                    local tx, ty = px + dx, py + dy
                    pcall(function() RemoteFist:FireServer(Vector2.new(tx, ty)) end)
                    task.wait(0.1)
                    pcall(function() RemotePlace:FireServer(Vector2.new(tx, ty), Manager.COLLECT_SAPLING_ID) end)
                    task.wait(Manager.COLLECT_DELAY)
                end
                if not Manager._collectRunning then break end
            end
        end
        task.wait(1)
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
    Manager._collectThread = task.spawn(collectLoop)
end

function Manager.stopCollect()
    Manager._collectRunning = false
end

function Manager.isCollectRunning()
    return Manager._collectRunning
end

return Manager
