local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Variables principales
local HitboxEnabled = false
local AntiRagdollEnabled = false
local targetPlayer = nil
local exactTargetName = ""

-- ==================== LISTA DE PROHIBIDOS (DESDE GITHUB) ====================
local PROHIBITED_USERS = {}

-- Cargar lista desde GitHub
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

-- Cargar la lista
local listaExterna = cargarListaProhibidos()
if listaExterna and type(listaExterna) == "table" and #listaExterna > 0 then
    PROHIBITED_USERS = listaExterna
    print("✅ Lista de prohibidos cargada desde GitHub. Total: " .. #PROHIBITED_USERS .. " usuarios")
else
    PROHIBITED_USERS = {}
    print("⚠️ No se pudo cargar lista de prohibidos. Lista vacía.")
end

-- Función para verificar si un jugador está prohibido
local function isPlayerProhibited(playerObj)
    if not playerObj then return false end
    if playerObj == player then return false end
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

-- Variables para WalkSpeed
local WalkSpeedEnabled = false
local WalkSpeedValue = 16
local loopWalkSpeedConnection = nil

-- Variables para TP Walk
local TPWalkEnabled = false
local TPSpeedValue = 3
local tpWalkConnection = nil

-- ==================== DAMAGE REPEATER MEJORADO ====================
local REPEAT_AMOUNT = 26
local damageRepeaterEnabled = false
local MAX_REPEAT_DISTANCE = 30
local repeatedEvents = {} -- Para evitar bucles infinitos
local lastFireTime = {}

-- Nombres de eventos que SON golpes
local DAMAGE_EVENTS = {
    "Hit",
    "Damage", 
    "DealDamage",
    "TakeDamage",
    "MeleeHit",
    "Punch",
    "Kick",
    "Attack",
    "SwordHit",
    "Swing",
    "Strike",
    "Fire",
    "Shoot",
    "Explosion",
    "Blast"
}

-- Eventos a ignorar completamente
local IGNORED_EVENTS = {
    "SayMessageRequest",
    "MeleeUpdateEvent",
    "NinjaBombEvent",
    "BulletUpdateEvent",
    "UpdateAnimation",
    "SetAnimation",
    "MoveEvent",
    "JumpEvent",
    "SitEvent",
    "Emote",
    "Dance",
    "Pose",
    "AnimationEvent",
    "CharacterAdded",
    "HumanoidDescription",
    "LoadCharacter",
    "Respawn",
    "Teleport",
    "UpdateMotor6D",
    "SetMotor6D",
    "Ragdoll",
    "Fall"
}

-- Función para calcular distancia
local function getDistanceBetweenPlayers(player1, player2)
    if not player1 or not player2 then return math.huge end
    local char1 = player1.Character
    local char2 = player2.Character
    if not char1 or not char2 then return math.huge end
    local root1 = char1:FindFirstChild("HumanoidRootPart") or char1:FindFirstChild("Torso") or char1:FindFirstChild("UpperTorso")
    local root2 = char2:FindFirstChild("HumanoidRootPart") or char2:FindFirstChild("Torso") or char2:FindFirstChild("UpperTorso")
    if not root1 or not root2 then return math.huge end
    return (root1.Position - root2.Position).Magnitude
end

-- Función para obtener el jugador objetivo desde argumentos
local function getTargetPlayerFromArgs(...)
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if type(arg) == "string" then
            local target = Players:FindFirstChild(arg)
            if target and target ~= player then
                return target
            end
        elseif type(arg) == "table" and arg.Name then
            local target = Players:FindFirstChild(arg.Name)
            if target and target ~= player then
                return target
            end
        elseif type(arg) == "Instance" and arg:IsA("Player") and arg ~= player then
            return arg
        end
    end
    return nil
end

-- Función para verificar si es evento de daño
local function isDamageEvent(eventName)
    local lowerName = eventName:lower()
    for _, damageEvent in ipairs(DAMAGE_EVENTS) do
        if lowerName == damageEvent:lower() or lowerName:find(damageEvent:lower()) then
            return true
        end
    end
    return false
end

-- Función para verificar si es evento ignorado
local function isIgnoredEvent(eventName)
    local lowerName = eventName:lower()
    for _, ignoredEvent in ipairs(IGNORED_EVENTS) do
        if lowerName == ignoredEvent:lower() or lowerName:find(ignoredEvent:lower()) then
            return true
        end
    end
    return false
end

-- Función para repetir evento
local function repeatEvent(remote, ...)
    local targetPlayerObj = getTargetPlayerFromArgs(...)
    
    -- Verificar prohibidos
    if targetPlayerObj and isPlayerProhibited(targetPlayerObj) then
        return false
    end
    
    -- Verificar distancia
    if targetPlayerObj then
        local distance = getDistanceBetweenPlayers(player, targetPlayerObj)
        if distance > MAX_REPEAT_DISTANCE then
            return false
        end
    end
    
    -- Limitar repeticiones por segundo
    local now = tick()
    local remoteName = remote.Name
    local lastTime = lastFireTime[remoteName] or 0
    if now - lastTime < 0.05 then -- Máximo 20 repeticiones por segundo por remote
        return false
    end
    lastFireTime[remoteName] = now
    
    -- Repetir el daño
    for i = 1, REPEAT_AMOUNT do
        pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(...)
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(...)
            end
        end)
        if i % 10 == 0 then
            task.wait(0.01)
        end
    end
    
    return true
end

