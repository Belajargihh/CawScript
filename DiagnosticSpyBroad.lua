--[[
    DiagnosticSpyBroad.lua
    Tangkap SEMUA remote yang lewat tanpa filter.
]]

local player = game:GetService("Players").LocalPlayer
local results = {"--- BROAD SPY LOG ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[SPY] " .. tostring(txt)) end

log("Spy Aktif! Silakan AMBIL ITEM (pungut item) secara manual sekarang.")

local old; old = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" or method == "InvokeServer" then
        -- Log SEMUA yang dipanggil (biar gak ada yang lolos)
        log("FIRE: " .. self.Name .. " (" .. self.ClassName .. ") | Args: " .. #args)
        for i, v in ipairs(args) do
            local val = tostring(v)
            if #val > 50 then val = val:sub(1, 50) .. "..." end
            log("   [" .. i .. "] " .. val .. " (" .. type(v) .. ")")
        end
    end
    return old(self, ...)
end)

-- UI Copy
local sg = Instance.new("ScreenGui", player.PlayerGui)
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 300, 0, 50)
btn.Position = UDim2.new(0.5, -150, 0.6, 0)
btn.BackgroundColor3 = Color3.fromRGB(150, 50, 150)
btn.Text = "COPY BROAD SPY LOG"
btn.TextColor3 = Color3.new(1,1,1)

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
