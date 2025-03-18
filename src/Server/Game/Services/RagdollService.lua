local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local RagdollData = require(script.Parent.Data.RagdollData)

local RagdollService = Knit.CreateService {
    Name = "RagdollService";
    Client = {
        RequestRagdoll = Knit.CreateSignal(),
        RequestUnragdoll = Knit.CreateSignal()
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
                local copy: BasePart = v:Clone()
                copy.Parent = v
                copy.Name = "Collide"
                copy.Size = Vector3.one
                copy.Transparency = 1
                copy.Massless = true
                copy.CanCollide = false
                copy.CustomPhysicalProperties = PhysicalProperties.new(1, 0.1 , 0.5)
                copy:ClearAllChildren()

                local weld =  Instance.new("Weld")
                weld.Parent = copy
                weld.Part0 = v
                weld.Part1 = copy

            end
        end
    end
end

function RagdollService:_ControlNetworkOwnership(character: Model, enablePlayerControl: boolean)
    local player = Players:GetPlayerFromCharacter(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        if enablePlayerControl and player then
            -- Delegar control al cliente
            hrp:SetNetworkOwner(player)
        else
            -- Tomar control en el servidor
            hrp:SetNetworkOwner(nil)
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
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Configuración del ragdoll
    self:_enableMotor6d(character, false)
    self:_buildJoints(character)
    self:_enableCollisionParts(character, true)
    
    -- Control de red desde el cliente
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        self:_ControlNetworkOwnership(character, false)
    end
    self:_ControlNetworkOwnership(character, false)
    
    hum.AutoRotate = false
    hum.PlatformStand = true
end

function RagdollService:UnragdollCharacter(character: Model)
    local player = Players:GetPlayerFromCharacter(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    
    self:_enableCollisionParts(character, false)
    self:_destroyJoints(character)
    self:_enableMotor6d(character, true)
        
    if hum then
        hum.AutoRotate = true
        hum.PlatformStand = false
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    
    task.wait(0.1)
    if hum:GetState() == Enum.HumanoidStateType.FallingDown then
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    -- Restauración del control
    if player then
        self:_ControlNetworkOwnership(character, true)
    end
    

end

function RagdollService:ApplyForce(character: Model, direction: Vector3, targetVelocity: number)
    local hrp: BasePart = character:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        warn("HRP not found for " .. character.Name)
        return 
    end

    local attachment = Instance.new("Attachment")
    attachment.Parent = hrp

    local linVel = Instance.new("LinearVelocity")
    linVel.Attachment0 = attachment
    linVel.RelativeTo = Enum.ActuatorRelativeTo.World
    linVel.MaxForce = 1e5
    linVel.VectorVelocity = direction.Unit * targetVelocity
    linVel.Parent = hrp

    print("Applying force to " .. character.Name)
    game:GetService("Debris"):AddItem(linVel, 0.1)
end

-- Métodos del cliente
function RagdollService.Client:RequestRagdoll(player)
    local character = player.Character
    if character then
        self.Server:RagdollCharacter(character)
    end
end

function RagdollService.Client:RequestUnragdoll(player)
    local character = player.Character
    if character then
        self.Server:UnragdollCharacter(character)
    end
end

-- Runs when Knit starts
function RagdollService:KnitInit()
    self:_InitializeCharacters()

    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            self:_SetupCharacter(character)

            local hum = character:WaitForChild("Humanoid")
            hum.Died:Connect(function()
                self:RagdollCharacter(character)
            end)
        end)
    end)
end

return RagdollService