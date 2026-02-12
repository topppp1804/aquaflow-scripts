-- [[ Auto Fish System: V6.7 OMEGA MASTERY (Global Timeout Fix) ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- [SECTION 1: Core Services]
local Knit = ReplicatedStorage:WaitForChild("common"):WaitForChild("packages"):WaitForChild("Knit")
local StartCatching = Knit:WaitForChild("Services"):WaitForChild("HarpoonService"):WaitForChild("RF"):WaitForChild(
    "StartCatching")
local SellService = Knit:WaitForChild("Services"):WaitForChild("SellService"):WaitForChild("RF"):WaitForChild(
    "SellInventory")
local BuyItem = Knit:WaitForChild("Services"):WaitForChild("PurchaseService"):WaitForChild("RF"):WaitForChild(
    "BuyItem")

-- Quest Service Remotes
local QuestService = Knit:WaitForChild("Services"):WaitForChild("QuestsService"):WaitForChild("RF")
local SubmitNpcInteract = QuestService:WaitForChild("SubmitNpcInteract")
local SubmitNpcDialogueInteract = QuestService:WaitForChild("SubmitNpcDialogueInteract")
local FinishQuest = QuestService:WaitForChild("FinishQuest")
local ClaimQuest = QuestService:WaitForChild("ClaimQuest")

-- Geode/Artifact Remotes
local GeodeOpen = Knit:WaitForChild("Services"):WaitForChild("ArtifactService"):WaitForChild("RF"):WaitForChild("Open")

local ScriptActive = true
local function checkScriptActive()
    if not ScriptActive then
        -- Force stop everything
        Config.AutoCatch = false
        Config.AutoSell = false
        Config.AutoRefill = false
        Config.AutoChest = false
        return false
    end
    return true
end

-- Pre-declare local functions for Section 2 scope
local parseNum, getMaxHealth, isFishValid, hasMutation, getBestFish, smoothTween, isQuestDone, getRealFishName
local StatusTxt, WeightDisplay, isOpeningChests -- Pre-declare for global access

local FishContainer = workspace:WaitForChild("Game"):WaitForChild("Fish"):WaitForChild("client")
local MainGui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Main")

-- [Theme & Config]
Config = {
    AutoCatch = false,
    AutoMinigame = false,
    HunterMode = false,
    AutoSell = false,
    AutoRefill = true,
    AutoChest = false,
    TargetWeight = 40,
    TargetFish = "All",
    SelectedFish = { ["All"] = true },
    SelectedMutations = { ["All"] = true },
    SelectedChests = { ["Tier 1"] = true },
    TweenSpeed = 120,
    HomePos = nil,
    FishDistance = 14,
    SearchRange = 1000,
    MinOxygen = 25,
    TargetMode = "Highest HP",
    StuckLimit = 15,
    TravelLocation = "None",
    ShopCategory = "guns",
    ShopItem = "None",
    AutoQuest = false,
    BringProtect = true,
    _questOverrideFish = nil,
    _questOverrideMutation = nil,
    _activeQuestType = nil,
    _activeQuestNpc = nil
}
local isSelling = false
local Blacklist = {}
local lastTargetObj = nil

local TravelList = { "None" }
local ShopItemList = {} -- Will store {name, category}
local ItemPrices = {}
local firstAttemptTime = 0

local FishList = { "All" }
local MutationList = { "All" }
local ChestTierList = {}
local TravelList = { "None" }
local ShopItemList = { "None" }
local ItemPrices = {}

-- [SECTION 2: UI Redesign - Premium Sidebar System]
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AquaFlow_Omega_Premium"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 520, 0, 360)
Main.Position = UDim2.new(0.5, -260, 0.4, -180)
Main.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", Main)
Stroke.Thickness = 1.2
Stroke.Color = Color3.fromRGB(45, 48, 60)
Stroke.Transparency = 0.6

-- [ Window Controls ]
local MiniOpen = Instance.new("TextButton")
MiniOpen.Name = "MiniOpen"
MiniOpen.Size = UDim2.new(0, 60, 0, 30)
MiniOpen.Position = UDim2.new(1, -70, 0, 20)
MiniOpen.BackgroundColor3 = Color3.fromRGB(255, 64, 128)
MiniOpen.Text = "OPEN"
MiniOpen.TextColor3 = Color3.new(1, 1, 1)
MiniOpen.Font = Enum.Font.GothamBold
MiniOpen.TextSize = 10
MiniOpen.Visible = false
MiniOpen.Parent = ScreenGui
Instance.new("UICorner", MiniOpen).CornerRadius = UDim.new(0, 6)

-- Deleted the overlapping ControlFrame from Main

-- Left Sidebar
local Sidebar = Instance.new("Frame", Main)
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
Sidebar.BorderSizePixel = 0

local SidebarCorner = Instance.new("UICorner", Sidebar)
SidebarCorner.CornerRadius = UDim.new(0, 10)

local ControlFrame = Instance.new("Frame", Sidebar)
ControlFrame.Name = "ControlFrame"
ControlFrame.Size = UDim2.new(0, 60, 0, 30)
ControlFrame.Position = UDim2.new(0, 10, 0, 10)
ControlFrame.BackgroundTransparency = 1
ControlFrame.ZIndex = 10

local CloseBtn = Instance.new("TextButton", ControlFrame)
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -25, 0, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 64, 64)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.ZIndex = 11
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

local MiniBtn = Instance.new("TextButton", ControlFrame)
MiniBtn.Size = UDim2.new(0, 25, 0, 25)
MiniBtn.Position = UDim2.new(0, 0, 0, 0)
MiniBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
MiniBtn.Text = "-"
MiniBtn.TextColor3 = Color3.new(1, 1, 1)
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.TextSize = 14
MiniBtn.ZIndex = 11
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(0, 4)

CloseBtn.MouseButton1Click:Connect(function()
    ScriptActive = false
    task.wait(0.1)
    ScreenGui:Destroy()
end)
MiniBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    MiniOpen.Visible = true
end)
MiniOpen.MouseButton1Click:Connect(function()
    Main.Visible = true
    MiniOpen.Visible = false
end)

-- Sidebar Title (Adjusted position)
local SideTitle = Instance.new("TextLabel", Sidebar)
SideTitle.Size = UDim2.new(1, 0, 0, 40)
SideTitle.Position = UDim2.new(0, 0, 0, 40)
SideTitle.Text = "ABYSS [PREMIUM]"
SideTitle.TextColor3 = Color3.fromRGB(255, 64, 128)
SideTitle.Font = Enum.Font.GothamBold
SideTitle.TextSize = 11
SideTitle.BackgroundTransparency = 1

local NavList = Instance.new("Frame", Sidebar)
NavList.Size = UDim2.new(1, -20, 1, -100)
NavList.Position = UDim2.new(0, 10, 0, 85)
NavList.BackgroundTransparency = 1
Instance.new("UIListLayout", NavList).Padding = UDim.new(0, 5)

-- Right Container
local Container = Instance.new("Frame", Main)
Container.Size = UDim2.new(1, -175, 1, -45)
Container.Position = UDim2.new(0, 165, 0, 10)
Container.BackgroundTransparency = 1

local FishingPage = Instance.new("ScrollingFrame", Container)
FishingPage.Size = UDim2.new(1, 0, 1, 0)
FishingPage.BackgroundTransparency = 1
FishingPage.ScrollBarThickness = 2
FishingPage.ScrollBarImageColor3 = Color3.fromRGB(45, 125, 255)
FishingPage.Visible = true

local QuestPage = Instance.new("ScrollingFrame", Container)
QuestPage.Size = UDim2.new(1, 0, 1, 0)
QuestPage.BackgroundTransparency = 1
QuestPage.ScrollBarThickness = 0
QuestPage.Visible = false

local TravelPage = Instance.new("ScrollingFrame", Container)
TravelPage.Size = UDim2.new(1, 0, 1, 0)
TravelPage.BackgroundTransparency = 1
TravelPage.ScrollBarThickness = 0
TravelPage.Visible = false

for _, page in ipairs({ FishingPage, QuestPage, TravelPage }) do
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local padding = Instance.new("UIPadding", page)
    padding.PaddingBottom = UDim.new(0, 15)
    padding.PaddingLeft = UDim.new(0, 2)
    padding.PaddingRight = UDim.new(0, 8)
end

