--[[
    DiagnosticItemMetadata.lua
    Deep scan metadata item & struktur Tiles.
]]

local player = game:GetService("Players").LocalPlayer
local results = {"--- METADATA & TILE SCAN ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[META] " .. tostring(txt)) end

-- 1. Bedah ReplicatedStorage.Items
local rs = game:GetService("ReplicatedStorage")
local itemsColl = rs:FindFirstChild("Items")
if itemsColl then
    log("Scanning RS.Items children...")
    for _, v in ipairs(itemsColl:GetChildren()) do
        log("ID: " .. v.Name .. " (" .. v.ClassName .. ")")
        if v:IsA("ImageLabel") or v:IsA("ImageButton") then
             log("   Image: " .. tostring(v.Image))
        end
        for k, attr in pairs(v:GetAttributes()) do
            log("   Attr: " .. k .. " = " .. tostring(attr))
        end
    end
else
    log("ERR: ReplicatedStorage.Items not found")
end

-- 2. Bedah Workspace.Tiles
local tiles = workspace:FindFirstChild("Tiles")
if tiles then
    log("Scanning Workspace.Tiles top 5...")
    local children = tiles:GetChildren()
    for i = 1, math.min(10, #children) do
        local v = children[i]
        log("TILE ["..i.."]: " .. v.Name .. " (" .. v.ClassName .. ")")
        -- Cek apa isinya
        for _, c in ipairs(v:GetChildren()) do
            log("   Child: " .. c.Name .. " (" .. c.ClassName .. ")")
        end
        for k, attr in pairs(v:GetAttributes()) do
            log("   Attr: " .. k .. " = " .. tostring(attr))
        end
    end
else
    log("ERR: Workspace.Tiles not found")
end

-- UI Copy
local sg = Instance.new("ScreenGui", player.PlayerGui)
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 300, 0, 50)
btn.Position = UDim2.new(0.5, -150, 0.5, 0)
btn.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
btn.Text = "COPY METADATA LOG"
btn.TextColor3 = Color3.new(1,1,1)

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
