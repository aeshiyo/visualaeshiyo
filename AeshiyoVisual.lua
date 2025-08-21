local ChineseHat = {}

function ChineseHat.new(config)
    local self = {}
    
    -- Конфигурация по умолчанию
    config = config or {}
    self.enabled = config.enabled ~= false
    self.heightOffset = config.heightOffset or 0.9
    self.hatHeight = config.hatHeight or 0.8
    self.radius = config.radius or 1.8
    self.topRadius = config.topRadius or 0.6
    self.sides = config.sides or 64
    self.color = config.color or Color3.new(1, 0, 0)
    self.transparency = config.transparency or 0.3
    
    -- Сервисы
    self.players = game:GetService("Players")
    self.runService = game:GetService("RunService")
    self.userInputService = game:GetService("UserInputService")
    
    -- Переменные
    self.player = self.players.LocalPlayer
    self.character = nil
    self.head = nil
    self.circle = nil
    self.triangles = {}
    self.connections = {}
    self.active = false
    
    -- Локальные функции
    local function initialize()
        if not self.enabled then return end
        
        -- Создаем основу (круг)
        self.circle = Drawing.new("Circle")
        self.circle.Visible = false
        self.circle.Thickness = 0
        self.circle.Filled = true
        self.circle.NumSides = self.sides
        
        -- Создаем треугольники для 3D эффекта
        self.triangles = {}
        for i = 1, self.sides * 2 + 10 do
            local triangle = Drawing.new("Triangle")
            triangle.Visible = false
            triangle.Filled = true
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
        
        -- Позиции в мире
        local basePosition = self.head.Position + Vector3.new(0, self.heightOffset, 0)
        local topPosition = basePosition + Vector3.new(0, self.hatHeight, 0)
        
        -- Переводим в 2D координаты экрана
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
        
        -- Обновляем основу
        self.circle.Position = center2D
        self.circle.Radius = self.topRadius
        self.circle.Visible = self.enabled
        
        -- Рассчитываем позиции для граней
        local circlePositions = {}
        for i = 1, self.sides do
            local angle = math.rad((i / self.sides) * 360)
            local offset = Vector3.new(math.cos(angle) * self.radius, 0, math.sin(angle) * self.radius)
            local pointPos = camera:WorldToViewportPoint(basePosition + offset)
            circlePositions[i] = Vector2.new(pointPos.X, pointPos.Y)
        end
        
        -- Рисуем боковые грани
        local triangleIndex = 1
        
        -- Нижние треугольники (основание)
        for i = 1, self.sides do
            local nextIndex = i % self.sides + 1
            self.triangles[triangleIndex].PointA = center2D
            self.triangles[triangleIndex].PointB = circlePositions[i]
            self.triangles[triangleIndex].PointC = circlePositions[nextIndex]
            self.triangles[triangleIndex].Visible = self.enabled
            triangleIndex = triangleIndex + 1
        end
        
        -- Верхние треугольники (крыша)
        for i = 1, self.sides do
            local nextIndex = i % self.sides + 1
            self.triangles[triangleIndex].PointA = top2D
            self.triangles[triangleIndex].PointB = circlePositions[i]
            self.triangles[triangleIndex].PointC = circlePositions[nextIndex]
            self.triangles[triangleIndex].Visible = self.enabled
            triangleIndex = triangleIndex + 1
        end
        
        -- Скрываем неиспользуемые треугольники
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

    -- Публичные методы
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

    -- Автоматический запуск
    self:Start()
    
    return self
end

return ChineseHat
