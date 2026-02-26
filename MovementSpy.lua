--[[
    MovementSpy.lua
    Khusus untuk scan "PlayerMovementPackets" dan remote movement lainnya.
    Gunakan ini untuk melihat isi data yang dikirim game saat kamu jalan/lompat.
]]

local player = game:GetService("Players").LocalPlayer
local Remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
local MovementFolder = Remotes:WaitForChild("PlayerMovementPackets")

local results = {}
local lastPackets = {} -- Untuk menghindari spam data yang sama

-- ═══════════════════════════════════════
-- UI SETUP
-- ═══════════════════════════════════════
local p; pcall(function() p = gethui() end)
if not p then pcall(function() p = game:GetService("CoreGui") end) end

local gui
if not _G.DiagnosticLog then
gui = Instance.new("ScreenGui")
gui.Name = "MovementSpyUI"
gui.DisplayOrder = 9999
gui.Parent = p or player.PlayerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 450, 0, 350)
bg.Position = UDim2.new(1, -460, 0.5, -175)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
bg.BorderSizePixel = 0
bg.Parent = gui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
title.Text = "📡 Movement Packet Spy — Geraklah/Lompatlah!"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = bg

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -40)
scroll.Position = UDim2.new(0, 5, 0, 35)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = bg

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 5)
list.Parent = scroll
end

local function log(text, color)
    if _G.DiagnosticLog then
        _G.DiagnosticLog(text)
    end

    if not gui then return end
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -10, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = os.date("[%H:%M:%S] ") .. text
    lbl.TextColor3 = color or Color3.fromRGB(200, 200, 200)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Code
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = scroll
    
    scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
    scroll.CanvasPosition = Vector2.new(0, scroll.CanvasSize.Y.Offset)
    
    -- Limit entries
    if #scroll:GetChildren() > 55 then
        scroll:GetChildren()[2]:Destroy()
    end
end

-- ═══════════════════════════════════════
-- SPY LOGIC
-- ═══════════════════════════════════════

local function formatArgs(...)
    local args = {...}
    local str = ""
    for i, v in ipairs(args) do
        local val = tostring(v)
        if typeof(v) == "Vector3" then
            val = string.format("V3(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
        elseif typeof(v) == "Vector2" then
            val = string.format("V2(%.2f, %.2f)", v.X, v.Y)
        elseif typeof(v) == "CFrame" then
            val = "CF(...)"
        end
        str = str .. "[" .. i .. "]:" .. val .. " "
    end
    return str
end

-- Hook semua remote di ReplicatedStorage.Remotes
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" or method == "InvokeServer" then
        local name = self.Name
        local path = self:GetFullName()
        
        -- Cek apakah remote berhubungan dengan movement
        if path:find("PlayerMovementPackets") or name:find("Movement") or name:find("Velocity") or name:find("Position") then
            local argStr = formatArgs(...)
            
            -- Hindari Log Spam (hanya log jika data berubah drastis atau beda remote)
            if lastPackets[name] ~= argStr then
                lastPackets[name] = argStr
                
                local color = Color3.fromRGB(150, 255, 150) -- Default Green
                if path:find("PlayerMovementPackets") then
                    color = Color3.fromRGB(255, 200, 100) -- Orange for packets
                elseif name:find("Velocity") then
                    color = Color3.fromRGB(100, 200, 255) -- Blue
                end
                
                log(name .. " -> " .. argStr, color)
            end
        end
    end
    
    return oldNamecall(self, ...)
end))

log("Movement Spy Active! Gerakkan karaktermu...", Color3.fromRGB(255, 255, 255))
log("Scanning path: " .. MovementFolder:GetFullName(), Color3.fromRGB(200, 200, 200))
