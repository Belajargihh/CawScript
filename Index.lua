--[[
    Index.lua — Entry Point / Loader
    
    TEMPEL SCRIPT INI DI DELTA EXECUTOR
    Script ini hanya loader, semua logic
    ada di file Main.lua di GitHub.
    
    CARA PAKAI:
    1. Push semua file ke GitHub
    2. Copy-paste script ini ke Delta Executor
    3. Tekan Execute
]]

local GITHUB_USER = "Belajargihh"
local GITHUB_REPO = "CawScript"
local BRANCH      = "main"

-- Anti-cache: tambah timestamp ke URL
local NOCACHE = "?t=" .. tostring(math.floor(tick()))

local BASE_URL = string.format(
    "https://raw.githubusercontent.com/%s/%s/%s/",
    GITHUB_USER,
    GITHUB_REPO,
    BRANCH
)

-- Load & Execute Main.lua (anti-cache)
local success, err = pcall(function()
    loadstring(game:HttpGet(BASE_URL .. "Main.lua" .. NOCACHE))()
end)

if not success then
    warn("[CawScript] Gagal load Main.lua: " .. tostring(err))
end