-- MÉTODO 1: Hookear remotas específicas
local hookedRemotes = {}
local function findAndHookDamageRemotes()
    local function hookRemote(remote)
        if hookedRemotes[remote] then return end
        if not remote:IsA("RemoteEvent") and not remote:IsA("RemoteFunction") then return end
        
        local remoteName = remote.Name
        if isIgnoredEvent(remoteName) then return end
        
        if isDamageEvent(remoteName) or remoteName:lower():find("damage") or remoteName:lower():find("hit") then
            hookedRemotes[remote] = true
            
            if remote:IsA("RemoteEvent") then
                local oldFire = remote.FireServer
                remote.FireServer = function(self, ...)
                    if damageRepeaterEnabled then
                        local success, err = pcall(function()
                            repeatEvent(self, ...)
                        end)
                        if not success then
                            -- Si falla, ejecutar normal
                            return oldFire(self, ...)
                        end
                        return
                    end
                    return oldFire(self, ...)
                end
            elseif remote:IsA("RemoteFunction") then
                local oldInvoke = remote.InvokeServer
                remote.InvokeServer = function(self, ...)
                    if damageRepeaterEnabled then
                        local success, err = pcall(function()
                            repeatEvent(self, ...)
                        end)
                        if not success then
                            return oldInvoke(self, ...)
                        end
                        return
                    end
                    return oldInvoke(self, ...)
                end
            end
            print("🔗 Remote hookeada: " .. remoteName)
        end
    end
    
    -- Buscar en ReplicatedStorage
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        hookRemote(remote)
    end
    
    -- Buscar en el jugador
    for _, remote in pairs(player.PlayerGui:GetDescendants()) do
        hookRemote(remote)
    end
    
    -- Buscar en Workspace
    for _, remote in pairs(Workspace:GetDescendants()) do
        hookRemote(remote)
    end
end

-- MÉTODO 2: Hookear el metatable (fallback)
local mt = nil
local oldNamecall = nil
local metatableHooked = false

local function hookMetatable()
    if metatableHooked then return end
    
    local success, result = pcall(function()
        mt = getrawmetatable(game)
        oldNamecall = mt.__namecall
        setreadonly(mt, false)
        
        mt.__namecall = function(self, ...)
            local method = getnamecallmethod()
            local name = self.Name
            
            if damageRepeaterEnabled and (method == "FireServer" or method == "InvokeServer") then
                if isDamageEvent(name) and not isIgnoredEvent(name) then
                    local targetObj = getTargetPlayerFromArgs(...)
                    
                    if targetObj and not isPlayerProhibited(targetObj) then
                        local distance = getDistanceBetweenPlayers(player, targetObj)
                        if distance <= MAX_REPEAT_DISTANCE then
                            -- Repetir
                            for i = 1, REPEAT_AMOUNT do
                                oldNamecall(self, ...)
                                if i % 10 == 0 then
                                    task.wait(0.005)
                                end
                            end
                            return
                        end
                    end
                end
            end
            
            return oldNamecall(self, ...)
        end
        
        metatableHooked = true
        return true
    end)
    
    return success
end

-- MÉTODO 3: Signal detection (para juegos que usan BindToClose)
local signalConnections = {}
local function hookSignals()
    local originalBindToClose = game.BindToClose
    game.BindToClose = function(func)
        if damageRepeaterEnabled then
            -- No interferir
        end
        return originalBindToClose(func)
    end
end

