--[[
    AquaFlow UI Library v1.0
    Premium Sidebar UI System — Reusable for any Roblox script

    Usage:
        local UILib = loadstring(game:HttpGet("url/ui_library.lua"))()
        -- or: local UILib = require(path)

        local Config = { AutoFarm = false, Speed = 100 }
        local win = UILib:CreateWindow("MY SCRIPT", Config)

        local page1 = win:AddPage("Farm")
        win:AddHeader(page1, "Auto Farm")
        win:AddToggle(page1, "Enable Farm", "AutoFarm")
        win:AddDropdown(page1, "Target", "Select mob", mobList, "Target", true)
        win:AddButton(page1, "Teleport", "Go to boss", "GO", nil, function() ... end)

        win:SetStatus("Farming...", Color3.new(0,1,0))
        win:SetInfo("Weight: 50kg")
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local UILib = {}
UILib.__index = UILib

function UILib:CreateWindow(title, config)
    local win = setmetatable({}, { __index = UILib })
    win.Config = config or {}
    win.Pages = {}
    win.NavButtons = {}
    win.ActivePage = nil

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "AquaFlow_" .. (title or "UI")
    sg.Parent = CoreGui
    sg.ResetOnSpawn = false
    win.ScreenGui = sg

    -- Main Frame
    local main = Instance.new("Frame", sg)
    main.Size = UDim2.new(0, 520, 0, 360)
    main.Position = UDim2.new(0.5, -260, 0.4, -180)
    main.BackgroundColor3 = Color3.fromRGB(15, 16, 22)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    win.Main = main
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", main)
    stroke.Thickness = 1.2
    stroke.Color = Color3.fromRGB(45, 48, 60)
    stroke.Transparency = 0.6

    -- Mini Open Button
    local miniOpen = Instance.new("TextButton", sg)
    miniOpen.Size = UDim2.new(0, 60, 0, 30)
    miniOpen.Position = UDim2.new(1, -70, 0, 20)
    miniOpen.BackgroundColor3 = Color3.fromRGB(255, 64, 128)
    miniOpen.Text = "OPEN"
    miniOpen.TextColor3 = Color3.new(1, 1, 1)
    miniOpen.Font = Enum.Font.GothamBold
    miniOpen.TextSize = 10
    miniOpen.Visible = false
    Instance.new("UICorner", miniOpen).CornerRadius = UDim.new(0, 6)

    -- Sidebar
    local sidebar = Instance.new("Frame", main)
    sidebar.Size = UDim2.new(0, 160, 1, 0)
    sidebar.BackgroundColor3 = Color3.fromRGB(20, 21, 28)
    sidebar.BorderSizePixel = 0
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 10)

    -- Window Controls
    local cf = Instance.new("Frame", sidebar)
    cf.Size = UDim2.new(0, 60, 0, 30)
    cf.Position = UDim2.new(0, 10, 0, 10)
    cf.BackgroundTransparency = 1
    cf.ZIndex = 10

    local closeBtn = Instance.new("TextButton", cf)
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -25, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 64, 64)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.ZIndex = 11
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

    local miniBtn = Instance.new("TextButton", cf)
    miniBtn.Size = UDim2.new(0, 25, 0, 25)
    miniBtn.Position = UDim2.new(0, 0, 0, 0)
    miniBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    miniBtn.Text = "-"
    miniBtn.TextColor3 = Color3.new(1, 1, 1)
    miniBtn.Font = Enum.Font.GothamBold
    miniBtn.TextSize = 14
    miniBtn.ZIndex = 11
    Instance.new("UICorner", miniBtn).CornerRadius = UDim.new(0, 4)

    win.OnClose = nil -- callback
    closeBtn.MouseButton1Click:Connect(function()
        if win.OnClose then win.OnClose() end
        sg:Destroy()
    end)
    miniBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        miniOpen.Visible = true
    end)
    miniOpen.MouseButton1Click:Connect(function()
        main.Visible = true
        miniOpen.Visible = false
    end)

    -- Sidebar Title
    local sideTitle = Instance.new("TextLabel", sidebar)
    sideTitle.Size = UDim2.new(1, 0, 0, 40)
    sideTitle.Position = UDim2.new(0, 0, 0, 40)
    sideTitle.Text = (title or "SCRIPT"):upper()
    sideTitle.TextColor3 = Color3.fromRGB(255, 64, 128)
    sideTitle.Font = Enum.Font.GothamBold
    sideTitle.TextSize = 11
    sideTitle.BackgroundTransparency = 1

    -- Nav List
    local navList = Instance.new("Frame", sidebar)
    navList.Size = UDim2.new(1, -20, 1, -100)
    navList.Position = UDim2.new(0, 10, 0, 85)
    navList.BackgroundTransparency = 1
    Instance.new("UIListLayout", navList).Padding = UDim.new(0, 5)
    win.NavList = navList

    -- Container (right side)
    local container = Instance.new("Frame", main)
    container.Size = UDim2.new(1, -175, 1, -45)
    container.Position = UDim2.new(0, 165, 0, 10)
    container.BackgroundTransparency = 1
    win.Container = container

    -- Footer
    local footer = Instance.new("Frame", main)
    footer.Size = UDim2.new(1, 0, 0, 30)
    footer.Position = UDim2.new(0, 0, 1, -30)
    footer.BackgroundColor3 = Color3.fromRGB(12, 13, 18)
    footer.BorderSizePixel = 0
    local fLine = Instance.new("Frame", footer)
    fLine.Size = UDim2.new(1, 0, 0, 1)
    fLine.BackgroundColor3 = Color3.fromRGB(45, 48, 60)
    fLine.BackgroundTransparency = 0.5
    fLine.BorderSizePixel = 0

    local statusTxt = Instance.new("TextLabel", footer)
    statusTxt.Size = UDim2.new(0.5, -10, 1, 0)
    statusTxt.Position = UDim2.new(0, 15, 0, 0)
    statusTxt.Text = "STATUS: IDLE"
    statusTxt.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    statusTxt.Font = Enum.Font.GothamBold
    statusTxt.TextSize = 8
    statusTxt.BackgroundTransparency = 1
    statusTxt.TextXAlignment = Enum.TextXAlignment.Left
    win.StatusTxt = statusTxt

    local infoTxt = Instance.new("TextLabel", footer)
    infoTxt.Size = UDim2.new(0.5, -10, 1, 0)
    infoTxt.Position = UDim2.new(0.5, 0, 0, 0)
    infoTxt.Text = ""
    infoTxt.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    infoTxt.Font = Enum.Font.GothamMedium
    infoTxt.TextSize = 8
    infoTxt.BackgroundTransparency = 1
    infoTxt.TextXAlignment = Enum.TextXAlignment.Right
    win.InfoTxt = infoTxt

    return win
