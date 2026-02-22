--[[
    Main.lua
    UI Utama — Rayfield Interface (Craft a World)
    
    Tab:
    1. Auto PnB — Toggle, auto-sync position, item dropdown
    2. Settings — Delay config, antiban
    3. Info — Panduan penggunaan
    
    Cara pakai: Di-load oleh Index.lua via loadstring
]]

-- ═══════════════════════════════════════
-- LOAD DEPENDENCIES DARI GITHUB
-- ═══════════════════════════════════════

local GITHUB_BASE = "https://raw.githubusercontent.com/Belajargihh/CawScript/main/"

local AutoPnB     = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/AutoPnB.lua"))()
local Antiban      = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/Antiban.lua"))()
local Coordinates  = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/Coordinates.lua"))()

-- Load Item Catalog dari JSON
local HttpService = game:GetService("HttpService")
local itemsRaw = game:HttpGet(GITHUB_BASE .. "Assets/items.json")
local itemsData = HttpService:JSONDecode(itemsRaw)

-- Build dropdown list & lookup
local itemDropdownList = {}
local itemNameToId = {}

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

-- Posisi saat ini (auto-detect)
local PosLabel    = TabPnB:CreateLabel("📍 Posisi: belum sync")
local TargetLabel = TabPnB:CreateLabel("🎯 Target: X=0  Y=0")
local StatusLabel = TabPnB:CreateLabel("Status: Idle")
local CycleLabel  = TabPnB:CreateLabel("Siklus: 0")

-- Auto-sync toggle
local autoSyncEnabled = false

TabPnB:CreateToggle({
    Name = "📍 Auto-Sync Posisi (Real-Time)",
    CurrentValue = false,
    Callback = function(value)
        autoSyncEnabled = value
        if value then
            Rayfield:Notify({
                Title = "Auto-Sync",
                Content = "Posisi akan terupdate otomatis!",
                Duration = 2
            })
        end
    end,
})

-- Tombol sync manual
TabPnB:CreateButton({
    Name = "🔄 Sync Posisi Sekarang",
    Callback = function()
        local gx, gy = Coordinates.getGridPosition()
        if gx then
            AutoPnB.TARGET_X = gx
            AutoPnB.TARGET_Y = gy
            TargetLabel:Set("🎯 Target: " .. Coordinates.formatDisplay(gx, gy))
            Rayfield:Notify({
                Title = "Synced!",
                Content = "Target set ke " .. Coordinates.formatDisplay(gx, gy),
                Duration = 2
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Karakter tidak ditemukan!",
                Duration = 2
            })
        end
    end,
})

-- Input Target manual (slider)
TabPnB:CreateSlider({
    Name = "Target Grid X (Manual)",
    Range = {0, 200},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(value)
        AutoPnB.TARGET_X = value
        TargetLabel:Set("🎯 Target: X=" .. AutoPnB.TARGET_X .. "  Y=" .. AutoPnB.TARGET_Y)
    end,
})

TabPnB:CreateSlider({
    Name = "Target Grid Y (Manual)",
    Range = {0, 200},
    Increment = 1,
    CurrentValue = 0,
    Callback = function(value)
        AutoPnB.TARGET_Y = value
        TargetLabel:Set("🎯 Target: X=" .. AutoPnB.TARGET_X .. "  Y=" .. AutoPnB.TARGET_Y)
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
    Name = "▶️ Aktifkan Auto PnB",
    CurrentValue = false,
    Callback = function(value)
        if value then
            -- Auto-sync posisi sebelum mulai kalau belum di-set
            if AutoPnB.TARGET_X == 0 and AutoPnB.TARGET_Y == 0 then
                local gx, gy = Coordinates.getGridPosition()
                if gx then
                    AutoPnB.TARGET_X = gx
                    AutoPnB.TARGET_Y = gy
                    TargetLabel:Set("🎯 Target: " .. Coordinates.formatDisplay(gx, gy))
                end
            end
            
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

-- Real-time update loop
spawn(function()
    while true do
        -- Update posisi karakter
        local gx, gy = Coordinates.getGridPosition()
        if gx then
            PosLabel:Set("📍 Posisi: " .. Coordinates.formatDisplay(gx, gy))
            
            -- Auto-sync target kalau enabled
            if autoSyncEnabled and not AutoPnB.isRunning() then
                AutoPnB.TARGET_X = gx
                AutoPnB.TARGET_Y = gy
                TargetLabel:Set("🎯 Target: " .. Coordinates.formatDisplay(gx, gy))
            end
        end
        
        -- Update status
        StatusLabel:Set("Status: " .. AutoPnB.getStatus())
        if AutoPnB.isRunning() then
            CycleLabel:Set("Siklus: " .. AutoPnB.getCycleCount())
        end
        
        task.wait(0.5)
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
TabInfo:CreateParagraph({
    Title = "Cara Pakai",
    Content = "1. Nyalakan Auto-Sync → posisi otomatis ke-detect\n2. Atau klik Sync Posisi → ambil posisi sekarang\n3. Atau atur manual pakai slider X dan Y\n4. Pilih item dari dropdown\n5. Aktifkan Auto PnB\n\nRumus: Grid = round(WorldPos / 4.5)"
})
TabInfo:CreateParagraph({
    Title = "Tips Anti-Ban",
    Content = "• Jangan set delay terlalu rendah\n• Aktifkan Human Jitter\n• Max 8 aksi/detik (default)\n• Jangan AFK terlalu lama saat auto-farm"
})