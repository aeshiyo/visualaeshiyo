loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()

local function applyChineseHat()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")

    if character:FindFirstChild("ChineseHat") then
        character.ChineseHat:Destroy()
    end

    local hat = Instance.new("Part")
    hat.Name = "ChineseHat"
    hat.Size = Vector3.new(2.5, 0.2, 2.5)
    hat.Shape = Enum.PartType.Cylinder
    hat.Color = Color3.fromRGB(255, 0, 0)
    hat.Material = Enum.Material.Neon
    hat.Anchored = false
    hat.CanCollide = false

    local tip = Instance.new("Part")
    tip.Name = "HatTip"
    tip.Size = Vector3.new(0.5, 1.5, 0.5)
    tip.Shape = Enum.PartType.Ball
    tip.Color = Color3.fromRGB(255, 255, 0)
    tip.Material = Enum.Material.Neon
    tip.Anchored = false
    tip.CanCollide = false

    local weld1 = Instance.new("WeldConstraint")
    weld1.Part0 = character.Head
    weld1.Part1 = hat
    weld1.Parent = hat

    local weld2 = Instance.new("WeldConstraint")
    weld2.Part0 = hat
    weld2.Part1 = tip
    weld2.C0 = CFrame.new(0, 0.8, 0)
    weld2.Parent = tip

    hat.CFrame = character.Head.CFrame * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90))
    hat.Parent = character
    tip.Parent = character

    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end

    humanoid.AnimationPlayed:Connect(function(track)
        task.wait(0.1)
        track:Stop()
    end)

    workspace.CurrentCamera.FieldOfView = 105
end

local function onCharacterAdded(character)
    character:WaitForChild("Humanoid")
    task.wait(1)
    applyChineseHat()
end

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if game:GetService("Players").LocalPlayer.Character then
    applyChineseHat()
end

local UIS = game:GetService("UserInputService")
UIS.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.H then
        applyChineseHat()
    end
end)
