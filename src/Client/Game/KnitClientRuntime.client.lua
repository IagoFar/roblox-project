print("Starting Knit on Client")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddControllers(script.Parent.Controllers)


Knit.Start():catch(warn):await()