-- Navigation Logic
local function createNavBtn(txt, page)
    local btn = Instance.new("TextButton", NavList)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
    btn.Text = "  " .. txt
    btn.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        FishingPage.Visible = (page == FishingPage)
        QuestPage.Visible = (page == QuestPage)
        TravelPage.Visible = (page == TravelPage)

        for _, child in ipairs(NavList:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextColor3 = Color3.new(0.6, 0.6, 0.6)
                child.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
            end
        end
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.BackgroundColor3 = Color3.fromRGB(255, 64, 128)
    end)
    return btn
end

local fishNav = createNavBtn("AUTO FARM", FishingPage)
local questNav = createNavBtn("QUESTS", QuestPage)
local travelNav = createNavBtn("TRAVEL", TravelPage)
fishNav.TextColor3 = Color3.new(1, 1, 1)
fishNav.BackgroundColor3 = Color3.fromRGB(255, 64, 128)

-- [ Fish Database ]
local function crawlFish()
    pcall(function()
        local fishFolder = ReplicatedStorage:FindFirstChild("common") and
            ReplicatedStorage.common:FindFirstChild("presets") and
            ReplicatedStorage.common.presets:FindFirstChild("items") and
            ReplicatedStorage.common.presets.items:FindFirstChild("fish")

        if fishFolder then
            for _, zone in ipairs(fishFolder:GetChildren()) do
                for _, fish in ipairs(zone:GetChildren()) do
                    local found = false
                    for _, v in ipairs(FishList) do
                        if v == fish.Name then
                            found = true; break
                        end
                    end
                    if not found then
                        table.insert(FishList, fish.Name)
                    end
                end
            end
        end
    end)
    table.sort(FishList)
end
crawlFish()

local function crawlMutations()
    pcall(function()
        local mutFolder = game:GetService("ReplicatedStorage"):FindFirstChild("common") and
            game.ReplicatedStorage.common:FindFirstChild("presets") and
            game.ReplicatedStorage.common.presets:FindFirstChild("fish") and
            game.ReplicatedStorage.common.presets.fish:FindFirstChild("mutations")

        if mutFolder then
            for _, mut in ipairs(mutFolder:GetChildren()) do
                if mut:IsA("ModuleScript") or mut:IsA("Folder") or mut:IsA("Configuration") then
                    local found = false
                    for _, v in ipairs(MutationList) do
                        if v == mut.Name then
                            found = true; break
                        end
                    end
                    if not found then
                        table.insert(MutationList, mut.Name)
                    end
                end
            end
        end
    end)
    table.sort(MutationList, function(a, b)
        if a == "All" then return true end
        if b == "All" then return false end
        return a < b
    end)
end
crawlMutations()

local function crawlChests()
    pcall(function()
        local chestFolder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Chests")
        if chestFolder then
            for _, tier in ipairs(chestFolder:GetChildren()) do
                if tier.Name:find("Tier") then
                    local found = false
                    for _, v in ipairs(ChestTierList) do
                        if v == tier.Name then
                            found = true; break
                        end
                    end
                    if not found then
                        table.insert(ChestTierList, tier.Name)
                    end
                end
            end
        end
    end)
    table.sort(ChestTierList)
end
crawlChests()

local crawlShop -- Forward declaration

-- UI Builders
local function createPremiumDropdown(parent, txt, subtitle, list, configKey, singleSelect, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, -10, 0, 45)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(0.6, 0, 0, 15); lbl.Position = UDim2.new(0, 0, 0, 2)
    lbl.Text = txt; lbl.TextColor3 = Color3.new(0.9, 0.9, 0.9); lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local sLbl = Instance.new("TextLabel", frame)
    sLbl.Size = UDim2.new(0.6, 0, 0, 12); sLbl.Position = UDim2.new(0, 0, 0, 16)
    sLbl.Text = subtitle; sLbl.TextColor3 = Color3.new(0.5, 0.5, 0.5); sLbl.Font = Enum.Font.GothamMedium
    sLbl.TextSize = 8; sLbl.BackgroundTransparency = 1; sLbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.35, 0, 0, 24); btn.Position = UDim2.new(0.65, -5, 0, 10)
    btn.BackgroundColor3 = Color3.fromRGB(28, 30, 40); btn.Text = "Select... "; btn.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 9; btn.ClipsDescendants = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.fromRGB(45, 48, 60); stroke.Thickness = 1

    local arrow = Instance.new("TextLabel", btn)
    arrow.Size = UDim2.new(0, 20, 1, 0); arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.Text = "v"; arrow.TextColor3 = Color3.new(0.6, 0.6, 0.6); arrow.BackgroundTransparency = 1; arrow.Font = Enum
        .Font.GothamBold

    local menu = Instance.new("ScrollingFrame", ScreenGui) -- Floating menu
    menu.Size = UDim2.new(0, 180, 0, 150); menu.BackgroundColor3 = Color3.fromRGB(24, 25, 32)
    menu.BorderSizePixel = 0; menu.Visible = false; menu.ZIndex = 100
    menu.ScrollBarThickness = 2; menu.ScrollBarImageColor3 = Color3.fromRGB(45, 125, 255)
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)
    local mStroke = Instance.new("UIStroke", menu); mStroke.Color = Color3.fromRGB(60, 60, 75); mStroke.Thickness = 1

    local mLayout = Instance.new("UIListLayout", menu); mLayout.Padding = UDim.new(0, 2)
    Instance.new("UIPadding", menu).PaddingTop = UDim.new(0, 4)

    local function updateSummary()
        if singleSelect then
            btn.Text = tostring(Config[configKey]) .. " "
            return
        end
        local selected = {}
        for k, v in pairs(Config[configKey]) do if v then table.insert(selected, k) end end
        if #selected == 0 then
            btn.Text = "None "
        elseif #selected == 1 then
            btn.Text = selected[1] .. " "
        else
            btn.Text = #
                selected .. " Selected "
        end
    end

    local function rebuildMenu()
        for _, c in ipairs(menu:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _, name in ipairs(list) do
            local b = Instance.new("TextButton", menu)
            b.Size = UDim2.new(1, -4, 0, 24); b.BackgroundTransparency = 1

            local displayTxt = "  " .. name
            if ItemPrices[name] then
                displayTxt = displayTxt .. " ($" .. ItemPrices[name] .. ")"
            end

            local function updateAppearance()
                local isSelected = singleSelect and Config[configKey] == name or Config[configKey][name]
                b.TextColor3 = isSelected and Color3.new(1, 1, 1) or Color3.new(0.6, 0.6, 0.6)
                b.BackgroundColor3 = isSelected and Color3.fromRGB(45, 125, 255) or Color3.fromRGB(30, 31, 40)
                b.BackgroundTransparency = isSelected and 0 or 1
            end

            b.Text = displayTxt
            b.Font = Enum.Font.GothamMedium; b.TextSize = 9; b.TextXAlignment = Enum.TextXAlignment.Left; b.ZIndex = 101
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
            updateAppearance()

            b.MouseButton1Click:Connect(function()
                if singleSelect then
                    Config[configKey] = name
                    menu.Visible = false
                else
                    Config[configKey][name] = not Config[configKey][name]
                    updateAppearance() -- Immediate feedback
                end
                updateSummary()
                if callback then callback(name) end
            end)
        end
        task.wait(0.01)
        local itemsCount = #list
        local contentSize = itemsCount * 26 + 10
        menu.CanvasSize = UDim2.new(0, 0, 0, contentSize)
        menu.Size = UDim2.new(0, 180, 0, math.min(contentSize, 180))
    end

    btn.MouseButton1Click:Connect(function()
        if menu.Visible then
            menu.Visible = false
        else
            if configKey == "ShopItem" and crawlShop then crawlShop() end -- Refresh prices for shop
            rebuildMenu()
            menu.Position = UDim2.new(0, btn.AbsolutePosition.X - 180 + btn.AbsoluteSize.X, 0,
                btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 36)
            menu.Visible = true
        end
    end)

    updateSummary()
    return frame
end

local function createPremiumToggle(parent, txt, key, activeColor)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 35)
    f.BackgroundTransparency = 1

    local cb = Instance.new("TextButton", f)
    cb.Size = UDim2.new(0, 18, 0, 18)
    cb.Position = UDim2.new(0, 5, 0.5, -9)
    cb.BackgroundColor3 = Color3.fromRGB(35, 37, 45)
    cb.Text = ""
    Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 4)
    local ck = Instance.new("Frame", cb)
    ck.Size = UDim2.new(0.6, 0, 0.6, 0); ck.Position = UDim2.new(0.2, 0, 0.2, 0)
    ck.BackgroundColor3 = activeColor or Color3.fromRGB(255, 64, 128); ck.Visible = Config[key]
    Instance.new("UICorner", ck).CornerRadius = UDim.new(0, 2)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -35, 1, 0); lbl.Position = UDim2.new(0, 30, 0, 0)
    lbl.Text = txt; lbl.TextColor3 = Color3.new(0.9, 0.9, 0.9); lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left

    cb.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        ck.Visible = Config[key]

        -- Auto-capture HomePos if it's the AutoCatch toggle and HomePos is nil
        if key == "AutoCatch" and Config[key] and not Config.HomePos then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                Config.HomePos = root.CFrame
                print("[AquaFlow] Auto-captured Return Spot at: " .. tostring(root.Position))
            end
        end
    end)