-- Activar/Desactivar repeater
local function enableDamageRepeater()
    if damageRepeaterEnabled then return end
    
    -- Intentar método 1: Hookear remotas específicas
    findAndHookDamageRemotes()
    
    -- Intentar método 2: Hookear metatable
    hookMetatable()
    
    damageRepeaterEnabled = true
    
    if damageRepeaterBtn then
        damageRepeaterBtn.Text = "REP\nON"
        damageRepeaterBtn.TextColor3 = Color3.fromRGB(80, 255, 80)
        damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(40, 70, 40)
    end
    if repeatStatusLabel then
        repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x (dist: " .. MAX_REPEAT_DISTANCE .. ")"
        repeatStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
    end
    
    print("✅ Damage Repeater ACTIVADO")
    print("   - " .. #hookedRemotes .. " remotas hookeadas")
    print("   - Metatable hookeado: " .. tostring(metatableHooked))
    print("   - Distancia máxima: " .. MAX_REPEAT_DISTANCE)
end

local function disableDamageRepeater()
    if not damageRepeaterEnabled then return end
    
    -- Restaurar metatable
    if mt and oldNamecall and metatableHooked then
        pcall(function()
            mt.__namecall = oldNamecall
            setreadonly(mt, true)
        end)
        metatableHooked = false
    end
    
    damageRepeaterEnabled = false
    
    if damageRepeaterBtn then
        damageRepeaterBtn.Text = "REP\nOFF"
        damageRepeaterBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    end
    if repeatStatusLabel then
        repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x"
        repeatStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
    
    print("❌ Damage Repeater DESACTIVADO")
end

local function toggleDamageRepeater()
    if damageRepeaterEnabled then
        disableDamageRepeater()
    else
        enableDamageRepeater()
    end
end

-- Función para cambiar repeticiones
local function setRepeatAmount(amount)
    REPEAT_AMOUNT = math.clamp(amount, 1, 100)
    if repeatInput then
        repeatInput.Text = tostring(REPEAT_AMOUNT)
    end
    if repeatStatusLabel then
        if damageRepeaterEnabled then
            repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x (dist: " .. MAX_REPEAT_DISTANCE .. ")"
        else
            repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x"
        end
    end
    print("📊 Repeticiones cambiadas a: " .. REPEAT_AMOUNT)
end

-- Función para cambiar distancia
local function setRepeaterDistance(distance)
    MAX_REPEAT_DISTANCE = math.clamp(distance, 1, 500)
    if distanceInput then
        distanceInput.Text = tostring(MAX_REPEAT_DISTANCE)
    end
    if repeatDistanceLabel then
        repeatDistanceLabel.Text = "Distancia máx: " .. MAX_REPEAT_DISTANCE
    end
    if damageRepeaterEnabled and repeatStatusLabel then
        repeatStatusLabel.Text = "Repetir: " .. REPEAT_AMOUNT .. "x (dist: " .. MAX_REPEAT_DISTANCE .. ")"
    end
    print("📏 Distancia máxima cambiada a: " .. MAX_REPEAT_DISTANCE)
end

-- Escuchar nuevas remotas que se añadan
ReplicatedStorage.ChildAdded:Connect(function(child)
    task.wait(0.5)
    if damageRepeaterEnabled then
        findAndHookDamageRemotes()
    end
end)

player.PlayerGui.ChildAdded:Connect(function(child)
    task.wait(0.5)
    if damageRepeaterEnabled then
        findAndHookDamageRemotes()
    end
end)

-- ==================== ANTI-RAGDOLL ====================
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

-- ==================== HITBOX ====================
local function resetHitbox(target)
    pcall(function()
        if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = target.Character.HumanoidRootPart
            rootPart.Size = Vector3.new(2, 2, 1)
            rootPart.Transparency = 1
            rootPart.Material = Enum.Material.Plastic
            rootPart.Color = Color3.fromRGB(255, 255, 255)
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
            rootPart.Size = Vector3.new(HITBOX_SIZE, HITBOX_SIZE, HITBOX_SIZE)
            rootPart.Transparency = HITBOX_TRANSPARENCY
            rootPart.Color = HITBOX_COLOR
            rootPart.Material = Enum.Material.SmoothPlastic
            rootPart.CanCollide = false
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

local function updateHitboxes()
    if not HitboxEnabled then
        resetAllHitboxes()
        return
    end
    
    if targetPlayer then
        if shouldHitPlayer(targetPlayer) then
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= player and v ~= targetPlayer and not isPlayerProhibited(v) then
                    resetHitbox(v)
                end
            end
            applyHitboxToPlayer(targetPlayer)
        else
            resetHitbox(targetPlayer)
        end
    else
        for _, v in pairs(Players:GetPlayers()) do
            if shouldHitPlayer(v) then
                applyHitboxToPlayer(v)
            else
                resetHitbox(v)
            end
        end
    end
end

local function setHitboxSize(value)
    HITBOX_SIZE = tonumber(value)
    if hitboxSizeLabel then
        hitboxSizeLabel.Text = "Tamaño: " .. HITBOX_SIZE
    end
    if HitboxEnabled then
        updateHitboxes()
    end
end

local function setHitboxTransparency(value)
    HITBOX_TRANSPARENCY = tonumber(value)
    if hitboxTransparencyLabel then
        hitboxTransparencyLabel.Text = "Transparencia: " .. HITBOX_TRANSPARENCY
    end
    if HitboxEnabled then
        updateHitboxes()
    end
end

-- Funciones de movimiento
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

-- Funciones para TP Walk
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

-- ==================== INTERFAZ ====================
local function CreateButtonsInterface()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ButtonsGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player.PlayerGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 320, 0, 85)
    Frame.Position = UDim2.new(0.5, -160, 0.02, 0)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Frame.BackgroundTransparency = 0.05
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 100, 255)
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = 0.5
    UIStroke.Parent = Frame

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    TopBar.Position = UDim2.new(0, 0, 0, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    TopBar.BackgroundTransparency = 0.2
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Frame

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 12)
    TopBarCorner.Parent = TopBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.6, 0, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⋮⋮  PANEL DE CONTROL  ⋮⋮"
    Title.TextColor3 = Color3.fromRGB(200, 200, 255)
    Title.TextSize = 11
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    local ConfigButton = Instance.new("TextButton")
    ConfigButton.Size = UDim2.new(0, 35, 0, 30)
    ConfigButton.Position = UDim2.new(1, -42, 0, 2.5)
    ConfigButton.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
    ConfigButton.Text = "⚙️"
    ConfigButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ConfigButton.Font = Enum.Font.GothamBold
    ConfigButton.TextSize = 16
    ConfigButton.Parent = TopBar

    local configCorner = Instance.new("UICorner")
    configCorner.CornerRadius = UDim.new(0, 6)
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
    hitboxBtn.TextSize = 11
    hitboxBtn.TextWrapped = true
    hitboxBtn.Parent = ButtonsContainer

    local hitboxCorner = Instance.new("UICorner")
    hitboxCorner.CornerRadius = UDim.new(0, 8)
    hitboxCorner.Parent = hitboxBtn

    tpWalkBtn = Instance.new("TextButton")
    tpWalkBtn.Size = UDim2.new(0.24, 0, 1, 0)
    tpWalkBtn.Position = UDim2.new(0.25, 0, 0, 0)
    tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tpWalkBtn.Text = "TP\nOFF"
    tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    tpWalkBtn.Font = Enum.Font.GothamBold
    tpWalkBtn.TextSize = 11
    tpWalkBtn.TextWrapped = true
    tpWalkBtn.Parent = ButtonsContainer

    local tpWalkCorner = Instance.new("UICorner")
    tpWalkCorner.CornerRadius = UDim.new(0, 8)
    tpWalkCorner.Parent = tpWalkBtn

    antiRagdollBtn = Instance.new("TextButton")
    antiRagdollBtn.Size = UDim2.new(0.24, 0, 1, 0)
    antiRagdollBtn.Position = UDim2.new(0.5, 0, 0, 0)
    antiRagdollBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    antiRagdollBtn.Text = "RAG\nOFF"
    antiRagdollBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    antiRagdollBtn.Font = Enum.Font.GothamBold
    antiRagdollBtn.TextSize = 11
    antiRagdollBtn.TextWrapped = true
    antiRagdollBtn.Parent = ButtonsContainer

    local antiRagdollCorner = Instance.new("UICorner")
    antiRagdollCorner.CornerRadius = UDim.new(0, 8)
    antiRagdollCorner.Parent = antiRagdollBtn

    damageRepeaterBtn = Instance.new("TextButton")
    damageRepeaterBtn.Size = UDim2.new(0.24, 0, 1, 0)
    damageRepeaterBtn.Position = UDim2.new(0.75, 0, 0, 0)
    damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    damageRepeaterBtn.Text = "REP\nOFF"
    damageRepeaterBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    damageRepeaterBtn.Font = Enum.Font.GothamBold
    damageRepeaterBtn.TextSize = 11
    damageRepeaterBtn.TextWrapped = true
    damageRepeaterBtn.Parent = ButtonsContainer

    local damageRepeaterCorner = Instance.new("UICorner")
    damageRepeaterCorner.CornerRadius = UDim.new(0, 8)
    damageRepeaterCorner.Parent = damageRepeaterBtn

    MakeDraggableWithHandle(Frame, TopBar)

    return ScreenGui, Frame, ConfigButton
