local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Variables principales
local HitboxEnabled = false
local AntiRagdollEnabled = false
local targetPlayers = {}
local exactTargetNames = {}

-- ==================== LISTA DE PROHIBIDOS ====================
local PROHIBITED_USERS = {}

local function cargarListaProhibidos()
    local success, resultado = pcall(function()
        local url = "https://raw.githubusercontent.com/villalobos66/personalizado/main/LisPro.lua"
        local listaRaw = game:HttpGet(url)
        local listaFunc = loadstring(listaRaw)
        if listaFunc then
            return listaFunc()
        end
        return nil
    end)
    return success and resultado or nil
end

local listaExterna = cargarListaProhibidos()
if listaExterna and type(listaExterna) == "table" and #listaExterna > 0 then
    PROHIBITED_USERS = listaExterna
    print("✅ Lista de prohibidos cargada: " .. #PROHIBITED_USERS .. " usuarios")
else
    PROHIBITED_USERS = {}
    print("⚠️ Lista de prohibidos vacía")
end

local function isPlayerProhibited(playerObj)
    if not playerObj or playerObj == player then return false end
    local playerNameLower = playerObj.Name:lower()
    local displayNameLower = playerObj.DisplayName:lower()
    for _, prohibitedName in ipairs(PROHIBITED_USERS) do
        local prohibitedLower = tostring(prohibitedName):lower()
        if playerNameLower == prohibitedLower or displayNameLower == prohibitedLower then
            return true
        end
    end
    return false
end

-- ==================== CONFIGURACIÓN ====================
local HITBOX_SIZE = 30
local HITBOX_TRANSPARENCY = 0.5
local HITBOX_COLOR = Color3.fromRGB(255, 0, 0)
local HITBOX_MATERIAL = Enum.Material.Neon

-- Variables para WalkSpeed
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local loopWalkSpeedConnection = nil

-- Variables para TP Walk
local TPWalkEnabled = false
local TPSpeedValue = 3
local tpWalkConnection = nil

-- ==================== DAMAGE REPEATER ====================
local REPEAT_AMOUNT = 26
local damageRepeaterEnabled = false
local mt = nil
local old = nil
local isMetatableHooked = false

local DAMAGE_EVENTS = {
    "Hit", "Damage", "DealDamage", "TakeDamage", "MeleeHit",
    "Punch", "Kick", "Attack", "SwordHit", "Swing", "Strike"
}

local IGNORED_EVENTS = {
    "SayMessageRequest", "MeleeUpdateEvent", "NinjaBombEvent",
    "BulletUpdateEvent", "UpdateAnimation", "SetAnimation",
    "MoveEvent", "JumpEvent", "SitEvent", "Emote", "Dance",
    "CharacterAdded", "LoadCharacter", "Respawn", "Teleport",
    "Ragdoll", "Fall"
}

local lastRepeatTime = {}
local MAX_REPEAT_PER_SECOND = 15

task.spawn(function()
    while true do
        task.wait(10)
        local now = tick()
        for name, time in pairs(lastRepeatTime) do
            if now - time > 5 then
                lastRepeatTime[name] = nil
            end
        end
    end
end)

local function getTargetPlayerFromArgs(...)
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if type(arg) == "string" then
            local target = Players:FindFirstChild(arg)
            if target then return target end
        elseif type(arg) == "table" and arg.Name then
            local target = Players:FindFirstChild(arg.Name)
            if target then return target end
        elseif type(arg) == "Instance" and arg:IsA("Player") then
            return arg
        end
    end
    return nil
end

local function isDamageEvent(eventName)
    local lowerName = eventName:lower()
    for _, damageEvent in ipairs(DAMAGE_EVENTS) do
        if lowerName == damageEvent:lower() or lowerName:find(damageEvent:lower()) then
            return true
        end
    end
    return false
end

local function isIgnoredEvent(eventName)
    local lowerName = eventName:lower()
    for _, ignoredEvent in ipairs(IGNORED_EVENTS) do
        if lowerName == ignoredEvent:lower() or lowerName:find(ignoredEvent:lower()) then
            return true
        end
    end
    return false
end

local function shouldRepeat(targetPlayerName)
    if not targetPlayerName then return true end
    local now = tick()
    local lastTime = lastRepeatTime[targetPlayerName] or 0
    if now - lastTime < (1 / MAX_REPEAT_PER_SECOND) then
        return false
    end
    lastRepeatTime[targetPlayerName] = now
    return true
end

local function createNamecallHandler()
    return function(self, ...)
        local method = getnamecallmethod()
        local eventName = self.Name
        
        if isIgnoredEvent(eventName) then
            return old(self, ...)
        end
        
        if method == "FireServer" or method == "InvokeServer" then
            if isDamageEvent(eventName) then
                local targetPlayerObj = getTargetPlayerFromArgs(...)
                
                if targetPlayerObj and isPlayerProhibited(targetPlayerObj) then
                    return old(self, ...)
                end
                
                local targetName = targetPlayerObj and targetPlayerObj.Name or nil
                
                if shouldRepeat(targetName) then
                    for i = 1, REPEAT_AMOUNT do
                        old(self, ...)
                        if i % 5 == 0 then
                            task.wait(0.005)
                        end
                    end
                else
                    old(self, ...)
                end
                return
            end
        end
        
        return old(self, ...)
    end
end

local function EnableDamageRepeater()
    if isMetatableHooked then return end
    if not mt then
        mt = getrawmetatable(game)
        old = mt.__namecall
        setreadonly(mt, false)
    end
    mt.__namecall = createNamecallHandler()
    isMetatableHooked = true
end

local function DisableDamageRepeater()
    if not isMetatableHooked then return end
    if mt and old then
        mt.__namecall = old
        isMetatableHooked = false
    end
end

local function toggleDamageRepeater()
    damageRepeaterEnabled = not damageRepeaterEnabled
    if damageRepeaterEnabled then
        EnableDamageRepeater()
        if damageRepeaterBtn then
            damageRepeaterBtn.Text = "REP\nON"
            damageRepeaterBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
            damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        end
        if repeatStatusLabel then
            repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x (solo golpes)"
            repeatStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
        end
    else
        DisableDamageRepeater()
        if damageRepeaterBtn then
            damageRepeaterBtn.Text = "REP\nOFF"
            damageRepeaterBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
        if repeatStatusLabel then
            repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x"
            repeatStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
    end
end

-- ==================== ANTI-RAGDOLL OPTIMIZADO ====================
local antiRagdollConnection = nil
local currentCharacterJoints = {}

local function updateJoints(character)
    if not character then return end
    currentCharacterJoints = {}
    for _, joint in pairs(character:GetDescendants()) do
        if joint:IsA("Motor6D") then
            currentCharacterJoints[joint.Name] = {
                Part0 = joint.Part0,
                Part1 = joint.Part1,
                C0 = joint.C0,
                C1 = joint.C1
            }
        end
    end
end

local function restoreJoints()
    for name, data in pairs(currentCharacterJoints) do
        if data.Part0 and data.Part0.Parent then
            if data.Part0:FindFirstChild(name) == nil then
                local joint = Instance.new("Motor6D")
                joint.Name = name
                joint.Part0 = data.Part0
                joint.Part1 = data.Part1
                joint.C0 = data.C0
                joint.C1 = data.C1
                joint.Parent = data.Part0
            end
        end
    end
end

local function isInRagdoll(humanoid)
    if not humanoid then return false end
    local state = humanoid:GetState()
    return state == Enum.HumanoidStateType.Physics or
           state == Enum.HumanoidStateType.FallingDown or
           humanoid.PlatformStand
end

local function antiRagdollLoop()
    if not AntiRagdollEnabled then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    updateJoints(character)
    
    if isInRagdoll(humanoid) then
        restoreJoints()
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid.AutoRotate = true
        rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 20, rootPart.Velocity.Z)
    end
