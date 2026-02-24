--[[
    ItemScanner.lua
    Diagnostic script to identify dropped items in workspace.
    Run this to see which objects are items and what attributes they have.
]]

local player = game:GetService("Players").LocalPlayer
local results = {}

table.insert(results, "=== ITEM SCANNER (Workspace) ===")

local function scan(folder)
    for _, item in ipairs(folder:GetChildren()) do
        -- Heuristic: items are usually BaseParts or Models with specific names/attributes
        local isPotential = false
        if item:IsA("BasePart") or item:IsA("Model") then
            -- Check for common item indicators
            if item:FindFirstChild("TouchInterest") or item:GetAttribute("itemID") or item:GetAttribute("Count") then
                isPotential = true
            end
            
            -- Also check for specific names related to blocks/saplings
            local name = item.Name:lower()
            if name:find("sapling") or name:find("seed") or name:find("block") or name:find("item") then
                isPotential = true
            end
        end

        if isPotential then
            local info = string.format("[%s] %s", item.ClassName, item.Name)
            table.insert(results, info)
            
            -- List attributes
            for k, v in pairs(item:GetAttributes()) do
                table.insert(results, string.format("   attr: %s = %s", k, tostring(v)))
            end
            
            -- List important children
            for _, child in ipairs(item:GetChildren()) do
                if child:IsA("ValueBase") then
                    table.insert(results, string.format("   val: %s = %s", child.Name, tostring(child.Value)))
                end
            end
            
            -- Stop after 20 items to avoid lag
            if #results > 60 then 
                table.insert(results, "...(limit reached)")
                return true 
            end
        end
        
        -- Recursive for 'Items' folder if found
        if item.Name == "Items" or item.Name == "Drops" then
            if scan(item) then return true end
        end
    end
    return false
end

scan(workspace)

-- Show UI
local gui = Instance.new("ScreenGui")
gui.Name = "ItemScannerUI"
gui.DisplayOrder = 10000

local parent = pcall(function() return gethui() end) or pcall(function() return game:GetService("CoreGui") end) or player.PlayerGui
gui.Parent = parent

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 450, 0, 400)
bg.Position = UDim2.new(0.5, -225, 0.5, -200)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
bg.BorderSizePixel = 0
bg.Parent = gui
Instance.new("UICorner", bg)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(80, 50, 200)
title.Text = "📦 Item Scanner Diagnostic"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.Parent = bg

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -80)
scroll.Position = UDim2.new(0, 10, 0, 40)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, #results * 18)
scroll.Parent = bg

local out = Instance.new("TextLabel")
out.Size = UDim2.new(1, 0, 0, #results * 18)
out.BackgroundTransparency = 1
out.Text = table.concat(results, "\n")
out.TextColor3 = Color3.fromRGB(200, 255, 200)
out.TextSize = 12
out.Font = Enum.Font.Code
out.TextXAlignment = Enum.TextXAlignment.Left
out.TextYAlignment = Enum.TextYAlignment.Top
out.Parent = scroll

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 100, 0, 30)
close.Position = UDim2.new(0.5, -50, 1, -35)
close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
close.Text = "CLOSE"
close.TextColor3 = Color3.new(1,1,1)
close.Parent = bg
close.MouseButton1Click:Connect(function() gui:Destroy() end)