end

local function CreateConfigInterface()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ConfigGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Enabled = false
    ScreenGui.Parent = player.PlayerGui
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 260, 0, 400)
    Frame.Position = UDim2.new(0.5, -130, 0.5, -200)
    Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Frame.BorderSizePixel = 0
    Frame.ClipsDescendants = true
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 12)
    UICorner.Parent = Frame

    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(100, 100, 255)
    UIStroke.Thickness = 1.5
    UIStroke.Transparency = 0.5
    UIStroke.Parent = Frame

    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    TitleBar.BackgroundTransparency = 0.1
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Frame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⋮⋮ CONFIGURACIÓN ⋮⋮"
    Title.TextColor3 = Color3.fromRGB(255, 200, 100)
    Title.TextSize = 11
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -34, 0, 3.5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 16
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn

    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, 0, 1, -35)
    Content.Position = UDim2.new(0, 0, 0, 35)
    Content.BackgroundTransparency = 1
    Content.ScrollBarThickness = 4
    Content.CanvasSize = UDim2.new(0, 0, 0, 500)
    Content.Parent = Frame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.Parent = Content

    -- Sección HITBOX
    local hitboxTitle = Instance.new("TextLabel")
    hitboxTitle.Size = UDim2.new(0.9, 0, 0, 20)
    hitboxTitle.BackgroundTransparency = 1
    hitboxTitle.Text = "⚔️ HITBOX"
    hitboxTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    hitboxTitle.Font = Enum.Font.GothamBold
    hitboxTitle.TextSize = 11
    hitboxTitle.TextXAlignment = Enum.TextXAlignment.Left
    hitboxTitle.Parent = Content

    local sizeContainer = Instance.new("Frame")
    sizeContainer.Size = UDim2.new(0.9, 0, 0, 30)
    sizeContainer.BackgroundTransparency = 1
    sizeContainer.Parent = Content
    
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Size = UDim2.new(0.4, 0, 1, 0)
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.Text = "Tamaño hitbox:"
    sizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sizeLabel.Font = Enum.Font.Gotham
    sizeLabel.TextSize = 10
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    sizeLabel.Parent = sizeContainer

    local hitboxSizeInput = Instance.new("TextBox")
    hitboxSizeInput.Size = UDim2.new(0.5, 0, 1, 0)
    hitboxSizeInput.Position = UDim2.new(0.48, 0, 0, 0)
    hitboxSizeInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hitboxSizeInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    hitboxSizeInput.Font = Enum.Font.Gotham
    hitboxSizeInput.TextSize = 10
    hitboxSizeInput.Text = "30"
    hitboxSizeInput.Parent = sizeContainer

    local sizeCorner = Instance.new("UICorner")
    sizeCorner.CornerRadius = UDim.new(0, 5)
    sizeCorner.Parent = hitboxSizeInput

    hitboxSizeLabel = Instance.new("TextLabel")
    hitboxSizeLabel.Size = UDim2.new(0.9, 0, 0, 20)
    hitboxSizeLabel.BackgroundTransparency = 1
    hitboxSizeLabel.Text = "Tamaño actual: 30"
    hitboxSizeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    hitboxSizeLabel.Font = Enum.Font.Gotham
    hitboxSizeLabel.TextSize = 9
    hitboxSizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    hitboxSizeLabel.Parent = Content

    local transContainer = Instance.new("Frame")
    transContainer.Size = UDim2.new(0.9, 0, 0, 30)
    transContainer.BackgroundTransparency = 1
    transContainer.Parent = Content
    
    local transLabel = Instance.new("TextLabel")
    transLabel.Size = UDim2.new(0.4, 0, 1, 0)
    transLabel.BackgroundTransparency = 1
    transLabel.Text = "Transparencia:"
    transLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    transLabel.Font = Enum.Font.Gotham
    transLabel.TextSize = 10
    transLabel.TextXAlignment = Enum.TextXAlignment.Left
    transLabel.Parent = transContainer

    local hitboxTransparencyInput = Instance.new("TextBox")
    hitboxTransparencyInput.Size = UDim2.new(0.5, 0, 1, 0)
    hitboxTransparencyInput.Position = UDim2.new(0.48, 0, 0, 0)
    hitboxTransparencyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    hitboxTransparencyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    hitboxTransparencyInput.Font = Enum.Font.Gotham
    hitboxTransparencyInput.TextSize = 10
    hitboxTransparencyInput.Text = "0.5"
    hitboxTransparencyInput.Parent = transContainer

    local transCorner = Instance.new("UICorner")
    transCorner.CornerRadius = UDim.new(0, 5)
    transCorner.Parent = hitboxTransparencyInput

    hitboxTransparencyLabel = Instance.new("TextLabel")
    hitboxTransparencyLabel.Size = UDim2.new(0.9, 0, 0, 20)
    hitboxTransparencyLabel.BackgroundTransparency = 1
    hitboxTransparencyLabel.Text = "Transparencia actual: 0.5"
    hitboxTransparencyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    hitboxTransparencyLabel.Font = Enum.Font.Gotham
    hitboxTransparencyLabel.TextSize = 9
    hitboxTransparencyLabel.TextXAlignment = Enum.TextXAlignment.Left
    hitboxTransparencyLabel.Parent = Content

    -- Separador
    local sep1 = Instance.new("Frame")
    sep1.Size = UDim2.new(0.9, 0, 0, 1)
    sep1.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep1.Parent = Content

    -- Sección WALKSPEED
    local wsTitle = Instance.new("TextLabel")
    wsTitle.Size = UDim2.new(0.9, 0, 0, 20)
    wsTitle.BackgroundTransparency = 1
    wsTitle.Text = "🏃 LOOP WALKSPEED"
    wsTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    wsTitle.Font = Enum.Font.GothamBold
    wsTitle.TextSize = 11
    wsTitle.TextXAlignment = Enum.TextXAlignment.Left
    wsTitle.Parent = Content

    local wsContainer = Instance.new("Frame")
    wsContainer.Size = UDim2.new(0.9, 0, 0, 35)
    wsContainer.BackgroundTransparency = 1
    wsContainer.Parent = Content

    walkSpeedBtn = Instance.new("TextButton")
    walkSpeedBtn.Size = UDim2.new(0.35, 0, 1, 0)
    walkSpeedBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    walkSpeedBtn.Text = "LOOP\nOFF"
    walkSpeedBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    walkSpeedBtn.Font = Enum.Font.GothamBold
    walkSpeedBtn.TextSize = 9
    walkSpeedBtn.TextWrapped = true
    walkSpeedBtn.Parent = wsContainer

    local wsBtnCorner = Instance.new("UICorner")
    wsBtnCorner.CornerRadius = UDim.new(0, 6)
    wsBtnCorner.Parent = walkSpeedBtn

    local walkSpeedInput = Instance.new("TextBox")
    walkSpeedInput.Size = UDim2.new(0.55, 0, 1, 0)
    walkSpeedInput.Position = UDim2.new(0.38, 0, 0, 0)
    walkSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    walkSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    walkSpeedInput.Font = Enum.Font.Gotham
    walkSpeedInput.TextSize = 10
    walkSpeedInput.Text = "16"
    walkSpeedInput.Parent = wsContainer

    local wsInputCorner = Instance.new("UICorner")
    wsInputCorner.CornerRadius = UDim.new(0, 5)
    wsInputCorner.Parent = walkSpeedInput

    walkSpeedValueLabel = Instance.new("TextLabel")
    walkSpeedValueLabel.Size = UDim2.new(0.9, 0, 0, 20)
    walkSpeedValueLabel.BackgroundTransparency = 1
    walkSpeedValueLabel.Text = "Velocidad actual: 16"
    walkSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    walkSpeedValueLabel.Font = Enum.Font.Gotham
    walkSpeedValueLabel.TextSize = 9
    walkSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    walkSpeedValueLabel.Parent = Content

    -- Separador
    local sep2 = Instance.new("Frame")
    sep2.Size = UDim2.new(0.9, 0, 0, 1)
    sep2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep2.Parent = Content

    -- Sección TP WALK
    local tpTitle = Instance.new("TextLabel")
    tpTitle.Size = UDim2.new(0.9, 0, 0, 20)
    tpTitle.BackgroundTransparency = 1
    tpTitle.Text = "✨ TP WALK"
    tpTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    tpTitle.Font = Enum.Font.GothamBold
    tpTitle.TextSize = 11
    tpTitle.TextXAlignment = Enum.TextXAlignment.Left
    tpTitle.Parent = Content

    local tpContainer = Instance.new("Frame")
    tpContainer.Size = UDim2.new(0.9, 0, 0, 35)
    tpContainer.BackgroundTransparency = 1
    tpContainer.Parent = Content

    tpWalkBtn = Instance.new("TextButton")
    tpWalkBtn.Size = UDim2.new(0.35, 0, 1, 0)
    tpWalkBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tpWalkBtn.Text = "TP\nOFF"
    tpWalkBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    tpWalkBtn.Font = Enum.Font.GothamBold
    tpWalkBtn.TextSize = 9
    tpWalkBtn.TextWrapped = true
    tpWalkBtn.Parent = tpContainer

    local tpBtnCorner = Instance.new("UICorner")
    tpBtnCorner.CornerRadius = UDim.new(0, 6)
    tpBtnCorner.Parent = tpWalkBtn

    local tpSpeedInput = Instance.new("TextBox")
    tpSpeedInput.Size = UDim2.new(0.55, 0, 1, 0)
    tpSpeedInput.Position = UDim2.new(0.38, 0, 0, 0)
    tpSpeedInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    tpSpeedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpSpeedInput.Font = Enum.Font.Gotham
    tpSpeedInput.TextSize = 10
    tpSpeedInput.Text = "3"
    tpSpeedInput.Parent = tpContainer

    local tpInputCorner = Instance.new("UICorner")
    tpInputCorner.CornerRadius = UDim.new(0, 5)
    tpInputCorner.Parent = tpSpeedInput

    tpSpeedValueLabel = Instance.new("TextLabel")
    tpSpeedValueLabel.Size = UDim2.new(0.9, 0, 0, 20)
    tpSpeedValueLabel.BackgroundTransparency = 1
    tpSpeedValueLabel.Text = "Velocidad TP: 3"
    tpSpeedValueLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    tpSpeedValueLabel.Font = Enum.Font.Gotham
    tpSpeedValueLabel.TextSize = 9
    tpSpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Left
    tpSpeedValueLabel.Parent = Content

    -- Separador
    local sep3 = Instance.new("Frame")
    sep3.Size = UDim2.new(0.9, 0, 0, 1)
    sep3.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep3.Parent = Content

    -- Sección DAMAGE REPEATER
    local repeaterTitle = Instance.new("TextLabel")
    repeaterTitle.Size = UDim2.new(0.9, 0, 0, 20)
    repeaterTitle.BackgroundTransparency = 1
    repeaterTitle.Text = "💥 DAMAGE REPEATER"
    repeaterTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    repeaterTitle.Font = Enum.Font.GothamBold
    repeaterTitle.TextSize = 11
    repeaterTitle.TextXAlignment = Enum.TextXAlignment.Left
    repeaterTitle.Parent = Content

    local repeatContainer = Instance.new("Frame")
    repeatContainer.Size = UDim2.new(0.9, 0, 0, 35)
    repeatContainer.BackgroundTransparency = 1
    repeatContainer.Parent = Content

    local repeatLabel = Instance.new("TextLabel")
    repeatLabel.Size = UDim2.new(0.35, 0, 1, 0)
    repeatLabel.BackgroundTransparency = 1
    repeatLabel.Text = "Repeticiones:"
    repeatLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    repeatLabel.Font = Enum.Font.Gotham
    repeatLabel.TextSize = 10
    repeatLabel.TextXAlignment = Enum.TextXAlignment.Left
    repeatLabel.Parent = repeatContainer

    repeatInput = Instance.new("TextBox")
    repeatInput.Size = UDim2.new(0.55, 0, 1, 0)
    repeatInput.Position = UDim2.new(0.43, 0, 0, 0)
    repeatInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    repeatInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    repeatInput.Font = Enum.Font.Gotham
    repeatInput.TextSize = 10
    repeatInput.Text = tostring(REPEAT_AMOUNT)
    repeatInput.Parent = repeatContainer

    local repeatCorner = Instance.new("UICorner")
    repeatCorner.CornerRadius = UDim.new(0, 5)
    repeatCorner.Parent = repeatInput

    local distanceContainer = Instance.new("Frame")
    distanceContainer.Size = UDim2.new(0.9, 0, 0, 35)
    distanceContainer.BackgroundTransparency = 1
    distanceContainer.Parent = Content

    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(0.35, 0, 1, 0)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "Distancia máx:"
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.Font = Enum.Font.Gotham
    distanceLabel.TextSize = 10
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    distanceLabel.Parent = distanceContainer

    distanceInput = Instance.new("TextBox")
    distanceInput.Size = UDim2.new(0.55, 0, 1, 0)
    distanceInput.Position = UDim2.new(0.43, 0, 0, 0)
    distanceInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    distanceInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    distanceInput.Font = Enum.Font.Gotham
    distanceInput.TextSize = 10
    distanceInput.Text = tostring(MAX_REPEAT_DISTANCE)
    distanceInput.Parent = distanceContainer

    local distanceCorner = Instance.new("UICorner")
    distanceCorner.CornerRadius = UDim.new(0, 5)
    distanceCorner.Parent = distanceInput

    repeatDistanceLabel = Instance.new("TextLabel")
    repeatDistanceLabel.Size = UDim2.new(0.9, 0, 0, 20)
    repeatDistanceLabel.BackgroundTransparency = 1
    repeatDistanceLabel.Text = "Distancia actual: " .. MAX_REPEAT_DISTANCE
    repeatDistanceLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    repeatDistanceLabel.Font = Enum.Font.Gotham
    repeatDistanceLabel.TextSize = 9
    repeatDistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    repeatDistanceLabel.Parent = Content

    repeatStatusLabel = Instance.new("TextLabel")
    repeatStatusLabel.Size = UDim2.new(0.9, 0, 0, 20)
    repeatStatusLabel.BackgroundTransparency = 1
    repeatStatusLabel.Text = "Estado: OFF"
    repeatStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    repeatStatusLabel.Font = Enum.Font.Gotham
    repeatStatusLabel.TextSize = 9
    repeatStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    repeatStatusLabel.Parent = Content

    -- Separador
    local sep4 = Instance.new("Frame")
    sep4.Size = UDim2.new(0.9, 0, 0, 1)
    sep4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sep4.Parent = Content

    -- Sección TARGET
    local targetTitle = Instance.new("TextLabel")
    targetTitle.Size = UDim2.new(0.9, 0, 0, 20)
    targetTitle.BackgroundTransparency = 1
    targetTitle.Text = "🎯 TARGET"
    targetTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
    targetTitle.Font = Enum.Font.GothamBold
    targetTitle.TextSize = 11
    targetTitle.TextXAlignment = Enum.TextXAlignment.Left
    targetTitle.Parent = Content

    targetBox = Instance.new("TextBox")
    targetBox.Size = UDim2.new(0.9, 0, 0, 35)
    targetBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    targetBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    targetBox.Font = Enum.Font.Gotham
    targetBox.TextSize = 10
    targetBox.PlaceholderText = "Nombre del jugador (3+ letras)"
    targetBox.Text = ""
    targetBox.Parent = Content

    local targetCorner = Instance.new("UICorner")
    targetCorner.CornerRadius = UDim.new(0, 5)
    targetCorner.Parent = targetBox

    targetStatus = Instance.new("TextLabel")
    targetStatus.Size = UDim2.new(0.9, 0, 0, 20)
    targetStatus.BackgroundTransparency = 1
    targetStatus.Text = "Objetivo: TODOS"
    targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    targetStatus.Font = Enum.Font.Gotham
    targetStatus.TextSize = 9
    targetStatus.TextXAlignment = Enum.TextXAlignment.Left
    targetStatus.Parent = Content

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(0.9, 0, 0, 35)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = Content

    clearTargetBtn = Instance.new("TextButton")
    clearTargetBtn.Size = UDim2.new(0.48, 0, 1, 0)
    clearTargetBtn.BackgroundColor3 = Color3.fromRGB(180, 70, 70)
    clearTargetBtn.Text = "Limpiar"
    clearTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearTargetBtn.Font = Enum.Font.GothamBold
    clearTargetBtn.TextSize = 10
    clearTargetBtn.Parent = btnContainer

    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 5)
    clearCorner.Parent = clearTargetBtn

    closestBtn = Instance.new("TextButton")
    closestBtn.Size = UDim2.new(0.48, 0, 1, 0)
    closestBtn.Position = UDim2.new(0.52, 0, 0, 0)
    closestBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
    closestBtn.Text = "Más Cercano"
    closestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closestBtn.Font = Enum.Font.GothamBold
    closestBtn.TextSize = 10
    closestBtn.Parent = btnContainer

    local closestCorner = Instance.new("UICorner")
    closestCorner.CornerRadius = UDim.new(0, 5)
    closestCorner.Parent = closestBtn

    searchResult = Instance.new("TextLabel")
    searchResult.Size = UDim2.new(0.9, 0, 0, 20)
    searchResult.BackgroundTransparency = 1
    searchResult.Text = "Presiona Enter para buscar"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    searchResult.Font = Enum.Font.Gotham
    searchResult.TextSize = 9
    searchResult.TextXAlignment = Enum.TextXAlignment.Left
    searchResult.Parent = Content

    -- Info
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Size = UDim2.new(0.9, 0, 0, 20)
    infoLabel.BackgroundTransparency = 1
    infoLabel.Text = "K=Mostrar | E=Hitbox | R=TP Walk"
    infoLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    infoLabel.Font = Enum.Font.Gotham
    infoLabel.TextSize = 9
    infoLabel.TextXAlignment = Enum.TextXAlignment.Center
    infoLabel.Parent = Content

    -- Eventos de inputs
    hitboxSizeInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(hitboxSizeInput.Text)
            if val and val >= 0.1 and val <= 100 then
                setHitboxSize(val)
                hitboxSizeLabel.Text = "Tamaño actual: " .. val
                searchResult.Text = "✓ Tamaño cambiado a " .. val
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                hitboxSizeInput.Text = tostring(HITBOX_SIZE)
                searchResult.Text = "✗ Tamaño inválido (0.1-100)"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    hitboxTransparencyInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(hitboxTransparencyInput.Text)
            if val and val >= 0 and val <= 1 then
                setHitboxTransparency(val)
                hitboxTransparencyLabel.Text = "Transparencia actual: " .. val
                searchResult.Text = "✓ Transparencia cambiada a " .. val
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                hitboxTransparencyInput.Text = tostring(HITBOX_TRANSPARENCY)
                searchResult.Text = "✗ Transparencia inválida (0-1)"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    walkSpeedInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(walkSpeedInput.Text)
            if val and val >= 0.1 and val <= 500 then
                setWalkSpeed(val)
                walkSpeedValueLabel.Text = "Velocidad actual: " .. string.format("%.2f", val)
                searchResult.Text = "✓ Velocidad cambiada a " .. val
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                walkSpeedInput.Text = tostring(WalkSpeedValue)
                searchResult.Text = "✗ Velocidad inválida (0.1-500)"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    tpSpeedInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(tpSpeedInput.Text)
            if val and val >= 0.01 and val <= 50 then
                setTPSpeed(val)
                tpSpeedValueLabel.Text = "Velocidad TP: " .. string.format("%.2f", val)
                searchResult.Text = "✓ Vel TP cambiada a " .. val
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                tpSpeedInput.Text = tostring(TPSpeedValue)
                searchResult.Text = "✗ Vel TP inválida (0.01-50)"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    repeatInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(repeatInput.Text)
            if val and val >= 1 and val <= 100 then
                setRepeatAmount(val)
                searchResult.Text = "✓ Repeticiones cambiadas a " .. val
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                repeatInput.Text = tostring(REPEAT_AMOUNT)
                searchResult.Text = "✗ Repeticiones inválidas (1-100)"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    distanceInput.FocusLost:Connect(function(enter)
        if enter then
            local val = tonumber(distanceInput.Text)
            if val and val >= 1 and val <= 500 then
                setRepeaterDistance(val)
                repeatDistanceLabel.Text = "Distancia actual: " .. val
                searchResult.Text = "✓ Distancia cambiada a " .. val
                searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
                task.wait(1.5)
                searchResult.Text = "Presiona Enter para buscar"
                searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
            else
                distanceInput.Text = tostring(MAX_REPEAT_DISTANCE)
                searchResult.Text = "✗ Distancia inválida (1-500)"
                searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
                task.wait(2)
                searchResult.Text = "Presiona Enter para buscar"
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
        repeatStatusLabel.Text = "Estado: ACTIVADO (dist: " .. MAX_REPEAT_DISTANCE .. ")"
        repeatStatusLabel.TextColor3 = Color3.fromRGB(80, 255, 80)
    else
        damageRepeaterBtn.Text = "REP\nOFF"
        damageRepeaterBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        damageRepeaterBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        repeatStatusLabel.Text = "Estado: DESACTIVADO"
        repeatStatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function updateTargetStatus()
    if targetPlayer then
        targetStatus.Text = "Objetivo: " .. exactTargetName
        targetStatus.TextColor3 = Color3.fromRGB(80, 255, 80)
        targetBox.Text = exactTargetName
    else
        targetStatus.Text = "Objetivo: TODOS"
        targetStatus.TextColor3 = Color3.fromRGB(120, 200, 255)
    end
end

local function searchAndSetTarget()
    local searchText = targetBox.Text:gsub("%s+", "")
    local foundPlayer, resultName = findPlayerByPartialName(searchText)
    if foundPlayer then
        targetPlayer = foundPlayer
        exactTargetName = resultName
        updateTargetStatus()
        searchResult.Text = "✓ Encontrado: " .. exactTargetName
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
        if HitboxEnabled then
            updateHitboxes()
        end
    elseif foundPlayer == nil then
        targetPlayer = nil
        exactTargetName = "TODOS"
        updateTargetStatus()
        searchResult.Text = "✓ Modo: TODOS"
        searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
        if HitboxEnabled then
            updateHitboxes()
        end
    else
        searchResult.Text = resultName
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
    task.wait(2)
    if searchResult.Text:sub(1,1) == "✓" or searchResult.Text:find("no encontrado") or searchResult.Text:find("Mínimo") then
        searchResult.Text = "Presiona Enter para buscar"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function targetClosest()
    local closestDistance = math.huge
    local closestPlayer = nil
    local myChar = player.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar:FindFirstChild("UpperTorso"))
    
    if not myRoot then
        searchResult.Text = "✗ No se puede calcular distancia"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(2)
        searchResult.Text = "Presiona Enter para buscar"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
        return
    end
    
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and not isPlayerProhibited(v) then
            pcall(function()
                local char = v.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
                    if root then
                        local distance = (root.Position - myRoot.Position).Magnitude
                        if distance < closestDistance then
                            closestDistance = distance
                            closestPlayer = v
                        end
                    end
                end
            end)
        end
    end
    
    if closestPlayer then
        targetPlayer = closestPlayer
        exactTargetName = closestPlayer.DisplayName .. " (" .. closestPlayer.Name .. ")"
        updateTargetStatus()
        targetBox.Text = closestPlayer.Name
        searchResult.Text = "✓ Target: " .. exactTargetName .. " (dist: " .. math.floor(closestDistance) .. ")"
        searchResult.TextColor3 = Color3.fromRGB(80, 255, 80)
        if HitboxEnabled then
            updateHitboxes()
        end
        task.wait(2)
        searchResult.Text = "Presiona Enter para buscar"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    else
        searchResult.Text = "✗ No hay jugadores cercanos"
        searchResult.TextColor3 = Color3.fromRGB(255, 80, 80)
        task.wait(2)
        searchResult.Text = "Presiona Enter para buscar"
        searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

