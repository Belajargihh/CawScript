--[[
    DiagnosticGems (v1.6 - SIMPLE COPY)
    Klik tombol untuk COPY log Gems ke clipboard.
]]

local results = {"--- GEM SPY LOG (v1.6) ---"}
local function log(txt) 
    table.insert(results, tostring(txt)) 
    if _G.DiagnosticLog then
        _G.DiagnosticLog(txt)
    end
    print("[GEM-SPY] " .. tostring(txt)) 
end

-- 1. UI SETUP
local player = game:GetService("Players").LocalPlayer
local pgui = player:WaitForChild("PlayerGui", 5)

-- Hapus yang lama
if pgui:FindFirstChild("GemSpySimple") then pgui.GemSpySimple:Destroy() end

local sg = Instance.new("ScreenGui", pgui)
sg.Name = "GemSpySimple"
sg.ResetOnSpawn = false
sg.DisplayOrder = 9999

local btn
if not _G.DiagnosticLog then
btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0.5, -100, 0.1, 0) -- Di atas tengah layar
btn.BackgroundColor3 = Color3.fromRGB(80, 50, 200)
btn.Text = "COPY GEMS DATA 💎"
btn.TextColor3 = Color3.new(1, 1, 1)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
Instance.new("UICorner", btn)

log("Diagnostic Aktif! Silakan ambil/pakai Gems.")

btn.MouseButton1Click:Connect(function()
    local text = table.concat(results, "\n")
    local success = pcall(function() setclipboard(text) end)
    if not success then pcall(function() toclipboard(text) end) end
    
    btn.Text = success and "COPIED! ✅" or "FAILED! ❌"
    btn.BackgroundColor3 = success and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(200, 0, 0)
    task.wait(2)
    btn.Text = "COPY GEMS DATA 💎"
    btn.BackgroundColor3 = Color3.fromRGB(80, 50, 200)
end)
end

-- 2. HOOK LOGIC
local keywords = {"gem", "diamond", "jewel", "currenc", "money", "shop", "buy", "purchase", "transaction", "reward", "redeem"}

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" or method == "InvokeServer" then
        local name = tostring(self.Name):lower()
        local matches = false
        for _, k in ipairs(keywords) do if name:find(k) then matches = true break end end
        
        if matches then
            log("FIRE: " .. self.Name)
            for i, v in ipairs(args) do
                log("  [" .. i .. "] " .. tostring(v) .. " (" .. typeof(v) .. ")")
            end
        end
    end
    return oldNamecall(self, ...)
end))
