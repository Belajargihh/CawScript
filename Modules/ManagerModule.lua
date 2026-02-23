--[[
    ManagerModule.lua
    Module: Manager Features — Auto Drop & Auto Collect

    Auto Drop: fire PlayerDrop → immediately confirm via UIPromptEvent
    → then destroy the popup GUI so it doesn't show
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
-- CONFIG: AUTO DROP
-- ═══════════════════════════════════════
Manager.DROP_ITEM_ID    = 1
Manager.DROP_AMOUNT     = 1
Manager.DROP_DELAY      = 2
Manager._dropRunning    = false
Manager._dropThread     = nil

-- ═══════════════════════════════════════
-- CONFIG: AUTO COLLECT
-- ═══════════════════════════════════════
Manager.COLLECT_BLOCK_ID   = 1
Manager.COLLECT_SAPLING_ID = 1
Manager.COLLECT_RANGE      = 2
Manager.COLLECT_DELAY      = 0.3
Manager._collectRunning    = false
Manager._collectThread     = nil

-- ═══════════════════════════════════════
-- HELPER: Destroy popup from PlayerGui
-- ═══════════════════════════════════════
local function destroyPopup()
    pcall(function()
        local pg = player:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, g in ipairs(pg:GetChildren()) do
            if g:IsA("ScreenGui") and g.Name ~= "KolinUI" then
                -- Cari frame popup drop
                for _, child in ipairs(g:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        local txt = child.Text or ""
                        if txt:find("Drop") and txt:find("?") then
                            -- Ini popup drop, destroy parent ScreenGui-nya
                            g:Destroy()
                            return
                        end
                    end
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════
-- AUTO DROP LOOP
-- ═══════════════════════════════════════

local function dropLoop()
    while Manager._dropRunning do
        if not RemoteDrop or not RemotePrompt then
            Manager._dropRunning = false
            warn("[Manager] Auto Drop gagal: Remote tidak ditemukan")
            break
        end

        -- Step 1: Fire PlayerDrop (server perlu ini buat tau item mana)
        pcall(function()
            RemoteDrop:FireServer(Manager.DROP_ITEM_ID)
        end)
        
        -- Step 2: LANGSUNG confirm (tanpa nunggu popup render)
        pcall(function()
            RemotePrompt:FireServer({
                ButtonAction = "drp",
                Inputs = {
                    amt = tostring(Manager.DROP_AMOUNT)
                }
            })
        end)
        
        -- Step 3: Destroy popup kalau masih sempet muncul
        destroyPopup()
        task.wait(0.1)
        destroyPopup()  -- double kill

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
                        break
                    end
                    local tx, ty = px + dx, py + dy
                    pcall(function() RemoteFist:FireServer(Vector2.new(tx, ty)) end)
                    task.wait(0.1)
                    pcall(function() RemotePlace:FireServer(Vector2.new(tx, ty), Manager.COLLECT_SAPLING_ID) end)
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
