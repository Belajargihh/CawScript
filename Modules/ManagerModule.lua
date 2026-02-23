--[[
    ManagerModule.lua
    Module: Manager Features — Auto Drop & Auto Collect

    Auto Drop Flow (skip popup):
    1. PlayerDrop:FireServer(itemId)
    2. UIPromptEvent:FireServer({ButtonAction = "drp", Inputs = {amt = "N"}})
]]

local Manager = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Antiban
local Coordinates

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)
local Managers = game:GetService("ReplicatedStorage"):WaitForChild("Managers", 5)

local RemoteDrop, RemotePrompt, RemotePlace, RemoteFist

if Remotes then
    RemoteDrop  = Remotes:FindFirstChild("PlayerDrop")
    RemotePlace = Remotes:FindFirstChild("PlayerPlaceItem")
    RemoteFist  = Remotes:FindFirstChild("PlayerFist")
end

if Managers then
    local UIManager = Managers:FindFirstChild("UIManager")
    if UIManager then
        RemotePrompt = UIManager:FindFirstChild("UIPromptEvent")
    end
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
Manager.COLLECT_RANGE      = 2
Manager.COLLECT_DELAY      = 0.3
Manager._collectRunning    = false
Manager._collectThread     = nil

-- ═══════════════════════════════════════
-- AUTO DROP LOOP
-- Skip popup: fire PlayerDrop lalu langsung confirm via UIPromptEvent
-- ═══════════════════════════════════════

local function dropLoop()
    while Manager._dropRunning do
        if not RemoteDrop or not RemotePrompt then
            Manager._dropRunning = false
            warn("[Manager] Auto Drop gagal: Remote tidak ditemukan")
            break
        end

        -- Step 1: Fire PlayerDrop dengan item ID
        pcall(function()
            RemoteDrop:FireServer(Manager.DROP_ITEM_ID)
        end)
        task.wait(0.15)

        -- Step 2: Langsung confirm jumlah via UIPromptEvent (skip popup)
        pcall(function()
            RemotePrompt:FireServer({
                ButtonAction = "drp",
                Inputs = {
                    amt = tostring(Manager.DROP_AMOUNT)
                }
            })
        end)

        task.wait(Manager.DROP_DELAY)
    end
end

-- ═══════════════════════════════════════
-- AUTO COLLECT LOOP
-- Punch blocks in radius, then place sapling
-- ═══════════════════════════════════════

local function collectLoop()
    while Manager._collectRunning do
        local px, py = Coordinates.getGridPosition()
        if px then
            local r = Manager.COLLECT_RANGE
            for dx = -r, r do
                for dy = -r, r do
                    if not Manager._collectRunning then break end
                    if not RemoteFist or not RemotePlace then
                        Manager._collectRunning = false
                        warn("[Manager] Auto Collect gagal: Remote tidak lengkap")
                        break
                    end

                    local tx, ty = px + dx, py + dy

                    -- Punch block
                    pcall(function()
                        RemoteFist:FireServer(Vector2.new(tx, ty))
                    end)
                    task.wait(0.1)

                    -- Place sapling
                    pcall(function()
                        RemotePlace:FireServer(Vector2.new(tx, ty), Manager.COLLECT_SAPLING_ID)
                    end)
                    task.wait(Manager.COLLECT_DELAY)
                end
                if not Manager._collectRunning then break end
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

-- Auto Drop
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

-- Auto Collect
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
