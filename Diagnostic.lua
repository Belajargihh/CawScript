--[[
    Diagnostic.lua
    Jalankan di Delta Executor untuk scan inventory/backpack
    Hasilnya tampil di layar game (bukan console)
]]

local player = game:GetService("Players").LocalPlayer
local results = {}

table.insert(results, "=== PLAYER CHILDREN ===")
for _, child in ipairs(player:GetChildren()) do
    local info = child.ClassName .. " > " .. child.Name
    table.insert(results, info)
    
    if child:IsA("Folder") or child:IsA("Configuration") or child:IsA("Model") then
        for _, sub in ipairs(child:GetChildren()) do
            local subInfo = "   " .. sub.ClassName .. " > " .. sub.Name
            if sub:IsA("ValueBase") then
                subInfo = subInfo .. " = " .. tostring(sub.Value)
            else
                subInfo = subInfo .. " [" .. #sub:GetChildren() .. " children]"
            end
            table.insert(results, subInfo)
            
            -- Go 1 level deeper
            if sub:IsA("Folder") or sub:IsA("Configuration") then
                for _, deep in ipairs(sub:GetChildren()) do
                    local deepInfo = "      " .. deep.ClassName .. " > " .. deep.Name
                    if deep:IsA("ValueBase") then
                        deepInfo = deepInfo .. " = " .. tostring(deep.Value)
                    else
                        deepInfo = deepInfo .. " [" .. #deep:GetChildren() .. " children]"
                    end
                    table.insert(results, deepInfo)
                end
            end
        end
    end
end

table.insert(results, "\n=== BACKPACK ===")
local bp = player:FindFirstChild("Backpack")
if bp then
    if #bp:GetChildren() == 0 then
        table.insert(results, "(kosong)")
    end
    for _, item in ipairs(bp:GetChildren()) do
        table.insert(results, item.ClassName .. " > " .. item.Name)
        for k, v in pairs(item:GetAttributes()) do
            table.insert(results, "   attr: " .. k .. " = " .. tostring(v))
        end
    end
else
    table.insert(results, "(tidak ada)")
end

-- Cek ReplicatedStorage untuk data inventory
table.insert(results, "\n=== REPLICATED STORAGE (Inventory?) ===")
pcall(function()
    local rs = game:GetService("ReplicatedStorage")
    for _, child in ipairs(rs:GetChildren()) do
        local name = child.Name:lower()
        if name:find("inv") or name:find("item") or name:find("data") or name:find("backpack") or name:find("bag") or name:find("slot") then
            local info = child.ClassName .. " > " .. child.Name .. " [" .. #child:GetChildren() .. " children]"
            table.insert(results, info)
            for _, sub in ipairs(child:GetChildren()) do
                table.insert(results, "   " .. sub.ClassName .. " > " .. sub.Name)
            end
        end
    end
end)

-- Tampilkan di layar
local gui = Instance.new("ScreenGui")
gui.Name = "DiagnosticUI"
gui.DisplayOrder = 9999

local parent
pcall(function() parent = gethui() end)
if not parent then pcall(function() parent = game:GetService("CoreGui") end) end
if not parent then parent = player.PlayerGui end
gui.Parent = parent

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 400, 0, 500)
bg.Position = UDim2.new(0.5, -200, 0.5, -250)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
bg.BorderSizePixel = 0
bg.Parent = gui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(100, 80, 255)
title.Text = "🔍 Kolin Diagnostic — SCREENSHOT INI"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = bg
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -70)
scroll.Position = UDim2.new(0, 5, 0, 35)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, #results * 16)
scroll.Parent = bg

local output = Instance.new("TextLabel")
output.Size = UDim2.new(1, -10, 0, #results * 16)
output.Position = UDim2.new(0, 5, 0, 0)
output.BackgroundTransparency = 1
output.Text = table.concat(results, "\n")
output.TextColor3 = Color3.fromRGB(200, 255, 200)
output.TextSize = 11
output.Font = Enum.Font.Code
output.TextXAlignment = Enum.TextXAlignment.Left
output.TextYAlignment = Enum.TextYAlignment.Top
output.TextWrapped = true
output.Parent = scroll

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -20, 0, 28)
closeBtn.Position = UDim2.new(0, 10, 1, -34)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "TUTUP"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 13
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bg
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
    gui:Destroy()
end)
