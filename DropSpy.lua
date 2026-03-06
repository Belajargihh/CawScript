-- CawScript Drop Spy (Nuclear Compatibility Edition)
-- Use this if other versions didn't show the panel

print("[DropSpy] SCRIPT STARTED")

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- UI CREATION (Same style as Main.lua)
local gui = Instance.new("ScreenGui")
gui.Name = "DropSpyNuclear"
gui.ResetOnSpawn = false
gui.DisplayOrder = 99999

local guiParent
pcall(function() guiParent = gethui() end)
if not guiParent then pcall(function() guiParent = game:GetService("CoreGui") end) end
if not guiParent then guiParent = player:WaitForChild("PlayerGui", 5) end

if not guiParent then
    print("[DropSpy] ERROR: No UI Parent found. Printing to console instead.")
else
    gui.Parent = guiParent
    print("[DropSpy] UI Parented successfully to: " .. tostring(guiParent))
end

local Main = Instance.new("Frame", gui)
Main.Size = UDim2.new(0, 320, 0, 280)
Main.Position = UDim2.new(0.5, -160, 0.5, -140)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main)

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(30,30,50)
Title.Text = "📡 Network Sniffer (Dupe Researcher)"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Instance.new("UICorner", Title)

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1, -10, 1, -85)
Scroll.Position = UDim2.new(0, 5, 0, 40)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local termText = Instance.new("TextLabel", Scroll)
termText.Size = UDim2.new(1, 0, 0, 0)
termText.AutomaticSize = Enum.AutomaticSize.Y
termText.BackgroundTransparency = 1
termText.Text = "--- LOG START ---"
termText.TextColor3 = Color3.fromRGB(0, 255, 100)
termText.TextSize = 10
termText.Font = Enum.Font.Code
termText.TextXAlignment = Enum.TextXAlignment.Left
termText.TextYAlignment = Enum.TextYAlignment.Top
termText.TextWrapped = true

local function log(msg)
    local ts = os.date("%M:%S")
    termText.Text = termText.Text .. "\n[" .. ts .. "] " .. tostring(msg)
    Scroll.CanvasPosition = Vector2.new(0, Scroll.AbsoluteCanvasSize.Y)
    print("[DropSpy Output] " .. tostring(msg))
end

local Copy = Instance.new("TextButton", Main)
Copy.Size = UDim2.new(1, -10, 0, 35)
Copy.Position = UDim2.new(0, 5, 1, -40)
Copy.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
Copy.Text = "📋 COPY ALL LOGS"
Copy.TextColor3 = Color3.new(1,1,1)
Copy.Font = Enum.Font.GothamBold
Instance.new("UICorner", Copy)

Copy.MouseButton1Click:Connect(function()
    setclipboard(termText.Text)
    Copy.Text = "✅ COPIED!"
    task.wait(1)
    Copy.Text = "📋 COPY ALL LOGS"
end)

-- HOOK LOGIC (Careful with conflicts)
log("Attempting to hook network...")

local success, err = pcall(function()
    local old
    old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" or method == "InvokeServer" then
            local name = tostring(self.Name)
            log("EVT: " .. name)
            for i, v in ipairs(args) do
                local s = tostring(v)
                if #s > 40 then s = s:sub(1,37).."..." end
                log("  A["..i.."]: "..s)
            end
        end
        return old(self, ...)
    end))
end)

if not success then
    log("HOOK ERROR: " .. tostring(err))
    warn("[DropSpy] Hook failed. Using fallback method...")
end

log("READY. Please drop items.")