end

local function createPremiumButton(parent, txt, subtitle, btnTxt, color, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 45)
    f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.6, 0, 0, 15); lbl.Position = UDim2.new(0, 5, 0, 5)
    lbl.Text = txt; lbl.TextColor3 = Color3.new(0.9, 0.9, 0.9); lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10; lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local sLbl = Instance.new("TextLabel", f)
    sLbl.Size = UDim2.new(0.6, 0, 0, 12); sLbl.Position = UDim2.new(0, 5, 0, 20)
    sLbl.Text = subtitle; sLbl.TextColor3 = Color3.new(0.5, 0.5, 0.5); sLbl.Font = Enum.Font.GothamMedium
    sLbl.TextSize = 8; sLbl.BackgroundTransparency = 1; sLbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0.35, 0, 0, 24); btn.Position = UDim2.new(0.65, -5, 0, 10)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 125, 255); btn.Text = btnTxt
    btn.TextColor3 = Color3.new(1, 1, 1); btn.Font = Enum.Font.GothamBold; btn.TextSize = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local stroke = Instance.new("UIStroke", btn); stroke.Color = Color3.new(1, 1, 1); stroke.Thickness = 0.5
    stroke.Transparency = 0.8

    btn.MouseButton1Click:Connect(function()
        if callback then callback(btn) end
    end)
    return f, btn
end

local function createCategoryHeader(parent, text)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1, -10, 0, 30)
    container.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", container)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.Text = text:upper()
    lbl.TextColor3 = Color3.fromRGB(45, 125, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local bar = Instance.new("Frame", container)
    bar.Size = UDim2.new(1, 0, 0, 2)
    bar.Position = UDim2.new(0, 0, 0, 22)
    bar.BackgroundColor3 = Color3.fromRGB(45, 125, 255)
    bar.BorderSizePixel = 0
    local grad = Instance.new("UIGradient", bar)
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    })
end

-- [ FISHING PAGE CONTENT ]
createCategoryHeader(FishingPage, "Fish Farm")

createPremiumDropdown(FishingPage, "Select Fish", "Target specific species", FishList, "SelectedFish")
createPremiumDropdown(FishingPage, "Select Mutations", "Filter by fish mutation", MutationList, "SelectedMutations")
local TargetModeList = { "Highest HP", "Nearest", "Mutation Only" }
createPremiumDropdown(FishingPage, "Target Mode", "Choose targeting priority", TargetModeList, "TargetMode", true)

createPremiumToggle(FishingPage, "Auto Farm Fish", "AutoCatch", Color3.fromRGB(150, 255, 100))
createPremiumToggle(FishingPage, "Hunter Tween (Follow Fish)", "HunterMode", Color3.fromRGB(180, 80, 255))
createPremiumToggle(FishingPage, "Auto Minigame", "AutoMinigame", Color3.fromRGB(45, 125, 255))

-- Oxygen Settings
createCategoryHeader(FishingPage, "Oxygen Settings")

local OxySet = Instance.new("Frame", FishingPage)
OxySet.Size = UDim2.new(1, -10, 0, 35); OxySet.BackgroundTransparency = 1
local oLbl = Instance.new("TextLabel", OxySet)
oLbl.Size = UDim2.new(0.6, 0, 1, 0); oLbl.Text = "Refill Oxygen At (%):"; oLbl.TextColor3 = Color3.new(0.6, 0.6, 0.6)
oLbl.Font = Enum.Font.GothamMedium; oLbl.TextSize = 9; oLbl.BackgroundTransparency = 1; oLbl.TextXAlignment = Enum
    .TextXAlignment.Left
local oInp = Instance.new("TextBox", OxySet)
oInp.Size = UDim2.new(0.3, 0, 0, 22); oInp.Position = UDim2.new(0.65, 0, 0.5, -11)
oInp.BackgroundColor3 = Color3.fromRGB(28, 30, 40); oInp.Text = tostring(Config.MinOxygen)
oInp.TextColor3 = Color3.new(1, 1, 1); oInp.Font = Enum.Font.GothamBold; oInp.TextSize = 10
Instance.new("UICorner", oInp).CornerRadius = UDim.new(0, 4)
oInp.FocusLost:Connect(function() Config.MinOxygen = tonumber(oInp.Text) or Config.MinOxygen end)

createPremiumToggle(FishingPage, "Auto Refill oxygen", "AutoRefill", Color3.fromRGB(45, 125, 255))

-- Configuration
createCategoryHeader(FishingPage, "Configuration")

createPremiumToggle(FishingPage, "Auto Sell Inventory", "AutoSell", Color3.fromRGB(255, 170, 0))

local WeightSet = Instance.new("Frame", FishingPage)
WeightSet.Size = UDim2.new(1, -10, 0, 35); WeightSet.BackgroundTransparency = 1
local wLbl = Instance.new("TextLabel", WeightSet)
wLbl.Size = UDim2.new(0.6, 0, 1, 0); wLbl.Text = "Sell At Weight (KG):"; wLbl.TextColor3 = Color3.new(0.6, 0.6, 0.6)
wLbl.Font = Enum.Font.GothamMedium; wLbl.TextSize = 9; wLbl.BackgroundTransparency = 1; wLbl.TextXAlignment = Enum
    .TextXAlignment.Left
local wInp = Instance.new("TextBox", WeightSet)
wInp.Size = UDim2.new(0.3, 0, 0, 22); wInp.Position = UDim2.new(0.65, 0, 0.5, -11)
wInp.BackgroundColor3 = Color3.fromRGB(28, 30, 40); wInp.Text = tostring(Config.TargetWeight)
wInp.TextColor3 = Color3.new(1, 1, 1); wInp.Font = Enum.Font.GothamBold; wInp.TextSize = 10
Instance.new("UICorner", wInp).CornerRadius = UDim.new(0, 4)
wInp.FocusLost:Connect(function() Config.TargetWeight = tonumber(wInp.Text) or Config.TargetWeight end)

local SpeedSet = Instance.new("Frame", FishingPage)
SpeedSet.Size = UDim2.new(1, -10, 0, 35); SpeedSet.BackgroundTransparency = 1
local sLbl = Instance.new("TextLabel", SpeedSet)
sLbl.Size = UDim2.new(0.6, 0, 1, 0); sLbl.Text = "Tween Speed (Studs/s):"; sLbl.TextColor3 = Color3.new(0.6, 0.6, 0.6)
sLbl.Font = Enum.Font.GothamMedium; sLbl.TextSize = 9; sLbl.BackgroundTransparency = 1; sLbl.TextXAlignment = Enum
    .TextXAlignment.Left
local sInp = Instance.new("TextBox", SpeedSet)
sInp.Size = UDim2.new(0.3, 0, 0, 22); sInp.Position = UDim2.new(0.65, 0, 0.5, -11)
sInp.BackgroundColor3 = Color3.fromRGB(28, 30, 40); sInp.Text = string.format("%.0f", Config.TweenSpeed)
sInp.TextColor3 = Color3.new(1, 1, 1); sInp.Font = Enum.Font.GothamBold; sInp.TextSize = 10
Instance.new("UICorner", sInp).CornerRadius = UDim.new(0, 4)
sInp.FocusLost:Connect(function() Config.TweenSpeed = tonumber(sInp.Text) or Config.TweenSpeed end)

