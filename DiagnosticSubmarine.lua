--[[
    DiagnosticSubmarine.lua
    Edisi "Menyelam": Scan total tanpa ampun untuk nyari item.
]]

local player = game:GetService("Players").LocalPlayer
local results = {"--- SUBMARINE DEEP DIVE LOG ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[DIVE] " .. tostring(txt)) end

log("Memulai penyelaman... Mencari jejak item di seluruh Workspace.")

-- 1. Scan EVERY child of Workspace for potentially hidden containers
for _, v in ipairs(workspace:GetChildren()) do
    local descendants = v:GetDescendants()
    local dCount = #descendants
    
    -- Cari yang isinya banyak
    if dCount > 10 then
        log("OBJEK BESAR: " .. v.Name .. " (" .. v.ClassName .. ") | " .. dCount .. " descendants")
        
        -- Cari atribut 'id' di mana saja di dalam sini
        local idCount = 0
        local sampleIds = {}
        for _, d in ipairs(descendants) do
            local id = d:GetAttribute("id") or d:GetAttribute("ItemId") or d:GetAttribute("TileId")
            if id then
                idCount = idCount + 1
                if #sampleIds < 3 then table.insert(sampleIds, tostring(id)) end
            end
        end
        
        if idCount > 0 then
            log("   -> KETEMU " .. idCount .. " objek ber-ID! Sample: " .. table.concat(sampleIds, ", "))
        end
        
        -- Cek struktur level 1
        local level1 = v:GetChildren()
        if #level1 > 0 then
            log("   Struktur level 1 (sample 3):")
            for i = 1, math.min(3, #level1) do
                local child = level1[i]
                log("     - [" .. i .. "] " .. child.Name .. " (" .. child.ClassName .. ") | " .. #child:GetChildren() .. " children")
                -- Cek atribut child ini
                for k, attr in pairs(child:GetAttributes()) do
                    log("       Attr: " .. k .. " = " .. tostring(attr))
                end
            end
        end
    end
end

-- 2. Scan ReplicatedStorage for anything related to "Items", "Tiles", "Config"
log("Scanning ReplicatedStorage for metadata...")
for _, v in ipairs(game:GetService("ReplicatedStorage"):GetChildren()) do
    if v.Name:lower():find("item") or v.Name:lower():find("tile") or v.Name:lower():find("config") or v.Name:lower():find("data") then
        log("RS POTENSIAL: " .. v.Name .. " (" .. v.ClassName .. ")")
        -- Jika folder/model, cek isinya
        if #v:GetChildren() > 0 then
             local c = v:GetChildren()[1]
             log("   Contoh isi: " .. c.Name .. " (" .. c.ClassName .. ")")
             for k, attr in pairs(c:GetAttributes()) do
                 log("     Attr: " .. k .. " = " .. tostring(attr))
             end
        end
    end
end

-- 3. Cari dimana "Tile highlights" itu berada sebenarnya
local th = workspace:FindFirstChild("TileHighlights", true)
if th then
    log("TileHighlights ditemukan via Recursive search di: " .. th:GetFullName())
else
    log("TileHighlights TIDAK ditemukan via recursive search.")
end

-- UI Copy
local sg = Instance.new("ScreenGui", player.PlayerGui)
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 300, 0, 50)
btn.Position = UDim2.new(0.5, -150, 0.6, 0)
btn.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
btn.Text = "COPY SUBMARINE LOG"
btn.TextColor3 = Color3.new(1,1,1)

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
