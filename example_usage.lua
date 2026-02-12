--[[
    Example: Using AquaFlow UI Library for a different game
    Copy this template and modify for your game!
]]

-- Load the library
local UILib = loadstring(game:HttpGet("YOUR_URL/ui_library.lua"))()
-- Or if local: local UILib = require(path.to.ui_library)

-- Define YOUR game's config
local Config = {
    AutoFarm = false,
    AutoSell = false,
    Speed = 100,
    Target = "All",
    SelectedMobs = { ["All"] = true },
}

-- Create window
local win = UILib:CreateWindow("MY GAME SCRIPT", Config)

-- Optional: handle close
win.OnClose = function()
    Config.AutoFarm = false
    Config.AutoSell = false
end

-- ============ Page 1: Farm ============
local farmPage = win:AddPage("AUTO FARM")

win:AddHeader(farmPage, "Farming")
win:AddToggle(farmPage, "Auto Farm Mobs", "AutoFarm", Color3.fromRGB(150, 255, 100))
win:AddToggle(farmPage, "Auto Sell Loot", "AutoSell", Color3.fromRGB(255, 170, 0))

-- Single-select dropdown
local modeList = { "Nearest", "Highest Level", "Boss Only" }
win:AddDropdown(farmPage, "Target Mode", "Choose priority", modeList, "Target", true)

-- Multi-select dropdown
local mobList = { "All", "Zombie", "Skeleton", "Dragon", "Boss" }
win:AddDropdown(farmPage, "Select Mobs", "Filter targets", mobList, "SelectedMobs")

-- Number input
win:AddInput(farmPage, "Speed (studs/s):", "Speed")

-- Action button
win:AddActionButton(farmPage, "SET HOME POSITION", Color3.fromRGB(255, 64, 128), function(btn)
    btn.Text = "SAVED!"
    task.wait(1)
    btn.Text = "SET HOME POSITION"
end)

-- ============ Page 2: Settings ============
local settingsPage = win:AddPage("SETTINGS")

win:AddHeader(settingsPage, "General")
win:AddLabel(settingsPage, "Configure your script settings here.\nAdjust values as needed.")

win:AddButton(settingsPage, "Teleport", "Go to safe zone", "GO", Color3.fromRGB(45, 125, 255), function(btn)
    btn.Text = "TELEPORTING..."
    task.wait(2)
    btn.Text = "ARRIVED!"
    task.wait(1)
    btn.Text = "GO"
end)

-- ============ Your Game Logic ============
-- (Put your auto-farm loops, hooks, etc. here)
-- Use Config.AutoFarm, Config.Target, etc. to check toggle states

-- Example loop:
--[[
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoFarm then
            win:SetStatus("FARMING...", Color3.fromRGB(64, 255, 64))
            -- your farm logic here
        else
            win:SetStatus("STATUS: IDLE", Color3.new(0.6, 0.6, 0.6))
        end
    end
end)
]]

print("[Script] Loaded with AquaFlow UI!")
