local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = game.Players.LocalPlayer


Player.CharacterAdded:Connect(function(character)
	local Humanoid = character:WaitForChild("Humanoid")
	local Camera = game.Workspace.Camera

	-- Configuración
	local normalSpeed = 15 -- Velocidad normal
	local runningSpeed = 24 -- Velocidad al correr
	local normalFOV = 70 -- Campo de visión normal
	local runningFOV = 90 -- Campo de visión al correr
	local transitionSpeed = 10 -- Velocidad de transición (ajusta para mayor o menor suavidad)

	-- Variables de estado
	local isRunning = false
	local currentSpeed = normalSpeed
	local currentFOV = normalFOV

	-- Función para interpolación suave
	local function lerp(start, goal, alpha)
		return start + (goal - start) * alpha
	end

	-- Actualizar velocidad y FOV gradualmente
	RunService.Heartbeat:Connect(function(deltaTime)
		local targetSpeed = isRunning and runningSpeed or normalSpeed
		local targetFOV = isRunning and runningFOV or normalFOV

		-- Interpolar la velocidad
		currentSpeed = lerp(currentSpeed, targetSpeed, transitionSpeed * deltaTime)
		Humanoid.WalkSpeed = currentSpeed

		-- Interpolar el FOV de la cámara
		currentFOV = lerp(currentFOV, targetFOV, transitionSpeed * deltaTime)
		Camera.FieldOfView = currentFOV
	end)

	-- Detectar cuando el jugador presiona Shift
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			isRunning = true
		end
	end)

	-- Detectar cuando el jugador suelta Shift
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.LeftShift then
			isRunning = false
		end
	end)
end)
