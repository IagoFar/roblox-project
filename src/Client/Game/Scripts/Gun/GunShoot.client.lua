local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit:OnStart():await()

local ExplosionService = Knit.GetService("ExplosionService")
local GunService = Knit.GetService("GunService")

local Player = Players.LocalPlayer

Player.CharacterAdded:Connect(function(character: Model)
    character.ChildAdded:Connect(function(child: Instance)
        if child:IsA("Tool") and CollectionService:HasTag(child, "Gun") then
            local debounce = false
            child.Equipped:Connect(function()
                child.Activated:Connect(function()
                    if debounce then return end
                    debounce = true

                    local mouse = Player:GetMouse()
                    local origin = mouse.UnitRay.Origin
                    local direction = mouse.UnitRay.Direction * 1000

                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

                    local raycastResult = Workspace:Raycast(origin, direction, raycastParams)

                    if raycastResult then
                        local hitPart = raycastResult.Instance
                        local hitPosition = raycastResult.Position
                        local hitNormal = raycastResult.Normal

                        if CollectionService:HasTag(hitPart, "Explosive") or CollectionService:HasTag(hitPart.Parent, "Explosive") then
                            ExplosionService:AddBarrelState(hitPart)
                        elseif hitPart.Parent:FindFirstChildOfClass("Humanoid") then
                            GunService:DamageCharacter(hitPart.Parent, child)
                        end
                    end

                    local fireRate = child:FindFirstChild("FireRate")
                    if fireRate and fireRate:IsA("IntValue") then
                        local delay = 60 / fireRate.Value
                        print("Delay: ", delay)
                        task.wait(delay)
                    else
                        task.wait(1)
                    end

                    debounce = false
                end)
            end)
        end
    end)
end)