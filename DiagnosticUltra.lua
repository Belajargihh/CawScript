--[[
    DiagnosticUltra.lua
    Scan AGRESIF untuk nyari dimana sebenernya item berada.
]]

local player = game:GetService("Players").LocalPlayer
local results = {"--- ULTRA SCAN LOG ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[ULTRA] " .. tostring(txt)) end

log("Memulai scan agresif... Tolong DROP ITEM dulu!")

local function scan(obj)
    pcall(function()
        for _, v in ipairs(obj:GetChildren()) do
            local name = v.Name:lower()
            -- Cari apa pun yang namanya mencurigakan
            if name:find("item") or name:find("drop") or name:find("sapling") or name:find("seed") or v:IsA("TouchInterest") then
                log("KETEMU: " .. v.Name .. " [" .. v.ClassName .. "] @ " .. v:GetFullName())
                if v:IsA("BasePart") or v:IsA("Model") then
                    log("   Pos: " .. tostring(v:GetPivot().Position))
                    for k, attr in pairs(v:GetAttributes()) do
                        log("   Attr: " .. k .. " = " .. tostring(attr))
                    end
                end
            end
            
            -- Scan lebih dalam (kecuali folder yang pasti bukan item)
            if v ~= player.Character and v.Name ~= "Terrain" and v.Name ~= "Map" then
                scan(v)
            end
        end
    end)
end

-- Scan Workspace & ReplicatedStorage (siapa tau itemnya di client-side folder aneh)
log("Scanning Workspace...")
scan(workspace)
log("Scanning ReplicatedStorage...")
scan(game:GetService("ReplicatedStorage"))

-- UI Copy
local sg = Instance.new("ScreenGui", player.PlayerGui)
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 300, 0, 50)
btn.Position = UDim2.new(0.5, -150, 0.5, -25)
btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
btn.Text = "COPY ULTRA LOG (" .. #results .. " lines)"
btn.TextColor3 = Color3.new(1,1,1)

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)

log("Scan Selesai!")
