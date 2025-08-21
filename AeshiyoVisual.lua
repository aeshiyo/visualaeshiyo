local ChineseHat = {}

function ChineseHat.new(config)
    local self = {}
    config = config or {}
    self.enabled = config.enabled ~= false
    self.heightOffset = config.heightOffset or 0.9
    self.hatHeight = config.hatHeight or 0.8
    self.radius = config.radius or 1.8
    self.topRadius = config.topRadius or 0.6
    self.sides = config.sides or 64
    self.color = config.color or Color3.new(1, 1, 1)
    self.transparency = config.transparency or 0.1
    self.smoothness = config.smoothness or 32
    self.players = game:GetService("Players")
    self.runService = game:GetService("RunService")
    self.userInputService = game:GetService("UserInputService")
    self.player = self.players.LocalPlayer
    self.character = nil
    self.head = nil
    self.circle = nil
    self.triangles = {}
    self.connections = {}
    self.active = false
    
    local function initialize()
        if not self.enabled then return end
        
        self.circle = Drawing.new("Circle")
        self.circle.Visible = false
        self.circle.Thickness = 0
        self.circle.Filled = true
        self.circle.NumSides = self.smoothness
        
        self.triangles = {}
        for i = 1, self.smoothness * 2 + 10 do
            local triangle = Drawing.new("Triangle")
            triangle.Visible = false
            triangle.Filled = true
            triangle.Thickness = 0
            table.insert(self.triangles, triangle)
        end
        
        self:updateVisuals()
    end

    local function cleanup()
        if self.circle then
            self.circle:Remove()
            self.circle = nil
        end
        for _, triangle in ipairs(self.triangles) do
            if triangle then
                triangle.Visible = false
                triangle:Remove()
            end
        end
        self.triangles = {}
        self.character = nil
        self.head = nil
    end

    function self:updateVisuals()
        if not self.circle then return end
        self.circle.Color = self.color
        self.circle.Transparency = self.transparency
        for _, triangle in ipairs(self.triangles) do
            triangle.Color = self.color
            triangle.Transparency = self.transparency
        end
    end

    function self:update()
        if not self.enabled then return end
        if not self.circle or not self.character or not self.head then 
            if self.circle then 
                self.circle.Visible = false 
            end
            for _, triangle in ipairs(self.triangles) do 
                triangle.Visible = false 
            end
            return 
        end
        
        local camera = workspace.CurrentCamera
        if not camera then return end
        
        local basePosition = self.head.Position + Vector3.new(0, self.heightOffset, 0)
        local topPosition = basePosition + Vector3.new(0, self.hatHeight, 0)
        
        local baseScreenPos, baseVisible = camera:WorldToViewportPoint(basePosition)
        local topScreenPos, topVisible = camera:WorldToViewportPoint(topPosition)
        
        if not (baseVisible and topVisible) then
            self.circle.Visible = false
            for _, triangle in ipairs(self.triangles) do 
                triangle.Visible = false 
            end
            return
        end
        
        local center2D = Vector2.new(baseScreenPos.X, baseScreenPos.Y)
        local top2D = Vector2.new(topScreenPos.X, topScreenPos.Y)
        
        self.circle.Position = center2D
        self.circle.Radius = self.topRadius
        self.circle.Visible = self.enabled
        
        local circlePositions = {}
        for i = 1, self.smoothness do
            local angle = math.rad((i / self.smoothness) * 360)
            local offset = Vector3.new(math.cos(angle) * self.radius, 0, math.sin(angle) * self.radius)
            local pointPos = camera:WorldToViewportPoint(basePosition + offset)
            circlePositions[i] = Vector2.new(pointPos.X, pointPos.Y)
        end
        
        local triangleIndex = 1
        
        for i = 1, self.smoothness do
            local nextIndex = i % self.smoothness + 1
            self.triangles[triangleIndex].PointA = center2D
            self.triangles[triangleIndex].PointB = circlePositions[i]
            self.triangles[triangleIndex].PointC = circlePositions[nextIndex]
            self.triangles[triangleIndex].Visible = self.enabled
            triangleIndex = triangleIndex + 1
        end
        
        for i = 1, self.smoothness do
            local nextIndex = i % self.smoothness + 1
            self.triangles[triangleIndex].PointA = top2D
            self.triangles[triangleIndex].PointB = circlePositions[i]
            self.triangles[triangleIndex].PointC = circlePositions[nextIndex]
            self.triangles[triangleIndex].Visible = self.enabled
            triangleIndex = triangleIndex + 1
        end
        
        for i = triangleIndex, #self.triangles do
            self.triangles[i].Visible = false
        end
    end

    local function setupCharacter(newCharacter)
        self.character = newCharacter
        self.head = self.character:WaitForChild("Head")
        local humanoid = self.character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            table.insert(self.connections, humanoid.Died:Connect(function()
                cleanup()
            end))
        end
        initialize()
    end

    function self:Start()
        if self.active then return end
        self.active = true
        cleanup()
        if self.player.Character then
            setupCharacter(self.player.Character)
        end
        table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
            setupCharacter(character)
        end))
        table.insert(self.connections, self.runService.RenderStepped:Connect(function()
            if self.enabled and self.character and self.head then
                self:update()
            end
        end))
    end

    function self:Destroy()
        self.active = false
        self.enabled = false
        for _, connection in ipairs(self.connections) do
            connection:Disconnect()
        end
        self.connections = {}
        cleanup()
    end

    function self:SetEnabled(state)
        self.enabled = state
        if not state then
            cleanup()
        else
            if self.player.Character and not self.character then
                setupCharacter(self.player.Character)
            end
        end
    end

    function self:SetColor(newColor)
        self.color = newColor
        self:updateVisuals()
    end

    function self:SetTransparency(newTransparency)
        self.transparency = newTransparency
        self:updateVisuals()
    end

    function self:SetHeight(newHeight)
        self.hatHeight = newHeight
    end

    function self:SetRadius(newRadius)
        self.radius = newRadius
    end

    function self:SetSmoothness(newSmoothness)
        self.smoothness = newSmoothness
        if self.enabled then
            cleanup()
            initialize()
        end
    end

    self:Start()
    return self