end

-- Page System
function UILib:AddPage(name)
    local page = Instance.new("ScrollingFrame", self.Container)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.ScrollBarImageColor3 = Color3.fromRGB(45, 125, 255)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = (#self.Pages == 0) -- first page visible

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 10)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    local pad = Instance.new("UIPadding", page)
    pad.PaddingBottom = UDim.new(0, 15)
    pad.PaddingLeft = UDim.new(0, 2)
    pad.PaddingRight = UDim.new(0, 8)

    table.insert(self.Pages, page)

    -- Nav Button
    local btn = Instance.new("TextButton", self.NavList)
    btn.Size = UDim2.new(1, 0, 0, 35)
    btn.BackgroundColor3 = (#self.Pages == 1) and Color3.fromRGB(255, 64, 128) or Color3.fromRGB(28, 30, 40)
    btn.Text = "  " .. name
    btn.TextColor3 = (#self.Pages == 1) and Color3.new(1, 1, 1) or Color3.new(0.6, 0.6, 0.6)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    table.insert(self.NavButtons, btn)

    local pages = self.Pages
    local navBtns = self.NavButtons
    btn.MouseButton1Click:Connect(function()
        for i, p in ipairs(pages) do
            p.Visible = (p == page)
            navBtns[i].TextColor3 = (p == page) and Color3.new(1, 1, 1) or Color3.new(0.6, 0.6, 0.6)
            navBtns[i].BackgroundColor3 = (p == page) and Color3.fromRGB(255, 64, 128) or Color3.fromRGB(28, 30, 40)
        end
    end)

    return page
end

-- Header
function UILib:AddHeader(parent, text)
    local c = Instance.new("Frame", parent)
    c.Size = UDim2.new(1, -10, 0, 30)
    c.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", c)
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.Text = text:upper()
    lbl.TextColor3 = Color3.fromRGB(45, 125, 255)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 10
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local bar = Instance.new("Frame", c)
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
    return c
end

-- Toggle
function UILib:AddToggle(parent, text, configKey, activeColor)
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
    ck.Size = UDim2.new(0.6, 0, 0.6, 0)
    ck.Position = UDim2.new(0.2, 0, 0.2, 0)
    ck.BackgroundColor3 = activeColor or Color3.fromRGB(255, 64, 128)
    ck.Visible = self.Config[configKey] or false
    Instance.new("UICorner", ck).CornerRadius = UDim.new(0, 2)

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1, -35, 1, 0)
    lbl.Position = UDim2.new(0, 30, 0, 0)
    lbl.Text = text
    lbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 10
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local cfg = self.Config
    cb.MouseButton1Click:Connect(function()
        cfg[configKey] = not cfg[configKey]
        ck.Visible = cfg[configKey]
    end)
    return f
end

-- Input (TextBox)
function UILib:AddInput(parent, text, configKey, placeholder)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 35)
    f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Text = text
    lbl.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 9
    lbl.BackgroundTransparency = 1
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local inp = Instance.new("TextBox", f)
    inp.Size = UDim2.new(0.3, 0, 0, 22)
    inp.Position = UDim2.new(0.65, 0, 0.5, -11)
    inp.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
    inp.Text = tostring(self.Config[configKey] or placeholder or "")
    inp.TextColor3 = Color3.new(1, 1, 1)
    inp.Font = Enum.Font.GothamBold
    inp.TextSize = 10
    Instance.new("UICorner", inp).CornerRadius = UDim.new(0, 4)

    local cfg = self.Config
    inp.FocusLost:Connect(function()
        cfg[configKey] = tonumber(inp.Text) or cfg[configKey]
    end)
    return f, inp