end

local function setupAntiRagdoll(character)
    if antiRagdollConnection then
        antiRagdollConnection:Disconnect()
        antiRagdollConnection = nil
    end
    task.wait(0.5)
    updateJoints(character)
    if AntiRagdollEnabled then
        antiRagdollConnection = RunService.Heartbeat:Connect(antiRagdollLoop)
    end
end

local function toggleAntiRagdoll()
    AntiRagdollEnabled = not AntiRagdollEnabled
    if AntiRagdollEnabled then
        if player.Character then
            setupAntiRagdoll(player.Character)
        end
    else
        if antiRagdollConnection then
            antiRagdollConnection:Disconnect()
            antiRagdollConnection = nil
        end
    end
end

if player.Character then
    setupAntiRagdoll(player.Character)
end

player.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    setupAntiRagdoll(character)
end)

-- ==================== FUNCIONES AUXILIARES ====================
local function findPlayerByPartialName(inputText)
    if inputText == "" or inputText:lower() == "todos" or inputText:lower() == "all" then
        return nil, "TODOS"
    end
    local searchText = inputText:lower():gsub("%s+", "")
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and not isPlayerProhibited(p) then
            if p.Name:lower() == searchText then return p, p.Name end
            if p.DisplayName:lower() == searchText then return p, p.DisplayName end
        end
    end
    if #searchText >= 3 then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then
                if p.Name:lower():sub(1, #searchText) == searchText then return p, p.Name end
                if p.DisplayName:lower():sub(1, #searchText) == searchText then return p, p.DisplayName end
            end
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and not isPlayerProhibited(p) then
                if p.Name:lower():find(searchText, 1, true) then return p, p.Name end
                if p.DisplayName:lower():find(searchText, 1, true) then return p, p.DisplayName end
            end
        end
    end
    if #searchText > 0 and #searchText < 3 then return false, "Mínimo 3 letras" end
    return false, "No encontrado"
end

-- ==================== HITBOX OPTIMIZADO (SOLO CUANDO ES NECESARIO) ====================
-- Almacenar estado actual de hitboxes para evitar cambios innecesarios
local currentHitboxState = {} -- player -> {size, transparency, color, material, enabled}

local function resetHitbox(target)
    pcall(function()
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = target.Character.HumanoidRootPart
            -- Solo resetear si no está ya en estado normal
            if currentHitboxState[target] and currentHitboxState[target].enabled then
                rootPart.Size = Vector3.new(2, 2, 1)
                rootPart.Transparency = 1
                rootPart.Color = Color3.fromRGB(255, 255, 255)
                rootPart.Material = Enum.Material.Plastic
                rootPart.CanCollide = false
                currentHitboxState[target] = {enabled = false, size = 2, transparency = 1}
            end
        end
    end)
end

local function resetAllHitboxes()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and not isPlayerProhibited(v) then
            resetHitbox(v)
        end
    end
end

local function applyHitboxToPlayer(target)
    pcall(function()
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = target.Character.HumanoidRootPart
            
            -- Verificar si ya tiene el hitbox aplicado para evitar cambios innecesarios
            local current = currentHitboxState[target]
            if current and current.enabled and 
               current.size == HITBOX_SIZE and 
               current.transparency == HITBOX_TRANSPARENCY then
                return -- Ya está correcto, no hacer nada
            end
            
            -- Aplicar hitbox
            rootPart.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
            rootPart.Transparency = HITBOX_TRANSPARENCY
            rootPart.Color = HITBOX_COLOR
            rootPart.Material = HITBOX_MATERIAL
            rootPart.CanCollide = false
            
            -- Guardar estado
            currentHitboxState[target] = {
                enabled = true,
                size = HITBOX_SIZE,
                transparency = HITBOX_TRANSPARENCY
            }
        end
    end)
end

local function shouldHitPlayer(playerObj)
    if playerObj == player then return false end
    if isPlayerProhibited(playerObj) then return false end
    if not playerObj.Character then return false end
    if not playerObj.Character:FindFirstChild("HumanoidRootPart") then return false end
    return true
end

-- NUEVA FUNCIÓN OPTIMIZADA: Solo aplica hitboxes cuando el estado cambia
local function updateHitboxesOptimized()
    if not HitboxEnabled then
        resetAllHitboxes()
        return
    end
    
    -- Si hay targets específicos
    if #targetPlayers > 0 then
        -- Resetear hitboxes de jugadores que NO están en targets
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player and not isPlayerProhibited(v) then
                local isTarget = false
                for _, target in ipairs(targetPlayers) do
                    if target == v then
                        isTarget = true
                        break
                    end
                end
                if not isTarget then
                    resetHitbox(v)
                end
            end
        end
        -- Aplicar hitbox a targets
        for _, target in ipairs(targetPlayers) do
            if target and shouldHitPlayer(target) then
                applyHitboxToPlayer(target)
            end
        end
    else
        -- Sin targets específicos, aplicar a todos
        for _, v in pairs(Players:GetPlayers()) do
            if shouldHitPlayer(v) then
                applyHitboxToPlayer(v)
            else
                resetHitbox(v)
            end
        end
    end
end

-- Evento de cambio de tamaño/transparencia - actualizar hitboxes solo cuando cambian
local function onHitboxConfigChanged()
    if HitboxEnabled then
        -- Forzar actualización de todos los hitboxes activos
        for _, v in pairs(Players:GetPlayers()) do
            if shouldHitPlayer(v) then
                -- Limpiar estado para forzar reaplicación
                currentHitboxState[v] = nil
            end
        end
        updateHitboxesOptimized()
    end
end

local function setHitboxSize(value)
    HITBOX_SIZE = tonumber(value)
    if hitboxSizeLabel then
        hitboxSizeLabel.Text = "Tamaño: " .. HITBOX_SIZE
    end
    onHitboxConfigChanged()
end

local function setHitboxTransparency(value)
    HITBOX_TRANSPARENCY = tonumber(value)
    if hitboxTransparencyLabel then
        hitboxTransparencyLabel.Text = "Transparencia: " .. HITBOX_TRANSPARENCY
    end
    onHitboxConfigChanged()
end

-- Eventos de jugadores para hitbox optimizado
local function onPlayerAdded(p)
    task.wait(1)
    if HitboxEnabled then
        local isTarget = #targetPlayers == 0
        if not isTarget then
            for _, target in ipairs(targetPlayers) do
                if target == p then
                    isTarget = true
                    break
                end
            end
        end
        if isTarget and shouldHitPlayer(p) then
            applyHitboxToPlayer(p)
        end
    end
end

local function onCharacterAdded(p, character)
    task.wait(0.5)
    if HitboxEnabled then
        local isTarget = #targetPlayers == 0
        if not isTarget then
            for _, target in ipairs(targetPlayers) do
                if target == p then
                    isTarget = true
                    break
                end
            end
        end
        if isTarget and shouldHitPlayer(p) then
            -- Limpiar estado para forzar reaplicación
            currentHitboxState[p] = nil
            applyHitboxToPlayer(p)
        end
    end
end

-- ==================== FUNCIONES DE MOVIMIENTO ====================
local function getCharacter()
    return player.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function setupLoopWalkSpeed()
    if loopWalkSpeedConnection then
        loopWalkSpeedConnection:Disconnect()
        loopWalkSpeedConnection = nil
    end
    
    if WalkSpeedEnabled then
        loopWalkSpeedConnection = RunService.Heartbeat:Connect(function()
            local humanoid = getHumanoid()
            if humanoid and math.abs(humanoid.WalkSpeed - WalkSpeedValue) > 0.001 then
                pcall(function()
                    humanoid.WalkSpeed = WalkSpeedValue
                end)
            end
        end)
    end
end

local function setWalkSpeed(value)
    WalkSpeedValue = tonumber(value)
    local humanoid = getHumanoid()
    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = WalkSpeedValue
        end)
    end
    if walkSpeedValueLabel then
        walkSpeedValueLabel.Text = "Vel actual: " .. string.format("%.2f", WalkSpeedValue)
    end
end

local function setWalkSpeedEnabled(enabled)
    WalkSpeedEnabled = enabled
    setupLoopWalkSpeed()
    
    if not enabled then
        local humanoid = getHumanoid()
        if humanoid then
            pcall(function()
                humanoid.WalkSpeed = 16
            end)
        end
    else
        local humanoid = getHumanoid()
        if humanoid then
            pcall(function()
                humanoid.WalkSpeed = WalkSpeedValue
            end)
        end
    end
    
    if walkSpeedBtn then
        if enabled then
            walkSpeedBtn.Text = "LOOP\nON"
            walkSpeedBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
            walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        else
            walkSpeedBtn.Text = "LOOP\nOFF"
            walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
end

local function setupTPWalk()
    if tpWalkConnection then
        tpWalkConnection:Disconnect()
        tpWalkConnection = nil
    end
    
    if TPWalkEnabled then
        tpWalkConnection = RunService.Heartbeat:Connect(function()
            local char = getCharacter()
            local hum = getHumanoid()
            
            if char and hum and hum.Parent then
                if hum.MoveDirection.Magnitude > 0 then
                    pcall(function()
                        local speed = tonumber(TPSpeedValue) or 3
                        char:TranslateBy(hum.MoveDirection * speed)
                    end)
                end
            end
        end)
    end
end

local function setTPSpeed(value)
    TPSpeedValue = tonumber(value)
    if tpSpeedValueLabel then
        tpSpeedValueLabel.Text = "Vel TP: " .. string.format("%.2f", TPSpeedValue)
    end
end

local function setTPWalkEnabled(enabled)
    TPWalkEnabled = enabled
    setupTPWalk()
    
    if tpWalkBtn then
        if enabled then
            tpWalkBtn.Text = "TP\nON"
            tpWalkBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
            tpWalkBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
        else
            tpWalkBtn.Text = "TP\nOFF"
            tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
            tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end
end

-- ==================== FUNCIÓN DE ARRASTRE ====================
local function MakeDraggableWithHandle(frame, handle)
    local dragging = false
    local dragStartPos = nil
    local frameStartPos = nil
    
    handle.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            frameStartPos = frame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
           input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            frame.Position = UDim2.new(
                frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
                frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ==================== INTERFAZ DE BOTONES PRINCIPALES ====================
local function CreateButtonsInterface()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ButtonsGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 208, 0, 55)
    Frame.Position = UDim2.new(0.5, -104, 0.02, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Frame.BackgroundTransparency = 0.05
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 100, 255)
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = 0.5
    UIStroke.Parent = Frame

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 23)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    TopBar.BackgroundTransparency = 0.2
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Frame

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 8)
    TopBarCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.6, 0, 1, 0)
    Title.Position = UDim2.new(0, 8, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⋮⋮ PANEL ⋮⋮"
    Title.TextColor3 = Color3.fromRGB(200, 200, 255)
    Title.TextSize = 8
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local ConfigButton = Instance.new("TextButton")
    ConfigButton.Size = UDim2.new(0, 23, 0, 20)
    ConfigButton.Position = UDim2.new(1, -27, 0, 1.5)
    ConfigButton.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    ConfigButton.Text = "⚙️"
    ConfigButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConfigButton.Font = Enum.Font.GothamBold
    ConfigButton.TextSize = 11
    ConfigButton.Parent = TopBar

    local configCorner = Instance.new("UICorner")
    configCorner.CornerRadius = UDim.new(0, 4)
    configCorner.Parent = ConfigButton

    local ButtonsContainer = Instance.new("Frame")
    ButtonsContainer.Size = UDim2.new(0.96, 0, 0.55, 0)
    ButtonsContainer.Position = UDim2.new(0.02, 0, 0.48, 0)
    ButtonsContainer.BackgroundTransparency = 1
    ButtonsContainer.Parent = Frame

    hitboxBtn = Instance.new("TextButton")
    hitboxBtn.Size = UDim2.new(0.24, 0, 1, 0)
    hitboxBtn.Position = UDim2.new(0, 0, 0, 0)
    hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    hitboxBtn.Text = "HIT\nOFF"
    hitboxBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    hitboxBtn.Font = Enum.Font.GothamBold
    hitboxBtn.TextSize = 8
    hitboxBtn.TextWrapped = true
    hitboxBtn.Parent = ButtonsContainer

    local hitboxCorner = Instance.new("UICorner")
    hitboxCorner.CornerRadius = UDim.new(0, 5)
    hitboxCorner.Parent = hitboxBtn

    tpWalkBtn = Instance.new("TextButton")
    tpWalkBtn.Size = UDim2.new(0.24, 0, 1, 0)
    tpWalkBtn.Position = UDim2.new(0.25, 0, 0, 0)
    tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tpWalkBtn.Text = "TP\nOFF"
    tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    tpWalkBtn.Font = Enum.Font.GothamBold
    tpWalkBtn.TextSize = 8
    tpWalkBtn.TextWrapped = true
    tpWalkBtn.Parent = ButtonsContainer

    local tpWalkCorner = Instance.new("UICorner")
    tpWalkCorner.CornerRadius = UDim.new(0, 5)
    tpWalkCorner.Parent = tpWalkBtn

    antiRagdollBtn = Instance.new("TextButton")
    antiRagdollBtn.Size = UDim2.new(0.24, 0, 1, 0)
    antiRagdollBtn.Position = UDim2.new(0.5, 0, 0, 0)
    antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    antiRagdollBtn.Text = "RAG\nOFF"
    antiRagdollBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    antiRagdollBtn.Font = Enum.Font.GothamBold
    antiRagdollBtn.TextSize = 8
    antiRagdollBtn.TextWrapped = true
    antiRagdollBtn.Parent = ButtonsContainer

    local antiRagdollCorner = Instance.new("UICorner")
    antiRagdollCorner.CornerRadius = UDim.new(0, 5)
    antiRagdollCorner.Parent = antiRagdollBtn

    damageRepeaterBtn = Instance.new("TextButton")
    damageRepeaterBtn.Size = UDim2.new(0.24, 0, 1, 0)
    damageRepeaterBtn.Position = UDim2.new(0.75, 0, 0, 0)
    damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    damageRepeaterBtn.Text = "REP\nOFF"
    damageRepeaterBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    damageRepeaterBtn.Font = Enum.Font.GothamBold
    damageRepeaterBtn.TextSize = 8
    damageRepeaterBtn.TextWrapped = true
    damageRepeaterBtn.Parent = ButtonsContainer

    local damageRepeaterCorner = Instance.new("UICorner")
    damageRepeaterCorner.CornerRadius = UDim.new(0, 5)
    damageRepeaterCorner.Parent = damageRepeaterBtn

    MakeDraggableWithHandle(Frame, TopBar)

    return ScreenGui, Frame, ConfigButton
end

-- ==================== INTERFAZ DE CONFIGURACIÓN ====================
local function CreateConfigInterface()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ConfigGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.Parent = player.PlayerGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 182, 0, 270)
    Frame.Position = UDim2.new(0.5, -91, 0.5, -135)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 100, 255)
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = 0.5
    UIStroke.Parent = Frame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 24)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    TitleBar.BackgroundTransparency = 0.1
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Frame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 8)
    TitleCorner.Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 8, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⋮⋮ CONFIG ⋮⋮"
    Title.TextColor3 = Color3.fromRGB(255, 200, 100)
    Title.TextSize = 8
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -24, 0, 2)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 11
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseBtn

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, 0, 1, -24)
    Content.Position = UDim2.new(0, 0, 0, 24)
    Content.BackgroundTransparency = 1
    Content.Parent = Frame

    local yOffset = 0.05

    -- Sección HITBOX
    local hitboxTitle = Instance.new("TextLabel")
    hitboxTitle.Size = UDim2.new(0.9, 0, 0, 11)
    hitboxTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    hitboxTitle.BackgroundTransparency = 1
    hitboxTitle.Text = "HITBOX"
    hitboxTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    hitboxTitle.Font = Enum.Font.GothamBold
    hitboxTitle.TextSize = 8
    hitboxTitle.TextXAlignment = Enum.TextXAlignment.Left
    hitboxTitle.Parent = Content
    yOffset = yOffset + 0.055

    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(0.3, 0, 0, 14)
    sizeLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Text = "Tamaño:"
    sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.TextSize = 7
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    sizeLabel.Parent = Content

    local hitboxSizeInput = Instance.new("TextBox")
    hitboxSizeInput.Size = UDim2.new(0.35, 0, 0, 15)
    hitboxSizeInput.Position = UDim2.new(0.32, 0, yOffset, 0)
    hitboxSizeInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hitboxSizeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    hitboxSizeInput.Font = Enum.Font.Gotham
    hitboxSizeInput.TextSize = 7
    hitboxSizeInput.PlaceholderText = "0.1-100"
    hitboxSizeInput.Text = "30"
    hitboxSizeInput.Parent = Content

    local sizeInputCorner = Instance.new("UICorner")
    sizeInputCorner.CornerRadius = UDim.new(0, 4)
    sizeInputCorner.Parent = hitboxSizeInput

    hitboxSizeLabel = Instance.new("TextLabel")
    hitboxSizeLabel.Size = UDim2.new(0.25, 0, 0, 14)
    hitboxSizeLabel.Position = UDim2.new(0.7, 0, yOffset, 0)
    hitboxSizeLabel.BackgroundTransparency = 1
    hitboxSizeLabel.Text = "Tam: 30"
    hitboxSizeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    hitboxSizeLabel.Font = Enum.Font.Gotham
    hitboxSizeLabel.TextSize = 7
    hitboxSizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    hitboxSizeLabel.Parent = Content
    yOffset = yOffset + 0.06

    local transLabel = Instance.new("TextLabel")
    transLabel.Size = UDim2.new(0.3, 0, 0, 14)
    transLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    transLabel.BackgroundTransparency = 1
    transLabel.Text = "Transparencia:"
    transLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    transLabel.Font = Enum.Font.Gotham
    transLabel.TextSize = 7
    transLabel.TextXAlignment = Enum.TextXAlignment.Left
    transLabel.Parent = Content

    local hitboxTransparencyInput = Instance.new("TextBox")
    hitboxTransparencyInput.Size = UDim2.new(0.35, 0, 0, 15)
    hitboxTransparencyInput.Position = UDim2.new(0.32, 0, yOffset, 0)
    hitboxTransparencyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hitboxTransparencyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    hitboxTransparencyInput.Font = Enum.Font.Gotham
    hitboxTransparencyInput.TextSize = 7
    hitboxTransparencyInput.PlaceholderText = "0-1"
    hitboxTransparencyInput.Text = "0.5"
    hitboxTransparencyInput.Parent = Content

    local transInputCorner = Instance.new("UICorner")
    transInputCorner.CornerRadius = UDim.new(0, 4)
    transInputCorner.Parent = hitboxTransparencyInput

    hitboxTransparencyLabel = Instance.new("TextLabel")
    hitboxTransparencyLabel.Size = UDim2.new(0.25, 0, 0, 14)
    hitboxTransparencyLabel.Position = UDim2.new(0.7, 0, yOffset, 0)
    hitboxTransparencyLabel.BackgroundTransparency = 1
    hitboxTransparencyLabel.Text = "Trans: 0.5"
    hitboxTransparencyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    hitboxTransparencyLabel.Font = Enum.Font.Gotham
    hitboxTransparencyLabel.TextSize = 7
    hitboxTransparencyLabel.TextXAlignment = Enum.TextXAlignment.Left
    hitboxTransparencyLabel.Parent = Content
    yOffset = yOffset + 0.06

    local sep1 = Instance.new("Frame")
    sep1.Size = UDim2.new(0.9, 0, 0, 1)
    sep1.Position = UDim2.new(0.05, 0, yOffset, 0)
    sep1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep1.BorderSizePixel = 0
    sep1.Parent = Content
    yOffset = yOffset + 0.05

    -- Sección LOOP WALKSPEED
    local wsTitle = Instance.new("TextLabel")
    wsTitle.Size = UDim2.new(0.9, 0, 0, 11)
    wsTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    wsTitle.BackgroundTransparency = 1
    wsTitle.Text = "LOOP WALKSPEED"
    wsTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    wsTitle.Font = Enum.Font.GothamBold
    wsTitle.TextSize = 8
    wsTitle.TextXAlignment = Enum.TextXAlignment.Left
    wsTitle.Parent = Content
    yOffset = yOffset + 0.055

    local wsContainer = Instance.new("Frame")
    wsContainer.Size = UDim2.new(0.9, 0, 0, 21)
    wsContainer.Position = UDim2.new(0.05, 0, yOffset, 0)
    wsContainer.BackgroundTransparency = 1
    wsContainer.Parent = Content

    walkSpeedBtn = Instance.new("TextButton")
    walkSpeedBtn.Size = UDim2.new(0.35, 0, 1, 0)
    walkSpeedBtn.Position = UDim2.new(0, 0, 0, 0)
    walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    walkSpeedBtn.Text = "LOOP\nOFF"
    walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    walkSpeedBtn.Font = Enum.Font.GothamBold
    walkSpeedBtn.TextSize = 7
    walkSpeedBtn.TextWrapped = true
    walkSpeedBtn.Parent = wsContainer

    local wsBtnCorner = Instance.new("UICorner")
    wsBtnCorner.CornerRadius = UDim.new(0, 4)
    wsBtnCorner.Parent = walkSpeedBtn

    local walkSpeedInput = Instance.new("TextBox")
    walkSpeedInput.Size = UDim2.new(0.55, 0, 1, 0)
    walkSpeedInput.Position = UDim2.new(0.38, 0, 0, 0)
    walkSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    walkSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    walkSpeedInput.Font = Enum.Font.Gotham
    walkSpeedInput.TextSize = 7
    walkSpeedInput.PlaceholderText = "Velocidad"
    walkSpeedInput.Text = "16"
    walkSpeedInput.Parent = wsContainer

    local wsInputCorner = Instance.new("UICorner")
    wsInputCorner.CornerRadius = UDim.new(0, 4)
    wsInputCorner.Parent = walkSpeedInput
    yOffset = yOffset + 0.07

    walkSpeedValueLabel = Instance.new("TextLabel")
    walkSpeedValueLabel.Size = UDim2.new(0.9, 0, 0, 11)
    walkSpeedValueLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    walkSpeedValueLabel.BackgroundTransparency = 1
    walkSpeedValueLabel.Text = "Vel actual: 16"
    walkSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    walkSpeedValueLabel.Font = Enum.Font.Gotham
    walkSpeedValueLabel.TextSize = 6
    walkSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    walkSpeedValueLabel.Parent = Content
    yOffset = yOffset + 0.05

    local sep2 = Instance.new("Frame")
    sep2.Size = UDim2.new(0.9, 0, 0, 1)
    sep2.Position = UDim2.new(0.05, 0, yOffset, 0)
    sep2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep2.BorderSizePixel = 0
    sep2.Parent = Content
    yOffset = yOffset + 0.05

    -- Sección TP WALK
    local tpTitle = Instance.new("TextLabel")
    tpTitle.Size = UDim2.new(0.9, 0, 0, 11)
    tpTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    tpTitle.BackgroundTransparency = 1
    tpTitle.Text = "TP WALK"
    tpTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    tpTitle.Font = Enum.Font.GothamBold
    tpTitle.TextSize = 8
    tpTitle.TextXAlignment = Enum.TextXAlignment.Left
    tpTitle.Parent = Content
    yOffset = yOffset + 0.055

    local tpLabel = Instance.new("TextLabel")
    tpLabel.Size = UDim2.new(0.3, 0, 0, 14)
    tpLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    tpLabel.BackgroundTransparency = 1
    tpLabel.Text = "Velocidad TP:"
    tpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    tpLabel.Font = Enum.Font.Gotham
    tpLabel.TextSize = 7
    tpLabel.TextXAlignment = Enum.TextXAlignment.Left
    tpLabel.Parent = Content

    local tpSpeedInput = Instance.new("TextBox")
    tpSpeedInput.Size = UDim2.new(0.35, 0, 0, 15)
    tpSpeedInput.Position = UDim2.new(0.32, 0, yOffset, 0)
    tpSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tpSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpSpeedInput.Font = Enum.Font.Gotham
    tpSpeedInput.TextSize = 7
    tpSpeedInput.PlaceholderText = "0.01-50"
    tpSpeedInput.Text = "3"
    tpSpeedInput.Parent = Content

    local tpInputCorner = Instance.new("UICorner")
    tpInputCorner.CornerRadius = UDim.new(0, 4)
    tpInputCorner.Parent = tpSpeedInput

    tpSpeedValueLabel = Instance.new("TextLabel")
    tpSpeedValueLabel.Size = UDim2.new(0.25, 0, 0, 14)
    tpSpeedValueLabel.Position = UDim2.new(0.7, 0, yOffset, 0)
    tpSpeedValueLabel.BackgroundTransparency = 1
    tpSpeedValueLabel.Text = "Vel TP: 3"
    tpSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    tpSpeedValueLabel.Font = Enum.Font.Gotham
    tpSpeedValueLabel.TextSize = 7
    tpSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    tpSpeedValueLabel.Parent = Content
    yOffset = yOffset + 0.06

    local sep3 = Instance.new("Frame")
    sep3.Size = UDim2.new(0.9, 0, 0, 1)
    sep3.Position = UDim2.new(0.05, 0, yOffset, 0)
    sep3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep3.BorderSizePixel = 0
    sep3.Parent = Content
    yOffset = yOffset + 0.05

    -- Sección DAMAGE REPEATER
    local repeaterTitle = Instance.new("TextLabel")
    repeaterTitle.Size = UDim2.new(0.9, 0, 0, 11)
    repeaterTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    repeaterTitle.BackgroundTransparency = 1
    repeaterTitle.Text = "DAMAGE REPEATER"
    repeaterTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    repeaterTitle.Font = Enum.Font.GothamBold
    repeaterTitle.TextSize = 8
    repeaterTitle.TextXAlignment = Enum.TextXAlignment.Left
    repeaterTitle.Parent = Content
    yOffset = yOffset + 0.055

    local repeatLabel = Instance.new("TextLabel")
    repeatLabel.Size = UDim2.new(0.4, 0, 0, 14)
    repeatLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    repeatLabel.BackgroundTransparency = 1
    repeatLabel.Text = "Repeticiones:"
    repeatLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    repeatLabel.Font = Enum.Font.Gotham
    repeatLabel.TextSize = 7
    repeatLabel.TextXAlignment = Enum.TextXAlignment.Left
    repeatLabel.Parent = Content

    repeatInput = Instance.new("TextBox")
    repeatInput.Size = UDim2.new(0.35, 0, 0, 18)
    repeatInput.Position = UDim2.new(0.45, 0, yOffset - 0.002, 0)
    repeatInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    repeatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    repeatInput.Font = Enum.Font.Gotham
    repeatInput.TextSize = 8
    repeatInput.PlaceholderText = "1-100"
    repeatInput.Text = tostring(REPEAT_AMOUNT)
    repeatInput.Parent = Content

    local repeatInputCorner = Instance.new("UICorner")
    repeatInputCorner.CornerRadius = UDim.new(0, 4)
    repeatInputCorner.Parent = repeatInput
    yOffset = yOffset + 0.07

    repeatStatusLabel = Instance.new("TextLabel")
    repeatStatusLabel.Size = UDim2.new(0.9, 0, 0, 11)
    repeatStatusLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    repeatStatusLabel.BackgroundTransparency = 1
    repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x"
    repeatStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    repeatStatusLabel.Font = Enum.Font.Gotham
    repeatStatusLabel.TextSize = 6
    repeatStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    repeatStatusLabel.Parent = Content
    yOffset = yOffset + 0.05

    local sep4 = Instance.new("Frame")
    sep4.Size = UDim2.new(0.9, 0, 0, 1)
    sep4.Position = UDim2.new(0.05, 0, yOffset, 0)
    sep4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep4.BorderSizePixel = 0
    sep4.Parent = Content
    yOffset = yOffset + 0.05

    -- Sección TARGET
    local targetTitle = Instance.new("TextLabel")
    targetTitle.Size = UDim2.new(0.9, 0, 0, 11)
    targetTitle.Position = UDim2.new(0.05, 0, yOffset, 0)
    targetTitle.BackgroundTransparency = 1
    targetTitle.Text = "TARGET (TOGGLE)"
    targetTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    targetTitle.Font = Enum.Font.GothamBold
    targetTitle.TextSize = 8
    targetTitle.TextXAlignment = Enum.TextXAlignment.Left
    targetTitle.Parent = Content
    yOffset = yOffset + 0.055

    targetBox = Instance.new("TextBox")
    targetBox.Size = UDim2.new(0.9, 0, 0, 18)
    targetBox.Position = UDim2.new(0.05, 0, yOffset, 0)
    targetBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetBox.Font = Enum.Font.Gotham
    targetBox.TextSize = 8
    targetBox.PlaceholderText = "Nombre (Enter para añadir/quitar)"
    targetBox.Text = ""
    targetBox.Parent = Content

    local targetCorner = Instance.new("UICorner")
    targetCorner.CornerRadius = UDim.new(0, 4)
    targetCorner.Parent = targetBox
    yOffset = yOffset + 0.07

    targetStatus = Instance.new("TextLabel")
    targetStatus.Size = UDim2.new(0.9, 0, 0, 24)
    targetStatus.Position = UDim2.new(0.05, 0, yOffset, 0)
    targetStatus.BackgroundTransparency = 1
    targetStatus.Text = "Objetivos: TODOS"
    targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    targetStatus.Font = Enum.Font.Gotham
    targetStatus.TextSize = 6
    targetStatus.TextXAlignment = Enum.TextXAlignment.Left
    targetStatus.TextWrapped = true
    targetStatus.Parent = Content
    yOffset = yOffset + 0.09

    searchResult = Instance.new("TextLabel")
    searchResult.Size = UDim2.new(0.9, 0, 0, 10)
    searchResult.Position = UDim2.new(0.05, 0, yOffset, 0)
    searchResult.BackgroundTransparency = 1
    searchResult.Text = "Escribe nombre y presiona Enter"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    searchResult.Font = Enum.Font.Gotham
    searchResult.TextSize = 6
    searchResult.TextXAlignment = Enum.TextXAlignment.Left
    searchResult.Parent = Content
    yOffset = yOffset + 0.05

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(0.9, 0, 0, 18)
    btnContainer.Position = UDim2.new(0.05, 0, yOffset, 0)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = Content

    clearTargetBtn = Instance.new("TextButton")
    clearTargetBtn.Size = UDim2.new(0.3, 0, 1, 0)
    clearTargetBtn.Position = UDim2.new(0, 0, 0, 0)
    clearTargetBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
    clearTargetBtn.Text = "Limpiar"
    clearTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearTargetBtn.Font = Enum.Font.GothamBold
    clearTargetBtn.TextSize = 7
    clearTargetBtn.Parent = btnContainer

    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 4)
    clearCorner.Parent = clearTargetBtn

    removeLastBtn = Instance.new("TextButton")
    removeLastBtn.Size = UDim2.new(0.3, 0, 1, 0)
    removeLastBtn.Position = UDim2.new(0.34, 0, 0, 0)
    removeLastBtn.BackgroundColor3 = Color3.fromRGB(200, 130, 50)
    removeLastBtn.Text = "Quitar Últ"
    removeLastBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    removeLastBtn.Font = Enum.Font.GothamBold
    removeLastBtn.TextSize = 7
    removeLastBtn.Parent = btnContainer

    local removeLastCorner = Instance.new("UICorner")
    removeLastCorner.CornerRadius = UDim.new(0, 4)
    removeLastCorner.Parent = removeLastBtn

    closestBtn = Instance.new("TextButton")
    closestBtn.Size = UDim2.new(0.36, 0, 1, 0)
    closestBtn.Position = UDim2.new(0.64, 0, 0, 0)
    closestBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    closestBtn.Text = "Añadir Cerca"
    closestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closestBtn.Font = Enum.Font.GothamBold
    closestBtn.TextSize = 7
    closestBtn.Parent = btnContainer

    local closestCorner = Instance.new("UICorner")
    closestCorner.CornerRadius = UDim.new(0, 4)
    closestCorner.Parent = closestBtn
    yOffset = yOffset + 0.07

    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.9, 0, 0, 10)
    infoLabel.Position = UDim2.new(0.05, 0, yOffset, 0)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "K=Mostrar | E=Hitbox | R=TP"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 6
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = Content

    -- CONECTAR EVENTOS DE LOS INPUTS
    hitboxSizeInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(hitboxSizeInput.Text)
            if val and val >= 0.1 and val <= 100 then
                setHitboxSize(val)
                searchResult.Text = "✓ Tamaño cambiado"
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                hitboxSizeInput.Text = tostring(HITBOX_SIZE)
                searchResult.Text = "✗ Tam inválido"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    hitboxTransparencyInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(hitboxTransparencyInput.Text)
            if val and val >= 0 and val <= 1 then
                setHitboxTransparency(val)
                searchResult.Text = "✓ Transparencia cambiada"
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                hitboxTransparencyInput.Text = tostring(HITBOX_TRANSPARENCY)
                searchResult.Text = "✗ Trans inválida"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    walkSpeedInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(walkSpeedInput.Text)
            if val and val >= 0.1 and val <= 500 then
                setWalkSpeed(val)
                searchResult.Text = "✓ Velocidad cambiada"
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                walkSpeedInput.Text = tostring(WalkSpeedValue)
                searchResult.Text = "✗ Vel inválida"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    tpSpeedInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(tpSpeedInput.Text)
            if val and val >= 0.01 and val <= 50 then
                setTPSpeed(val)
                searchResult.Text = "✓ Vel TP cambiada"
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                tpSpeedInput.Text = tostring(TPSpeedValue)
                searchResult.Text = "✗ Vel TP inválida"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Escribe nombre y presiona Enter"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    MakeDraggableWithHandle(Frame, TitleBar)

    return ScreenGui, Frame, CloseBtn
