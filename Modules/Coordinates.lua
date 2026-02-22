--[[
    Coordinates.lua
    Module: World-to-Grid Transformation (Koziz Formula)
    
    Rumus Koordinat:
    GridX = clamp(floor(rawX / BLOCK_SIZE + 0.5) + OFFSET_X, 0, MAX_GRID)
    GridY = clamp(floor(rawY / BLOCK_SIZE + 0.5) + OFFSET_Y, 0, MAX_GRID)
]]

local Coordinates = {}

-- ═══════════════════════════════════════
-- KONFIGURASI (Hasil Kalibrasi)
-- ═══════════════════════════════════════
Coordinates.BLOCK_SIZE = 3.5      -- Lebar 1 blok dalam studs
Coordinates.OFFSET_X   = -4       -- Pergeseran horizontal origin
Coordinates.OFFSET_Y   = -10      -- Pergeseran vertikal origin
Coordinates.MIN_GRID   = 0        -- Batas minimum grid
Coordinates.MAX_GRID   = 100      -- Batas maksimum grid

-- Cache posisi terakhir
Coordinates._lastGridX = 0
Coordinates._lastGridY = 0
Coordinates._lastRawX  = 0
Coordinates._lastRawY  = 0

-- ═══════════════════════════════════════
-- FUNGSI UTAMA
-- ═══════════════════════════════════════

--- Konversi posisi dunia (studs) ke indeks grid
-- Menggunakan +0.5 sebelum floor untuk pembulatan ke blok terdekat
-- @param rawX number - Posisi X dari HumanoidRootPart
-- @param rawY number - Posisi Y dari HumanoidRootPart  
-- @return number gridX, number gridY
function Coordinates.worldToGrid(rawX, rawY)
    -- Step 1: Bagi dengan ukuran blok + rounding trick
    local normalX = math.floor(rawX / Coordinates.BLOCK_SIZE + 0.5)
    local normalY = math.floor(rawY / Coordinates.BLOCK_SIZE + 0.5)
    
    -- Step 2: Tambahkan offset origin
    local shiftedX = normalX + Coordinates.OFFSET_X
    local shiftedY = normalY + Coordinates.OFFSET_Y
    
    -- Step 3: Clamp ke rentang aman (0 - MAX_GRID)
    local gridX = math.clamp(shiftedX, Coordinates.MIN_GRID, Coordinates.MAX_GRID)
    local gridY = math.clamp(shiftedY, Coordinates.MIN_GRID, Coordinates.MAX_GRID)
    
    -- Cache hasil
    Coordinates._lastGridX = gridX
    Coordinates._lastGridY = gridY
    Coordinates._lastRawX  = rawX
    Coordinates._lastRawY  = rawY
    
    return gridX, gridY
end

--- Ambil posisi grid dari karakter saat ini
-- @return number gridX, number gridY | nil jika karakter tidak ditemukan
function Coordinates.getGridPosition()
    local player = game.Players.LocalPlayer
    local char = player and player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hrp then
        return nil
    end
    
    local pos = hrp.Position
    return Coordinates.worldToGrid(pos.X, pos.Z)  -- X = horizontal, Z = depth
end

--- Cek apakah koordinat grid masih dalam batas area valid
-- @param gridX number
-- @param gridY number
-- @return boolean
function Coordinates.isInBounds(gridX, gridY)
    return gridX >= Coordinates.MIN_GRID 
       and gridX <= Coordinates.MAX_GRID
       and gridY >= Coordinates.MIN_GRID 
       and gridY <= Coordinates.MAX_GRID
end

--- Ambil posisi grid terakhir dari cache (tanpa recalculate)
-- @return number gridX, number gridY
function Coordinates.getLastPosition()
    return Coordinates._lastGridX, Coordinates._lastGridY
end

--- Format koordinat jadi string untuk tampilan UI
-- @param gridX number
-- @param gridY number
-- @return string
function Coordinates.formatDisplay(gridX, gridY)
    return string.format("X=%d  Y=%d", gridX, gridY)
end

--- Hitung jarak grid antara dua titik (Manhattan distance)
-- @param x1 number
-- @param y1 number
-- @param x2 number
-- @param y2 number
-- @return number
function Coordinates.gridDistance(x1, y1, x2, y2)
    return math.abs(x2 - x1) + math.abs(y2 - y1)
end

return Coordinates
