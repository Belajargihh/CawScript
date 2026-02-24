--[[
    DiagnosticSuper.lua (ULTRA STABLE)
    Lacak ITEM dan REMOTE dalam satu script.
]]

local player = game:GetService("Players").LocalPlayer
local results = {"--- SUPER LOG START ---"}

local function log(txt)
    table.insert(results, tostring(txt))
    print("[SUPER] " .. tostring(txt))
end

-- 1. TRACKER (Watch Workspace)
log("Tracker Aktiv: Lacak Item Jatuh...")
task.spawn(function()
    workspace.ChildAdded:Connect(function(child)
        task.wait(0.1)
        log("JATUH: " .. child.Name .. " [" .. child.ClassName .. "] @ " .. child:GetFullName())
        for k,v in pairs(child:GetAttributes()) do log("   Attr: " .. k .. " = " .. v) end
    end)
    
    -- Juga lacak di folder Drops
    local drops = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Items")
    if drops then
        drops.ChildAdded:Connect(function(child)
            task.wait(0.1)
            log("DROP LOG: " .. child.Name .. " @ " .. child:GetFullName())
        end)
    end
end)

-- 2. SPY (Stable Method - Hook Remote Calls)
log("Spy Aktif: Lacak Pickup...")
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" or method == "InvokeServer" then
        local name = self.Name
        if name:lower():find("item") or name:lower():find("pickup") or name:lower():find("drop") or name:lower():find("collect") then
            log("REMOTE FIRE: " .. name .. " | Args: " .. #args)
            for i,v in ipairs(args) do log("  ["..i.."] " .. tostring(v)) end
        end
    end
    return old(self, ...)
end)

-- 3. UI Super Simpel (Tanpa gethui/CoreGui failure)
local sg = Instance.new("ScreenGui")
sg.Name = "SuperDiagUI"
sg.Parent = player:WaitForChild("PlayerGui") -- Pake PlayerGui karena gethui bermasalah di Delta kadang

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 300, 0, 100)
bg.Position = UDim2.new(0.5, -150, 0.2, 0)
bg.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
bg.Parent = sg

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0, 40)
label.Text = "DIAGNOSTIC RUNNING...\nLiat F9 Console & Chat!"
label.TextColor3 = Color3.new(1,1,1)
label.BackgroundTransparency = 1
label.Parent = bg

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.8, 0, 0, 40)
btn.Position = UDim2.new(0.1, 0, 0.5, 0)
btn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
btn.Text = "COPY LOGS"
btn.TextColor3 = Color3.new(1,1,1)
btn.Parent = bg

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)

log("Diagnostic Siap. Silakan DROP 1 item, lalu PUNGUT 1 item.")
log("Lalu klik tombol COPY LOGS.")