end

-- Funciones de actualización de botones
local function updateHitboxButton()
    if HitboxEnabled then
        hitboxBtn.Text = "HIT\nON"
        hitboxBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        hitboxBtn.Text = "HIT\nOFF"
        hitboxBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        hitboxBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateTPWalkButton()
    if TPWalkEnabled then
        tpWalkBtn.Text = "TP\nON"
        tpWalkBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        tpWalkBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        tpWalkBtn.Text = "TP\nOFF"
        tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateAntiRagdollButton()
    if AntiRagdollEnabled then
        antiRagdollBtn.Text = "RAG\nON"
        antiRagdollBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        antiRagdollBtn.Text = "RAG\nOFF"
        antiRagdollBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateWalkSpeedButton()
    if WalkSpeedEnabled then
        walkSpeedBtn.Text = "LOOP\nON"
        walkSpeedBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        walkSpeedBtn.Text = "LOOP\nOFF"
        walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateDamageRepeaterButton()
    if damageRepeaterEnabled then
        damageRepeaterBtn.Text = "REP\nON"
        damageRepeaterBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    else
        damageRepeaterBtn.Text = "REP\nOFF"
        damageRepeaterBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
end

local function updateTargetStatus()
    if #targetPlayers > 0 then
        local names = {}
        for i, target in ipairs(targetPlayers) do
            table.insert(names, exactTargetNames[target] or target.Name)
        end
        local displayText = "Objetivos: " .. table.concat(names, ", ")
        if #displayText > 35 then
            displayText = displayText:sub(1, 32) .. "..."
        end
        targetStatus.Text = displayText
        targetStatus.TextColor3 = Color3.fromRGB(80, 255, 80)
    else
        targetStatus.Text = "Objetivos: TODOS"
        targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    end
