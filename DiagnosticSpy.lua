--[[
    DiagnosticSpy.lua
    Monitor Remote Events pas kamu ambil item.
]]

local results = {"--- REMOTE SPY LOG ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[SPY] " .. tostring(txt)) end

log("Spy Aktif! Silakan AMBIL ITEM (pungut item) di game.")

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" or method == "InvokeServer" then
        local name = self.Name
        -- Filter remotes yang berkaitan dengan item/inventory
        if name:lower():find("item") or name:lower():find("inv") or name:lower():find("drop") or name:lower():find("collect") or name:lower():find("pickup") then
            log("FIRE: " .. name .. " | Args: " .. #args .. " items")
            for i, v in ipairs(args) do
                log("   [" .. i .. "] " .. tostring(v) .. " (" .. type(v) .. ")")
            end
        end
    end
    
    return oldNamecall(self, ...)
end))

-- UI to copy results
local sg = Instance.new("ScreenGui", (gethui and gethui()) or game:GetService("CoreGui"))
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0.5, -100, 0.8, 0)
btn.BackgroundColor3 = Color3.fromRGB(80, 50, 200)
btn.Text = "COPY SPY LOG"
btn.TextColor3 = Color3.new(1,1,1)
btn.Font = Enum.Font.GothamBold

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
