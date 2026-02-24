--[[
    DiagnosticTracker.lua
    Watch workspace for new items.
]]

local results = {"--- OBJECT TRACKER LOG ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[TRACKER] " .. tostring(txt)) end

log("Tracker Aktif! Silakan DROP ITEM sekarang.")

local function watch(obj)
    obj.ChildAdded:Connect(function(child)
        task.wait(0.1) -- Jeda dikit biar properties ke-load
        log("NEW OBJECT: " .. child.Name .. " [" .. child.ClassName .. "] @ " .. child:GetFullName())
        if child:IsA("BasePart") or child:IsA("Model") then
             for k, v in pairs(child:GetAttributes()) do
                 log("   Attr: " .. k .. " = " .. tostring(v))
             end
        end
    end)
end

-- Watch workspace and folders
watch(workspace)
for _, v in ipairs(workspace:GetChildren()) do
    if v:IsA("Folder") then watch(v) end
end

-- UI to copy results
local sg = Instance.new("ScreenGui", (gethui and gethui()) or game:GetService("CoreGui"))
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 200, 0, 50)
btn.Position = UDim2.new(0.5, -100, 0.7, 0)
btn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
btn.Text = "COPY TRACKER LOG"
btn.TextColor3 = Color3.new(1,1,1)
btn.Font = Enum.Font.GothamBold

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