end

-- Dropdown
function UILib:AddDropdown(parent, text, subtitle, list, configKey, singleSelect, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 45)
    f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.6, 0, 0, 15); lbl.Position = UDim2.new(0, 0, 0, 2)
    lbl.Text = text; lbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local sLbl = Instance.new("TextLabel", f)
    sLbl.Size = UDim2.new(0.6, 0, 0, 12); sLbl.Position = UDim2.new(0, 0, 0, 16)
    sLbl.Text = subtitle; sLbl.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    sLbl.Font = Enum.Font.GothamMedium; sLbl.TextSize = 8
    sLbl.BackgroundTransparency = 1; sLbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0.35, 0, 0, 24); btn.Position = UDim2.new(0.65, -5, 0, 10)
    btn.BackgroundColor3 = Color3.fromRGB(28, 30, 40); btn.Text = "Select... "
    btn.TextColor3 = Color3.new(0.8, 0.8, 0.8); btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9; btn.ClipsDescendants = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(45, 48, 60)

    local arrow = Instance.new("TextLabel", btn)
    arrow.Size = UDim2.new(0, 20, 1, 0); arrow.Position = UDim2.new(1, -20, 0, 0)
    arrow.Text = "v"; arrow.TextColor3 = Color3.new(0.6, 0.6, 0.6)
    arrow.BackgroundTransparency = 1; arrow.Font = Enum.Font.GothamBold

    local menu = Instance.new("ScrollingFrame", self.ScreenGui)
    menu.Size = UDim2.new(0, 180, 0, 150)
    menu.BackgroundColor3 = Color3.fromRGB(24, 25, 32)
    menu.BorderSizePixel = 0; menu.Visible = false; menu.ZIndex = 100
    menu.ScrollBarThickness = 2
    menu.ScrollBarImageColor3 = Color3.fromRGB(45, 125, 255)
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 6)
    local mStroke = Instance.new("UIStroke", menu)
    mStroke.Color = Color3.fromRGB(60, 60, 75); mStroke.Thickness = 1
    Instance.new("UIListLayout", menu).Padding = UDim.new(0, 2)
    Instance.new("UIPadding", menu).PaddingTop = UDim.new(0, 4)

    local cfg = self.Config
    local function updateSummary()
        if singleSelect then
            btn.Text = tostring(cfg[configKey]) .. " "
        else
            local sel = {}
            for k, v in pairs(cfg[configKey]) do if v then table.insert(sel, k) end end
            btn.Text = #sel == 0 and "None " or (#sel == 1 and sel[1] .. " " or #sel .. " Selected ")
        end
    end

    local function rebuildMenu()
        for _, c in ipairs(menu:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _, name in ipairs(list) do
            local b = Instance.new("TextButton", menu)
            b.Size = UDim2.new(1, -4, 0, 24)
            b.BackgroundTransparency = 1
            b.Text = "  " .. name
            b.Font = Enum.Font.GothamMedium; b.TextSize = 9
            b.TextXAlignment = Enum.TextXAlignment.Left; b.ZIndex = 101
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)

            local function updateLook()
                local sel = singleSelect and cfg[configKey] == name or cfg[configKey][name]
                b.TextColor3 = sel and Color3.new(1, 1, 1) or Color3.new(0.6, 0.6, 0.6)
                b.BackgroundColor3 = sel and Color3.fromRGB(45, 125, 255) or Color3.fromRGB(30, 31, 40)
                b.BackgroundTransparency = sel and 0 or 1
            end
            updateLook()

            b.MouseButton1Click:Connect(function()
                if singleSelect then
                    cfg[configKey] = name
                    menu.Visible = false
                else
                    cfg[configKey][name] = not cfg[configKey][name]
                    updateLook()
                end
                updateSummary()
                if callback then callback(name) end
            end)
        end
        local count = #list
        local content = count * 26 + 10
        menu.CanvasSize = UDim2.new(0, 0, 0, content)
        menu.Size = UDim2.new(0, 180, 0, math.min(content, 180))
    end

    btn.MouseButton1Click:Connect(function()
        if menu.Visible then
            menu.Visible = false
        else
            rebuildMenu()
            menu.Position = UDim2.new(0, btn.AbsolutePosition.X - 180 + btn.AbsoluteSize.X, 0,
                btn.AbsolutePosition.Y + btn.AbsoluteSize.Y + 36)
            menu.Visible = true
        end
    end)

    updateSummary()
    return f
