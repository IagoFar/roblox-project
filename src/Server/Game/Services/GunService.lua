local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local CollectionService = game:GetService("CollectionService")

local GunService = Knit.CreateService {
    Name = "GunService";
    Client = {
        Shoot = Knit.CreateSignal()
    }
}

local damageEvents = {}

function GunService.Client:DamageCharacter(player: Player, character: Model, Gun: Tool)
    self.Server:DamageCharacter(player, character, Gun) 
end

function GunService:DamageCharacter(player: Player, character: Model, gun: Tool)
    local Humanoid = character:FindFirstChildOfClass("Humanoid")
    if Humanoid then
        Humanoid:TakeDamage(gun.Damage.Value)

        if not character:GetAttribute("UniqueId") then
            character:SetAttribute("UniqueId", HttpService:GenerateGUID(false))
        end

        local characterId = character:GetAttribute("UniqueId")
        damageEvents[characterId] = player
        task.delay(20, function()
            damageEvents[characterId] = nil
        end)

        Humanoid.Died:Connect(function()
            if damageEvents[characterId] then
                self:SetKillCredit(character, damageEvents[characterId])
                damageEvents[characterId] = nil
            end
        end)
    end
end

function GunService:SetKillCredit(character: Model, player: Player)
    print(player.Name .. " has killed " .. character.Name)
end

return GunService