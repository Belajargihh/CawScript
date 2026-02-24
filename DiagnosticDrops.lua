--[[
    DiagnosticDrops.lua
    Scan TOTAL folder Drops tanpa filter apapun.
]]

local player = game:GetService("Players").LocalPlayer
local results = {"--- RAW DROPS SCAN ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[RAW] " .. tostring(txt)) end

log("Memulai scan folder Drops... Tolong DROP ITEM dulu!")

local d = workspace:FindFirstChild("Drops")
if d then
    local children = d:GetChildren()
    log("Jumlah benda di Drops: " .. #children)
    for i, v in ipairs(children) do
        log("ITEM ["..i.."]: " .. v.Name .. " (" .. v.ClassName .. ")")
        log("   Full: " .. v:GetFullName())
        -- List semua anak di dalamnya (siapa tau itemnya nested)
        for _, c in ipairs(v:GetChildren()) do
            log("     - Anak: " .. c.Name .. " (" .. c.ClassName .. ")")
        end
        -- List attributes
        for k, attr in pairs(v:GetAttributes()) do
            log("     - Attr: " .. k .. " = " .. tostring(attr))
        end
        if i >= 10 then log("... dan seterusnya") break end
    end
else
    log("ERR: Folder Drops tidak ditemukan di Workspace!")
end

-- UI Copy
local sg = Instance.new("ScreenGui", player.PlayerGui)
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 300, 0, 50)
btn.Position = UDim2.new(0.5, -150, 0.4, 0)
btn.BackgroundColor3 = Color3.fromRGB(50, 50, 200)
btn.Text = "COPY RAW DROPS LOG"
btn.TextColor3 = Color3.new(1,1,1)

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
