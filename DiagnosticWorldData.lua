--[[
    DiagnosticWorldData.lua
    Bedah ModuleScript WorldTiles dan data-data rahasia lainnya.
]]

local player = game:GetService("Players").LocalPlayer
local results = {"--- DEEP DATA SCAN ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[DATA] " .. tostring(txt)) end

-- 1. Bedah ReplicatedStorage.WorldTiles
local rs = game:GetService("ReplicatedStorage")
local wt = rs:FindFirstChild("WorldTiles")
if wt and wt:IsA("ModuleScript") then
    log("KETEMU ReplicatedStorage.WorldTiles! Mencoba Requiring...")
    local ok, data = pcall(require, wt)
    if ok then
        log("Berhasil Require WorldTiles!")
        if type(data) == "table" then
            local count = 0
            for k, v in pairs(data) do count = count + 1 end
            log("Jumlah entry di table: " .. count)
            
            -- Dump 5 baris pertama
            log("Sample Data:")
            local i = 0
            for k, v in pairs(data) do
                i = i + 1
                log("  Key: " .. tostring(k) .. " | ValueType: " .. type(v))
                if type(v) == "table" then
                    for kk, vv in pairs(v) do
                        log("     " .. tostring(kk) .. " = " .. tostring(vv))
                    end
                else
                    log("     Value: " .. tostring(v))
                end
                if i >= 5 then break end
            end
        else
            log("Data bukan table: " .. type(data))
        end
    else
        log("Gagal Require WorldTiles: " .. tostring(data))
    end
else
    log("WorldTiles tidak ditemukan atau bukan ModuleScript.")
end

-- 2. Scan Workspace.Tiles lagi, tapi cek EVERYTHING (Property, Attribute, Name)
local tiles = workspace:FindFirstChild("Tiles")
if tiles then
    log("Scanning Workspace.Tiles Deep Sample...")
    local des = tiles:GetDescendants()
    local foundAttributes = {}
    for i = 1, math.min(100, #des) do
        local d = des[i]
        for k, v in pairs(d:GetAttributes()) do
            foundAttributes[k] = (foundAttributes[k] or 0) + 1
        end
    end
    log("Attributes ditemukan di 100 sample pertama:")
    for k, v in pairs(foundAttributes) do
        log("  - " .. k .. ": " .. v .. " kali")
    end
end

-- UI Copy
local sg = Instance.new("ScreenGui", player.PlayerGui)
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 300, 0, 50)
btn.Position = UDim2.new(0.5, -150, 0.7, 0)
btn.BackgroundColor3 = Color3.fromRGB(100, 0, 100)
btn.Text = "COPY DATA SCAN LOG"
btn.TextColor3 = Color3.new(1,1,1)

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
