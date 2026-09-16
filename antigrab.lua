--[[
    BOTÓN CAÑÓN - Anti-Ragdoll (arrastrable)
    - 1 toque = dispara el cañón
    - Alcance x3 (300 studs)
    - Detecta cooldown y usa el siguiente cañón
    - Tecla K para ocultar/mostrar
    - FIX respawn lejano: limpia el acumulador al respawnear
--]]

local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- =================== CONFIG ===================
local SEARCH_RANGE       = 300
local OCCUPIED_DIST      = 10
local COOLDOWN_FALLBACK  = 2.2

local COOLDOWN_NAME_HINTS = {
    "cooldown", "reload", "reloading", "canfire", "ready", "busy",
    "firing", "fired", "disabled", "lock", "locked", "used", "usetime",
    "lastfire", "nextfire", "timer",
}

-- =================== ESTADO ===================
local cooldownUntil = {}

-- =================== HELPERS ===================
local function getCannonPart(cannonModel)
    return cannonModel.PrimaryPart
        or cannonModel:FindFirstChild("Part")
        or cannonModel:FindFirstChildWhichIsA("BasePart")
end

local function nameMatchesCooldown(name)
    local lower = string.lower(name)
    for _, hint in ipairs(COOLDOWN_NAME_HINTS) do
        if string.find(lower, hint, 1, true) then
            return true
        end
    end
    return false
end

local function gameSaysOnCooldown(cannonModel)
    for attrName, attrVal in pairs(cannonModel:GetAttributes()) do
        if nameMatchesCooldown(attrName) then
            if type(attrVal) == "boolean" and attrVal == true then
                return true
            elseif type(attrVal) == "number" then
                if attrVal > os.clock() and (attrVal - os.clock()) < 30 then
                    return true
                end
            end
        end
    end

    for _, d in ipairs(cannonModel:GetDescendants()) do
        if d:IsA("BoolValue") and nameMatchesCooldown(d.Name) and d.Value == true then
            return true
        elseif d:IsA("NumberValue") and nameMatchesCooldown(d.Name) then
            if d.Value > os.clock() and (d.Value - os.clock()) < 30 then
                return true
            end
        elseif d:IsA("StringValue") and nameMatchesCooldown(d.Name) then
            local v = string.lower(tostring(d.Value))
            if v == "true" or v == "cooling" or v == "reloading" or v == "busy" then
                return true
            end
        end
    end

    local cds = cannonModel:GetDescendants()
    local hasCD = false
    for _, d in ipairs(cds) do
        if d:IsA("ClickDetector") then
            hasCD = true
            if d.MaxActivationDistance == 0 then
                return true
            end
        end
    end
    if not hasCD then
        return true
    end

    return false
end

local function isOnCooldown(cannonModel)
    local until_ = cooldownUntil[cannonModel]
    if until_ and os.clock() < until_ then
        return true
    end
    if gameSaysOnCooldown(cannonModel) then
        return true
    end
    return false
end

local function isCannonOccupiedByPlayer(cannonModel)
    local pp = getCannonPart(cannonModel)
    if not pp then return false end
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            local char = other.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local d = (char.HumanoidRootPart.Position - pp.Position).Magnitude
                if d <= OCCUPIED_DIST then
                    return true
                end
            end
        end
    end
    return false
end

-- =================== BUSCAR CAÑONES ===================
local function findCannonsInRange()
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return {} end
    local rootPart = character.HumanoidRootPart

    local list = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Cannon" then
            local pp = getCannonPart(obj)
            if pp and not obj:IsDescendantOf(character) then
                local d = (rootPart.Position - pp.Position).Magnitude
                if d <= SEARCH_RANGE then
                    table.insert(list, { model = obj, distance = d })
                end
            end
        end
    end
    table.sort(list, function(a, b) return a.distance < b.distance end)
    return list
end