end

local function toggleTarget(playerObj, displayName)
    if not playerObj then return false end
    if playerObj == player then
        searchResult.Text = "✗ No te puedes añadir a ti mismo"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        return false
    end
    if isPlayerProhibited(playerObj) then
        searchResult.Text = "✗ Usuario prohibido"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        return false
    end
    
    for i, existing in ipairs(targetPlayers) do
        if existing == playerObj then
            table.remove(targetPlayers, i)
            exactTargetNames[playerObj] = nil
            updateTargetStatus()
            searchResult.Text = "🗑️ Eliminado: " .. (displayName or playerObj.Name)
            searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
            if HitboxEnabled then
                -- Limpiar estado y resetear hitbox
                currentHitboxState[playerObj] = nil
                updateHitboxesOptimized()
            end
            return true
        end
    end
    
    table.insert(targetPlayers, playerObj)
    exactTargetNames[playerObj] = displayName or playerObj.Name
    updateTargetStatus()
    searchResult.Text = "✓ Añadido: " .. (displayName or playerObj.Name)
    searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
    if HitboxEnabled then
        updateHitboxesOptimized()
    end
    return true
end

local function removeLastTarget()
    if #targetPlayers > 0 then
        local removed = table.remove(targetPlayers)
        local removedName = exactTargetNames[removed] or removed.Name
        exactTargetNames[removed] = nil
        updateTargetStatus()
        searchResult.Text = "🗑️ Eliminado: " .. removedName
        searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
        if HitboxEnabled then
            currentHitboxState[removed] = nil
            updateHitboxesOptimized()
        end
    else
        searchResult.Text = "⚠️ No hay objetivos para eliminar"
        searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
    end
    task.wait(2)
    if searchResult.Text:sub(1,1) == "✓" or searchResult.Text:sub(1,1) == "🗑️" or searchResult.Text:sub(1,1) == "⚠️" then
        searchResult.Text = "Escribe nombre y presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function addClosestTarget()
    local closestDistance = math.huge
    local closestPlayer = nil
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and not isPlayerProhibited(v) then
            pcall(function()
                if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (v.Character.HumanoidRootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance < closestDistance then
                        closestDistance = distance
                        closestPlayer = v
                    end
                end
            end)
        end
    end
    
    if closestPlayer then
        toggleTarget(closestPlayer, closestPlayer.DisplayName .. " (" .. closestPlayer.Name .. ")")
    else
        searchResult.Text = "✗ No hay jugadores cercanos disponibles"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(2)
        searchResult.Text = "Escribe nombre y presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function clearTargets()
    targetPlayers = {}
    exactTargetNames = {}
    targetBox.Text = ""
    updateTargetStatus()
    searchResult.Text = "✓ Todos los objetivos eliminados"
    searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
    if HitboxEnabled then
        for _, v in pairs(Players:GetPlayers()) do
            currentHitboxState[v] = nil
        end
        updateHitboxesOptimized()
    end
    task.wait(2)
    searchResult.Text = "Escribe nombre y presiona Enter"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
end

local function searchAndToggleTarget()
    local searchText = targetBox.Text:gsub("%s+", "")
    if searchText == "" or searchText:lower() == "todos" or searchText:lower() == "all" then
        searchResult.Text = "⚠️ Escribe un nombre específico"
        searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
        task.wait(2)
        searchResult.Text = "Escribe nombre y presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
        targetBox.Text = ""
        return
    end
    
    local foundPlayer, resultName = findPlayerByPartialName(searchText)
    if foundPlayer then
        toggleTarget(foundPlayer, resultName)
        targetBox.Text = ""
    elseif foundPlayer == nil then
        searchResult.Text = "✓ Modo TODOS - escribe un nombre para añadir/quitar"
        searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
    else
        searchResult.Text = resultName
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    
    task.wait(2)
    if searchResult.Text:sub(1,1) == "✓" or searchResult.Text:sub(1,1) == "🗑️" or searchResult.Text:sub(1,1) == "⚠️" or searchResult.Text:find("no encontrado") then
        searchResult.Text = "Escribe nombre y presiona Enter"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

-- Crear interfaces
local buttonsGUI, buttonsFrame, configButton = CreateButtonsInterface()
local configGUI, configFrame, closeConfigBtn = CreateConfigInterface()

-- Conectar eventos
hitboxBtn.MouseButton1Click:Connect(function()
    HitboxEnabled = not HitboxEnabled
    updateHitboxButton()
    updateHitboxesOptimized()
end)

tpWalkBtn.MouseButton1Click:Connect(function()
    setTPWalkEnabled(not TPWalkEnabled)
    updateTPWalkButton()
end)

antiRagdollBtn.MouseButton1Click:Connect(function()
    toggleAntiRagdoll()
    updateAntiRagdollButton()
end)

damageRepeaterBtn.MouseButton1Click:Connect(function()
    toggleDamageRepeater()
    updateDamageRepeaterButton()
end)

configButton.MouseButton1Click:Connect(function()
    configGUI.Enabled = not configGUI.Enabled
end)

closeConfigBtn.MouseButton1Click:Connect(function()
    configGUI.Enabled = false
end)

-- Evento para repeticiones
if repeatInput then
    repeatInput.FocusLost:Connect(function()
        local num = tonumber(repeatInput.Text)
        if num and num >= 1 and num <= 100 then
            REPEAT_AMOUNT = math.floor(num)
            repeatInput.Text = tostring(REPEAT_AMOUNT)
            if repeatStatusLabel then
                repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x (solo golpes)"
                if damageRepeaterEnabled then
                    repeatStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
                else
                    repeatStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end
            if damageRepeaterEnabled then
                DisableDamageRepeater()
                EnableDamageRepeater()
            end
        else
            repeatInput.Text = tostring(REPEAT_AMOUNT)
        end
    end)
end

if walkSpeedBtn then
    walkSpeedBtn.MouseButton1Click:Connect(function()
        setWalkSpeedEnabled(not WalkSpeedEnabled)
        updateWalkSpeedButton()
    end)
end

if targetBox then
    targetBox.FocusLost:Connect(function(enter)
        if enter then searchAndToggleTarget() end
    end)
end

if clearTargetBtn then
    clearTargetBtn.MouseButton1Click:Connect(clearTargets)
end

if removeLastBtn then
    removeLastBtn.MouseButton1Click:Connect(removeLastTarget)
end

if closestBtn then
    closestBtn.MouseButton1Click:Connect(addClosestTarget)
end

-- Eventos de jugadores
Players.PlayerRemoving:Connect(function(p)
    local wasRemoved = false
    for i, target in ipairs(targetPlayers) do
        if target == p then
            table.remove(targetPlayers, i)
            exactTargetNames[p] = nil
            wasRemoved = true
            break
        end
    end
    if wasRemoved then
        updateTargetStatus()
        currentHitboxState[p] = nil
        if searchResult then
            searchResult.Text = "⚠️ " .. p.Name .. " salió del juego"
            searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
            task.wait(2)
            searchResult.Text = "Escribe nombre y presiona Enter"
            searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        if HitboxEnabled then
            updateHitboxesOptimized()
        end
    end
end)

Players.PlayerAdded:Connect(onPlayerAdded)

for _, p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(character)
        onCharacterAdded(p, character)
    end)
