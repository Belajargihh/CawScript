--[[
    DiagnosticScannerFix.lua
    1. Mencari atribut 'count/amount/stack' di drop item.
    2. Mencari isi table di cell WorldTiles yang bermasalah.
]]

local rs = game:GetService("ReplicatedStorage")
local wt = rs:FindFirstChild("WorldTiles")
local results = {"--- SCANNER FIX DIAGNOSTIC ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[FIX] " .. tostring(txt)) end

-- 1. Cek Drop Item Attributes
local drops = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Items")
if drops then
    local d = drops:GetDescendants()
    if #d > 0 then
        log("Mengecek sample Drop Item...")
        local sample = d[1]
        log("Nama: " .. sample.Name .. " (" .. sample.ClassName .. ")")
        log("Attributes:")
        for k, v in pairs(sample:GetAttributes()) do
            log("  - " .. k .. " = " .. tostring(v) .. " (" .. type(v) .. ")")
        end
    else
        log("Tidak ada drop item untuk dicek.")
    end
else
    log("Folder Drops/Items tidak ditemukan.")
end

-- 2. Cek Table di WorldTiles
if wt then
    local ok, data = pcall(require, wt)
    if ok and type(data) == "table" then
        log("Mencari cell yang isinya TABLE di WorldTiles...")
        local count = 0
        for x, row in pairs(data) do
            if type(row) == "table" then
                for y, cell in pairs(row) do
                    if type(cell) == "table" then
                        -- Cek apakah salah satu fieldnya table lagi?
                        if type(cell[1]) == "table" then
                            log("KETEMU TABLE di Cell["..x.."]["..y.."][1]:")
                            for k, v in pairs(cell[1]) do
                                log("  - " .. tostring(k) .. " = " .. tostring(v))
                            end
                            count = count + 1
                        end
                        if type(cell[2]) == "table" then
                            log("KETEMU TABLE di Cell["..x.."]["..y.."][2]:")
                            for k, v in pairs(cell[2]) do
                                log("  - " .. tostring(k) .. " = " .. tostring(v))
                            end
                            count = count + 1
                        end
                    end
                    if count >= 3 then break end
                end
            end
            if count >= 3 then break end
        end
    end
end

-- UI Copy
local player = game:GetService("Players").LocalPlayer
local sg = Instance.new("ScreenGui", player.PlayerGui)
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 300, 0, 50)
btn.Position = UDim2.new(0.5, -150, 0.5, 0)
btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
btn.Text = "COPY FIX LOG"
btn.TextColor3 = Color3.new(1,1,1)

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