local SetHome = Instance.new("TextButton", FishingPage)
SetHome.Size = UDim2.new(1, -10, 0, 30); SetHome.BackgroundColor3 = Color3.fromRGB(255, 64, 128)
SetHome.Text = "SET RETURN SPOT"; SetHome.TextColor3 = Color3.new(1, 1, 1); SetHome.Font = Enum.Font.GothamBold; SetHome.TextSize = 10
Instance.new("UICorner", SetHome).CornerRadius = UDim.new(0, 6)
SetHome.MouseButton1Click:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
        Config.HomePos = LocalPlayer.Character.PrimaryPart.CFrame
        SetHome.Text = "SPOT SAVED!"; task.wait(1); SetHome.Text = "SET RETURN SPOT"
    end
end)

-- Chest Farm Section
createCategoryHeader(FishingPage, "Chests Farm")

createPremiumDropdown(FishingPage, "Select Chests", "Choose tiers to farm", ChestTierList, "SelectedChests")
createPremiumToggle(FishingPage, "Auto Farm Chests", "AutoChest", Color3.fromRGB(255, 215, 0))

-- Status & Footer Display
local Footer = Instance.new("Frame", Main)
Footer.Name = "Footer"
Footer.Size = UDim2.new(1, 0, 0, 30)
Footer.Position = UDim2.new(0, 0, 1, -30)
Footer.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
Footer.BorderSizePixel = 0

local FooterLine = Instance.new("Frame", Footer)
FooterLine.Size = UDim2.new(1, 0, 0, 1)
FooterLine.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
FooterLine.BackgroundTransparency = 0.5
FooterLine.BorderSizePixel = 0

StatusTxt = Instance.new("TextLabel", Footer)
StatusTxt.Size = UDim2.new(0.5, -10, 1, 0); StatusTxt.Position = UDim2.new(0, 15, 0, 0)
StatusTxt.Text = "STATUS: IDLE"; StatusTxt.TextColor3 = Color3.new(0.6, 0.6, 0.6)
StatusTxt.Font = Enum.Font.GothamBold; StatusTxt.TextSize = 8; StatusTxt.BackgroundTransparency = 1; StatusTxt.TextXAlignment =
    Enum.TextXAlignment.Left

WeightDisplay = Instance.new("TextLabel", Footer)
WeightDisplay.Size = UDim2.new(0.5, -10, 1, 0); WeightDisplay.Position = UDim2.new(0.5, 0, 0, 0)
WeightDisplay.Text = "CARGO: 0/0 KG | OXY: 100%"; WeightDisplay.TextColor3 = Color3.new(0.5, 0.5, 0.5)
WeightDisplay.Font = Enum.Font.GothamMedium; WeightDisplay.TextSize = 8; WeightDisplay.BackgroundTransparency = 1; WeightDisplay.TextXAlignment =
    Enum.TextXAlignment.Right

-- Dynamically crawl locations
local function crawlTravel()
    pcall(function()
        local teleporters = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Teleporters")
        if teleporters then
            for _, location in ipairs(teleporters:GetChildren()) do
                local found = false
                for _, v in ipairs(TravelList) do
                    if v == location.Name then
                        found = true; break
                    end
                end
                if not found then table.insert(TravelList, location.Name) end
            end
        end
    end)
    table.sort(TravelList)
end
crawlTravel()

-- Dynamically crawl shop items and prices
crawlShop = function()
    pcall(function()
        -- Clear old items to avoid duplicates or mixed types (strings vs tables)
        for i = #ShopItemList, 1, -1 do ShopItemList[i] = nil end

        local common = ReplicatedStorage:FindFirstChild("common")
        local assets = common and common:FindFirstChild("assets")

        local interactables = workspace:FindFirstChild("Game") and
            workspace.Game:FindFirstChild("Interactables") and
            workspace.Game.Interactables:FindFirstChild("Equipment")

        local categories = { "guns", "tubes" }

        for _, cat in ipairs(categories) do
            local catAssets = assets and assets:FindFirstChild(cat)
            if catAssets then
                for _, item in ipairs(catAssets:GetChildren()) do
                    local found = false
                    for _, v in ipairs(ShopItemList) do
                        if v.name == item.Name then
                            found = true; break
                        end
                    end
                    if not found then
                        table.insert(ShopItemList, { name = item.Name, category = cat })
                    end

                    -- Try to find price in workspace
                    if interactables then
                        -- Special case for specific prompts or generic equipment
                        local promptOwner = interactables:FindFirstChild(item.Name)
                        if not promptOwner and item.Name == "Plane" then
                            promptOwner = interactables:FindFirstChild("Pufferfish")
                        end

                        if promptOwner then
                            -- Look for prompt in common containers (Base, RootPart, etc.)
                            local containers = { "Base", "base", "RootPart", "rootpart", "Root" }
                            local prompt = nil
                            for _, cName in ipairs(containers) do
                                local container = promptOwner:FindFirstChild(cName)
                                if container then
                                    prompt = container:FindFirstChild("Prompt") or
                                        container:FindFirstChildWhichIsA("ProximityPrompt") or
                                        container:FindFirstChildWhichIsA("TextLabel")
                                    if prompt then break end
                                end
                            end

                            -- Fallback: Check directly on the owner
                            prompt = prompt or promptOwner:FindFirstChild("Prompt") or
                                promptOwner:FindFirstChildWhichIsA("ProximityPrompt")

                            if prompt then
                                local text = prompt:IsA("ProximityPrompt") and (prompt.ActionText or "") or
                                    (prompt.Text or "")
                                -- Strip rich text tags like <font color="..."> and then match $X,XXX
                                local cleanText = text:gsub("<[^>]+>", "")
                                local price = cleanText:match("%$([%d,]+)")
                                if price then
                                    ItemPrices[item.Name] = price
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    table.sort(ShopItemList, function(a, b)
        local an = a and a.name or ""
        local bn = b and b.name or ""
        return an < bn
    end)
end
crawlShop()

createCategoryHeader(TravelPage, "Location Select")
createPremiumDropdown(TravelPage, "Select Destination", "Choose a place to travel", TravelList, "TravelLocation", true)

local _, GoBtn = createPremiumButton(TravelPage, "Teleport System", "Instant travel to selected area", "TELEPORT",
    Color3.fromRGB(45, 125, 255), function(btn)
        local target = Config.TravelLocation
        if target == "None" then return end

        local teleporters = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Teleporters")
        local location = teleporters and teleporters:FindFirstChild(target)
        local part = location and
            (location:IsA("BasePart") and location or location:FindFirstChildWhichIsA("BasePart", true))

        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root or not part or not smoothTween then return end

        btn.Text = "WAITING..."
        local dest = part.CFrame
        smoothTween(root.CFrame + Vector3.new(0, 220, 0))
        smoothTween(dest + Vector3.new(0, 220, 0))
        smoothTween(dest + Vector3.new(0, 3, 0))
        btn.Text = "ARRIVED!"
        task.wait(1)
        btn.Text = "TELEPORT"
    end)

-- Shop Section on TravelPage
createCategoryHeader(TravelPage, "Equipment Shop")

local CurrentShopItems = {} -- Table that will be updated dynamically

local function updateFilteredShopList()
    -- Compatible table clear
    for i = #CurrentShopItems, 1, -1 do CurrentShopItems[i] = nil end
    table.insert(CurrentShopItems, "None")
    for _, item in ipairs(ShopItemList) do
        if item.category == Config.ShopCategory then
            table.insert(CurrentShopItems, item.name)
        end
    end
end

local _, BuyBtn = createPremiumButton(TravelPage, "Purchase System", "Buy selected gear instantly", "BUY ITEM",
    Color3.fromRGB(255, 64, 128), function(btn)
        local item = Config.ShopItem
        if item == "None" or not item then return end

        btn.Text = "BUYING..."
        local success, err = pcall(function()
            -- Pass the item's category dynamically
            return BuyItem:InvokeServer(item, 1, Config.ShopCategory)
        end)

        if success then
            btn.Text = "SUCCESS!"
        else
            btn.Text = "FAILED!"
        end
        task.wait(1)
        local price = ItemPrices[item]
        btn.Text = price and ("BUY (" .. price .. ")") or "BUY ITEM"
    end)

createPremiumDropdown(TravelPage, "Shop Category", "Switch between guns and tubes", { "guns", "tubes" }, "ShopCategory",
    true, function(val)
        Config.ShopItem = "None"
        updateFilteredShopList()
        BuyBtn.Text = "BUY ITEM"
    end)

updateFilteredShopList() -- Initial population

createPremiumDropdown(TravelPage, "Select Item", "Choose gear to purchase", CurrentShopItems, "ShopItem", true,
    function(val)
        local price = ItemPrices[val]
        BuyBtn.Text = price and ("BUY (" .. price .. ")") or "BUY ITEM"
    end)

-- [ QUEST PAGE CONTENT ]
createCategoryHeader(QuestPage, "Auto Quest")
createPremiumToggle(QuestPage, "Auto Quest (Catch/Bring/Crack)", "AutoQuest", Color3.fromRGB(64, 255, 128))
createPremiumToggle(QuestPage, "Protect Bring Fish (Don't Sell)", "BringProtect", Color3.fromRGB(255, 170, 0))

local QuestStatusLabel = Instance.new("TextLabel", QuestPage)
QuestStatusLabel.Size = UDim2.new(1, -10, 0, 80)
QuestStatusLabel.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
QuestStatusLabel.TextColor3 = Color3.new(0.7, 0.7, 0.7)
QuestStatusLabel.Font = Enum.Font.GothamMedium
QuestStatusLabel.TextSize = 9
QuestStatusLabel.Text = "Quest status will appear here..."
QuestStatusLabel.TextWrapped = true
QuestStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
Instance.new("UICorner", QuestStatusLabel).CornerRadius = UDim.new(0, 6)
local qlPad = Instance.new("UIPadding", QuestStatusLabel)
qlPad.PaddingTop = UDim.new(0, 8); qlPad.PaddingLeft = UDim.new(0, 8)

createCategoryHeader(QuestPage, "Manual Quest TP")

local QuestBtn = Instance.new("TextButton", QuestPage)
QuestBtn.Size = UDim2.new(1, -10, 0, 35); QuestBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 255)
QuestBtn.Text = "TP TO ACTIVE QUEST ITEM"; QuestBtn.TextColor3 = Color3.new(1, 1, 1)
QuestBtn.Font = Enum.Font.GothamBold; QuestBtn.TextSize = 10
Instance.new("UICorner", QuestBtn).CornerRadius = UDim.new(0, 8)
QuestBtn.MouseButton1Click:Connect(function()
    local partsRoot = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("QuestItems") and
        workspace.Game.QuestItems:FindFirstChild("TeleporterParts")
    if not partsRoot then
        QuestBtn.Text = "ERR: NO PARTS"; task.wait(1); QuestBtn.Text = "TP TO QUEST ITEM"; return
    end
    local items = partsRoot:GetChildren()
    for _, item in ipairs(items) do
        local p = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart", true)
        if p then
            QuestBtn.Text = "TP: " .. item.Name:upper()
            smoothTween(p.CFrame + Vector3.new(0, 3, 0))
            QuestBtn.Text = "ARRIVED!"; task.wait(1); QuestBtn.Text = "TP TO QUEST ITEM"
            return
        end
    end
    QuestBtn.Text = "NO ITEMS"; task.wait(1); QuestBtn.Text = "TP TO QUEST ITEM"
end)

