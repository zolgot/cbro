-- Roblox Advanced Script with Menu
-- Includes: ESP, Aim Assist, FOV Circle, Anti-AFK

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

-- Local player
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local Settings = {
    ESP = {
        Enabled = true,
        Boxes = true,
        Names = true,
        Health = true,
        Distance = true,
        TeamColor = true,
        TeamCheck = false,
        BoxColor = Color3.fromRGB(0, 255, 0),
        TextColor = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextFont = Enum.Font.SourceSans
    },
    AimAssist = {
        Enabled = false,
        FOV = 100,
        Smoothness = 0.2,
        TeamCheck = false,
        Keybind = Enum.UserInputType.MouseButton2,
        VisibleCheck = true,
        ClosestPart = "Head"
    },
    AntiAFK = {
        Enabled = true
    }
}

-- UI Library
local Library = {
    Enabled = true,
    Keybind = Enum.KeyCode.RightShift,
    Theme = {
        Background = Color3.fromRGB(30, 30, 40),
        Text = Color3.fromRGB(255, 255, 255),
        Accent = Color3.fromRGB(0, 150, 255)
    }
}

-- ESP Functions
local ESP = {
    Objects = {}
}

function ESP:Create(player)
    if self.Objects[player] then return end
    
    local Drawings = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    Drawings.Box.Visible = false
    Drawings.Box.Color = Settings.ESP.BoxColor
    Drawings.Box.Thickness = 1
    Drawings.Box.Filled = false
    
    Drawings.Name.Visible = false
    Drawings.Name.Color = Settings.ESP.TextColor
    Drawings.Name.Size = Settings.ESP.TextSize
    Drawings.Name.Center = true
    Drawings.Name.Outline = true
    Drawings.Name.Font = Settings.ESP.TextFont
    
    Drawings.Health.Visible = false
    Drawings.Health.Color = Settings.ESP.TextColor
    Drawings.Health.Size = Settings.ESP.TextSize
    Drawings.Health.Center = true
    Drawings.Health.Outline = true
    Drawings.Health.Font = Settings.ESP.TextFont
    
    Drawings.Distance.Visible = false
    Drawings.Distance.Color = Settings.ESP.TextColor
    Drawings.Distance.Size = Settings.ESP.TextSize
    Drawings.Distance.Center = true
    Drawings.Distance.Outline = true
    Drawings.Distance.Font = Settings.ESP.TextFont
    
    self.Objects[player] = {
        Drawings = Drawings,
        Player = player,
        Character = nil,
        Connections = {}
    }
    
    self:Update(player)
end

function ESP:Update(player)
    local obj = self.Objects[player]
    if not obj then return end
    
    local character = player.Character
    if not character then return end
    
    obj.Character = character
    
    -- Update connections
    for _, conn in pairs(obj.Connections) do
        conn:Disconnect()
    end
    
    obj.Connections = {
        character:GetPropertyChangedSignal("Parent"):Connect(function()
            if not character.Parent then
                self:Remove(player)
            end
        end),
        player:GetPropertyChangedSignal("Team"):Connect(function()
            self:Update(player)
        end)
    }
    
    if character:FindFirstChild("Humanoid") then
        table.insert(obj.Connections, character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
            self:Update(player)
        end))
    end
end

function ESP:Remove(player)
    local obj = self.Objects[player]
    if not obj then return end
    
    for _, conn in pairs(obj.Connections) do
        conn:Disconnect()
    end
    
    for _, drawing in pairs(obj.Drawings) do
        drawing:Remove()
    end
    
    self.Objects[player] = nil
end

function ESP:UpdateAll()
    for player, _ in pairs(self.Objects) do
        self:Update(player)
    end
end