end

-- Button
function UILib:AddButton(parent, text, subtitle, btnText, color, callback)
    local f = Instance.new("Frame", parent)
    f.Size = UDim2.new(1, -10, 0, 45)
    f.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(0.6, 0, 0, 15); lbl.Position = UDim2.new(0, 5, 0, 5)
    lbl.Text = text; lbl.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10
    lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left

    local sLbl = Instance.new("TextLabel", f)
    sLbl.Size = UDim2.new(0.6, 0, 0, 12); sLbl.Position = UDim2.new(0, 5, 0, 20)
    sLbl.Text = subtitle; sLbl.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    sLbl.Font = Enum.Font.GothamMedium; sLbl.TextSize = 8
    sLbl.BackgroundTransparency = 1; sLbl.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0.35, 0, 0, 24); btn.Position = UDim2.new(0.65, -5, 0, 10)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 125, 255)
    btn.Text = btnText; btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 9
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", btn)
    s.Color = Color3.new(1, 1, 1); s.Thickness = 0.5; s.Transparency = 0.8

    btn.MouseButton1Click:Connect(function()
        if callback then callback(btn) end
    end)
    return f, btn
end

-- Full-width Action Button
function UILib:AddActionButton(parent, text, color, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.BackgroundColor3 = color or Color3.fromRGB(255, 64, 128)
    btn.Text = text; btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 10
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        if callback then callback(btn) end
    end)
    return btn
end

-- Label
function UILib:AddLabel(parent, text)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -10, 0, 60)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.new(0.5, 0.5, 0.5)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 9
    lbl.TextWrapped = true
    return lbl
end

-- Status / Info helpers
function UILib:SetStatus(text, color)
    self.StatusTxt.Text = text
    self.StatusTxt.TextColor3 = color or Color3.new(0.6, 0.6, 0.6)
end

function UILib:SetInfo(text)
    self.InfoTxt.Text = text
end

function UILib:Destroy()
    if self.ScreenGui then self.ScreenGui:Destroy() end
end

return UILib
