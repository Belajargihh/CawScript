--[[
    AutoPnB.lua
    Module: Auto Place and Break — Multi-Target Grid System
    
    Siklus per target:
    1. Hitung posisi: playerGrid + offset
    2. Place blok (PlayerPlaceItem)
    3. Punch blok (PlayerFist)
    4. Collect drops (if enabled)
    5. Lanjut ke target berikutnya
]]

local AutoPnB = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Antiban
local Coordinates
local _log = nil

local function log(msg)
    if _log then _log(msg) end
    print("[AutoPnB] " .. tostring(msg))
end

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local RemotePlace = Remotes and Remotes:WaitForChild("PlayerPlaceItem", 2)
local RemoteFist  = Remotes and Remotes:WaitForChild("PlayerFist", 2)

if not Remotes then
    warn("[AutoPnB] ERROR: Remotes folder not found!")
end

-- ═══════════════════════════════════════
-- KONFIGURASI
-- ═══════════════════════════════════════

AutoPnB.ITEM_ID       = 2       -- Item ID (2 = Dirt Block)
AutoPnB.DELAY_BREAK   = 0.15    -- Jeda setelah setiap aksi (150ms)
AutoPnB.ENABLE_PLACE  = true    -- Toggle place ON/OFF
AutoPnB.ENABLE_BREAK  = true    -- Toggle break ON/OFF
AutoPnB.ENABLE_COLLECT = false   -- Toggle auto-collect ON/OFF
AutoPnB.COLLECT_DELAY  = 0.05   -- Delay per teleport step

-- Multi-target: daftar offset {dx, dy} relatif dari posisi karakter
-- Contoh: {{1,0}, {-1,0}, {0,1}} = kanan, kiri, atas
AutoPnB._targets = {}

-- State
AutoPnB._running      = false
AutoPnB._cycleCount   = 0
AutoPnB._collectCount = 0
AutoPnB._statusText   = "Idle"
AutoPnB._currentTarget = ""
AutoPnB._thread       = nil

-- ═══════════════════════════════════════
-- INTERNAL
-- ═══════════════════════════════════════

local function doPlace(gridX, gridY, itemId)
    if not RemotePlace then return end
    RemotePlace:FireServer(Vector2.new(gridX, gridY), itemId)
end

local function doPunch(gridX, gridY)
    if not RemoteFist then return end
    RemoteFist:FireServer(Vector2.new(gridX, gridY))
end

local BLOCK_SIZE = 4.5

-- Fast access to movement packets
local function getMoveRemote()
    local folder = Remotes and Remotes:FindFirstChild("PlayerMovementPackets")
    if folder then
        -- Returns the first child (dynamic name like Hans_123920)
        return folder:GetChildren()[1]
    end
end

-- Helper: Walk to a position and wait
local function walkTo(position, timeout)
    local player = game:GetService("Players").LocalPlayer
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    
    -- Force character to be movable
    hum.PlatformStand = false
    hum.Sit = false
    
    -- In side-scroller, we walk mostly horizontally (X) and vertically (Y)
    local walkPos = Vector3.new(position.X, position.Y, hrp.Position.Z)
    local remote = getMoveRemote()
    
    hum:MoveTo(walkPos)
    
    local finished = false
    local connection = hum.MoveToFinished:Connect(function()
        finished = true
    end)
    
    local start = tick()
    local lastDist = (hrp.Position - walkPos).Magnitude
    local stuckTick = 0
    local lastPacket = 0
    
    while not finished and tick() - start < (timeout or 2) do
        task.wait(0.05)
        if not AutoPnB._running then break end
        
        -- Fire movement packet to sync with server (Anti-Damage)
        if remote and tick() - lastPacket > 0.1 then
            remote:FireServer(Vector2.new(hrp.Position.X, hrp.Position.Y))
            lastPacket = tick()
        end
        
        local currentDist = (hrp.Position - walkPos).Magnitude
        
        -- Proximity Check (Arrived early)
        if currentDist < 2.5 then
            finished = true
            break
        end
        
        -- Stuck Check
        if math.abs(currentDist - lastDist) < 0.1 then
            stuckTick = stuckTick + 1
            if stuckTick > 5 then
                hum.Jump = true
                stuckTick = 0
            end
        else
            stuckTick = 0
        end
        lastDist = currentDist
    end
    
    if connection then connection:Disconnect() end
