--[[
    BackpackSync.lua
    Core Module: Sinkronisasi data inventory dari hotbar UI

    Path: InventoryUI > Handle > Frame > Hotbar > ImageButton[1-16] > AmountText
    
    Usage:
        BackpackSync.getSlotCount(1)         → 84
        BackpackSync.getAllSlots()            → {[1]={count=84,hasItem=true}, ...}
        BackpackSync.getTotalItems()         → total semua item
        BackpackSync.findSlotsWithItems()    → {1, 2, 3} (slot yg ada item)
]]

local BackpackSync = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Cache data
BackpackSync._slots = {}     -- {[slotNum] = {count=N, hasItem=bool}}
BackpackSync._totalSlots = 16
BackpackSync._lastSync = 0
BackpackSync._syncInterval = 0.5  -- sync setiap 0.5 detik
BackpackSync._running = false

-- ═══════════════════════════════════════
-- INTERNAL: Baca data dari 1 slot
-- ═══════════════════════════════════════
local function readSlot(hotbar, slotNumber)
    local slot = hotbar:FindFirstChild(tostring(slotNumber))
    if not slot then
        return { count = 0, hasItem = false }
    end
    
    local amountLabel = slot:FindFirstChild("AmountText")
    local itemDisplay = slot:FindFirstChild("ItemDisplay")
    
    local count = 0
    if amountLabel then
        count = tonumber(amountLabel.Text) or 0
    end
    
    -- Cek apakah slot ada item (dari ItemDisplay visibility/image)
    local hasItem = false
    if itemDisplay then
        hasItem = (itemDisplay.Image ~= nil and itemDisplay.Image ~= "")
    end
    
    -- Kalau count = 0 tapi ada image, berarti punya 1 item
    if hasItem and count == 0 then
        count = 1
    end
    
    return { count = count, hasItem = hasItem }
end

-- ═══════════════════════════════════════
-- INTERNAL: Cari Hotbar frame
-- ═══════════════════════════════════════
local function getHotbar()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local inv = pg:FindFirstChild("InventoryUI")
    if not inv then return nil end
    local handle = inv:FindFirstChild("Handle")
    if not handle then return nil end
    local frame = handle:FindFirstChild("Frame")
    if not frame then return nil end
    local hotbar = frame:FindFirstChild("Hotbar")
    return hotbar
end

-- ═══════════════════════════════════════
-- SYNC: Update semua slot data
-- ═══════════════════════════════════════
function BackpackSync.sync()
    local hotbar = getHotbar()
    if not hotbar then return false end
    
    for i = 1, BackpackSync._totalSlots do
        local ok, data = pcall(readSlot, hotbar, i)
        if ok then
            BackpackSync._slots[i] = data
        else
            BackpackSync._slots[i] = { count = 0, hasItem = false }
        end
    end
    
    BackpackSync._lastSync = tick()
    return true
end

-- ═══════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════

-- Ambil jumlah item di slot tertentu
function BackpackSync.getSlotCount(slotNumber)
    -- Auto sync kalau data sudah stale
    if tick() - BackpackSync._lastSync > BackpackSync._syncInterval then
        BackpackSync.sync()
    end
    local slot = BackpackSync._slots[slotNumber]
    return slot and slot.count or 0
end

-- Ambil data semua 16 slot
function BackpackSync.getAllSlots()
    if tick() - BackpackSync._lastSync > BackpackSync._syncInterval then
        BackpackSync.sync()
    end
    return BackpackSync._slots
end

-- Total semua item di inventory
function BackpackSync.getTotalItems()
    if tick() - BackpackSync._lastSync > BackpackSync._syncInterval then
        BackpackSync.sync()
    end
    local total = 0
    for _, slot in pairs(BackpackSync._slots) do
        total = total + slot.count
    end
    return total
end

-- Cari slot yang ada item-nya
function BackpackSync.findSlotsWithItems()
    if tick() - BackpackSync._lastSync > BackpackSync._syncInterval then
        BackpackSync.sync()
    end
    local found = {}
    for i = 1, BackpackSync._totalSlots do
        local slot = BackpackSync._slots[i]
        if slot and slot.hasItem then
            table.insert(found, i)
        end
    end
    return found
end

-- Cek apakah slot punya cukup item
function BackpackSync.hasEnough(slotNumber, amount)
    return BackpackSync.getSlotCount(slotNumber) >= amount
end

-- Info ringkas untuk UI
function BackpackSync.getSummary()
    if tick() - BackpackSync._lastSync > BackpackSync._syncInterval then
        BackpackSync.sync()
    end
    local used = 0
    local total = 0
    for i = 1, BackpackSync._totalSlots do
        local slot = BackpackSync._slots[i]
        if slot and slot.hasItem then
            used = used + 1
            total = total + slot.count
        end
    end
    return string.format("🎒 %d/%d slot | %d items", used, BackpackSync._totalSlots, total)
end

-- Initial sync
BackpackSync.sync()

return BackpackSync
