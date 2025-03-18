local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

local function onToolEquipped(tool: Tool)
    if CollectionService:HasTag(tool, "Gun") then
        
        local clonedTool = tool:Clone()

        for _, v in pairs(clonedTool:GetDescendants()) do
            if not v:IsA("BasePart") then
                v:Destroy()
            end
        end

        local gui = player:WaitForChild("PlayerGui"):FindFirstChild("GunGUI")
        if gui then
            local viewport = gui:FindFirstChildOfClass("ViewportFrame")
            if viewport then
                viewport:ClearAllChildren()

                local camera = Instance.new("Camera")
                viewport.CurrentCamera = camera
                camera.Parent = viewport

                clonedTool.Parent = viewport
                clonedTool.PrimaryPart.CFrame = CFrame.new(Vector3.new(0, 0, 0))
                
                camera.CFrame = CFrame.new(Vector3.new(0, 0, 5), Vector3.new(0, 0, 0))
            end
        end
    end    
end

if humanoid then
    humanoid.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            onToolEquipped(child)
        end
    end)
end