end

-- Teclas
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        if buttonsGUI then
            buttonsGUI.Enabled = not buttonsGUI.Enabled
        end
    elseif input.KeyCode == Enum.KeyCode.E then
        HitboxEnabled = not HitboxEnabled
        updateHitboxButton()
        updateHitboxesOptimized()
    elseif input.KeyCode == Enum.KeyCode.R then
        setTPWalkEnabled(not TPWalkEnabled)
        updateTPWalkButton()
    end
end)

-- Inicialización
updateTargetStatus()
updateHitboxButton()
updateTPWalkButton()
updateAntiRagdollButton()
updateWalkSpeedButton()
updateDamageRepeaterButton()
setWalkSpeed(16)
setTPSpeed(3)
setHitboxSize(30)
setHitboxTransparency(0.5)

print("=== HITBOX EXPANDER OPTIMIZADO ===")
print("✅ NO MÁS CRASHEOS - Hitbox optimizado sin loop constante")
print("✅ Los hitboxes solo se actualizan cuando es necesario")
print("✅ Sistema de estado para evitar cambios innecesarios")
print("✅ Damage Repeater solo repite golpes")
print("✅ Lista de prohibidos: " .. #PROHIBITED_USERS .. " usuarios")
print("✅ Teclas: K=Mostrar | E=Hitbox | R=TP Walk")