-- [[ QUEST PARSER & AUTO-QUEST SYSTEM ]]
local function parseAllQuests()
    local quests = {}
    local questsUI = MainGui:FindFirstChild("RightCenter")
        and MainGui.RightCenter:FindFirstChild("CanvasGroup")
        and MainGui.RightCenter.CanvasGroup:FindFirstChild("Quests")
    if not questsUI then return quests end

    for _, qFrame in ipairs(questsUI:GetChildren()) do
        if qFrame:IsA("Frame") or qFrame:IsA("CanvasGroup") then
            local black = qFrame:FindFirstChild("Black")
            local titleLbl = black and black:FindFirstChild("Title") and black.Title:FindFirstChild("Title")
            local progressLbl = black and black:FindFirstChild("Goal") and black.Goal:FindFirstChild("Progress")

            if titleLbl and progressLbl then
                local titleText = titleLbl.Text:gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
                local cur, total = progressLbl.Text:match("(%d+)%s*/%s*(%d+)")
                cur, total = tonumber(cur), tonumber(total)

                -- Parse NPC from frame name: "Lumi_Catch %s Napoleon"
                local npcName = qFrame.Name:match("^([^_]+)_")
                -- Parse action: Catch, Bring, Crack, Find, Kill, etc.
                local action = titleText:match("^(%a+)%s")
                -- Parse target: everything after the count
                local target = titleText:match("^%a+%s+%d+%s+(.+)$")

                if action and cur and total then
                    local isMutation = false
                    local mutationName = nil
                    local fishName = target

                    -- Detect mutation quests: "Fairy-Mutated Fish" -> mutation=Fairy, fish=any
                    if target and target:find("%-Mutated Fish") then
                        isMutation = true
                        mutationName = target:match("(.-)%-Mutated")
                        fishName = nil -- any fish with this mutation
                    end

                    table.insert(quests, {
                        npc = npcName,
                        action = action,
                        target = target,
                        fishName = fishName,
                        isMutation = isMutation,
                        mutationName = mutationName,
                        current = cur,
                        total = total,
                        done = (cur >= total),
                        frameName = qFrame.Name
                    })
                end
            end
        end
    end
    return quests
end

local function findNpcPart(npcName)
    -- Search workspace for NPC by name
    local function search(parent, depth)
        if depth > 5 then return nil end
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == npcName then
                return child:FindFirstChild("HumanoidRootPart")
                    or child:FindFirstChildWhichIsA("BasePart")
            end
            local found = search(child, depth + 1)
            if found then return found end
        end
        return nil
    end
    return search(workspace, 0)
end

-- Quest Auto-Loop
task.spawn(function()
    while task.wait(3) do
        if not checkScriptActive() then break end
        if not Config.AutoQuest then
            Config._questOverrideFish = nil
            Config._questOverrideMutation = nil
            Config._activeQuestType = nil
            Config._activeQuestNpc = nil
            QuestStatusLabel.Text = "Auto Quest: OFF"
            task.wait(2)
        else
            local quests = parseAllQuests()
            local statusLines = {}

            -- Find first uncompleted quest (priority: Catch > Bring > Crack)
            local activeQuest = nil
            local priorityOrder = { Catch = 1, Bring = 2, Crack = 3 }
            table.sort(quests, function(a, b)
                local pa = priorityOrder[a.action] or 99
                local pb = priorityOrder[b.action] or 99
                if pa ~= pb then return pa < pb end
                return (a.total - a.current) < (b.total - b.current)
            end)

            for _, q in ipairs(quests) do
                local mark = q.done and "✅" or "⬜"
                local line = mark ..
                    " " .. q.action .. " " .. (q.target or "?") .. " (" .. q.current .. "/" .. q.total .. ")"
                table.insert(statusLines, line)
                if not q.done and not activeQuest then
                    activeQuest = q
                end
            end

            QuestStatusLabel.Text = #statusLines > 0
                and table.concat(statusLines, "\n")
                or "No quests found"

            if activeQuest then
                local q = activeQuest
                Config._activeQuestType = q.action
                Config._activeQuestNpc = q.npc

                if q.action == "Catch" or q.action == "Bring" then
                    -- Override fish targeting
                    if q.isMutation then
                        Config._questOverrideFish = nil
                        Config._questOverrideMutation = q.mutationName
                    else
                        Config._questOverrideFish = q.fishName
                        Config._questOverrideMutation = nil
                    end

                    StatusTxt.Text = "QUEST: " ..
                        q.action .. " " .. (q.target or "?") .. " (" .. q.current .. "/" .. q.total .. ")"
                    StatusTxt.TextColor3 = Color3.fromRGB(64, 255, 128)
                elseif q.action == "Crack" then
                    Config._questOverrideFish = nil
                    Config._questOverrideMutation = nil
                    -- Parse geode type from target: "Rooted Geodes" → "Rooted"
                    local geodeType = q.target and q.target:match("^(%S+)%s+Geode") or "Rooted"
                    local crackCount = q.total - q.current
                    if crackCount <= 0 then crackCount = 1 end

                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local vPart = findNpcPart("Virelia")
                    if root and vPart and not isSelling then
                        StatusTxt.Text = "QUEST: Going to Virelia to crack " .. crackCount .. "x " .. geodeType .. "..."
                        StatusTxt.TextColor3 = Color3.fromRGB(255, 200, 64)
                        -- Fly to Virelia
                        smoothTween(root.CFrame + Vector3.new(0, 220, 0))
                        smoothTween(CFrame.new(vPart.Position) + Vector3.new(0, 220, 0))
                        smoothTween(CFrame.new(vPart.Position) + Vector3.new(0, 5, 0))
                        task.wait(1)
                        -- Step 1: Talk to Virelia
                        pcall(function() SubmitNpcDialogueInteract:InvokeServer("Virelia", "talk_to") end)
                        task.wait(2)
                        -- Step 2: Open geodes (tab auto-selects)
                        task.wait(1)
                        pcall(function() GeodeOpen:InvokeServer(geodeType, crackCount) end)
                        StatusTxt.Text = "QUEST: Cracked " .. crackCount .. "x " .. geodeType .. "!"
                        StatusTxt.TextColor3 = Color3.fromRGB(64, 255, 128)
                        task.wait(2)
                        -- Return home
                        if Config.HomePos then
                            smoothTween(CFrame.new(vPart.Position) + Vector3.new(0, 220, 0))
                            smoothTween(Config.HomePos + Vector3.new(0, 220, 0))
                            smoothTween(Config.HomePos)
                        end
                    end
                else
                    -- Unknown quest type - skip
                    Config._questOverrideFish = nil
                    Config._questOverrideMutation = nil
                end

                -- Check if all quests for this NPC are done → finish & claim
                local allDone = true
                for _, q2 in ipairs(quests) do
                    if q2.npc == q.npc and not q2.done then
                        allDone = false; break
                    end
                end
                if allDone and q.npc then
                    pcall(function() FinishQuest:InvokeServer(q.npc) end)
                    task.wait(1)
                    pcall(function() ClaimQuest:InvokeServer(q.npc) end)
                    StatusTxt.Text = "QUEST: Claimed reward from " .. q.npc .. "!"
                    StatusTxt.TextColor3 = Color3.fromRGB(255, 215, 0)
                    task.wait(2)
                end
            else
                Config._questOverrideFish = nil
                Config._questOverrideMutation = nil
                Config._activeQuestType = nil
            end
        end
    end
end)

