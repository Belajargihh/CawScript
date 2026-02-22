--[[
    Antiban.lua
    Module: Rate Limiter & Safety Checks
    
    Mencegah kick/ban dari server karena aksi terlalu cepat.
    Mengontrol jumlah request per detik dan menambahkan jeda acak.
]]

local Antiban = {}

-- ═══════════════════════════════════════
-- KONFIGURASI
-- ═══════════════════════════════════════
Antiban.MIN_DELAY       = 0.12   -- Jeda minimum antar aksi (detik)
Antiban.MAX_DELAY       = 0.25   -- Jeda maksimum antar aksi
Antiban.MAX_ACTIONS_SEC = 8      -- Maksimum aksi per detik sebelum auto-pause
Antiban.PAUSE_DURATION  = 1.5    -- Durasi auto-pause saat threshold terlampaui (detik)
Antiban.HUMAN_JITTER    = true   -- Tambahkan variasi acak agar terlihat manusia

-- State Internal
Antiban._actionCount    = 0
Antiban._lastActionTime = 0
Antiban._lastResetTime  = tick()
Antiban._isPaused       = false
Antiban._totalThrottled = 0

-- ═══════════════════════════════════════
-- INTERNAL
-- ═══════════════════════════════════════

--- Hitung jeda acak antara MIN dan MAX delay
local function getRandomDelay()
    if Antiban.HUMAN_JITTER then
        return Antiban.MIN_DELAY + math.random() * (Antiban.MAX_DELAY - Antiban.MIN_DELAY)
    else
        return Antiban.MIN_DELAY
    end
end

--- Reset counter aksi setiap detik
local function checkAndResetCounter()
    local now = tick()
    if now - Antiban._lastResetTime >= 1.0 then
        Antiban._actionCount = 0
        Antiban._lastResetTime = now
    end
end

--- Cek apakah sudah melampaui batas aksi per detik
local function isOverThreshold()
    return Antiban._actionCount >= Antiban.MAX_ACTIONS_SEC
end

-- ═══════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════

--- Eksekusi callback dengan throttling
-- Menambahkan jeda dan memeriksa rate limit sebelum menjalankan aksi
-- @param callback function - Fungsi yang akan dijalankan
function Antiban.throttle(callback)
    checkAndResetCounter()
    
    -- Auto-pause jika terlalu banyak aksi
    if isOverThreshold() then
        Antiban._isPaused = true
        Antiban._totalThrottled = Antiban._totalThrottled + 1
        warn("[Antiban] Threshold terlampaui! Auto-pause " .. Antiban.PAUSE_DURATION .. "s")
        task.wait(Antiban.PAUSE_DURATION)
        Antiban._isPaused = false
        Antiban._actionCount = 0
    end
    
    -- Tambahkan jeda antar aksi
    local delay = getRandomDelay()
    local elapsed = tick() - Antiban._lastActionTime
    if elapsed < delay then
        task.wait(delay - elapsed)
    end
    
    -- Jalankan aksi
    Antiban._actionCount = Antiban._actionCount + 1
    Antiban._lastActionTime = tick()
    
    if callback then
        callback()
    end
end

--- Reset semua counter
function Antiban.resetCounter()
    Antiban._actionCount = 0
    Antiban._lastResetTime = tick()
    Antiban._totalThrottled = 0
    Antiban._isPaused = false
end

--- Cek apakah sedang dalam mode pause
-- @return boolean
function Antiban.isPaused()
    return Antiban._isPaused
end

--- Ambil jumlah total throttle yang terjadi
-- @return number
function Antiban.getThrottleCount()
    return Antiban._totalThrottled
end

--- Ambil jumlah aksi saat ini dalam 1 detik terakhir
-- @return number
function Antiban.getCurrentRate()
    checkAndResetCounter()
    return Antiban._actionCount
end

--- Set konfigurasi delay
-- @param minDelay number
-- @param maxDelay number
-- @param maxPerSec number
function Antiban.configure(minDelay, maxDelay, maxPerSec)
    Antiban.MIN_DELAY = minDelay or Antiban.MIN_DELAY
    Antiban.MAX_DELAY = maxDelay or Antiban.MAX_DELAY
    Antiban.MAX_ACTIONS_SEC = maxPerSec or Antiban.MAX_ACTIONS_SEC
end

return Antiban