function ESP:Draw()
    if not Settings.ESP.Enabled then return end
    
    for player, obj in pairs(self.Objects) do
        local character = obj.Character
        if not character or not character.Parent then
            self:Remove(player)
            continue
        end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        
        if not humanoidRootPart or not humanoid then continue end
        
        local position, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
        if not onScreen then
            for _, drawing in pairs(obj.Drawings) do
                drawing.Visible = false
            end
            continue
        end
        
        local teamColor = Settings.ESP.TeamColor and player.Team and player.Team.TeamColor.Color or Settings.ESP.BoxColor
        local canShow = not Settings.ESP.TeamCheck or (player.Team ~= LocalPlayer.Team)
        
        if Settings.ESP.Boxes and canShow then
            local scaleFactor = 1 / (position.Z * math.tan(math.rad(Camera.FieldOfView / 2)) * 2) * 1000
            local width, height = 4 * scaleFactor, 5 * scaleFactor
            local x, y = position.X, position.Y
            
            obj.Drawings.Box.Visible = true
            obj.Drawings.Box.Size = Vector2.new(width, height)
            obj.Drawings.Box.Position = Vector2.new(x - width / 2, y - height / 2)
            obj.Drawings.Box.Color = teamColor
        else
            obj.Drawings.Box.Visible = false
        end
        
        if canShow then
            local offset = 0
            
            if Settings.ESP.Names then
                obj.Drawings.Name.Visible = true
                obj.Drawings.Name.Text = player.Name
                obj.Drawings.Name.Position = Vector2.new(position.X, position.Y - 30 - offset)
                obj.Drawings.Name.Color = Settings.ESP.TextColor
                offset = offset + 15
            else
                obj.Drawings.Name.Visible = false
            end
            
            if Settings.ESP.Health then
                obj.Drawings.Health.Visible = true
                obj.Drawings.Health.Text = "HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                obj.Drawings.Health.Position = Vector2.new(position.X, position.Y - 15 - offset)
                obj.Drawings.Health.Color = Color3.fromRGB(255 - (humanoid.Health / humanoid.MaxHealth) * 255, (humanoid.Health / humanoid.MaxHealth) * 255, 0)
                offset = offset + 15
            else
                obj.Drawings.Health.Visible = false
            end
            
            if Settings.ESP.Distance then
                local distance = (humanoidRootPart.Position - Camera.CFrame.Position).Magnitude
                obj.Drawings.Distance.Visible = true
                obj.Drawings.Distance.Text = math.floor(distance) .. "m"
                obj.Drawings.Distance.Position = Vector2.new(position.X, position.Y - offset)
                obj.Drawings.Distance.Color = Settings.ESP.TextColor
            else
                obj.Drawings.Distance.Visible = false
            end
        else
            obj.Drawings.Name.Visible = false
            obj.Drawings.Health.Visible = false
            obj.Drawings.Distance.Visible = false
        end
    end
end

-- Aim Assist Functions
local AimAssist = {
    FOVCircle = Drawing.new("Circle"),
    Target = nil
}

function AimAssist:Init()
    self.FOVCircle.Visible = false
    self.FOVCircle.Transparency = 1
    self.FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    self.FOVCircle.Thickness = 1
    self.FOVCircle.NumSides = 100
    self.FOVCircle.Filled = false
    self.FOVCircle.Radius = Settings.AimAssist.FOV
end

function AimAssist:UpdateFOV()
    self.FOVCircle.Radius = Settings.AimAssist.FOV
    self.FOVCircle.Visible = Settings.AimAssist.Enabled
    self.FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

function AimAssist:GetClosestPlayer()
    local closestPlayer = nil
    local closestDistance = Settings.AimAssist.FOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.AimAssist.TeamCheck and player.Team == LocalPlayer.Team then continue end
        
        local character = player.Character
        if not character then continue end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        
        if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then continue end
        
        local screenPoint, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
        if not onScreen and Settings.AimAssist.VisibleCheck then continue end
        
        local mousePos = UserInputService:GetMouseLocation()
        local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
        
        if distance < closestDistance then
            closestDistance = distance
            closestPlayer = player
        end
    end
    
    return closestPlayer
end