local function clearTarget()
    targetPlayer = nil
    exactTargetName = "TODOS"
    targetBox.Text = ""
    updateTargetStatus()
    searchResult.Text = "✓ Target limpiado"
    searchResult.TextColor3 = Color3.fromRGB(120, 200, 255)
    if HitboxEnabled then
        updateHitboxes()
    end
    task.wait(2)
    searchResult.Text = "Presiona Enter para buscar"
    searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
end

-- Crear interfaces
local buttonsGUI, buttonsFrame, configButton = CreateButtonsInterface()
local configGUI, configFrame, closeConfigBtn = CreateConfigInterface()

-- Conectar eventos
hitboxBtn.MouseButton1Click:Connect(function()
    HitboxEnabled = not HitboxEnabled
    updateHitboxButton()
    if HitboxEnabled then
        updateHitboxes()
    else
        resetAllHitboxes()
    end
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

if walkSpeedBtn then
    walkSpeedBtn.MouseButton1Click:Connect(function()
        setWalkSpeedEnabled(not WalkSpeedEnabled)
        updateWalkSpeedButton()
    end)
end

if targetBox then
    targetBox.FocusLost:Connect(function(enter)
        if enter then searchAndSetTarget() end
    end)
end

if clearTargetBtn then
    clearTargetBtn.MouseButton1Click:Connect(clearTarget)
end

if closestBtn then
    closestBtn.MouseButton1Click:Connect(targetClosest)
end

-- Eventos de jugadores
Players.PlayerRemoving:Connect(function(p)
    if targetPlayer == p then
        targetPlayer = nil
        exactTargetName = "TODOS"
        if targetBox then targetBox.Text = "" end
        updateTargetStatus()
        if searchResult then
            searchResult.Text = "⚠️ Objetivo salió del juego"
            searchResult.TextColor3 = Color3.fromRGB(255, 150, 50)
            task.wait(2)
            searchResult.Text = "Presiona Enter para buscar"
            searchResult.TextColor3 = Color3.fromRGB(150, 150, 150)
        end
        if HitboxEnabled then
            updateHitboxes()
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    task.wait(1)
    if HitboxEnabled and shouldHitPlayer(p) then
        applyHitboxToPlayer(p)
    end
end)

for _, p in pairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        if HitboxEnabled and shouldHitPlayer(p) then
            applyHitboxToPlayer(p)
        end
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
        if HitboxEnabled then
            updateHitboxes()
        else
            resetAllHitboxes()
        end
    elseif input.KeyCode == Enum.KeyCode.R then
        setTPWalkEnabled(not TPWalkEnabled)
        updateTPWalkButton()
    end
end)

-- Loop principal del hitbox
hitboxConnection = RunService.Heartbeat:Connect(updateHitboxes)

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

print("=== HITBOX EXPANDER + DAMAGE REPEATER MEJORADO ===")
print("✅ Damage Repeater usa MÚLTIPLES métodos de hookeo")
print("✅ Distancia máxima: " .. MAX_REPEAT_DISTANCE .. " studs")
print("✅ Los jugadores prohibidos NO son afectados")
print("✅ Repeticiones: " .. REPEAT_AMOUNT .. "x")
print("✅ Teclas: K=Mostrar | E=Hitbox | R=TP Walk")
