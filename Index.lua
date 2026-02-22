--[[
    Index.lua — Entry Point / Loader
    
    ╔═══════════════════════════════════════════╗
    ║  TEMPEL SCRIPT INI DI DELTA EXECUTOR     ║
    ║  Script ini hanya loader, semua logic     ║
    ║  ada di file Main.lua di GitHub.          ║
    ╚═══════════════════════════════════════════╝
    
    CARA PAKAI:
    1. Push semua file ke GitHub
    2. Ganti USERNAME dan REPO di bawah
    3. Copy-paste script ini ke Delta Executor
    4. Tekan Execute
]]

-- ⚠️ GANTI INI DENGAN URL GITHUB KAMU
local GITHUB_USER = "USERNAME"   -- Ganti dengan username GitHub kamu
local GITHUB_REPO = "REPO"      -- Ganti dengan nama repository kamu
local BRANCH      = "main"      -- Branch (biasanya "main")

-- Bangun URL
local BASE_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/",
    GITHUB_USER,
    GITHUB_REPO,
    BRANCH
)

-- Load & Execute Main.lua
local success, err = pcall(function()
    loadstring(game:HttpGet(BASE_URL .. "Main.lua"))()
end)

if not success then
    warn("[WC Automation] Gagal load Main.lua: " .. tostring(err))
    warn("[WC Automation] Pastikan URL GitHub sudah benar!")
end
