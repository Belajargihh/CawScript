--[[
    Main.lua
    UI Utama — Rayfield Interface
    
    Tab:
    1. Coordinates — Real-time grid display + Re-Sync
    2. Auto PnB — Toggle automation + status
    3. Settings — Delay config, antiban, tema
    4. Info — Panduan penggunaan
    
    Cara pakai: Di-load oleh Index.lua via loadstring
]]

-- ═══════════════════════════════════════
-- LOAD DEPENDENCIES DARI GITHUB
-- ═══════════════════════════════════════

-- ⚠️ GANTI URL INI SETELAH PUSH KE GITHUB
local GITHUB_BASE = "https://raw.githubusercontent.com/Belajargihh/CawScript/main/"

local Coordinates = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/Coordinates.lua"))()
local AutoPnB    = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/AutoPnB.lua"))()
local Antiban    = loadstring(game:HttpGet(GITHUB_BASE .. "Modules/Antiban.lua"))()

-- Inisialisasi dependencies antar module
AutoPnB.init(Coordinates, Antiban)

-- ═══════════════════════════════════════
-- RAYFIELD UI
-- ═══════════════════════════════════════

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "WC Automation | Koziz Style",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false,
})

-- ═══════════════════════════════════════
-- TAB 1: COORDINATES
-- ═══════════════════════════════════════

local TabCoord = Window:CreateTab("📍 Coordinates", 4483362458)

local CoordLabel = TabCoord:CreateLabel("Grid: Menunggu sync...")
local RawLabel   = TabCoord:CreateLabel("Raw: —")

TabCoord:CreateButton({
    Name = "🔄 Re-Sync Position",
    Callback = function()
        local gridX, gridY = Coordinates.getGridPosition()
        if gridX then
            CoordLabel:Set("Grid: " .. Coordinates.formatDisplay(gridX, gridY))
            RawLabel:Set(string.format("Raw: X=%.1f  Z=%.1f", 
                Coordinates._lastRawX, Coordinates._lastRawY))
            Rayfield:Notify({
                Title = "Synced!",
                Content = Coordinates.formatDisplay(gridX, gridY),
                Duration = 2
            })
        else
            CoordLabel:Set("Grid: Karakter tidak ditemukan!")
        end
    end,
})

-- Auto-update koordinat setiap 0.5 detik
local autoSyncEnabled = false

TabCoord:CreateToggle({
    Name = "Auto-Sync (Real-Time)",
    CurrentValue = false,
    Callback = function(value)
        autoSyncEnabled = value
    end,
})

-- Deteksi objek di workspace
local DetectLabel = TabCoord:CreateLabel("Objek: None")

spawn(function()
    while true do
        if autoSyncEnabled then
            local gridX, gridY = Coordinates.getGridPosition()
            if gridX then
                CoordLabel:Set("Grid: " .. Coordinates.formatDisplay(gridX, gridY))
                RawLabel:Set(string.format("Raw: X=%.1f  Z=%.1f", 
                    Coordinates._lastRawX, Coordinates._lastRawY))
            end
        end
        
        -- Deteksi tile highlight
        local highlight = workspace:FindFirstChild("tileHighlight")
        if highlight then
            DetectLabel:Set("Objek: " .. tostring(highlight))
        else
            DetectLabel:Set("Objek: None")
        end
        
        task.wait(0.5)
    end
end)

-- ═══════════════════════════════════════
-- TAB 2: AUTO PnB
-- ═══════════════════════════════════════

local TabPnB = Window:CreateTab("⚒️ Auto PnB", 4483362458)

local PnBStatusLabel = TabPnB:CreateLabel("Status: Idle")
local PnBCycleLabel  = TabPnB:CreateLabel("Siklus: 0")
local PnBTargetLabel = TabPnB:CreateLabel("Target: —")

TabPnB:CreateToggle({
    Name = "Aktifkan Auto PnB",
    CurrentValue = false,
    Callback = function(value)
        if value then
            AutoPnB.start()
            Rayfield:Notify({
                Title = "Auto PnB",
                Content = "Dimulai! Queue: Place → Break → Collect",
                Duration = 3
            })
        else
            AutoPnB.stop()
            Rayfield:Notify({
                Title = "Auto PnB",
                Content = "Dihentikan.",
                Duration = 2
            })
        end
    end,
})

-- Update status PnB secara real-time
spawn(function()
    while true do
        PnBStatusLabel:Set("Status: " .. AutoPnB.getStatus())
        if AutoPnB.isRunning() then
            PnBCycleLabel:Set("Siklus: " .. AutoPnB.getCycleCount())
            local tx, ty = AutoPnB.getTarget()
            PnBTargetLabel:Set("Target: " .. Coordinates.formatDisplay(tx, ty))
        end
        task.wait(0.3)
    end
end)

-- ═══════════════════════════════════════
-- TAB 3: SETTINGS
-- ═══════════════════════════════════════

local TabSettings = Window:CreateTab("⚙️ Settings", 4483362458)

local AntibanLabel = TabSettings:CreateLabel("Antiban: Aktif ✅ | Throttle: 0")

TabSettings:CreateSlider({
    Name = "Delay Siklus PnB (detik)",
    Range = {0.1, 2.0},
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

TabSettings:CreateSlider({
    Name = "Min Delay Antiban (detik)",
    Range = {0.05, 0.5},
    Increment = 0.01,
    CurrentValue = 0.12,
    Callback = function(value)
        Antiban.MIN_DELAY = value
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
-- TAB 4: INFO
-- ═══════════════════════════════════════

local TabInfo = Window:CreateTab("ℹ️ Info", 4483362458)

TabInfo:CreateLabel("WC Automation — Koziz Style")
TabInfo:CreateLabel("Grid: floor(raw/3.5 + 0.5) + offset")
TabInfo:CreateLabel("Offset: X=-4, Y=-10 | Range: 0-100")
TabInfo:CreateParagraph({
    Title = "Cara Pakai",
    Content = "1. Buka tab Coordinates, nyalakan Auto-Sync\n2. Buka tab Auto PnB, aktifkan toggle\n3. Atur delay di Settings sesuai kebutuhan\n\n⚠️ Pastikan RemoteEvent sudah diganti\ndi file Modules/AutoPnB.lua!"
})