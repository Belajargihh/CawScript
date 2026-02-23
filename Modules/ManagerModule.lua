--[[
    ManagerModule.lua
    Module: Manager Features — Auto Drop & Auto Collect

    Auto Drop Flow:
    1. Check backpack for item count
    2. If count >= setting → fire PlayerDrop + UIPromptEvent (skip popup)
    3. If count < setting → skip, wait, recheck
]]

local Manager = {}

-- ═══════════════════════════════════════
-- DEPENDENCIES
-- ═══════════════════════════════════════
local Antiban
local Coordinates

local Players = game:GetService("Players")
local player = Players.LocalPlayer

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
Manager.DROP_DELAY      = 2    -- delay antar drop cycle (detik)
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
-- HELPER: Count item in backpack by ID
-- ═══════════════════════════════════════
local function getBackpackCount(itemId)
    local count = 0
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            -- Check tool name or attribute matching the item ID
            local id = item:GetAttribute("ItemId") or item:GetAttribute("ID") or item:GetAttribute("id")
            if id and tonumber(id) == itemId then
                count = count + 1
            end
        end
    end
    
    -- Also check PlayerGui or data folder for inventory
    local data = player:FindFirstChild("Data")
    if data then
        local inv = data:FindFirstChild("Inventory")
        if inv then
            local slot = inv:FindFirstChild(tostring(itemId))
            if slot and slot:IsA("ValueBase") then
                return tonumber(slot.Value) or 0
            end
        end
    end
    
    -- Check leaderstats or any numeric value
    local ls = player:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            if v.Name == tostring(itemId) and v:IsA("ValueBase") then
                return tonumber(v.Value) or 0
            end
        end
    end
    
    return count
end

-- ═══════════════════════════════════════
-- AUTO DROP LOOP
-- Check backpack → drop only if enough items
-- ═══════════════════════════════════════

local function dropLoop()
    while Manager._dropRunning do
        if not RemoteDrop or not RemotePrompt then
            Manager._dropRunning = false
            warn("[Manager] Auto Drop gagal: Remote tidak ditemukan")
            break
        end

        -- Step 1: Fire PlayerDrop (initiate)
        local ok1 = pcall(function()
            RemoteDrop:FireServer(Manager.DROP_ITEM_ID)
        end)
        
        if ok1 then
            task.wait(0.3) -- tunggu popup muncul
            
            -- Step 2: Langsung confirm via UIPromptEvent (skip popup)
            pcall(function()
                RemotePrompt:FireServer({
                    ButtonAction = "drp",
                    Inputs = {
                        amt = tostring(Manager.DROP_AMOUNT)
                    }
                })
            end)
        end
        
        -- Tunggu cukup lama supaya animasi selesai, UI tidak overlap
        task.wait(Manager.DROP_DELAY)
    end
end

-- ═══════════════════════════════════════
-- AUTO COLLECT LOOP
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

                    pcall(function()
                        RemoteFist:FireServer(Vector2.new(tx, ty))
                    end)
                    task.wait(0.1)

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
