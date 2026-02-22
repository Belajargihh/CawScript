--[[
    Main.lua
    UI Utama — Rayfield Interface (Craft a World)
    
    Tab:
    1. Auto PnB — Toggle, target position, item dropdown
    2. Settings — Delay config, antiban
    3. Info — Panduan penggunaan
    
    Cara pakai: Di-load oleh Index.lua via loadstring
]]

-- ═══════════════════════════════════════
-- LOAD DEPENDENCIES DARI GITHUB
-- ═══════════════════════════════════════

local GITHUB_BASE = "https://raw.githubusercontent.com/Belajargihh/CawScript/main/"

local AutoPnB = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/AutoPnB.lua"))()
local Antiban = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/Antiban.lua"))()

-- Load Item Catalog dari JSON
local HttpService = game:GetService("HttpService")
local itemsRaw = game:HttpGet(GITHUB_BASE .. "Assets/items.json")
local itemsData = HttpService:JSONDecode(itemsRaw)

-- Build dropdown list & lookup
local itemDropdownList = {}  -- {"Dirt Block [2]", "Dirt Sapling [4]", ...}
local itemNameToId = {}      -- {["Dirt Block [2]"] = 2, ...}

for _, item in ipairs(itemsData.items) do
    local label = item.name .. " [" .. item.id .. "]"
    table.insert(itemDropdownList, label)
    itemNameToId[label] = item.id
end

-- Inisialisasi dependencies
AutoPnB.init(Antiban)

-- ═══════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "CawScript | Auto PnB",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false,
})

-- ═══════════════════════════════════════
-- TAB 1: AUTO PnB
-- ═══════════════════════════════════════

local TabPnB = Window:CreateTab("⚒️ Auto PnB", 4483362458)

local PnBStatusLabel = TabPnB:CreateLabel("Status: Idle")
local PnBCycleLabel  = TabPnB:CreateLabel("Siklus: 0")
local PnBTargetLabel = TabPnB:CreateLabel("Target: X=0  Y=0")

-- Input Target X
TabPnB:CreateSlider({
    Name = "Target Grid X",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(value)
        AutoPnB.TARGET_X = value
        PnBTargetLabel:Set("Target: X=" .. AutoPnB.TARGET_X .. "  Y=" .. AutoPnB.TARGET_Y)
    end,
})

-- Input Target Y
TabPnB:CreateSlider({
    Name = "Target Grid Y",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(value)
        AutoPnB.TARGET_Y = value
        PnBTargetLabel:Set("Target: X=" .. AutoPnB.TARGET_X .. "  Y=" .. AutoPnB.TARGET_Y)
    end,
})

-- Pilih Item (Dropdown)
TabPnB:CreateDropdown({
    Name = "Pilih Item",
    Options = itemDropdownList,
    CurrentOption = {"Dirt Block [2]"},
    Callback = function(option)
        local selected = option[1] or option
        local id = itemNameToId[selected]
        if id then
            AutoPnB.ITEM_ID = id
            Rayfield:Notify({
                Title = "Item Dipilih",
                Content = selected,
                Duration = 2
            })
        end
    end,
})

-- Toggle Auto PnB
TabPnB:CreateToggle({
    Name = "Aktifkan Auto PnB",
    CurrentValue = false,
    Callback = function(value)
        if value then
            AutoPnB.start()
            Rayfield:Notify({
                Title = "Auto PnB",
                Content = "Dimulai! Target: X=" .. AutoPnB.TARGET_X .. " Y=" .. AutoPnB.TARGET_Y,
                Duration = 3
            })
        else
            AutoPnB.stop()
            Rayfield:Notify({
                Title = "Auto PnB",
                Content = "Dihentikan. Siklus: " .. AutoPnB.getCycleCount(),
                Duration = 2
            })
        end
    end,
})

-- Update status real-time
spawn(function()
    while true do
        PnBStatusLabel:Set("Status: " .. AutoPnB.getStatus())
        if AutoPnB.isRunning() then
            PnBCycleLabel:Set("Siklus: " .. AutoPnB.getCycleCount())
        end
        task.wait(0.3)
    end
end)

-- ═══════════════════════════════════════
-- TAB 2: SETTINGS
-- ═══════════════════════════════════════

local TabSettings = Window:CreateTab("⚙️ Settings", 4483362458)

local AntibanLabel = TabSettings:CreateLabel("Antiban: Aktif ✅ | Throttle: 0")

TabSettings:CreateSlider({
    Name = "Delay Place (detik)",
    Range = {0.05, 2.0},
    Increment = 0.05,
    CurrentValue = 0.2,
    Callback = function(value)
        AutoPnB.DELAY_PLACE = value
    end,
})

TabSettings:CreateSlider({
    Name = "Delay Punch (detik)",
    Range = {0.05, 2.0},
    Increment = 0.05,
    CurrentValue = 0.15,
    Callback = function(value)
        AutoPnB.DELAY_BREAK = value
    end,
})

TabSettings:CreateSlider({
    Name = "Delay Siklus (detik)",
    Range = {0.1, 3.0},
    Increment = 0.05,
    CurrentValue = 0.3,
    Callback = function(value)
        AutoPnB.DELAY_CYCLE = value
    end,
})

TabSettings:CreateSlider({
    Name = "Max Aksi/Detik (Antiban)",
    Range = {3, 15},
    Increment = 1,
    CurrentValue = 8,
    Callback = function(value)
        Antiban.MAX_ACTIONS_SEC = value
    end,
})

TabSettings:CreateToggle({
    Name = "Human Jitter (Variasi Acak)",
    CurrentValue = true,
    Callback = function(value)
        Antiban.HUMAN_JITTER = value
    end,
})

TabSettings:CreateButton({
    Name = "🔃 Reset Antiban Counter",
    Callback = function()
        Antiban.resetCounter()
        Rayfield:Notify({
            Title = "Antiban",
            Content = "Counter di-reset!",
            Duration = 2
        })
    end,
})

-- Update antiban status
spawn(function()
    while true do
        local status = Antiban.isPaused() and "PAUSED ⚠️" or "Aktif ✅"
        AntibanLabel:Set("Antiban: " .. status .. " | Throttle: " .. Antiban.getThrottleCount())
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════
-- TAB 3: INFO
-- ═══════════════════════════════════════

local TabInfo = Window:CreateTab("ℹ️ Info", 4483362458)

TabInfo:CreateLabel("CawScript — Auto PnB for Craft a World")
TabInfo:CreateLabel("Game: Craft a World (Roblox)")
TabInfo:CreateParagraph({
    Title = "Cara Pakai",
    Content = "1. Set Target X dan Y (koordinat grid blok)\n2. Set Item ID (2 = Dirt Block)\n3. Aktifkan toggle Auto PnB\n4. Atur delay di Settings\n\n⚠️ Gunakan Remote Spy untuk cari Item ID lain!\n\nRemotes:\n• Place: PlayerPlaceItem\n• Punch: PlayerFist"
})
TabInfo:CreateParagraph({
    Title = "Tips Anti-Ban",
    Content = "• Jangan set delay terlalu rendah\n• Aktifkan Human Jitter\n• Max 8 aksi/detik (default)\n• Jangan AFK terlalu lama saat auto-farm"
})