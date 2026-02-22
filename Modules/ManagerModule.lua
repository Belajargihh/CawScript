--[[
    ManagerModule.lua
    Module: Manager Features — Auto Drop & Auto Collect
]]

local Manager = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Antiban
local Coordinates

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local RemoteTrash, RemotePlace, RemoteFist

if Remotes then
    RemoteTrash = Remotes:WaitForChild("PlayerItemTrash", 2)
    RemotePlace = Remotes:WaitForChild("PlayerPlaceItem", 2)
    RemoteFist  = Remotes:WaitForChild("PlayerFist", 2)
end

-- ═══════════════════════════════════════
-- CONFIGURATION: AUTO DROP
-- ═══════════════════════════════════════
Manager.DROP_ITEM_ID    = 1
Manager.DROP_AMOUNT     = 1
Manager.DROP_DELAY      = 0.5
Manager._dropRunning    = false
Manager._dropThread     = nil

-- ═══════════════════════════════════════
-- CONFIGURATION: AUTO COLLECT (FARM)
-- ═══════════════════════════════════════
Manager.COLLECT_BLOCK_ID   = 1
Manager.COLLECT_SAPLING_ID = 1
Manager.COLLECT_RANGE      = 2  -- Radius in grids
Manager.COLLECT_DELAY      = 0.3
Manager._collectRunning    = false
Manager._collectThread     = nil

-- ═══════════════════════════════════════
-- INTERNAL LOOPS
-- ═══════════════════════════════════════

local function dropLoop()
    while Manager._dropRunning do
        if not RemoteTrash then 
            Manager._dropRunning = false
            warn("[Manager] Auto Drop gagal: RemoteTrash tidak ditemukan")
            break 
        end
        if Antiban then
            Antiban.throttle(function()
                RemoteTrash:FireServer(Manager.DROP_ITEM_ID, tostring(Manager.DROP_AMOUNT))
            end)
        else
            RemoteTrash:FireServer(Manager.DROP_ITEM_ID, tostring(Manager.DROP_AMOUNT))
        end
        task.wait(Manager.DROP_DELAY)
    end
end

local function collectLoop()
    -- This is more complex: find blocks in radius and interact
    -- For now, let's implement a simple sweep of the radius
    while Manager._collectRunning do
        local px, py = Coordinates.getGridPosition()
        if px then
            local r = Manager.COLLECT_RANGE
            for dx = -r, r do
                for dy = -r, r do
                    if not Manager._collectRunning then break end
                    
                    -- Simple logic: try to punch then place at every spot in range
                    -- (User might need a more sophisticated 'find block' check later)
                    local tx, ty = px + dx, py + dy
                    
                    if not RemoteFist or not RemotePlace then
                        Manager._collectRunning = false
                        warn("[Manager] Auto Collect gagal: Remote tidak lengkap")
                        break
                    end

                    if Antiban then
                        Antiban.throttle(function()
                            RemoteFist:FireServer(Vector2.new(tx, ty))
                        end)
                    else
                        RemoteFist:FireServer(Vector2.new(tx, ty))
                    end
                    task.wait(0.1)
                    
                    if Antiban then
                        Antiban.throttle(function()
                            RemotePlace:FireServer(Vector2.new(tx, ty), Manager.COLLECT_SAPLING_ID)
                        end)
                    else
                        RemotePlace:FireServer(Vector2.new(tx, ty), Manager.COLLECT_SAPLING_ID)
                    end
                    task.wait(Manager.COLLECT_DELAY)
                end
            end
        end
        task.wait(1)
    end
end

-- ═══════════════════════════════════════
-- PUBLIC API
-- ═══════════════════════════════════════

function Manager.init(coords, antiban)
    Coordinates = coords
    Antiban = antiban
end

-- Auto Drop Controls
function Manager.startDrop()
    if Manager._dropRunning then return end
    Manager._dropRunning = true
    Manager._dropThread = task.spawn(dropLoop)
end

function Manager.stopDrop()
    Manager._dropRunning = false
end

function Manager.isDropRunning()
    return Manager._dropRunning
end

-- Auto Collect Controls
function Manager.startCollect()
    if Manager._collectRunning then return end
    Manager._collectRunning = true
    Manager._collectThread = task.spawn(collectLoop)
end

function Manager.stopCollect()
    Manager._collectRunning = false
end

function Manager.isCollectRunning()
    return Manager._collectRunning
end

return Manager
