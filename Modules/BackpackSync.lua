--[[
    BackpackSync.lua
    Core Module: Sinkronisasi data inventory dari hotbar UI

    Path: PlayerGui > InventoryUI > Handle > Frame > Hotbar > ImageButton[1-16] > AmountText
]]

local BackpackSync = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Cache
BackpackSync._slots = {}
BackpackSync._totalSlots = 16
BackpackSync._lastSync = 0
BackpackSync._syncInterval = 0.5
BackpackSync._hotbar = nil  -- cache hotbar reference

-- ═══════════════════════════════════════
-- INTERNAL: Cari InventoryScroll (data asli ada di sini)
-- Path: InventoryUI > Handle > Frame > Bottom > Frame > InventoryFrame > InventoryScroll
-- ═══════════════════════════════════════
local function findInventoryScroll()
    -- Kalau sudah di-cache dan masih valid, pakai cache
    if BackpackSync._hotbar and BackpackSync._hotbar.Parent then
        return BackpackSync._hotbar
    end
    
    local ok, scroll = pcall(function()
        local pg = player:WaitForChild("PlayerGui", 3)
        if not pg then return nil end
        local inv = pg:WaitForChild("InventoryUI", 3)
        if not inv then return nil end
        local handle = inv:WaitForChild("Handle", 3)
        if not handle then return nil end
        local frame = handle:WaitForChild("Frame", 3)
        if not frame then return nil end
        local bottom = frame:WaitForChild("Bottom", 3)
        if not bottom then return nil end
        local innerFrame = bottom:WaitForChild("Frame", 3)
        if not innerFrame then return nil end
        local invFrame = innerFrame:WaitForChild("InventoryFrame", 3)
        if not invFrame then return nil end
        local invScroll = invFrame:WaitForChild("InventoryScroll", 3)
        return invScroll
    end)
    
    if ok and scroll then
        BackpackSync._hotbar = scroll  -- cache it
        return scroll
    end
    return nil
end

-- ═══════════════════════════════════════
-- INTERNAL: Baca data dari 1 slot
-- ═══════════════════════════════════════
local function readSlot(hotbar, slotNumber)
    local slot = hotbar:FindFirstChild(tostring(slotNumber))
    if not slot then
        return { count = 0, hasItem = false }
    end
    
    -- AmountText ada di dalam ItemDisplay, bukan direct child
    -- Pakai recursive search (arg ke-2 = true)
    local amountLabel = slot:FindFirstChild("AmountText", true)
    
    local count = 0
    local hasItem = false
    
    if amountLabel then
        local text = amountLabel.Text or ""
        count = tonumber(text) or 0
        hasItem = (count > 0)
    end
    
    return { count = count, hasItem = hasItem }
end

-- ═══════════════════════════════════════
-- SYNC: Update semua slot
-- ═══════════════════════════════════════
function BackpackSync.sync()
    local hotbar = findInventoryScroll()
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

function BackpackSync.getSlotCount(slotNumber)
    if tick() - BackpackSync._lastSync > BackpackSync._syncInterval then
        BackpackSync.sync()
    end
    local slot = BackpackSync._slots[slotNumber]
    return slot and slot.count or 0
end

function BackpackSync.getAllSlots()
    if tick() - BackpackSync._lastSync > BackpackSync._syncInterval then
        BackpackSync.sync()
    end
    return BackpackSync._slots
end

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

function BackpackSync.hasEnough(slotNumber, amount)
    return BackpackSync.getSlotCount(slotNumber) >= amount
end

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

-- Initial sync (retry sampai ketemu)
task.spawn(function()
    for attempt = 1, 10 do
        if BackpackSync.sync() then
            break
        end
        task.wait(1)
    end
end)

return BackpackSync
