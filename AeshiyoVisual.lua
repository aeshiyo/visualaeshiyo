local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local function createChineseHat()
    if character:FindFirstChild("ChineseHat") then
        character.ChineseHat:Destroy()
    end
    
    local hat = Instance.new("Accessory")
    hat.Name = "ChineseHat"
    
    local handle = Instance.new("Part", hat)
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.2, 0.2, 0.2)
    handle.Transparency = 1
    
    local hatPart = Instance.new("Part")
    hatPart.Name = "HatPart"
    hatPart.Size = Vector3.new(2.5, 0.2, 2.5)
    hatPart.Shape = Enum.PartType.Cylinder
    hatPart.BrickColor = BrickColor.new("Bright red")
    hatPart.TopSurface = Enum.SurfaceType.Smooth
    hatPart.BottomSurface = Enum.SurfaceType.Smooth
    
    local cone = Instance.new("Part")
    cone.Name = "ConePart"
    cone.Size = Vector3.new(1.8, 1.8, 1.8)
    cone.Shape = Enum.PartType.Ball
    cone.BrickColor = BrickColor.new("Bright yellow")
    cone.TopSurface = Enum.SurfaceType.Smooth
    cone.BottomSurface = Enum.SurfaceType.Smooth
    
    local hatWeld = Instance.new("WeldConstraint", handle)
    hatWeld.Part0 = handle
    hatWeld.Part1 = hatPart
    
    local coneWeld = Instance.new("WeldConstraint", hatPart)
    coneWeld.Part0 = hatPart
    coneWeld.Part1 = cone
    coneWeld.C0 = CFrame.new(0, 1, 0)
    
    hat.Parent = character
    handle.CFrame = character.Head.CFrame * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90))
    hatPart.CFrame = handle.CFrame * CFrame.Angles(0, 0, math.rad(90))
    
    for _, part in ipairs(hat:GetDescendants()) do
        if part:IsA("BasePart") then
            part.LocalTransparencyModifier = 0
        end
    end
end

local function freezeAnimations()
    for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    
    humanoid.AnimationPlayed:Connect(function(track)
        track:Stop()
    end)
    
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
end

local function setFOV(value)
    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = value
    end
end

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    createChineseHat()
    freezeAnimations()
    setFOV(105)
end)

createChineseHat()
freezeAnimations()
setFOV(105)
