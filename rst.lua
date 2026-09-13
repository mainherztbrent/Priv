local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

-- Crear GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CoquetteReset"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 115, 0, 50)  -- 165*0.7 = 115.5 → 115, 72*0.7 = 50.4 → 50
Frame.Position = UDim2.new(0.5, -57.5, 0, 10)  -- Centrado: 115/2 = 57.5
Frame.BackgroundColor3 = Color3.fromRGB(30, 20, 35)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

-- Hacer que el Frame sea arrastrable
local dragging = false
local dragStart = nil
local startPos = nil

Frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        startPos = Frame.Position
    end
end)

Frame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
        local newX = startPos.X.Offset + delta.X
        local newY = startPos.Y.Offset + delta.Y
        Frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
    end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 17)  -- 24*0.7 = 16.8 → 17
Title.BackgroundTransparency = 1
Title.Text = ""
Title.TextColor3 = Color3.fromRGB(255, 182, 255)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local ResetButton = Instance.new("TextButton")
ResetButton.Size = UDim2.new(0.88, 0, 0, 23)  -- 33*0.7 = 23.1 → 23
ResetButton.Position = UDim2.new(0.06, 0, 0.45, 0)
ResetButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
ResetButton.Text = "RESET"
ResetButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetButton.TextScaled = true
ResetButton.Font = Enum.Font.GothamBold
ResetButton.Parent = Frame

-- Esquinas redondeadas
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)  -- 12*0.7 = 8.4 → 8
corner.Parent = Frame

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 6)  -- 8*0.7 = 5.6 → 6
corner2.Parent = ResetButton

-- Función para reiniciar personaje
local cooldown = false

local function resetCharacter()
    if cooldown then return end
    cooldown = true
    
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Health = 0
            print("Coquette Reset ejecutado")
            
            -- Efecto visual de confirmación
            ResetButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
            ResetButton.Text = "✓"
            task.wait(0.2)
            ResetButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            ResetButton.Text = "RESET"
        end
    end
    
    -- Desbloquear después de 1.5 segundos
    task.wait(1.5)
    cooldown = false
end

-- Click del botón
ResetButton.MouseButton1Click:Connect(resetCharacter)

-- Tecla R
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.R then
        resetCharacter()
    end
end)

print("")