-- Bring delivery loop: when catching is done and we have fish for Bring quest
task.spawn(function()
    while task.wait(5) do
        if not checkScriptActive() then break end
        if Config.AutoQuest and Config._activeQuestType == "Bring" and Config._activeQuestNpc then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and not isSelling then
                local npc = Config._activeQuestNpc
                local npcPart = findNpcPart(npc)
                if npcPart then
                    -- Check if we should deliver (every 5 fish caught or weight is getting high)
                    local w = MainGui:FindFirstChild("Wght", true)
                    local cur = w and parseNum(w.Text) or 0
                    if cur > 10 then
                        StatusTxt.Text = "QUEST: Delivering to " .. npc .. "..."
                        StatusTxt.TextColor3 = Color3.fromRGB(255, 170, 64)
                        smoothTween(root.CFrame + Vector3.new(0, 220, 0))
                        smoothTween(CFrame.new(npcPart.Position) + Vector3.new(0, 220, 0))
                        smoothTween(CFrame.new(npcPart.Position) + Vector3.new(0, 5, 0))
                        task.wait(1)
                        pcall(function() SubmitNpcInteract:InvokeServer(npc, "bring_item") end)
                        task.wait(2)
                        if Config.HomePos then
                            smoothTween(CFrame.new(npcPart.Position) + Vector3.new(0, 220, 0))
                            smoothTween(Config.HomePos + Vector3.new(0, 220, 0))
                            smoothTween(Config.HomePos)
                        end
                    end
                end
            end
        end
    end
end)

-- Chest Farm Logic
local function checkChestState(chestFolder)
    local chest = chestFolder:FindFirstChild("Chest")
    if not chest then return true end -- Gone = Opened

    local main = chest:FindFirstChild("Main")
    if main then
        local bottom = main:FindFirstChild("BottomChest")
        return not (bottom and bottom:FindFirstChild("RewardPart"))
    end
    return not chest:FindFirstChild("RewardPart", true)
end

