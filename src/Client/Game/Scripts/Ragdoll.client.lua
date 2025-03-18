local Players = game:GetService("Players")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)
local UserInputService = game:GetService("UserInputService")

Knit.OnStart():await()
print("Knit started")

local RagdollService = Knit.GetService("RagdollService")

local isRagdoll = false

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.R and not gameProcessedEvent then
        local character = Players.LocalPlayer.Character
        if character then
            if not isRagdoll then
                RagdollService:RequestRagdoll()
                isRagdoll = true
            else
                RagdollService:RequestUnragdoll()
                isRagdoll = false
            end
        end
    end
end)