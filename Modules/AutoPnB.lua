--[[
    AutoPnB.lua
    Module: Auto Place and Break — Multi-Target Grid System
    
    Siklus per target:
    1. Hitung posisi: playerGrid + offset
    2. Place blok (PlayerPlaceItem)
    3. Punch blok (PlayerFist)
    4. Lanjut ke target berikutnya
]]

local AutoPnB = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Antiban
local Coordinates

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local RemotePlace = Remotes and Remotes:WaitForChild("PlayerPlaceItem", 2)
local RemoteFist  = Remotes and Remotes:WaitForChild("PlayerFist", 2)

if not Remotes then
    warn("[AutoPnB] ERROR: Remotes folder not found!")
end

-- ═══════════════════════════════════════
-- KONFIGURASI
-- ═══════════════════════════════════════

AutoPnB.ITEM_ID      = 2       -- Item ID (2 = Dirt Block)
AutoPnB.DELAY_BREAK  = 0.15    -- Jeda setelah setiap aksi (150ms)
AutoPnB.ENABLE_PLACE = true     -- Toggle place ON/OFF
AutoPnB.ENABLE_BREAK = true     -- Toggle break ON/OFF

-- Multi-target: daftar offset {dx, dy} relatif dari posisi karakter
-- Contoh: {{1,0}, {-1,0}, {0,1}} = kanan, kiri, atas
AutoPnB._targets = {}

-- State
AutoPnB._running    = false
AutoPnB._cycleCount = 0
AutoPnB._statusText = "Idle"
AutoPnB._currentTarget = ""
AutoPnB._thread     = nil

-- ═══════════════════════════════════════
-- INTERNAL
-- ═══════════════════════════════════════

    if not RemotePlace then return end
    RemotePlace:FireServer(Vector2.new(gridX, gridY), itemId)
end

local function doPunch(gridX, gridY)
    if not RemoteFist then return end
    RemoteFist:FireServer(Vector2.new(gridX, gridY))
end

-- ═══════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════

local function pnbLoop()
    while AutoPnB._running do
        -- Cek ada target aktif
        if #AutoPnB._targets == 0 then
            AutoPnB._statusText = "Tidak ada target aktif!"
            task.wait(1)
            if not AutoPnB._running then break end
            -- Keep checking
        else
            -- Ambil posisi karakter saat ini
            local playerX, playerY = Coordinates.getGridPosition()
            
            if not playerX then
                AutoPnB._statusText = "Karakter tidak ditemukan"
                task.wait(0.5)
            else
                -- Cek minimal 1 mode aktif
                if not AutoPnB.ENABLE_PLACE and not AutoPnB.ENABLE_BREAK then
                    AutoPnB._statusText = "Place & Break OFF!"
                    task.wait(1)
                else
                    -- Loop semua target
                    for _, offset in ipairs(AutoPnB._targets) do
                        if not AutoPnB._running then break end
                        
                        local targetX = playerX + offset[1]
                        local targetY = playerY + offset[2]
                        
                        AutoPnB._currentTarget = "X=" .. targetX .. " Y=" .. targetY
                        
                        -- Place (jika aktif)
                        if AutoPnB.ENABLE_PLACE then
                            AutoPnB._statusText = "Place di " .. AutoPnB._currentTarget
                            if Antiban then
                                Antiban.throttle(function()
                                    doPlace(targetX, targetY, AutoPnB.ITEM_ID)
                                end)
                            else
                                doPlace(targetX, targetY, AutoPnB.ITEM_ID)
                            end
                            task.wait(AutoPnB.DELAY_BREAK)
                            if not AutoPnB._running then break end
                        end
                        
                        -- Punch / Break (jika aktif)
                        if AutoPnB.ENABLE_BREAK then
                            AutoPnB._statusText = "Punch di " .. AutoPnB._currentTarget
                            if Antiban then
                                Antiban.throttle(function()
                                    doPunch(targetX, targetY)
                                end)
                            else
                                doPunch(targetX, targetY)
                            end
                            task.wait(AutoPnB.DELAY_BREAK)
                        end
                    end
                end
                
                if AutoPnB._running then
                    AutoPnB._cycleCount = AutoPnB._cycleCount + 1
                    AutoPnB._statusText = "Siklus #" .. AutoPnB._cycleCount
                    task.wait(AutoPnB.DELAY_BREAK)
                end
            end
        end
    end
    
    AutoPnB._statusText = "Stopped"
end

-- ═══════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════

function AutoPnB.init(coords, antiban)
    Coordinates = coords
    Antiban = antiban
end

--- Set targets dari grid (array of {dx, dy})
function AutoPnB.setTargets(targets)
    AutoPnB._targets = targets
end

--- Tambah 1 target offset
function AutoPnB.addTarget(dx, dy)
    table.insert(AutoPnB._targets, {dx, dy})
end

--- Hapus 1 target offset
function AutoPnB.removeTarget(dx, dy)
    for i, t in ipairs(AutoPnB._targets) do
        if t[1] == dx and t[2] == dy then
            table.remove(AutoPnB._targets, i)
            return true
        end
    end
    return false
end

--- Cek apakah offset tertentu aktif
function AutoPnB.hasTarget(dx, dy)
    for _, t in ipairs(AutoPnB._targets) do
        if t[1] == dx and t[2] == dy then
            return true
        end
    end
    return false
end

--- Clear semua target
function AutoPnB.clearTargets()
    AutoPnB._targets = {}
end

function AutoPnB.start()
    if AutoPnB._running then return end
    AutoPnB._running = true
    AutoPnB._cycleCount = 0
    AutoPnB._statusText = "Starting..."
    AutoPnB._thread = task.spawn(pnbLoop)
end

function AutoPnB.stop()
    AutoPnB._running = false
    AutoPnB._statusText = "Stopping..."
end

function AutoPnB.isRunning()
    return AutoPnB._running
end

function AutoPnB.getStatus()
    return AutoPnB._statusText
end

function AutoPnB.getCycleCount()
    return AutoPnB._cycleCount
end

function AutoPnB.getTargetCount()
    return #AutoPnB._targets
end

return AutoPnB