task.spawn(function()
    local ignoreList = {}
    local chestBlacklist = {
        ["Tier 1"] = { ["71"] = true, ["72"] = true },
        ["Tier 2"] = { ["11"] = true, ["12"] = true }
    }

    while task.wait(1) do
        if not checkScriptActive() then break end
        if Config.AutoChest and not isSelling then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                for tierName, isEnabled in pairs(Config.SelectedChests) do
                    if isEnabled and Config.AutoChest and not isSelling then
                        local folder = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Chests")
                            and workspace.Game.Chests:FindFirstChild(tierName)

                        if folder then
                            local targets = {}
                            for _, chestFolder in ipairs(folder:GetChildren()) do
                                local blacklisted = chestBlacklist[tierName] and
                                    chestBlacklist[tierName][chestFolder.Name]
                                if not blacklisted and not ignoreList[chestFolder.Name] then
                                    if not checkChestState(chestFolder) then
                                        local p = chestFolder:FindFirstChildWhichIsA("BasePart", true)
                                        if p then table.insert(targets, { folder = chestFolder, part = p }) end
                                    end
                                end
                            end

                            -- Open nearest
                            if #targets > 0 then
                                isOpeningChests = true
                                table.sort(targets, function(a, b)
                                    return (root.Position - a.part.Position).Magnitude <
                                        (root.Position - b.part.Position).Magnitude
                                end)

                                local targetData = targets[1]
                                StatusTxt.Text = "CHEST: OPENING (" .. targetData.folder.Name .. ")"
                                StatusTxt.TextColor3 = Color3.fromRGB(255, 215, 0)

                                smoothTween(targetData.part.CFrame + Vector3.new(0, 5, 0))

                                pcall(function()
                                    game:GetService("ReplicatedStorage"):WaitForChild("common"):WaitForChild("packages")
                                        :WaitForChild("Knit"):WaitForChild("Services"):WaitForChild("ChestService")
                                        :WaitForChild("RF"):WaitForChild("UnlockChest"):InvokeServer(tierName,
                                        targetData.folder.Name)
                                end)

                                -- Faster verify
                                local start = tick()
                                while tick() - start < 2.5 do
                                    if checkChestState(targetData.folder) then break end
                                    task.wait(0.1)
                                end

                                ignoreList[targetData.folder.Name] = true
                                isOpeningChests = false
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- [SECTION 3: Logic Engine]
parseNum = function(txt)
    if not txt then return 0 end
    local clean = txt:gsub(",", ""):match("[%d%.]+")
    return tonumber(clean) or 0
end

isQuestDone = function(questFrame)
    if not questFrame then return false end
    -- พยายามหา Progress Label ตามพาธที่แจ้ง หรือค้นหาในลูกๆ
    local black = questFrame:FindFirstChild("Black")
    local goal = black and black:FindFirstChild("Goal")
    local progress = goal and goal:FindFirstChild("Progress")
    if not progress then progress = questFrame:FindFirstChild("Progress", true) end

    if progress and progress:IsA("TextLabel") then
        local cur, max = progress.Text:match("(%d+)%s*/%s*(%d+)")
        if cur and max then
            local isDone = tonumber(cur) >= tonumber(max)
            print(string.format("[QUEST] %s Progress: %s/%s (Done: %s)", questFrame.Name, cur, max, tostring(isDone)))
            return isDone
        end
    end
    return false
end

getMaxHealth = function(fish)
    local head = fish:FindFirstChild("Head")
    local stats = head and head:FindFirstChild("stats")
    if not stats then return 0 end

    -- 1. ลำดับแรก: ตามพิกัดที่แจ้ง stats.Health.Amount
    local healthFolder = stats:FindFirstChild("Health")
    if healthFolder then
        local amountLabel = healthFolder:FindFirstChild("Amount")
        if amountLabel and amountLabel:IsA("TextLabel") then
            -- ดึงเลขตัวที่สอง (Denominator) จาก format "118/158"
            local maxVal = amountLabel.Text:match("/%s*([%d%,%.]+)") or amountLabel.Text:match("([%d%,%.]+)")
            return parseNum(maxVal)
        end

        -- 2. สำรอง: stats.Health.Max
        local maxLabel = healthFolder:FindFirstChild("Max")
        if maxLabel and maxLabel:IsA("TextLabel") then
            return parseNum(maxLabel.Text)
        end

        -- 3. สำรอง: stats.Health (ที่เป็น TextLabel)
        if healthFolder:IsA("TextLabel") then
            local maxVal = healthFolder.Text:match("/%s*([%d%,%.]+)") or healthFolder.Text:match("([%d%,%.]+)")
            return parseNum(maxVal)
        end
    end

    -- 4. สำรองสุดท้าย: หาจากลูกๆ ทั้งหมดที่มีคำว่า Health หรือ HP
    for _, child in ipairs(stats:GetChildren()) do
        if child:IsA("TextLabel") and (child.Name:find("Health") or child.Name:find("HP")) then
            return parseNum(child.Text)
        end
    end

    return 0
end

isFishValid = function(fish)
    if not fish or not fish.Parent then return false end

    -- Accept fish even without Head/stats (for special fish like jellyfish, sunfish)
    local head = fish:FindFirstChild("Head")
    if not head then return true end -- No head = probably special fish, allow it

    local stats = head:FindFirstChild("stats")
    if not stats then return true end -- No stats = allow it

    -- Only skip if explicitly despawning
    local despawning = stats:FindFirstChild("Despawning")
    if despawning and despawning.Visible then return false end

    -- Skip if fish is dead (current health = 0)
    local healthFolder = stats:FindFirstChild("Health")
    if healthFolder then
        local amountLabel = healthFolder:FindFirstChild("Amount")
        if amountLabel and amountLabel:IsA("TextLabel") then
            -- Check if text starts with "0" (e.g., "0/150")
            if amountLabel.Text:find("^0") then
                return false -- Dead fish, skip it
            end
        end
    end

    return true
end

getMutationName = function(fish)
    local stats = (fish:FindFirstChild("Head") and fish.Head:FindFirstChild("stats")) or
        (fish:FindFirstChild("RootPart") and fish.RootPart:FindFirstChild("stats"))

    local mutation = stats and stats:FindFirstChild("Mutation")
    local label = mutation and mutation:FindFirstChild("Label")

    if label and label.Text ~= "" and label.Text ~= "None" then
        -- Strip HTML tags and trim
        local clean = label.Text:gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
        if clean == "Shiny" or clean == "" then return "Normal" end
        return clean
    end
    return "Normal"
end

hasMutation = function(fish)
    if Config.SelectedMutations["All"] then return true end
    local mName = getMutationName(fish)
    return Config.SelectedMutations[mName] == true
end

getRealFishName = function(f)
    local stats = (f:FindFirstChild("Head") and f.Head:FindFirstChild("stats")) or
        (f:FindFirstChild("RootPart") and f.RootPart:FindFirstChild("stats"))
    local label = stats and stats:FindFirstChild("Fish")
    return label and label.Text or "Unknown"
end

getBestFish = function()
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end
    local fishRoot = workspace:FindFirstChild("Game") and workspace.Game:FindFirstChild("Fish") and
        workspace.Game.Fish:FindFirstChild("client")
    if not fishRoot then return nil, nil end

    -- Quest override: if AutoQuest is active, override fish/mutation targeting
    local questFish = Config._questOverrideFish
    local questMut = Config._questOverrideMutation
    local useQuestOverride = Config.AutoQuest and (questFish or questMut)

    local bestTarget, bestPart, maxH, minD = nil, nil, -1, math.huge
    local fallbackTarget, fallbackPart, minD_fallback = nil, nil, math.huge
    local farFallbackTarget, farFallbackPart, minD_far = nil, nil, math.huge

    for _, f in ipairs(fishRoot:GetChildren()) do
        if isFishValid(f) and not Blacklist[f.Name] then
            local fishName = getRealFishName(f)
            local mName = getMutationName(f)

            -- Absolute nearest for fallback
            local p = f:IsA("BasePart") and f or f:FindFirstChildWhichIsA("BasePart")
            if p then
                local dist = (root.Position - p.Position).Magnitude
                if dist < minD_fallback then
                    minD_fallback, fallbackTarget, fallbackPart = dist, f, p
                end

                -- "Far" fallback (between 150 and 400 studs - "not too far")
                if dist > 150 and dist < 400 and dist < minD_far then
                    minD_far, farFallbackTarget, farFallbackPart = dist, f, p
                end

                -- Quest override or normal filtering
                local speciesMatch, mutationMatch, isStrictMutation
                if useQuestOverride then
                    speciesMatch = questFish == nil or fishName == questFish
                    mutationMatch = questMut == nil or mName == questMut
                    isStrictMutation = false
                else
                    speciesMatch = Config.SelectedFish["All"] or Config.SelectedFish[fishName]
                    mutationMatch = Config.SelectedMutations["All"] or Config.SelectedMutations[mName]
                    isStrictMutation = (Config.TargetMode == "Mutation Only") and (mName == "Normal")
                end

                if speciesMatch and mutationMatch and not isStrictMutation then
                    if dist <= Config.SearchRange then
                        if Config.TargetMode == "Highest HP" then
                            local health = getMaxHealth(f)
                            if health > maxH or (health == 0 and maxH == -1) then
                                maxH, minD, bestTarget, bestPart = health, dist, f, p
                            elseif health == maxH and dist < minD then
                                minD, bestTarget, bestPart = dist, f, p
                            end
                        elseif Config.TargetMode == "Nearest" or Config.TargetMode == "Mutation Only" then
                            if dist < minD then
                                minD, bestTarget, bestPart = dist, f, p
                            end
                        end
                    end
                end
            end
        end
    end

    if bestTarget then
        return bestTarget, bestPart, maxH, false
    end

    -- Smart Fallback: If already near the absolute nearest, go "far" to refresh
    if fallbackTarget and minD_fallback < 20 and farFallbackTarget then
        return farFallbackTarget, farFallbackPart, -1, true
    end

    return fallbackTarget, fallbackPart, -1, true
end
smoothTween = function(tPos, customSpeed)
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local dist = (tPos.Position - root.Position).Magnitude
    if dist < 0.1 then return end
    local speed = customSpeed or Config.TweenSpeed
    local tween = TweenService:Create(root, TweenInfo.new(dist / speed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        { CFrame = tPos })
    tween:Play()
    tween.Completed:Wait()
end

local function equipItem(slot)
    pcall(function()
        local args = { tostring(slot) }
        game:GetService("ReplicatedStorage"):WaitForChild("common"):WaitForChild("packages"):WaitForChild("Knit")
            :WaitForChild("Services"):WaitForChild("BackpackService"):WaitForChild("RF"):WaitForChild("Equip")
            :InvokeServer(unpack({ tostring(slot) }))
    end)
end

-- Hook Catching
local mt = getrawmetatable(game); setreadonly(mt, false); local old = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
    return old(self, ...)
end); setreadonly(mt, true)

-- Main Catching Loop
local consecutiveFallbacks = 0
task.spawn(function()
    while task.wait(0.1) do
        if not checkScriptActive() then break end
        if Config.AutoCatch and not isSelling then
            -- ค้นหาเป้าหมายที่ไม่ติดแบล็คลิสต์
            local target, part, hp, isFallback = getBestFish()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

            if root then
                -- ตรวจสอบมินิเกม
                local catchingBar = MainGui:FindFirstChild("CatchingBar", true)
                local isActuallyActive = false
                if catchingBar and catchingBar.Visible then
                    local prog = catchingBar:FindFirstChild("Progress", true)
                    if prog and prog.AbsolutePosition.X > 0 and prog.AbsoluteSize.X > 0 then
                        isActuallyActive = true
                    end
                end

                if target then
                    -- ระบบนับเวลา Global (ต่อปลา 1 ตัว)
                    if target ~= lastTargetObj then
                        lastTargetObj = target
                        firstAttemptTime = tick()
                    end

                    local totalElapsed = tick() - firstAttemptTime
                    if totalElapsed > Config.StuckLimit then
                        Blacklist[target.Name] = true
                        StatusTxt.Text = "TIMEOUT! SKIPPING: " .. target.Name:sub(1, 8)
                        StatusTxt.TextColor3 = Color3.fromRGB(255, 64, 64)
                        lastTargetObj = nil
                        task.wait(1)
                    else
                        -- Calculate hpInfo here for reuse
                        local hpInfo = (Config.TargetMode == "Highest HP" and hp and hp > 0) and
                            string.format(" [HP: %s]", hp) or ""

                        if isActuallyActive then
                            StatusTxt.Text = "AUTO MINIGAME ACTIVE..."
                            StatusTxt.TextColor3 = Color3.fromRGB(64, 255, 64)
                        elseif isFallback then
                            StatusTxt.Text = "AREA REFRESH: ZIG-ZAG MOVEMENT"
                            StatusTxt.TextColor3 = Color3.fromRGB(150, 150, 255)
                        else
                            StatusTxt.Text = "FARMING: " .. getRealFishName(target) .. hpInfo
                            StatusTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
                            consecutiveFallbacks = 0 -- Reset counter on successful target
                        end

                        if isActuallyActive then
                            consecutiveFallbacks = 0 -- Reset while actually catching
                        end

                        if not isActuallyActive then
                            -- ถ้ายังไม่เข้าโหมดตกปลา ให้ทำการขยับ/ยิง
                            equipItem("1")
                            if Config.HunterMode then
                                local dir = (root.Position - part.Position).Unit
                                local targetPos = part.Position + (dir * Config.FishDistance) + Vector3.new(0, 5, 0)
                                local distToPos = (root.Position - targetPos).Magnitude

                                if distToPos > 7 then -- ระยะขยับ
                                    smoothTween(CFrame.new(targetPos, part.Position))
                                end
                            end

                            if not isFallback then
                                pcall(function() StartCatching:InvokeServer(target.Name) end)
                            else
                                consecutiveFallbacks = consecutiveFallbacks + 1
                                if consecutiveFallbacks >= 8 and Config.HomePos then
                                    StatusTxt.Text = "REFRESHING: RETURNING HOME..."
                                    StatusTxt.TextColor3 = Color3.fromRGB(255, 100, 255)
                                    smoothTween(root.CFrame + Vector3.new(0, 100, 0))
                                    smoothTween(Config.HomePos + Vector3.new(0, 100, 0))
                                    smoothTween(Config.HomePos)
                                    consecutiveFallbacks = 0
                                    task.wait(2)
                                end
                            end
                        end
                    end
                else
                    StatusTxt.Text = "STATUS: SEARCHING FISH..."
                    StatusTxt.TextColor3 = Color3.new(0.6, 0.6, 0.6)
                    lastTargetObj = nil
                end
            end
        else
            lastTargetObj = nil
        end
    end
end)

-- Auto-Respawn Logic (Refined)
task.spawn(function()
    while task.wait(1) do
        if not checkScriptActive() then break end

        local isDead = false
        pcall(function()
            -- Mode A: Oxygen check
            local oxygenMain = MainGui:FindFirstChild("Oxygen")
            local oLbl = oxygenMain and
                (oxygenMain:FindFirstChild("CanvasGroup") and oxygenMain.CanvasGroup:FindFirstChild("Oxygen") or oxygenMain:FindFirstChild("Oxygen"))
            if oLbl and parseNum(oLbl.Text) <= 0 then
                isDead = true
            end

            -- Mode B: DeathScreen Visibility
            local ds = LocalPlayer.PlayerGui:FindFirstChild("DeathScreen")
            if ds and (ds.Enabled or (ds:FindFirstChild("Frame") and ds.Frame.Visible)) then
                isDead = true
            end
        end)

        if isDead then
            task.wait(5)
            pcall(function()
                local args = { "free" }
                game:GetService("ReplicatedStorage"):WaitForChild("common"):WaitForChild("packages"):WaitForChild("Knit")
                    :WaitForChild("Services"):WaitForChild("MovementService"):WaitForChild("RF"):WaitForChild("Respawn")
                    :InvokeServer(unpack(args))

                -- Manual UI Cleanup
                local ds = LocalPlayer.PlayerGui:FindFirstChild("DeathScreen")
                if ds then
                    ds.Enabled = false
                    if ds:FindFirstChild("Frame") then ds.Frame.Visible = false end
                end
            end)
            task.wait(3) -- Cool down to prevent spam
        end
    end
end)

-- Stats Refresh & Safe Slow Sell
task.spawn(function()
    while task.wait(1) do
        if not checkScriptActive() then break end
        local cur, cap, oxy, isPoisoned = 0, 0, 100, false
        pcall(function()
            local w = MainGui:FindFirstChild("Wght", true)
            local m = MainGui:FindFirstChild("Max", true)
            if w then cur = parseNum(w.Text) end
            if m then cap = parseNum(m.Text) end

            -- Detect Oxygen
            local oxygenMain = MainGui:FindFirstChild("Oxygen")
            local oLbl = oxygenMain and
                (oxygenMain:FindFirstChild("CanvasGroup") and oxygenMain.CanvasGroup:FindFirstChild("Oxygen") or oxygenMain:FindFirstChild("Oxygen"))
            if oLbl then
                oxy = parseNum(oLbl.Text)
            end

            -- Detect Poison
            local RightBottom = MainGui:FindFirstChild("RightBottom")
            local Perks = RightBottom and RightBottom:FindFirstChild("Perks")
            isPoisoned = Perks and Perks:FindFirstChild("Poisoned") ~= nil
        end)

        -- Debugging: Store raw values for logging if needed
        local currentWeight = cur
        local maxWeight = cap

        WeightDisplay.Text = string.format("CARGO: %.1f/%.1f KG | OXY: %d%%", cur, cap, oxy)

        local needRefill = Config.AutoRefill and oxy <= Config.MinOxygen
        local needSell = Config.AutoSell and cur >= Config.TargetWeight

        -- Trigger Sale/Refill logic
        if not isSelling then
            local trigger = false
            local reason = ""

            -- PRIORITY 1: Oxygen (Most Important)
            if needRefill then
                trigger = true
                reason = "LOW OXYGEN!"
                -- PRIORITY 2: Poison
            elseif isPoisoned then
                trigger = true
                reason = "POISONED!"
                -- PRIORITY 3: Weight
            elseif needSell then
                -- Protect fish if Bring quest active
                if Config.AutoQuest and Config.BringProtect and Config._activeQuestType == "Bring" then
                    trigger = false
                    reason = ""
                else
                    trigger = true
                    reason = "CARGO FULL!"
                end
            end

            if trigger then
                isSelling = true
                StatusTxt.Text = "STATUS: " .. reason .. " (SELLING)"
                StatusTxt.TextColor3 = Color3.fromRGB(255, 64, 64)

                -- Hardcoded Sell Position (As requested)
                local sellCFrame = CFrame.new(-7.13436, 4887.0, 125.2232)

                local home = Config.HomePos or
                    (LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and LocalPlayer.Character.PrimaryPart.CFrame)
                if home then
                    -- Start return sequence
                    smoothTween(LocalPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 220, 0))
                    smoothTween(sellCFrame + Vector3.new(0, 220, 0))
                    smoothTween(sellCFrame * CFrame.new(0, 6, 0))

                    task.wait(1.5)
                    pcall(function() SellService:InvokeServer() end)
                    task.wait(2)

                    StatusTxt.Text = "STATUS: RETURNING..."
                    smoothTween(sellCFrame + Vector3.new(0, 220, 0))
                    smoothTween(home + Vector3.new(0, 220, 0))
                    smoothTween(home)
                else
                    -- Fallback for selling if no home/character found (failsafe)
                    pcall(function() SellService:InvokeServer() end)
                end

                isSelling = false
                Blacklist = {} -- Clear blacklist after sell/refill
            end
        end
    end
end)

