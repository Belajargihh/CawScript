log("\n[DEEP SCAN] Analisa Item di folder DROPS...")
pcall(function()
    local d = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Items")
    if d then
        local items = d:GetChildren()
        if #items == 0 then
            log("(!) Folder ada tapi KOSONG. Tolong DROP ITEM dulu!")
        else
            for i, child in ipairs(items) do
                log("ITEM ["..i.."]: " .. child.Name .. " (" .. child.ClassName .. ")")
                log("   Parent: " .. child.Parent.Name)
                log("   Position: " .. tostring(child:GetPivot().Position))
                log("   TouchInterest: " .. (child:FindFirstChildOfClass("TouchInterest") and "ADA ✅" or "TIDAK ADA ❌"))
                log("   ProximityPrompt: " .. (child:FindFirstChildOfClass("ProximityPrompt") and "ADA ✅" or "TIDAK ADA ❌"))
                for k,v in pairs(child:GetAttributes()) do
                    log("   Attr: " .. k .. " = " .. tostring(v))
                end
                if i >= 5 then break end -- Jangan kebanyakan
            end
        end
    else
        log("(!) Folder Drops/Items TIDAK DITEMUKAN.")
    end
end)

-- 2. Bangun UI Paling Dasar (No Scrolling Frame)
local gui = Instance.new("ScreenGui")
gui.Name = "StableDiagUI"
gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") or player.PlayerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 400, 0, 450)
bg.Position = UDim2.new(0.5, -200, 0.5, -225)
bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
bg.Active = true
bg.Draggable = true
bg.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
title.Text = "🧪 DIAGNOSTIC GAMPANG"
title.TextColor3 = Color3.new(1,1,1)
title.Parent = bg

local out = Instance.new("TextBox") -- Pake TextBox biar bisa di-copy manual kalau tombol gagal
out.Size = UDim2.new(1, -20, 1, -80)
out.Position = UDim2.new(0, 10, 0, 40)
out.BackgroundTransparency = 0.9
out.Text = table.concat(results, "\n")
out.TextColor3 = Color3.new(1,1,1)
out.TextSize = 10
out.Font = Enum.Font.Code
out.TextXAlignment = Enum.TextXAlignment.Left
out.TextYAlignment = Enum.TextYAlignment.Top
out.ClearTextOnFocus = false
out.MultiLine = true
out.ReadOnly = true
out.Parent = bg

local copy = Instance.new("TextButton")
copy.Size = UDim2.new(0.5, -15, 0, 30)
copy.Position = UDim2.new(0, 10, 1, -35)
copy.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
copy.Text = "AUTO COPY"
copy.TextColor3 = Color3.new(1,1,1)
copy.Parent = bg
copy.MouseButton1Click:Connect(function()
    setclipboard(out.Text)
    copy.Text = "COPIED! ✅"
end)

local close = Instance.new("TextButton")
close.Size = UDim2.new(0.5, -15, 0, 30)
close.Position = UDim2.new(0.5, 5, 1, -35)
close.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
close.Text = "CLOSE"
close.TextColor3 = Color3.new(1,1,1)
close.Parent = bg
close.MouseButton1Click:Connect(function() gui:Destroy() end)

warn("[DIAG] SCRIPT SELESAI DIJALANKAN!")
