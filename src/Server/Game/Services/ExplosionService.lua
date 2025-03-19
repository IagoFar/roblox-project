local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local Workspace = game:GetService("Workspace")

local ExplosionService = Knit.CreateService {
    Name = "ExplosionService";
    Client = {
        AddBarrelState = Knit.CreateSignal()
    }
}

local RagdollService

function ExplosionService:KnitStart()
    RagdollService = Knit.GetService("RagdollService")
end


function ExplosionService.Client:AddBarrelState(Player, hitPart)
    self.Server:AddBarrelState(hitPart)
end

function ExplosionService:AddBarrelState(hit: Part)
    if CollectionService:HasTag(hit, "Casibum") then
        for _, descendant in pairs(Workspace:GetDescendants()) do
            if descendant:IsA("Humanoid") then
                local character = descendant.Parent
                if character and character:FindFirstChild("Humanoid") then
                    local humanoid = character.Humanoid
                    local distance = (character.PrimaryPart.Position - hit.Position).Magnitude
                    if distance <= 10 then
                        local damage = 100 * (1 - (distance / 10))
                        damage = math.max(damage, 30)
                        damage = math.round(damage)
                        print("Damage: ", damage)
                        humanoid:TakeDamage(damage)
                        RagdollService:RagdollCharacter(character)
                        RagdollService:ApplyForce(character, (character.PrimaryPart.Position - hit.Position).Unit, 75)
                    end
                end
            end
        end

        local explosion = game:GetService("ReplicatedStorage").kaboom:Clone()
        explosion.CFrame = hit.CFrame
        explosion.Parent = hit
        explosion.KABUMATT.kabum:Emit(1)
        explosion.KABUMATT.shockwave:Emit(1)
        explosion.KABUMATT.smoke1:Emit(50)
        explosion.KABUMATT.smoke2:Emit(50)

        if hit.Parent:IsA("Model") then
            hit = hit.Parent
        end
        hit:Destroy()
    else
        CollectionService:AddTag(hit, "Casibum")
        local sparks = game.ReplicatedStorage.casibum:Clone()
        sparks.CFrame = hit.CFrame
        sparks.Parent = hit
    end

end

return ExplosionService