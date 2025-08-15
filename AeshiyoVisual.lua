local OnyxHat = {}
--modify config
function OnyxHat.new(config)
    local self = {}
    config = config or {}
    self.enb = config.enb ~= false --def = false
    self.heigh = config.heigh or 0.9 --size
    self.cheigh = config.cheigh or 0.8
    self.rad = config.rad or 1.8 --radius
    self.crad = config.crad or 0.6
    self.nm = config.nm or 64 
    self.Color = config.Color or Color3.new(1, 0, 0) --color
    self.trp = 0.3 --transpery
    self.plr = game:GetService("Players")
    self.run = game:GetService("RunService")
    self.inp = game:GetService("UserInputService")
    self.player = self.plr.LocalPlayer
    self.character = nil
    self.head = nil
    self.cnt = nil
    self.fltr = {}
    self.connections = {}
    self.active = false
    local function init()
        if not self.enb then return end
        self.cnt = Drawing.new("Circle")
        self.cnt.Visible = false
        self.cnt.Thickness = 0
        self.cnt.Filled = true
        self.cnt.NumSides = 64
        self.fltr = {}
        for i = 1, self.nm * 2 + 10 do
            local triangle = Drawing.new("Triangle")
            triangle.Visible = false
            triangle.Filled = true
            table.insert(self.fltr, triangle)
        end
        self:updv()
    end
    local function clear()
        if self.cnt then
            self.cnt:Remove()
            self.cnt = nil
        end
        for i, tri in ipairs(self.fltr) do
            if tri then
                tri.Visible = false
                tri:Remove()
            end
        end
        self.fltr = {}
        self.character = nil
        self.head = nil
    end
    function self:updv()
        if not self.cnt then return end
        self.cnt.Color = self.Color
        self.cnt.Transparency = self.trp
        for _, tri in ipairs(self.fltr) do
            tri.Color = self.Color
            tri.Transparency = self.trp
        end
    end
    function self:upd()
        if not self.enb then return end
        if not self.cnt or not self.character or not self.head then 
            if self.cnt then 
                self.cnt.Visible = false 
            end
            for _, tri in ipairs(self.fltr) do 
                tri.Visible = false 
            end
            return 
        end
        local camera = workspace.CurrentCamera
        if not camera then return end
        local basePosition = self.head.Position + Vector3.new(0, self.heigh, 0)
        local baseScreenPos, baseVisible = camera:WorldToViewportPoint(basePosition)
        local topPosition = basePosition + Vector3.new(0, self.cheigh, 0)
        local topScreenPos, topVisible = camera:WorldToViewportPoint(topPosition)
        if not (baseVisible and topVisible) then
            self.cnt.Visible = false
            for _, tri in ipairs(self.fltr) do 
                tri.Visible = false 
            end
            return
        end
        local center2D = Vector2.new(baseScreenPos.X, baseScreenPos.Y)
        local top2D = Vector2.new(topScreenPos.X, topScreenPos.Y)
        self.cnt.Position = center2D
        self.cnt.Radius = self.crad
        self.cnt.Visible = self.enb
        local circlePositions = {}
        for i = 1, self.nm do
            local angle = math.rad((i / self.nm) * 360)
            local offset = Vector3.new(math.cos(angle) * self.rad, 0, math.sin(angle) * self.rad)
            local pointPos = camera:WorldToViewportPoint(basePosition + offset)
            circlePositions[i] = Vector2.new(pointPos.X, pointPos.Y)
        end
        local triIndex = 1
        for i = 1, self.nm do
            local next_i = i % self.nm + 1
            self.fltr[triIndex].PointA = center2D
            self.fltr[triIndex].PointB = circlePositions[i]
            self.fltr[triIndex].PointC = circlePositions[next_i]
            self.fltr[triIndex].Visible = self.enb
            triIndex = triIndex + 1
        end
        for i = 1, self.nm do
            local next_i = i % self.nm + 1
            self.fltr[triIndex].PointA = top2D
            self.fltr[triIndex].PointB = circlePositions[i]
            self.fltr[triIndex].PointC = circlePositions[next_i]
            self.fltr[triIndex].Visible = self.enb
            triIndex = triIndex + 1
        end
        for i = triIndex, #self.fltr do
            self.fltr[i].Visible = false
        end
    end
    local function setup(newCharacter)
        self.character = newCharacter
        self.head = self.character:WaitForChild("Head")
        local humanoid = self.character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            table.insert(self.connections, humanoid.Died:Connect(function()
                clear()
            end))
            table.insert(self.connections, humanoid.Running:Connect(function(state)
                if state == Enum.HumanoidStateType.Dead then
                    clear()
                end
            end))
        end
        table.insert(self.connections, self.character.ChildAdded:Connect(function(child)
            if child:IsA("Humanoid") then
                table.insert(self.connections, child.Running:Connect(function(state)
                    if state == Enum.HumanoidStateType.Dead then
                        clear()
                    end
                end))
            end
        end))
        init()
    end
    function self:Start()
        if self.active then return end
        self.active = true
        clear()
        if self.player.Character then
            setup(self.player.Character)
        end
        table.insert(self.connections, self.player.CharacterAdded:Connect(function(character)
            setup(character)
        end))
        table.insert(self.connections, self.run.RenderStepped:Connect(function()
            if self.enb and self.character and self.head then
                self:upd()
            end
        end))
        table.insert(self.connections, self.inp.WindowFocusReleased:Connect(function()
            if self.enb then self:upd() end
        end))
        table.insert(self.connections, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            if self.enb then self:upd() end
        end))
    end
    function self:Destroy()
        self.active = false
        self.enb = false
        for _, conn in ipairs(self.connections) do
            conn:Disconnect()
        end
        self.connections = {}
        clear()
    end
    function self:Setenb(state)
        self.enb = state
        if not state then
            clear()
        else
            if self.player.Character and not self.character then
                setup(self.player.Character)
            end
        end
    end
    function self:SetColor(newColor)
        self.Color = newColor
        self:updv()
    end
    function self:Settrp(newtrp)
        self.trp = newtrp
        self:updv()
    end
    self:Start()
    return self
end

return OnyxHat