function AimAssist:GetTargetPart(character)
    if not character then return nil end
    
    local partName = Settings.AimAssist.ClosestPart
    local part = character:FindFirstChild(partName)
    
    return part or character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

function AimAssist:AimAtTarget()
    if not Settings.AimAssist.Enabled or not UserInputService:IsMouseButtonPressed(Settings.AimAssist.Keybind) then
        self.Target = nil
        return
    end
    
    self.Target = self:GetClosestPlayer()
    if not self.Target then return end
    
    local character = self.Target.Character
    if not character then return end
    
    local targetPart = self:GetTargetPart(character)
    if not targetPart then return end
    
    local cameraCFrame = Camera.CFrame
    local targetPosition = targetPart.Position
    
    local currentLook = cameraCFrame.LookVector
    local desiredLook = (targetPosition - cameraCFrame.Position).Unit
    
    local smoothness = math.clamp(Settings.AimAssist.Smoothness, 0.01, 1)
    local newLook = currentLook:Lerp(desiredLook, 1 - smoothness)
    
    Camera.CFrame = CFrame.new(cameraCFrame.Position, cameraCFrame.Position + newLook)
end

-- Anti AFK
local AntiAFK = {}

function AntiAFK:Init()
    if not Settings.AntiAFK.Enabled then return end
    
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- UI Functions
local UI = {
    ScreenGui = nil,
    MainFrame = nil,
    Tabs = {},
    CurrentTab = nil
}

function UI:Create()
    -- Create ScreenGui
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "AdvancedScriptUI"
    self.ScreenGui.Parent = CoreGui
    self.ScreenGui.ResetOnSpawn = false
    
    -- Main Frame
    self.MainFrame = Instance.new("Frame")
    self.MainFrame.Name = "MainFrame"
    self.MainFrame.Size = UDim2.new(0, 400, 0, 400)
    self.MainFrame.Position = UDim2.new(0.5, -200, 0.5, -200)
    self.MainFrame.BackgroundColor3 = Library.Theme.Background
    self.MainFrame.BorderSizePixel = 0
    self.MainFrame.Active = true
    self.MainFrame.Draggable = true
    self.MainFrame.Visible = false
    self.MainFrame.Parent = self.ScreenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "Advanced Script"
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Library.Theme.Accent
    title.TextColor3 = Library.Theme.Text
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 18
    title.BorderSizePixel = 0
    title.Parent = self.MainFrame
    
    -- Close Button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Text = "X"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeButton.TextColor3 = Library.Theme.Text
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextSize = 18
    closeButton.BorderSizePixel = 0
    closeButton.Parent = self.MainFrame
    
    closeButton.MouseButton1Click:Connect(function()
        self.MainFrame.Visible = false
    end)
    
    -- Tab Buttons Frame
    local tabButtonsFrame = Instance.new("Frame")
    tabButtonsFrame.Name = "TabButtons"
    tabButtonsFrame.Size = UDim2.new(1, 0, 0, 30)
    tabButtonsFrame.Position = UDim2.new(0, 0, 0, 30)
    tabButtonsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    tabButtonsFrame.BorderSizePixel = 0
    tabButtonsFrame.Parent = self.MainFrame
    
    -- Tabs Container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Name = "TabsContainer"
    tabsContainer.Size = UDim2.new(1, 0, 1, -60)
    tabsContainer.Position = UDim2.new(0, 0, 0, 60)
    tabsContainer.BackgroundTransparency = 1
    tabsContainer.ClipsDescendants = true
    tabsContainer.Parent = self.MainFrame
    
    -- Create Tabs
    self:CreateTab("ESP", tabsContainer, tabButtonsFrame)
    self:CreateTab("Aim Assist", tabsContainer, tabButtonsFrame)
    self:CreateTab("Misc", tabsContainer, tabButtonsFrame)
    
    -- Switch to first tab
    if #self.Tabs > 0 then
        self:SwitchTab(self.Tabs[1])
    end