-- [[ SECTION: MINIGAME AUTO-PLAY (Physics Hack) ]]
-- ใช้ MinigameController แก้ physics ฝั่ง client ให้เล่นเองอัตโนมัติ
-- ได้ปลา + bonus item ทุกรอบ ไม่ต้องทำอะไร (~5 วินาที)

local MC = require(game:GetService("ReplicatedStorage").common.source.controllers.MinigameController)

RunService.RenderStepped:Connect(function()
    if not Config.AutoMinigame then return end
    local ok, gi = pcall(function() return debug.getupvalue(MC.IsMinigameActive, 1) end)
    if ok and gi and type(gi) == "table" and gi.running then
        -- ปิด gravity ให้ progress ขึ้นอย่างเดียว
        gi.progressGravity = 0
        gi.gravityStrength = 0
        -- ขยาย green zone + simulate กดค้าง
        gi.controlBarScale = 50
        gi.holding = true
        gi.momentum = 1
        gi.targetDirection = 1

        -- หา bonus item ที่ยังไม่เก็บ
        local uc
        if gi.rewards then
            for _, r in ipairs(gi.rewards) do
                if r.progress and r.progress < 1 then
                    uc = r
                    break
                end
            end
        end
        -- ถ้ามี bonus → ย้ายปลาไปที่ bonus เพื่อเก็บ
        if uc and uc.pos then
            gi._markerCurrent = uc.pos
            gi._markerTarget = uc.pos
        end
        -- zone ตามปลาเสมอ
        if gi._markerCurrent then gi.zonePos = gi._markerCurrent end
    end
end)
print("[AquaFlow] Auto-Play minigame system loaded!")