end

-- Collect drops near target grid positions, then return to origin
local function collectNearbyDrops(originPos, targetGridPositions)
    if not AutoPnB.ENABLE_COLLECT then return end
    
    local player = game:GetService("Players").LocalPlayer
    local char = player and player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local dropsFolder = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Items")
    if not dropsFolder then 
        log("No Drops/Items folder found.")
        return 
    end
    
    local toCollect = {}
    local allItems = dropsFolder:GetDescendants()
    
    -- Scan for items
    for _, item in ipairs(allItems) do
        if item:IsA("BasePart") or item:IsA("Model") then
            -- Only consider things that look like drops (have an ID or are small)
            local isDrop = item:GetAttribute("id") or item:GetAttribute("ItemId")
            if not isDrop then
                -- Heuristic: drops are usually small and not anchored
                if item:IsA("BasePart") and item.Size.Magnitude < 10 and not item.Anchored then
                    isDrop = true
                end
            end

            if isDrop then
                local ok, pos = pcall(function() return item:GetPivot().Position end)
                if ok and pos then
                    -- Check if drop is near any target grid position
                    for _, gpos in ipairs(targetGridPositions) do
                        local projX = gpos[1] * BLOCK_SIZE
                        local projY = gpos[2] * BLOCK_SIZE
                        local dx = math.abs(pos.X - projX)
                        local dy = math.abs(pos.Y - projY)
                        
                        -- Detect items within 4 block radius of target grid (XY PLANE)
                        if dx < BLOCK_SIZE * 4 and dy < BLOCK_SIZE * 4 then
                            table.insert(toCollect, {item = item, pos = pos})
                            break
                        end
                    end
                end
            end
        end
    end
    
    if #toCollect == 0 then 
        return 
    end
    
    log("Found " .. #toCollect .. " items. Collecting...")
    AutoPnB._statusText = "Walking to " .. #toCollect .. " drops..."
    
    for _, data in ipairs(toCollect) do
        if not AutoPnB._running then break end
        if not data.item.Parent then continue end
        
        walkTo(data.pos, 1.5)
        AutoPnB._collectCount = AutoPnB._collectCount + 1
        task.wait(0.05)
    end
    
    -- Return to starting position
    if AutoPnB._running then
        log("Returning to origin.")
        AutoPnB._statusText = "Returning to origin..."
        walkTo(originPos, 2)
    end
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
            continue
        end
        
        -- Ambil posisi player saat ini sebagai center
        local playerX, playerY = Coordinates.getGridPosition()
        if not playerX then 
            task.wait(1) 
            continue 
        end
        
        local hrp = game:GetService("Players").LocalPlayer.Character and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1) continue end
        local originPos = hrp.Position
        
        -- 1. PROCESS ALL TARGETS
        local activeGridPositions = {}
        for _, offset in ipairs(AutoPnB._targets) do
            if not AutoPnB._running then break end
            
            local targetX = playerX + offset[1]
            local targetY = playerY + offset[2]
            table.insert(activeGridPositions, {targetX, targetY})
            
            AutoPnB._currentTarget = string.format("X=%d, Y=%d", targetX, targetY)
            
            -- Place (jika aktif)
            if AutoPnB.ENABLE_PLACE then
                AutoPnB._statusText = "Placing..."
                log("Place at " .. AutoPnB._currentTarget)
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
                AutoPnB._statusText = "Breaking..."
                log("Break at " .. AutoPnB._currentTarget)
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
        
        -- 2. ALL TARGETS FINISHED -> COLLECT
        if AutoPnB._running and AutoPnB.ENABLE_COLLECT then
            collectNearbyDrops(originPos, activeGridPositions)
        end
        
        AutoPnB._cycleCount = AutoPnB._cycleCount + 1
        task.wait(0.1)
    end
    
    AutoPnB._thread = nil
    AutoPnB._statusText = "Stopped"
end

-- ═══════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════

function AutoPnB.init(coords, antiban, logFunc)
    Coordinates = coords
    Antiban = antiban
    _log = logFunc
    log("AutoPnB Module initialized.")
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
    -- Reset PlatformStand in case it was left on
    pcall(function()
        local char = game:GetService("Players").LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = false end
        end
    end)
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

function AutoPnB.getCollectCount()
    return AutoPnB._collectCount
end

return AutoPnB
