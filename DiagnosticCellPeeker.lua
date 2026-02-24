--[[
    DiagnosticCellPeeker.lua
    Ngintip isi daleman table WorldTiles.
]]

local rs = game:GetService("ReplicatedStorage")
local wt = rs:FindFirstChild("WorldTiles")
local results = {"--- CELL PEEKER LOG ---"}
local function log(txt) table.insert(results, tostring(txt)) print("[PEEK] " .. tostring(txt)) end

if wt and wt:IsA("ModuleScript") then
    local ok, data = pcall(require, wt)
    if ok and type(data) == "table" then
        -- Ambil row 1, col 1 (atau yang ada isinya)
        local sampleCell = nil
        local foundX, foundY
        
        for x, row in pairs(data) do
            if type(row) == "table" then
                for y, cell in pairs(row) do
                    if type(cell) == "table" then
                        sampleCell = cell
                        foundX, foundY = x, y
                        break
                    end
                end
            end
            if sampleCell then break end
        end
        
        if sampleCell then
            log("KETEMU CELL di ["..foundX.."]["..foundY.."]")
            for k, v in pairs(sampleCell) do
                log("  Field: " .. tostring(k) .. " (" .. type(v) .. ") = " .. tostring(v))
                if type(v) == "table" then
                    for k2, v2 in pairs(v) do
                        log("     -> " .. tostring(k2) .. " = " .. tostring(v2))
                    end
                end
            end
        else
            log("Gagal menemukan cell table di dalam WorldTiles.")
        end
    else
        log("Gagal require atau bukan table.")
    end
else
    log("WorldTiles tidak ditemukan.")
end

-- UI Copy
local player = game:GetService("Players").LocalPlayer
local sg = Instance.new("ScreenGui", player.PlayerGui)
local btn = Instance.new("TextButton", sg)
btn.Size = UDim2.new(0, 300, 0, 50)
btn.Position = UDim2.new(0.5, -150, 0.8, 0)
btn.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
btn.Text = "COPY CELL PEEKER LOG"
btn.TextColor3 = Color3.new(1,1,1)

btn.MouseButton1Click:Connect(function()
    setclipboard(table.concat(results, "\n"))
    btn.Text = "COPIED! ✅"
end)