end

function UI:CreateTab(name, container, buttonsFrame)
    local tab = {
        Name = name,
        Frame = Instance.new("ScrollingFrame"),
        Button = Instance.new("TextButton")
    }
    
    -- Tab Button
    tab.Button.Name = name .. "Button"
    tab.Button.Text = name
    tab.Button.Size = UDim2.new(0, 100, 1, 0)
    tab.Button.Position = UDim2.new(0, (#self.Tabs * 100), 0, 0)
    tab.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    tab.Button.TextColor3 = Library.Theme.Text
    tab.Button.Font = Enum.Font.SourceSans
    tab.Button.TextSize = 14
    tab.Button.BorderSizePixel = 0
    tab.Button.Parent = buttonsFrame
    
    tab.Button.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    
    -- Tab Frame
    tab.Frame.Name = name .. "Frame"
    tab.Frame.Size = UDim2.new(1, 0, 1, 0)
    tab.Frame.Position = UDim2.new(0, 0, 0, 0)
    tab.Frame.BackgroundTransparency = 1
    tab.Frame.ScrollBarThickness = 5
    tab.Frame.CanvasSize = UDim2.new(0, 0, 0, 0)
    tab.Frame.Visible = false
    tab.Frame.Parent = container
    
    -- Add controls based on tab name
    if name == "ESP" then
        self:CreateESPTab(tab.Frame)
    elseif name == "Aim Assist" then
        self:CreateAimAssistTab(tab.Frame)
    elseif name == "Misc" then
        self:CreateMiscTab(tab.Frame)
    end
    
    table.insert(self.Tabs, tab)
    return tab
end

function UI:SwitchTab(tab)
    if self.CurrentTab then
        self.CurrentTab.Frame.Visible = false
        self.CurrentTab.Button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    end
    
    self.CurrentTab = tab
    tab.Frame.Visible = true
    tab.Button.BackgroundColor3 = Library.Theme.Accent
end

function UI:CreateToggle(parent, text, flag, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = text .. "Toggle"
    toggleFrame.Size = UDim2.new(1, -20, 0, 30)
    toggleFrame.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 35)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent
    
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Text = ""
    toggleButton.Size = UDim2.new(0, 30, 0, 30)
    toggleButton.Position = UDim2.new(0, 0, 0, 0)
    toggleButton.BackgroundColor3 = Settings[flag].Enabled and Library.Theme.Accent or Color3.fromRGB(70, 70, 80)
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = toggleFrame
    
    local toggleText = Instance.new("TextLabel")
    toggleText.Name = "ToggleText"
    toggleText.Text = text
    toggleText.Size = UDim2.new(1, -40, 1, 0)
    toggleText.Position = UDim2.new(0, 40, 0, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.TextColor3 = Library.Theme.Text
    toggleText.Font = Enum.Font.SourceSans
    toggleText.TextSize = 14
    toggleText.TextXAlignment = Enum.TextXAlignment.Left
    toggleText.Parent = toggleFrame
    
    toggleButton.MouseButton1Click:Connect(function()
        Settings[flag].Enabled = not Settings[flag].Enabled
        toggleButton.BackgroundColor3 = Settings[flag].Enabled and Library.Theme.Accent or Color3.fromRGB(70, 70, 80)
        
        if callback then
            callback(Settings[flag].Enabled)
        end
    end)
    
    parent.CanvasSize = UDim2.new(0, 0, 0, #parent:GetChildren() * 35)
end

function UI:CreateSlider(parent, text, flag, min, max, defaultValue, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = text .. "Slider"
    sliderFrame.Size = UDim2.new(1, -20, 0, 50)
    sliderFrame.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 35)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = parent
    
    local sliderText = Instance.new("TextLabel")
    sliderText.Name = "SliderText"
    sliderText.Text = text .. ": " .. tostring(Settings[flag][text] or defaultValue)
    sliderText.Size = UDim2.new(1, 0, 0, 20)
    sliderText.Position = UDim2.new(0, 0, 0, 0)
    sliderText.BackgroundTransparency = 1
    sliderText.TextColor3 = Library.Theme.Text
    sliderText.Font = Enum.Font.SourceSans
    sliderText.TextSize = 14
    sliderText.TextXAlignment = Enum.TextXAlignment.Left
    sliderText.Parent = sliderFrame
    
    local slider = Instance.new("Frame")
    slider.Name = "Slider"
    slider.Size = UDim2.new(1, 0, 0, 10)
    slider.Position = UDim2.new(0, 0, 0, 25)
    slider.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    slider.BorderSizePixel = 0
    slider.Parent = sliderFrame
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "SliderFill"
    sliderFill.Size = UDim2.new((Settings[flag][text] or defaultValue - min) / (max - min), 0, 1, 0)
    sliderFill.Position = UDim2.new(0, 0, 0, 0)
    sliderFill.BackgroundColor3 = Library.Theme.Accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = slider
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Name = "SliderButton"
    sliderButton.Text = ""
    sliderButton.Size = UDim2.new(0, 20, 0, 20)
    sliderButton.Position = UDim2.new((Settings[flag][text] or defaultValue - min) / (max - min), -5, 0, -5)
    sliderButton.BackgroundColor3 = Library.Theme.Text
    sliderButton.BorderSizePixel = 0
    sliderButton.Parent = slider
    
    local dragging = false
    
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    sliderButton.MouseButton1Up:Connect(function()
        dragging = false
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then
            local mousePos = UserInputService:GetMouseLocation().X
            local sliderPos = slider.AbsolutePosition.X
            local sliderSize = slider.AbsoluteSize.X
            
            local relativePos = math.clamp(mousePos - sliderPos, 0, sliderSize)
            local value = min + (relativePos / sliderSize) * (max - min)
            value = math.floor(value * 10) / 10
            
            Settings[flag][text] = value
            sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            sliderButton.Position = UDim2.new((value - min) / (max - min), -5, 0, -5)
            sliderText.Text = text .. ": " .. tostring(value)
            
            if callback then
                callback(value)
            end
        end
    end)
    
    parent.CanvasSize = UDim2.new(0, 0, 0, #parent:GetChildren() * 35)
end

function UI:CreateDropdown(parent, text, flag, options, defaultValue, callback)
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Name = text .. "Dropdown"
    dropdownFrame.Size = UDim2.new(1, -20, 0, 30)
    dropdownFrame.Position = UDim2.new(0, 10, 0, #parent:GetChildren() * 35)
    dropdownFrame.BackgroundTransparency = 1
    dropdownFrame.Parent = parent
    
    local dropdownText = Instance.new("TextLabel")
    dropdownText.Name = "DropdownText"
    dropdownText.Text = text
    dropdownText.Size = UDim2.new(0.5, -5, 1, 0)
    dropdownText.Position = UDim2.new(0, 0, 0, 0)
    dropdownText.BackgroundTransparency = 1
    dropdownText.TextColor3 = Library.Theme.Text
    dropdownText.Font = Enum.Font.SourceSans
    dropdownText.TextSize = 14
    dropdownText.TextXAlignment = Enum.TextXAlignment.Left
    dropdownText.Parent = dropdownFrame
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Text = Settings[flag][text] or defaultValue
    dropdownButton.Size = UDim2.new(0.5, -5, 1, 0)
    dropdownButton.Position = UDim2.new(0.5, 5, 0, 0)
    dropdownButton.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
    dropdownButton.TextColor3 = Library.Theme.Text
    dropdownButton.Font = Enum.Font.SourceSans
    dropdownButton.TextSize = 14
    dropdownButton.BorderSizePixel = 0
    dropdownButton.Parent = dropdownFrame
    
    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Name = "DropdownList"
    dropdownList.Size = UDim2.new(0.5, -5, 0, 100)
    dropdownList.Position = UDim2.new(0.5, 5, 1, 5)
    dropdownList.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    dropdownList.BorderSizePixel = 0
    dropdownList.ScrollBarThickness = 5
    dropdownList.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
    dropdownList.Visible = false
    dropdownList.Parent = dropdownFrame
    
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Name = option .. "Option"
        optionButton.Text = option
        optionButton.Size = UDim2.new(1, 0, 0, 30)
        optionButton.Position = UDim2.new(0, 0, 0, (i-1)*30)
        optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        optionButton.TextColor3 = Library.Theme.Text
        optionButton.Font = Enum.Font.SourceSans
        optionButton.TextSize = 14
        optionButton.BorderSizePixel = 0
        optionButton.Parent = dropdownList
        
        optionButton.MouseButton1Click:Connect(function()
            Settings[flag][text] = option
            dropdownButton.Text = option
            dropdownList.Visible = false
            
            if callback then
                callback(option)
            end
        end)
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        dropdownList.Visible = not dropdownList.Visible
    end)
    
    parent.CanvasSize = UDim2.new(0, 0, 0, #parent:GetChildren() * 35)
end

function UI:CreateESPTab(parent)
    self:CreateToggle(parent, "ESP Enabled", "ESP", function(value)
        ESP:UpdateAll()
    end)
    
    self:CreateToggle(parent, "Boxes", "ESP", function(value)
        ESP:UpdateAll()
    end)
    
    self:CreateToggle(parent, "Names", "ESP", function(value)
        ESP:UpdateAll()
    end)
    
    self:CreateToggle(parent, "Health", "ESP", function(value)
        ESP:UpdateAll()
    end)
    
    self:CreateToggle(parent, "Distance", "ESP", function(value)
        ESP:UpdateAll()
    end)
    
    self:CreateToggle(parent, "Team Color", "ESP", function(value)
        ESP:UpdateAll()
    end)
    
    self:CreateToggle(parent, "Team Check", "ESP", function(value)
        ESP:UpdateAll()
    end)
    
    self:CreateSlider(parent, "TextSize", "ESP", 10, 24, 14, function(value)
        ESP:UpdateAll()
    end)
end

function UI:CreateAimAssistTab(parent)
    self:CreateToggle(parent, "Aim Assist Enabled", "AimAssist", function(value)
        AimAssist:UpdateFOV()
    end)
    
    self:CreateSlider(parent, "FOV", "AimAssist", 10, 500, 100, function(value)
        AimAssist:UpdateFOV()
    end)
    
    self:CreateSlider(parent, "Smoothness", "AimAssist", 0.1, 1, 0.2, function(value)
        -- Smoothness updated
    end)
    
    self:CreateToggle(parent, "Team Check", "AimAssist", function(value)
        -- Team check updated
    end)
    
    self:CreateToggle(parent, "Visible Check", "AimAssist", function(value)
        -- Visible check updated
    end)
    
    self:CreateDropdown(parent, "ClosestPart", "AimAssist", {"Head", "HumanoidRootPart", "Torso"}, "Head", function(value)
        -- Target part updated
    end)
end

function UI:CreateMiscTab(parent)
    self:CreateToggle(parent, "Anti-AFK", "AntiAFK", function(value)
        if value then
            AntiAFK:Init()
        end
    end)
end

-- Initialize
function Init()
    -- Setup ESP
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ESP:Create(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        ESP:Create(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        ESP:Remove(player)
    end)
    
    -- Setup Aim Assist
    AimAssist:Init()
    
    -- Setup Anti-AFK
    AntiAFK:Init()
    
    -- Setup UI
    UI:Create()
    
    -- Keybind to toggle UI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Library.Keybind then
            UI.MainFrame.Visible = not UI.MainFrame.Visible
        end
    end)
    
    -- Main loop
    RunService.RenderStepped:Connect(function()
        ESP:Draw()
        AimAssist:AimAtTarget()
    end)
end

-- Start the script
Init()
