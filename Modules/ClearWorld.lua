--[[
    ClearWorld.lua
    Module: Automate breaking all blocks in the world
]]

local ClearWorld = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Antiban

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local RemoteFist = Remotes and Remotes:WaitForChild("PlayerFist", 2)

if not Remotes then
    warn("[ClearWorld] ERROR: Remotes folder not found!")
end


-- ═══════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════
ClearWorld.MAX_X = 100
ClearWorld.MAX_Y = 60
ClearWorld.DELAY = 0.12 -- Slightly faster than PnB but safe

-- State
ClearWorld._running = false
ClearWorld._currentX = 0
ClearWorld._currentY = 0
ClearWorld._thread = nil
ClearWorld._statusText = "Ready"

-- ═══════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════

local function clearLoop()
    -- Scan from top to bottom (Y descending usually better for visual)
    for y = ClearWorld.MAX_Y, 0, -1 do
        ClearWorld._currentY = y
        for x = 0, ClearWorld.MAX_X do
            if not ClearWorld._running then return end
            
            ClearWorld._currentX = x
            ClearWorld._statusText = string.format("Clearing: X=%d Y=%d", x, y)
            
            pcall(function()
                if Antiban then
                    Antiban.throttle(function()
                        RemoteFist:FireServer(Vector2.new(x, y))
                    end)
                else
                    RemoteFist:FireServer(Vector2.new(x, y))
                end
            end)
            
            task.wait(ClearWorld.DELAY)
        end
    end
    
    ClearWorld._running = false
    ClearWorld._statusText = "Completed!"
end

-- ═══════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════

function ClearWorld.init(antiban)
    Antiban = antiban
end

function ClearWorld.start()
    if ClearWorld._running then return end
    ClearWorld._running = true
    ClearWorld._statusText = "Starting..."
    ClearWorld._thread = task.spawn(clearLoop)
end

function ClearWorld.stop()
    ClearWorld._running = false
    ClearWorld._statusText = "Stopped"
end

function ClearWorld.isRunning()
    return ClearWorld._running
end

function ClearWorld.getProgress()
    if not ClearWorld._running and ClearWorld._statusText ~= "Completed!" then return 0 end
    if ClearWorld._statusText == "Completed!" then return 100 end
    
    local totalCells = (ClearWorld.MAX_X + 1) * (ClearWorld.MAX_Y + 1)
    -- Y desc, X asc logic:
    local rowsCompleted = (ClearWorld.MAX_Y - ClearWorld._currentY)
    local cellsCompleted = (rowsCompleted * (ClearWorld.MAX_X + 1)) + (ClearWorld._currentX + 1)
    
    return math.floor((cellsCompleted / totalCells) * 100)
end

function ClearWorld.getStatus()
    return ClearWorld._statusText
end

return ClearWorld