end

local function CreateSmoothMenu()
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SmoothHatMenu"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 450)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -225)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    title.Text = "SMOOTH HAT"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 7)
    closeButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 20
    closeButton.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeButton
    
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -20, 1, -65)
    contentFrame.Position = UDim2.new(0, 10, 0, 55)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 3
    contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    contentFrame.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 12)
    layout.Parent = contentFrame
    
    local hat = ChineseHat.new({
        enabled = false,
        color = Color3.new(1, 1, 1),
        transparency = 0.1,
        smoothness = 32
    })
    
    local function CreateToggle(name, default, callback)
        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(1, 0, 0, 35)
        toggleFrame.BackgroundTransparency = 1
        toggleFrame.Parent = contentFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = toggleFrame
        
        local toggleButton = Instance.new("TextButton")
        toggleButton.Size = UDim2.new(0, 50, 0, 25)
        toggleButton.Position = UDim2.new(1, -55, 0.5, -12)
        toggleButton.BackgroundColor3 = default and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(80, 80, 80)
        toggleButton.Text = ""
        toggleButton.Parent = toggleFrame
        
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(1, 0)
        toggleCorner.Parent = toggleButton
        
        local toggleDot = Instance.new("Frame")
        toggleDot.Size = UDim2.new(0, 21, 0, 21)
        toggleDot.Position = UDim2.new(default and 0.7 or 0, -10, 0.5, -10)
        toggleDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleDot.Parent = toggleButton
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = toggleDot
        
        toggleButton.MouseButton1Click:Connect(function()
            local newState = not default
            default = newState
            
            local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            
            local bgTween = TweenService:Create(toggleButton, tweenInfo, {
                BackgroundColor3 = newState and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(80, 80, 80)
            })
            
            local dotTween = TweenService:Create(toggleDot, tweenInfo, {
                Position = UDim2.new(newState and 0.7 or 0, -10, 0.5, -10)
            })
            
            bgTween:Play()
            dotTween:Play()
            
            callback(newState)
        end)
        
        return toggleButton
    end
    
    local function CreateSlider(name, min, max, default, callback)
        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(1, 0, 0, 55)
        sliderFrame.BackgroundTransparency = 1
        sliderFrame.Parent = contentFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name .. ": " .. string.format("%.1f", default)
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = sliderFrame
        
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, 0, 0, 6)
        slider.Position = UDim2.new(0, 0, 0, 35)
        slider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        slider.Parent = sliderFrame
        
        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(1, 0)
        sliderCorner.Parent = slider
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
        fill.Parent = slider
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill
        
        local handle = Instance.new("TextButton")
        handle.Size = UDim2.new(0, 16, 0, 16)
        handle.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
        handle.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
        handle.Text = ""
        handle.Parent = slider
        
        local handleCorner = Instance.new("UICorner")
        handleCorner.CornerRadius = UDim.new(1, 0)
        handleCorner.Parent = handle
        
        local sliding = false
        
        handle.MouseButton1Down:Connect(function()
            sliding = true
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = UserInputService:GetMouseLocation()
                local sliderPos = slider.AbsolutePosition
                local sliderSize = slider.AbsoluteSize
                
                local relativeX = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
                local value = min + (max - min) * relativeX
                
                fill.Size = UDim2.new(relativeX, 0, 1, 0)
                handle.Position = UDim2.new(relativeX, -8, 0.5, -8)
                label.Text = name .. ": " .. string.format("%.1f", value)
                
                callback(value)
            end
        end)
    end
    
    local function CreateColorPicker(name, default, callback)
        local colorFrame = Instance.new("Frame")
        colorFrame.Size = UDim2.new(1, 0, 0, 40)
        colorFrame.BackgroundTransparency = 1
        colorFrame.Parent = contentFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.Font = Enum.Font.Gotham
        label.TextSize = 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = colorFrame
        
        local colorButton = Instance.new("TextButton")
        colorButton.Size = UDim2.new(0, 50, 0, 25)
        colorButton.Position = UDim2.new(1, -55, 0.5, -12)
        colorButton.BackgroundColor3 = default
        colorButton.Text = ""
        colorButton.Parent = colorFrame
        
        local colorCorner = Instance.new("UICorner")
        colorCorner.CornerRadius = UDim.new(0, 6)
        colorCorner.Parent = colorButton
        
        colorButton.MouseButton1Click:Connect(function()
            callback(default)
        end)
        
        return colorButton
    end
    
    CreateToggle("Enable Smooth Hat", false, function(state)
        hat:SetEnabled(state)
    end)
    
    CreateSlider("Height", 0.1, 3, 0.8, function(value)
        hat:SetHeight(value)
    end)
    
    CreateSlider("Radius", 0.1, 5, 1.8, function(value)
        hat:SetRadius(value)
    end)
    
    CreateSlider("Transparency", 0, 1, 0.1, function(value)
        hat:SetTransparency(value)
    end)
    
    CreateSlider("Smoothness", 16, 64, 32, function(value)
        hat:SetSmoothness(math.floor(value))
    end)
    
    CreateColorPicker("Color", Color3.new(1, 1, 1), function(color)
        hat:SetColor(color)
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        hat:Destroy()
    end)
    
    local openKey = Enum.KeyCode.RightShift
    local visible = true
    
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == openKey then
            visible = not visible
            mainFrame.Visible = visible
        end
    end)
    
    return screenGui
end

CreateSmoothMenu()
