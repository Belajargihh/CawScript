--[[
    ManagerModule.lua
    Auto Drop & Auto Collect with Backpack Sync

    Inventory path: InventoryUI > Handle > Frame > Hotbar > ImageButton[slot] > AmountText
    Drop flow: check slot count → if count >= setting → PlayerDrop + UIPromptEvent
]]

local Manager = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Antiban
local Coordinates

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local Managers = game:GetService("ReplicatedStorage"):WaitForChild("Managers", 5)

local RemoteDrop, RemotePrompt, RemotePlace, RemoteFist

if Remotes then
    RemoteDrop  = Remotes:FindFirstChild("PlayerDrop")
    RemotePlace = Remotes:FindFirstChild("PlayerPlaceItem")
    RemoteFist  = Remotes:FindFirstChild("PlayerFist")
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
Manager.DROP_ITEM_ID    = 1   -- slot number (1-16)
Manager.DROP_AMOUNT     = 1   -- jumlah minimum baru drop
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
-- BACKPACK SYNC: Read item count from hotbar slot
-- Path: InventoryUI > Handle > Frame > Hotbar > ImageButton[slot] > AmountText
-- ═══════════════════════════════════════

function Manager.getSlotCount(slotNumber)
    local ok, count = pcall(function()
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then return 0 end
        local inv = pg:FindFirstChild("InventoryUI")
        if not inv then return 0 end
        local handle = inv:FindFirstChild("Handle")
        if not handle then return 0 end
        local frame = handle:FindFirstChild("Frame")
        if not frame then return 0 end
        local hotbar = frame:FindFirstChild("Hotbar")
        if not hotbar then return 0 end
        local slot = hotbar:FindFirstChild(tostring(slotNumber))
        if not slot then return 0 end
        local amountLabel = slot:FindFirstChild("AmountText")
        if not amountLabel then return 0 end
        local text = amountLabel.Text or ""
        return tonumber(text) or 0
    end)
    return ok and count or 0
end

-- ═══════════════════════════════════════
-- AUTO DROP LOOP
-- Cek jumlah dulu → baru drop kalau cukup
-- ═══════════════════════════════════════

local function dropLoop()
    while Manager._dropRunning do
        if not RemoteDrop or not RemotePrompt then
            Manager._dropRunning = false
            warn("[Manager] Auto Drop gagal: Remote tidak ditemukan")
            break
        end

        -- SYNC: cek jumlah item di slot
        local count = Manager.getSlotCount(Manager.DROP_ITEM_ID)

        if count >= Manager.DROP_AMOUNT then
            -- Jumlah cukup → drop!
            pcall(function()
                RemoteDrop:FireServer(Manager.DROP_ITEM_ID)
            end)
            -- Langsung confirm biar skip popup
            pcall(function()
                RemotePrompt:FireServer({
                    ButtonAction = "drp",
                    Inputs = {
                        amt = tostring(Manager.DROP_AMOUNT)
                    }
                })
            end)
        end
        -- Kalau count < DROP_AMOUNT → skip, tunggu, cek lagi

        task.wait(Manager.DROP_DELAY)
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

function Manager.init(coords, antiban)
    Coordinates = coords
    Antiban = antiban
end

function Manager.startDrop()
    if Manager._dropRunning then return end
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
