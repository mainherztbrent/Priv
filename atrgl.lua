--[[
    ANTI-RAGDOLL ULTRA - VERSIÓN CORREGIDA (arrastre suave)
    Botón flotante que SÍ prende/apaga y NO se teletransporta
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = nil
local humanoid = nil

-- Estado del script
local antiRagdollEnabled = true
local guiCreated = false
local heartbeatConnection = nil
local characterAddedConnection = nil
local guiVisible = true

-- Almacén para objetos modificados
local modifiedObjects = {
    constraints = {},
    animations = {},
    scripts = {},
    parts = {},
}

-- Variables globales para la GUI
local button = nil
local screenGui = nil

-- =================== LIMPIAR CONEXIONES ===================
local function disconnectAll()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
end

-- =================== RESTAURAR TODO ===================
local function restoreAll()
    if not character then return end
    
    pcall(function()
        for _, constraint in ipairs(modifiedObjects.constraints) do
            if constraint then
                pcall(function()
                    if constraint:FindFirstChild("Enabled") then
                        constraint.Enabled = true
                    elseif constraint.Parent ~= character then
                        constraint.Parent = character
                    end
                end)
            end
        end
        
        for _, animTrack in ipairs(modifiedObjects.animations) do
            pcall(function() if animTrack then animTrack:Play() end end)
        end
        
        for _, scriptObj in ipairs(modifiedObjects.scripts) do
            pcall(function()
                if scriptObj and scriptObj:IsA("Script") then
                    scriptObj.Disabled = false
                end
            end)
        end
        
        for _, partData in ipairs(modifiedObjects.parts) do
            pcall(function()
                if partData.part then
                    partData.part.Parent = character
                    if partData.anchored ~= nil then
                        partData.part.Anchored = partData.anchored
                    end
                end
            end)
        end
        
        modifiedObjects.constraints = {}
        modifiedObjects.animations = {}
        modifiedObjects.scripts = {}
        modifiedObjects.parts = {}
    end)
    
    if humanoid then
        humanoid.PlatformStand = false
        humanoid.AutoRotate = true
    end
end

-- =================== APLICAR PROTECCIONES ===================
local function applyProtections()
    if not antiRagdollEnabled then return end
    if not character or not humanoid or not humanoid.Parent then return end
    
    pcall(function()
        local badStates = {
            [Enum.HumanoidStateType.Physics] = true,
            [Enum.HumanoidStateType.FallingDown] = true,
            [Enum.HumanoidStateType.GettingUp] = true,
            [Enum.HumanoidStateType.Dead] = true,
        }
        if badStates[humanoid:GetState()] then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end

        humanoid.PlatformStand = false
        humanoid.AutoRotate = true

        -- Constraints
        for _, constraint in ipairs(character:GetDescendants()) do
            if constraint:IsA("Constraint") then
                local alreadySaved = false
                for _, saved in ipairs(modifiedObjects.constraints) do
                    if saved == constraint then alreadySaved = true break end
                end
                if not alreadySaved then
                    table.insert(modifiedObjects.constraints, constraint)
                end
                
                if constraint:FindFirstChild("Enabled") then
                    constraint.Enabled = false
                else
                    local tempFolder = player:FindFirstChild("TempAntiRagdoll") or Instance.new("Folder")
                    tempFolder.Name = "TempAntiRagdoll"
                    tempFolder.Parent = player
                    constraint.Parent = tempFolder
                end
            end
        end

        -- Animaciones
        if humanoid.Animator then
            for _, track in ipairs(humanoid.Animator:GetPlayingAnimationTracks()) do
                local animId = track.Animation.AnimationId:lower()
                for _, keyword in ipairs({"ragdoll", "knock", "stun", "fall", "down", "hit"}) do
                    if animId:find(keyword) then
                        local alreadySaved = false
                        for _, saved in ipairs(modifiedObjects.animations) do
                            if saved == track then alreadySaved = true break end
                        end
                        if not alreadySaved then
                            table.insert(modifiedObjects.animations, track)
                        end
                        track:Stop()
                        break
                    end
                end
            end
        end

        -- Scripts
        for _, scriptObj in ipairs(character:GetDescendants()) do
            if scriptObj:IsA("Script") and (scriptObj.Name:lower():find("ragdoll") or scriptObj.Name:lower():find("stun")) then
                local alreadySaved = false
                for _, saved in ipairs(modifiedObjects.scripts) do
                    if saved == scriptObj then alreadySaved = true break end
                end
                if not alreadySaved then
                    table.insert(modifiedObjects.scripts, scriptObj)
                end
                scriptObj.Disabled = true
            end
        end

        -- Partes sospechosas
        local blacklist = {"ragdoll", "stun", "knock", "fall", "down", "hit", "grab", "freeze"}
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart") then
                local nameLower = obj.Name:lower()
                for _, word in ipairs(blacklist) do
                    if nameLower:find(word) then
                        local alreadySaved = false
                        for _, saved in ipairs(modifiedObjects.parts) do
                            if saved.part == obj then alreadySaved = true break end
                        end
                        if not alreadySaved then
                            table.insert(modifiedObjects.parts, {part = obj, anchored = obj.Anchored})
                        end
                        local tempFolder = player:FindFirstChild("TempAntiRagdoll") or Instance.new("Folder")
                        tempFolder.Name = "TempAntiRagdoll"
                        tempFolder.Parent = player
                        obj.Parent = tempFolder
                        break
                    end
                end
            end
        end
    end)
end

-- =================== LOOP ===================
local function startProtection()
    disconnectAll()
    heartbeatConnection = RunService.Heartbeat:Connect(applyProtections)
    print("🛡️ Protección ACTIVADA")
end

local function stopProtection()
    disconnectAll()
    restoreAll()
    print("⚠️ Protección DESACTIVADA")
end

-- =================== ACTUALIZAR GUI ===================
local function actualizarBoton()
    if not button then return end
    if antiRagdollEnabled then
        button.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        button.Text = "ON"
    else
        button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        button.Text = "OFF"
    end
end

-- =================== CREAR GUI CORREGIDA ===================
local function createGUI()
    if guiCreated then return end
    guiCreated = true

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiRagdollUltra"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 60)
    button.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    button.BorderSizePixel = 0
    button.Text = "ON"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 30
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = false
    button.Parent = screenGui
    
    -- Esquinas redondeadas
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button
    
    -- Sombra
    local shadow = Instance.new("UIStroke")
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Thickness = 2
    shadow.Transparency = 0.5
    shadow.Parent = button

    -- Cargar posición guardada (VALIDAR que sea un número)
    local savedX = player:GetAttribute("AntiRagdollBtnX")
    local savedY = player:GetAttribute("AntiRagdollBtnY")
    
    -- Posición por defecto (centro derecha, pero dentro de la pantalla)
    local defaultX = 500  -- posición X por defecto
    local defaultY = 150  -- posición Y por defecto
    
    -- Solo usar valores guardados si son números válidos
    if type(savedX) == "number" and type(savedY) == "number" and savedX > 0 and savedY > 0 then
        button.Position = UDim2.new(0, savedX, 0, savedY)
    else
        button.Position = UDim2.new(0, defaultX, 0, defaultY)
    end

    -- Variables para arrastre
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local clickStartPos = nil
    local clickThreshold = 5

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            dragging = true
            dragStart = input.Position
            startPos = button.Position
            clickStartPos = input.Position
            
            -- Feedback visual
            button.BackgroundColor3 = antiRagdollEnabled and Color3.fromRGB(0, 220, 0) or Color3.fromRGB(220, 0, 0)
        end
    end)

    button.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                         input.UserInputType == Enum.UserInputType.Touch) then
            
            if dragStart and startPos then
                local delta = input.Position - dragStart
                local distanceMoved = math.abs(delta.X) + math.abs(delta.Y)
                
                if distanceMoved > clickThreshold then
                    -- Calcular nueva posición
                    local newX = startPos.X.Offset + delta.X
                    local newY = startPos.Y.Offset + delta.Y
                    
                    -- Obtener límites de la pantalla de forma segura
                    local viewportX = player:GetMouse().ViewSizeX or 800
                    local viewportY = player:GetMouse().ViewSizeY or 600
                    
                    local maxX = viewportX - button.AbsoluteSize.X
                    local maxY = viewportY - button.AbsoluteSize.Y
                    
                    newX = math.clamp(newX, 0, maxX)
                    newY = math.clamp(newY, 0, maxY)
                    
                    -- Aplicar nueva posición
                    button.Position = UDim2.new(0, newX, 0, newY)
                    
                    -- Guardar posición
                    player:SetAttribute("AntiRagdollBtnX", newX)
                    player:SetAttribute("AntiRagdollBtnY", newY)
                end
            end
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            
            -- Verificar si fue click (no arrastre)
            local wasDrag = false
            if clickStartPos then
                local delta = input.Position - clickStartPos
                local distanceMoved = math.abs(delta.X) + math.abs(delta.Y)
                wasDrag = distanceMoved > clickThreshold
            end
            
            if not wasDrag then
                -- Click: activar/desactivar
                antiRagdollEnabled = not antiRagdollEnabled
                
                if antiRagdollEnabled then
                    startProtection()
                else
                    stopProtection()
                end
                
                actualizarBoton()
            end
            
            dragging = false
            clickStartPos = nil
            actualizarBoton()
        end
    end)

    -- Tecla K para ocultar/mostrar
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.K then
            guiVisible = not guiVisible
            button.Visible = guiVisible
        end
    end)
    
    actualizarBoton()
end

-- =================== MANEJO DE RESPAWN ===================
local function onCharacterAdded(newChar)
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
        heartbeatConnection = nil
    end
    
    character = newChar
    humanoid = character:WaitForChild("Humanoid", 10)
    
    modifiedObjects.constraints = {}
    modifiedObjects.animations = {}
    modifiedObjects.scripts = {}
    modifiedObjects.parts = {}
    
    if not guiCreated then
        createGUI()
    end
    
    if antiRagdollEnabled then
        startProtection()
    end
end

characterAddedConnection = player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end

print("🔥 Anti-Ragdoll cargado. 🛡️ Verde = Activado | 🔴 Rojo = Desactivado")
print("📌 Arrastra el botón para moverlo | Presiona K para ocultar/mostrar")