-- =================== DISPARAR ===================
local function fireCannon()
    local cannons = findCannonsInRange()
    if #cannons == 0 then return false end

    for _, entry in ipairs(cannons) do
        local m = entry.model
        if not isOnCooldown(m) and not isCannonOccupiedByPlayer(m) then
            local cd = m:FindFirstChildWhichIsA("ClickDetector", true)
            if cd and cd.MaxActivationDistance > 0 then
                local ok = pcall(function()
                    fireclickdetector(cd)
                end)
                if ok then
                    cooldownUntil[m] = os.clock() + COOLDOWN_FALLBACK
                    return true
                end
            end
        end
    end

    for _, entry in ipairs(cannons) do
        local m = entry.model
        if not isCannonOccupiedByPlayer(m) then
            local cd = m:FindFirstChildWhichIsA("ClickDetector", true)
            if cd then
                local ok = pcall(function()
                    fireclickdetector(cd)
                end)
                if ok then
                    cooldownUntil[m] = os.clock() + COOLDOWN_FALLBACK
                    return true
                end
            end
        end
    end

    return false
end

-- =================== GUI ===================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CannonButtonGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "FireButton"
button.Size = UDim2.new(0, 60, 0, 60)
button.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
button.BorderSizePixel = 0
button.Text = "🔥"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 30
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = false
button.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = button

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(0, 0, 0)
stroke.Thickness = 2
stroke.Transparency = 0.5
stroke.Parent = button

local savedX = player:GetAttribute("CannonBtnX")
local savedY = player:GetAttribute("CannonBtnY")
local btnSize = 60
local viewportX = player:GetMouse().ViewSizeX or 800
local viewportY = player:GetMouse().ViewSizeY or 600
local defaultX = (viewportX - btnSize) / 2
local defaultY = (viewportY - btnSize) / 2

if type(savedX) == "number" and type(savedY) == "number" and savedX > 0 and savedY > 0 then
    button.Position = UDim2.new(0, savedX, 0, savedY)
else
    button.Position = UDim2.new(0, defaultX, 0, defaultY)
end

-- =================== ARRASTRE + TAP ===================
local dragging = false
local dragStart = nil
local startPos = nil
local clickStartPos = nil
local clickThreshold = 5
local guiVisible = true

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
        clickStartPos = input.Position
        button.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
    end
end)

button.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                     or input.UserInputType == Enum.UserInputType.Touch) then
        if dragStart and startPos then
            local delta = input.Position - dragStart
            local distanceMoved = math.abs(delta.X) + math.abs(delta.Y)
            if distanceMoved > clickThreshold then
                local newX = startPos.X.Offset + delta.X
                local newY = startPos.Y.Offset + delta.Y
                local viewX = player:GetMouse().ViewSizeX or 800
                local viewY = player:GetMouse().ViewSizeY or 600
                local maxX = viewX - button.AbsoluteSize.X
                local maxY = viewY - button.AbsoluteSize.Y
                newX = math.clamp(newX, 0, maxX)
                newY = math.clamp(newY, 0, maxY)
                button.Position = UDim2.new(0, newX, 0, newY)
                player:SetAttribute("CannonBtnX", newX)
                player:SetAttribute("CannonBtnY", newY)
            end
        end
    end
end)

button.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
       or input.UserInputType == Enum.UserInputType.Touch then

        local wasDrag = false
        if clickStartPos then
            local delta = input.Position - clickStartPos
            local distanceMoved = math.abs(delta.X) + math.abs(delta.Y)
            wasDrag = distanceMoved > clickThreshold
        end

        if not wasDrag then
            local ok = fireCannon()
            if ok then
                button.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
            else
                button.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            end
            task.delay(0.15, function()
                button.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
            end)
        else
            button.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
        end

        dragging = false
        clickStartPos = nil
    end
end)

-- =================== LIMPIEZA DE COOLDOWNS ===================
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    for model, t in pairs(cooldownUntil) do
        if now > t then
            cooldownUntil[model] = nil
        end
    end
end)

-- =================== TECLA K ===================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.K then
        guiVisible = not guiVisible
        button.Visible = guiVisible
    end
end)

print("🔥 Botón cañón listo. K para ocultar.")
