--[[
    AutoPnB.lua
    Module: Auto Place and Break — Queue System
    
    Logika Antrian:
    1. Pasang Blok (Place)
    2. Pukul Blok (Break)  
    3. Ambil Drop (Collect)
    
    Semua aksi dikirim via FireServer ke RemoteEvent game.
]]

local AutoPnB = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Coordinates -- akan di-inject via init()
local Antiban     -- akan di-inject via init()

-- ═══════════════════════════════════════
-- KONFIGURASI
-- ═══════════════════════════════════════

-- ⚠️ GANTI NAMA REMOTE INI SESUAI GAME KAMU (pakai Remote Spy)
AutoPnB.REMOTE_PLACE = "PlaceBlock"     -- Nama RemoteEvent untuk pasang blok
AutoPnB.REMOTE_BREAK = "BreakBlock"     -- Nama RemoteEvent untuk pukul blok
AutoPnB.REMOTE_COLLECT = "CollectDrop"  -- Nama RemoteEvent untuk ambil item

AutoPnB.DELAY_PLACE   = 0.2    -- Jeda setelah pasang blok (detik)
AutoPnB.DELAY_BREAK   = 0.15   -- Jeda setelah pukul blok
AutoPnB.DELAY_COLLECT  = 0.1   -- Jeda setelah ambil drop
AutoPnB.DELAY_CYCLE    = 0.3   -- Jeda antar siklus penuh

-- State
AutoPnB._running    = false
AutoPnB._targetX    = 0
AutoPnB._targetY    = 0
AutoPnB._cycleCount = 0
AutoPnB._statusText = "Idle"
AutoPnB._thread     = nil

-- ═══════════════════════════════════════
-- INTERNAL: Kirim Remote ke Server
-- ═══════════════════════════════════════

local function getRemote(remoteName)
    -- Cari RemoteEvent di ReplicatedStorage atau workspace
    local remote = game:GetService("ReplicatedStorage"):FindFirstChild(remoteName)
    if not remote then
        remote = workspace:FindFirstChild(remoteName)
    end
    return remote
end

local function fireRemote(remoteName, ...)
    local remote = getRemote(remoteName)
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(...)
        return true
    else
        warn("[AutoPnB] Remote tidak ditemukan: " .. remoteName)
        return false
    end
end

-- ═══════════════════════════════════════
-- QUEUE STEPS
-- ═══════════════════════════════════════

--- Step 1: Pasang blok di koordinat target
local function stepPlace(gridX, gridY)
    AutoPnB._statusText = "Memasang blok..."
    
    if Antiban then
        Antiban.throttle(function()
            fireRemote(AutoPnB.REMOTE_PLACE, gridX, gridY)
        end)
    else
        fireRemote(AutoPnB.REMOTE_PLACE, gridX, gridY)
    end
    
    task.wait(AutoPnB.DELAY_PLACE)
end

--- Step 2: Pukul blok di koordinat target
local function stepBreak(gridX, gridY)
    AutoPnB._statusText = "Memukul blok..."
    
    if Antiban then
        Antiban.throttle(function()
            fireRemote(AutoPnB.REMOTE_BREAK, gridX, gridY)
        end)
    else
        fireRemote(AutoPnB.REMOTE_BREAK, gridX, gridY)
    end
    
    task.wait(AutoPnB.DELAY_BREAK)
end

--- Step 3: Ambil drop dari blok yang dipecah
local function stepCollect(gridX, gridY)
    AutoPnB._statusText = "Mengambil drop..."
    
    if Antiban then
        Antiban.throttle(function()
            fireRemote(AutoPnB.REMOTE_COLLECT, gridX, gridY)
        end)
    else
        fireRemote(AutoPnB.REMOTE_COLLECT, gridX, gridY)
    end
    
    task.wait(AutoPnB.DELAY_COLLECT)
end

-- ═══════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════

local function pnbLoop()
    while AutoPnB._running do
        -- Ambil posisi grid terbaru dari karakter
        local gridX, gridY = Coordinates.getGridPosition()
        
        if gridX then
            -- Update target ke posisi saat ini
            AutoPnB._targetX = gridX
            AutoPnB._targetY = gridY
            
            -- Pastikan posisi valid
            if Coordinates.isInBounds(gridX, gridY) then
                -- Jalankan antrian: Place → Break → Collect
                stepPlace(gridX, gridY)
                if not AutoPnB._running then break end
                
                stepBreak(gridX, gridY)
                if not AutoPnB._running then break end
                
                stepCollect(gridX, gridY)
                if not AutoPnB._running then break end
                
                AutoPnB._cycleCount = AutoPnB._cycleCount + 1
                AutoPnB._statusText = "Siklus #" .. AutoPnB._cycleCount .. " selesai"
            else
                AutoPnB._statusText = "Di luar area valid!"
            end
        else
            AutoPnB._statusText = "Karakter tidak ditemukan"
        end
        
        -- Jeda antar siklus
        task.wait(AutoPnB.DELAY_CYCLE)
    end
    
    AutoPnB._statusText = "Stopped"
end

-- ═══════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════

--- Inisialisasi module dengan dependencies
-- @param coords table - Module Coordinates
-- @param antiban table|nil - Module Antiban (opsional)
function AutoPnB.init(coords, antiban)
    Coordinates = coords
    Antiban = antiban
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

--- Cek apakah Auto PnB sedang jalan
-- @return boolean
function AutoPnB.isRunning()
    return AutoPnB._running
end

--- Ambil status text untuk ditampilkan di UI
-- @return string
function AutoPnB.getStatus()
    return AutoPnB._statusText
end

--- Ambil jumlah siklus yang sudah selesai
-- @return number
function AutoPnB.getCycleCount()
    return AutoPnB._cycleCount
end

--- Ambil target koordinat saat ini
-- @return number targetX, number targetY
function AutoPnB.getTarget()
    return AutoPnB._targetX, AutoPnB._targetY
end

--- Set delay untuk setiap step
-- @param place number
-- @param breakDelay number
-- @param collect number
-- @param cycle number
function AutoPnB.setDelays(place, breakDelay, collect, cycle)
    AutoPnB.DELAY_PLACE   = place or AutoPnB.DELAY_PLACE
    AutoPnB.DELAY_BREAK   = breakDelay or AutoPnB.DELAY_BREAK
    AutoPnB.DELAY_COLLECT = collect or AutoPnB.DELAY_COLLECT
    AutoPnB.DELAY_CYCLE   = cycle or AutoPnB.DELAY_CYCLE
end

return AutoPnB
