--[[
    BackpackSync.lua
    Core Module: Sinkronisasi data inventory dari InventoryScroll

    Path: InventoryUI > Handle > (recursive) > InventoryScroll > ImageButton[1-16]
    Per slot: AmountText (qty), ItemDisplay (image = item ID)
]]

local BackpackSync = {}

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Cache
BackpackSync._slots = {}
BackpackSync._totalSlots = 16
BackpackSync._lastSync = 0
BackpackSync._syncInterval = 0.5
BackpackSync._scroll = nil  -- cached InventoryScroll reference

-- ═══════════════════════════════════════
-- INTERNAL: Cari InventoryScroll (recursive, anti gagal)
-- ═══════════════════════════════════════
local function findScroll()
    if BackpackSync._scroll and BackpackSync._scroll.Parent then
        return BackpackSync._scroll
    end
    
    local ok, scroll = pcall(function()
        local pg = player:WaitForChild("PlayerGui", 3)
        if not pg then return nil end
        local inv = pg:WaitForChild("InventoryUI", 3)
        if not inv then return nil end
        local handle = inv:WaitForChild("Handle", 3)
        if not handle then return nil end
        -- Recursive search — nggak peduli path-nya gimana
        return handle:FindFirstChild("InventoryScroll", true)
    end)
    
    if ok and scroll then
        BackpackSync._scroll = scroll
        return scroll
    end
    return nil
end

-- ═══════════════════════════════════════
-- INTERNAL: Baca data dari 1 slot
-- ═══════════════════════════════════════
local function readSlot(scroll, slotNumber)
    local slot = scroll:FindFirstChild(tostring(slotNumber))
    if not slot then
        return { count = 0, hasItem = false, imageId = "" }
    end
    
    local amountLabel = slot:FindFirstChild("AmountText", true)
    local itemDisplay = slot:FindFirstChild("ItemDisplay", true)
    
    local count = 0
    local hasItem = false
    local imageId = ""
    
    if amountLabel then
        local text = amountLabel.Text or ""
        count = tonumber(text) or 0
        hasItem = (count > 0)
    end
    
    if itemDisplay then
        imageId = itemDisplay.Image or ""
        -- Kalau ada image tapi count 0, berarti punya minimal 1
        if imageId ~= "" and imageId ~= "rbxassetid://0" and not hasItem then
            count = 1
            hasItem = true
        end
    end
    
    return { count = count, hasItem = hasItem, imageId = imageId }
end

-- ═══════════════════════════════════════
-- SYNC: Update semua slot
-- ═══════════════════════════════════════
function BackpackSync.sync()
    local scroll = findScroll()
    if not scroll then return false end
    
    for i = 1, BackpackSync._totalSlots do
        local ok, data = pcall(readSlot, scroll, i)
        if ok then
            BackpackSync._slots[i] = data
        else
            BackpackSync._slots[i] = { count = 0, hasItem = false, imageId = "" }
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

function BackpackSync.getSlotInfo(slotNumber)
    if tick() - BackpackSync._lastSync > BackpackSync._syncInterval then
        BackpackSync.sync()
    end
    return BackpackSync._slots[slotNumber] or { count = 0, hasItem = false, imageId = "" }
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
