local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local RagdollData = require(script.Parent.Data.RagdollData)


local RagdollService = Knit.CreateService {
    Name = "RagdollService";
    Client = {
        Ragdoll = Knit.CreateSignal(),
        Unragdoll = Knit.CreateSignal(),
    };
}

if not PhysicsService:IsCollisionGroupRegistered("Ragdoll") then
    PhysicsService:RegisterCollisionGroup("Ragdoll")
end

PhysicsService:CollisionGroupSetCollidable("Ragdoll", "Ragdoll", false)

-- Set up characters
function RagdollService:_SetupCharacter(character: Model)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.BreakJointsOnDeath = false
        hum.RequiresNeck = false

        for _, v in pairs(character:GetDescendants()) do
            if v:IsA("BasePart") then
                local copy = v:Clone()
                copy.Parent = v
                copy.Name = "Collide"
                copy.Size = Vector3.one
                copy.Transparency = 1
                copy.Massless = true
                copy.CanCollide = false
                copy:ClearAllChildren()

                local weld =  Instance.new("Weld")
                weld.Parent = copy
                weld.Part0 = v
                weld.Part1 = copy

            end
        end
    end
end

-- Initialize existing characters
function RagdollService:_InitializeCharacters()
    for _, v in pairs(game.Workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChildOfClass("Humanoid") then
            self:_SetupCharacter(v)
        end
    end
end

function RagdollService:_enableCollisionParts(char: Model, enabled: boolean)
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
            v.CanCollide = not enabled
            v.CanCollide = enabled
        end
    end
end

function RagdollService:_destroyJoints(char: Model)
    char.HumanoidRootPart.Massless = false
    for _, v in pairs(char:GetDescendants()) do
        if v.Name == "RAGDOLL_ATTACHMENT" or v.Name == "RAGDOLL_CONSTRAINT" then
            v:Destroy() 
        end

        if not v:IsA("BasePart") or v:FindFirstAncestorOfClass("Accessory") or v.Name == "Handle" or v.Name == "Torso" or v.Name == "Head" then continue end
    end    
end

function RagdollService:_buildJoints(char: Model)
    local hrp = char:FindFirstChild("HumanoidRootPart")

    for _, v in pairs(char:GetDescendants()) do
        if not v:IsA("BasePart") or v:FindFirstAncestorOfClass("Accessory") or v.Name == "Handle" or v.Name == "Torso" or v.Name == "HumanoidRootPart" then continue end

        if not RagdollData[v.Name] then continue end

        local a0: Attachment, a1: Attachment = Instance.new("Attachment"), Instance.new("Attachment")
        local joint: Constraint = Instance.new("BallSocketConstraint")

        a0.Name = "RAGDOLL_ATTACHMENT"
        a0.Parent = v
        a0.CFrame = RagdollData[v.Name].CFrame[2]

        a1.Name = "RAGDOLL_ATTACHMENT"
        a1.Parent = hrp
        a1.CFrame = RagdollData[v.Name].CFrame[1]

        joint.Name = "RAGDOLL_CONSTRAINT"
        joint.Parent = v
        joint.Attachment0 = a0
        joint.Attachment1 = a1

        v.Massless = true
    end
    
end

function RagdollService:_enableMotor6d(char: Model, enabled: boolean)
    for _, v in pairs(char:GetDescendants()) do
        if v.Name == "Handle" or v.Name == "RootJoint" or v.Name == "Neck" then continue end
        if v:IsA("Motor6D") then 
            v.Enabled = enabled 
        end
        if v:IsA("BasePart") then 
            v.CollisionGroup = if enabled then "Character" else "Ragdoll" 
        end
    end    
end


function RagdollService:RagdollCharacter(character: Model)

    local plr = Players:GetPlayerFromCharacter(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    RagdollService:_enableMotor6d(character, false)
    RagdollService:_buildJoints(character)
    RagdollService:_enableCollisionParts(character, true)

    if plr then
        self.Client.Ragdoll:Fire(plr)
    else
        hrp:SetNetworkOwner(nil)
        hum.AutoRotate = false
        hum.PlatformStand = true
    end
end

function RagdollService:UnragdollCharacter(character: Model)
    local plr = Players:GetPlayerFromCharacter(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if plr then
        self.Client.Unragdoll:Fire(plr)
    else
        hrp:SetNetworkOwner(nil)
        if hum:GetState() == Enum.HumanoidStateType.Dead then return end
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    RagdollService:_enableMotor6d(character, true)
    RagdollService:_destroyJoints(character)
    RagdollService:_enableCollisionParts(character, false)

    hum.AutoRotate = true
end

-- Runs when Knit starts
function RagdollService:KnitInit()

    self:_InitializeCharacters()

    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            self:_SetupCharacter(character)

            local hum = character:WaitForChild("Humanoid")
            hum.Died:Once(function()
                self:RagdollCharacter(character)
            end)
        end)
    end)
end

return RagdollService