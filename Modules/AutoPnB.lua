--[[
    AutoPnB.lua
    Module: Auto Place and Break — Craft a World
    
    Siklus:
    1. Place blok di posisi target (PlayerPlaceItem)
    2. Punch blok di posisi target (PlayerFist)
    3. Ulangi
    
    Remote Path: ReplicatedStorage.Remotes
]]

local AutoPnB = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Antiban     -- akan di-inject via init()

-- Remote references (cache sekali aja)
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local RemotePlace = Remotes:WaitForChild("PlayerPlaceItem")
local RemoteFist  = Remotes:WaitForChild("PlayerFist")

-- ═══════════════════════════════════════
-- KONFIGURASI
-- ═══════════════════════════════════════

AutoPnB.ITEM_ID      = 2        -- Item ID (2 = Dirt Block)
AutoPnB.TARGET_X     = 0        -- Target grid X
AutoPnB.TARGET_Y     = 0        -- Target grid Y
AutoPnB.DELAY_PLACE  = 0.2      -- Jeda setelah place (detik)
AutoPnB.DELAY_BREAK  = 0.15     -- Jeda setelah punch
AutoPnB.DELAY_CYCLE  = 0.3      -- Jeda antar siklus

-- State
AutoPnB._running    = false
AutoPnB._cycleCount = 0
AutoPnB._statusText = "Idle"
AutoPnB._thread     = nil

-- ═══════════════════════════════════════
-- INTERNAL: Aksi ke Server
-- ═══════════════════════════════════════

--- Place blok di posisi target
local function doPlace(gridX, gridY, itemId)
    RemotePlace:FireServer(Vector2.new(gridX, gridY), itemId)
end

--- Punch blok di posisi target
local function doPunch(gridX, gridY)
    RemoteFist:FireServer(Vector2.new(gridX, gridY))
end

-- ═══════════════════════════════════════
-- QUEUE STEPS
-- ═══════════════════════════════════════

--- Step 1: Pasang blok
local function stepPlace(gridX, gridY, itemId)
    AutoPnB._statusText = "Memasang blok..."
    
    if Antiban then
        Antiban.throttle(function()
            doPlace(gridX, gridY, itemId)
        end)
    else
        doPlace(gridX, gridY, itemId)
    end
    
    task.wait(AutoPnB.DELAY_PLACE)
end

--- Step 2: Pukul/Punch blok
local function stepBreak(gridX, gridY)
    AutoPnB._statusText = "Memukul blok..."
    
    if Antiban then
        Antiban.throttle(function()
            doPunch(gridX, gridY)
        end)
    else
        doPunch(gridX, gridY)
    end
    
    task.wait(AutoPnB.DELAY_BREAK)
end

-- ═══════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════

local function pnbLoop()
    while AutoPnB._running do
        local gx = AutoPnB.TARGET_X
        local gy = AutoPnB.TARGET_Y
        local itemId = AutoPnB.ITEM_ID
        
        -- Siklus: Place → Punch
        stepPlace(gx, gy, itemId)
        if not AutoPnB._running then break end
        
        stepBreak(gx, gy)
        if not AutoPnB._running then break end
        
        AutoPnB._cycleCount = AutoPnB._cycleCount + 1
        AutoPnB._statusText = "Siklus #" .. AutoPnB._cycleCount .. " selesai"
        
        -- Jeda antar siklus
        task.wait(AutoPnB.DELAY_CYCLE)
    end
    
    AutoPnB._statusText = "Stopped"
end

-- ═══════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════

--- Inisialisasi module
function AutoPnB.init(antiban)
    Antiban = antiban
end

--- Set target posisi grid
function AutoPnB.setTarget(gridX, gridY)
    AutoPnB.TARGET_X = gridX
    AutoPnB.TARGET_Y = gridY
end

--- Set item ID yang mau di-place
function AutoPnB.setItemId(id)
    AutoPnB.ITEM_ID = id
end

--- Mulai Auto PnB
function AutoPnB.start()
    if AutoPnB._running then return end
    
    AutoPnB._running = true
    AutoPnB._cycleCount = 0
    AutoPnB._statusText = "Starting..."
    
    AutoPnB._thread = task.spawn(pnbLoop)
end

--- Stop Auto PnB
function AutoPnB.stop()
    AutoPnB._running = false
    AutoPnB._statusText = "Stopping..."
end

--- Cek apakah lagi jalan
function AutoPnB.isRunning()
    return AutoPnB._running
end

--- Status text untuk UI
function AutoPnB.getStatus()
    return AutoPnB._statusText
end

--- Jumlah siklus selesai
function AutoPnB.getCycleCount()
    return AutoPnB._cycleCount
end

--- Target saat ini
function AutoPnB.getTarget()
    return AutoPnB.TARGET_X, AutoPnB.TARGET_Y
end

return AutoPnB
