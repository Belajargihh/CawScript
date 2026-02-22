--[[
    Main.lua
    UI Utama — Rayfield Interface (Craft a World)
    
    Tab:
    1. Auto PnB — Toggle, auto-sync, auto-detect item
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

-- Inisialisasi dependencies
AutoPnB.init(Antiban)

-- ═══════════════════════════════════════
-- AUTO-DETECT POSISI TARGET VIA PUNCH
-- ═══════════════════════════════════════

local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local RemoteFist  = Remotes:WaitForChild("PlayerFist")

-- Hook __namecall: saat player punch manual, tangkap posisi grid-nya
local hookSuccess = false
local punchDetected = false
pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        
        -- Tangkap posisi dari PlayerFist (hanya saat bukan auto mode)
        if method == "FireServer" and self == RemoteFist and not AutoPnB.isRunning() then
            local args = {...}
            if args[1] and typeof(args[1]) == "Vector2" then
                AutoPnB.TARGET_X = args[1].X
                AutoPnB.TARGET_Y = args[1].Y
                punchDetected = true
            end
        end
        
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
    hookSuccess = true
end)

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

-- Status labels
local PosLabel    = TabPnB:CreateLabel("📍 Posisi: belum sync")
local TargetLabel = TabPnB:CreateLabel("🎯 Target: X=0  Y=0")
local StatusLabel = TabPnB:CreateLabel("Status: Idle")
local CycleLabel  = TabPnB:CreateLabel("Siklus: 0")

if hookSuccess then
    TabPnB:CreateLabel("✅ Punch Detection aktif — punch blok untuk set target")
else
    TabPnB:CreateLabel("⚠️ Hook gagal - pakai slider manual")
end

-- Auto-sync posisi
local autoSyncEnabled = false

TabPnB:CreateToggle({
    Name = "📍 Auto-Sync Posisi",
    CurrentValue = false,
    Callback = function(value)
        autoSyncEnabled = value
    end,
})

-- Sync manual
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
                Content = "Target: " .. Coordinates.formatDisplay(gx, gy),
                Duration = 2
            })
        end
    end,
})

-- Manual target sliders
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

-- Manual item ID (fallback kalau hook gagal)
TabPnB:CreateSlider({
    Name = "Item ID",
    Range = {1, 500},
    Increment = 1,
    CurrentValue = 2,
    Callback = function(value)
        AutoPnB.ITEM_ID = value
    end,
})

-- Toggle Auto PnB
TabPnB:CreateToggle({
    Name = "▶️ Aktifkan Auto PnB",
    CurrentValue = false,
    Callback = function(value)
        if value then
            -- Auto-sync posisi kalau belum di-set
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
                Content = "Target: X=" .. AutoPnB.TARGET_X .. " Y=" .. AutoPnB.TARGET_Y .. " | Item: " .. AutoPnB.ITEM_ID,
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
        -- Update posisi
        local gx, gy = Coordinates.getGridPosition()
        if gx then
            PosLabel:Set("📍 Posisi: " .. Coordinates.formatDisplay(gx, gy))
            
            if autoSyncEnabled and not AutoPnB.isRunning() then
                AutoPnB.TARGET_X = gx
                AutoPnB.TARGET_Y = gy
                TargetLabel:Set("🎯 Target: " .. Coordinates.formatDisplay(gx, gy))
            end
        end
        
        -- Update target dari punch detection
        if punchDetected then
            TargetLabel:Set("🎯 Target: X=" .. AutoPnB.TARGET_X .. "  Y=" .. AutoPnB.TARGET_Y .. " (punch)")
            punchDetected = false
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
    Content = "1. Place 1 blok manual → item otomatis ke-detect\n2. Nyalakan Auto-Sync → posisi otomatis update\n3. Aktifkan Auto PnB → Place + Punch loop\n\n🧱 Item auto-detect dari aksi manual kamu\n📍 Posisi auto-detect dari karakter"
})
TabInfo:CreateParagraph({
    Title = "Tips Anti-Ban",
    Content = "• Jangan set delay terlalu rendah\n• Aktifkan Human Jitter\n• Max 8 aksi/detik (default)"
})