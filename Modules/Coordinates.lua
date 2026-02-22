--[[
    Coordinates.lua
    Module: World-to-Grid Coordinate Conversion
    
    Rumus (dari kalibrasi):
    Grid = round(WorldPos / 4.5)
    
    Contoh:
    WorldX=342.3 → 342.3/4.5 = 76.07 → round = 76
    WorldY=165.9 → 165.9/4.5 = 36.87 → round = 37
]]

local Coordinates = {}

-- ═══════════════════════════════════════
-- KONFIGURASI
-- ═══════════════════════════════════════
Coordinates.BLOCK_SIZE = 4.5   -- 1 blok = 4.5 studs

-- Cache
Coordinates._lastGridX = 0
Coordinates._lastGridY = 0

-- ═══════════════════════════════════════
-- FUNGSI UTAMA
-- ═══════════════════════════════════════

--- Konversi posisi dunia ke grid
function Coordinates.worldToGrid(worldX, worldY)
    local gridX = math.floor(worldX / Coordinates.BLOCK_SIZE + 0.5)
    local gridY = math.floor(worldY / Coordinates.BLOCK_SIZE + 0.5)
    
    Coordinates._lastGridX = gridX
    Coordinates._lastGridY = gridY
    
    return gridX, gridY
end

--- Ambil posisi grid dari karakter saat ini
function Coordinates.getGridPosition()
    local player = game.Players.LocalPlayer
    local char = player and player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if not hrp then
        return nil
    end
    
    local pos = hrp.Position
    return Coordinates.worldToGrid(pos.X, pos.Y)  -- X = horizontal, Y = vertikal (2D game)
end

--- Ambil posisi grid terakhir dari cache
function Coordinates.getLastPosition()
    return Coordinates._lastGridX, Coordinates._lastGridY
end

--- Format untuk tampilan UI
function Coordinates.formatDisplay(gridX, gridY)
    return string.format("X=%d  Y=%d", gridX, gridY)
end

return Coordinates
