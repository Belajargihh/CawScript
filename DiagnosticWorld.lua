--[[
    DiagnosticWorld.lua
    Scan Workspace untuk nyari dimana Blok yang ditaruh (Placed) berada.
]]

local player = game:GetService("Players").LocalPlayer
local results = {"--- WORLD SCAN LOG ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[WORLD] " .. tostring(txt)) end

log("Memulai scan world... Mencari block storage.")

for _, v in ipairs(workspace:GetChildren()) do
    local childrenCount = #v:GetChildren()
    if childrenCount > 5 then
        log("FOLDER POTENSIAL: " .. v.Name .. " (" .. v.ClassName .. ") | " .. childrenCount .. " children")
        -- Cek sample anak
        local first = v:GetChildren()[1]
        if first then
            log("   Anak pertama: " .. first.Name .. " (" .. first.ClassName .. ")")
            for k, attr in pairs(first:GetAttributes()) do
                log("   Attr sample: " .. k .. " = " .. tostring(attr))
            end
        end
    end
end

-- Cari folder Items di ReplicatedStorage
local rs = game:GetService("ReplicatedStorage")
local itemsCol = rs:FindFirstChild("Items")
if itemsCol then
    log("KETEMU ReplicatedStorage.Items!")
    for i, v in ipairs(itemsCol:GetChildren()) do
        log("ITEM DB ["..i.."]: " .. v.Name .. " (" .. v.ClassName .. ")")
        for k, attr in pairs(v:GetAttributes()) do
             log("     - Attr: " .. k .. " = " .. tostring(attr))
        end
        if i >= 5 then break end
    end
end

-- UI Copy
local sg = Instance.new("ScreenGui", player.PlayerGui)
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 300, 0, 50)
btn.Position = UDim2.new(0.5, -150, 0.4, 0)
btn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
btn.Text = "COPY WORLD SCAN LOG"
btn.TextColor3 = Color3.new(1,1,1)

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
