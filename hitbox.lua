local HitboxV2 = Instance.new("ScreenGui")
HitboxV2.Name = "HitboxV2"
HitboxV2.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
HitboxV2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
HitboxV2.ResetOnSpawn = false

-- Botón flotante para mostrar/ocultar la interfaz principal
local ToggleGuiButton = Instance.new("TextButton")
ToggleGuiButton.Name = "ToggleGuiButton"
ToggleGuiButton.Parent = HitboxV2
ToggleGuiButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
ToggleGuiButton.BackgroundTransparency = 0.7
ToggleGuiButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
ToggleGuiButton.BorderSizePixel = 1
ToggleGuiButton.Size = UDim2.new(0, 40, 0, 40)
ToggleGuiButton.Position = UDim2.new(0, 10, 0.5, -20)
ToggleGuiButton.Font = Enum.Font.GothamBold
ToggleGuiButton.Text = "H"
ToggleGuiButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleGuiButton.TextSize = 20
ToggleGuiButton.Draggable = true
ToggleGuiButton.Active = true

-- Botón pequeño de ON/OFF
local MiniToggleButton = Instance.new("TextButton")
MiniToggleButton.Name = "MiniToggleButton"
MiniToggleButton.Parent = HitboxV2
MiniToggleButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
MiniToggleButton.BorderColor3 = Color3.fromRGB(255, 255, 255)
MiniToggleButton.BorderSizePixel = 1
MiniToggleButton.Size = UDim2.new(0, 50, 0, 30)
MiniToggleButton.Position = UDim2.new(0, 60, 0.5, -15)
MiniToggleButton.Font = Enum.Font.GothamBold
MiniToggleButton.Text = "OFF"
MiniToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniToggleButton.TextSize = 14
MiniToggleButton.Visible = false
MiniToggleButton.Draggable = true
MiniToggleButton.Active = true

-- Frame principal de la GUI
local HEHITBOXV2 = Instance.new("Frame")
HEHITBOXV2.Name = "HEHITBOXV2"
HEHITBOXV2.Parent = HitboxV2
HEHITBOXV2.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
HEHITBOXV2.BorderColor3 = Color3.fromRGB(180, 0, 0)
HEHITBOXV2.BorderSizePixel = 2
HEHITBOXV2.Position = UDim2.new(0.340681225, 0, 0.309215063, 0)
HEHITBOXV2.Size = UDim2.new(0, 256, 0, 256)
HEHITBOXV2.Active = true
HEHITBOXV2.Draggable = true
HEHITBOXV2.ClipsDescendants = true
HEHITBOXV2.Visible = true

-- Barra de pestañas
local TabBar = Instance.new("Frame")
TabBar.Parent = HEHITBOXV2
TabBar.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
TabBar.Size = UDim2.new(1, 0, 0, 32)
TabBar.Position = UDim2.new(0, 0, 0, 0)

local PrincipalTab = Instance.new("TextButton")
PrincipalTab.Parent = TabBar
PrincipalTab.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
PrincipalTab.Size = UDim2.new(0.5, 0, 1, 0)
PrincipalTab.Position = UDim2.new(0, 0, 0, 0)
PrincipalTab.Font = Enum.Font.GothamBold
PrincipalTab.Text = "Principal"
PrincipalTab.TextColor3 = Color3.fromRGB(255, 255, 255)
PrincipalTab.TextSize = 14

local TargetsTab = Instance.new("TextButton")
TargetsTab.Parent = TabBar
TargetsTab.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
TargetsTab.Size = UDim2.new(0.5, 0, 1, 0)
TargetsTab.Position = UDim2.new(0.5, 0, 0, 0)
TargetsTab.Font = Enum.Font.GothamBold
TargetsTab.Text = "Targets"
TargetsTab.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetsTab.TextSize = 14

-- Panel Principal
local PrincipalPanel = Instance.new("Frame")
PrincipalPanel.Parent = HEHITBOXV2
PrincipalPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PrincipalPanel.BackgroundTransparency = 1
PrincipalPanel.Position = UDim2.new(0, 0, 0, 32)
PrincipalPanel.Size = UDim2.new(1, 0, 0, 224)
PrincipalPanel.Visible = true

local MainFrame = Instance.new("Frame")
MainFrame.Parent = PrincipalPanel
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BackgroundTransparency = 1
MainFrame.Position = UDim2.new(0, 0, 0, 0)
MainFrame.Size = UDim2.new(1, 0, 0, 224)

local CenterContainer = Instance.new("Frame")
CenterContainer.Parent = MainFrame
CenterContainer.BackgroundTransparency = 1
CenterContainer.Size = UDim2.new(1, 0, 0, 224)

local CenterLayout = Instance.new("UIListLayout")
CenterLayout.Parent = CenterContainer
CenterLayout.SortOrder = Enum.SortOrder.LayoutOrder
CenterLayout.Padding = UDim.new(0, 8)
CenterLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Selector de Target
local TargetSelector = Instance.new("TextBox")
TargetSelector.Parent = CenterContainer
TargetSelector.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TargetSelector.BorderColor3 = Color3.fromRGB(180, 0, 0)
TargetSelector.BorderSizePixel = 1
TargetSelector.Size = UDim2.new(0, 224, 0, 28)
TargetSelector.Font = Enum.Font.Gotham
TargetSelector.Text = ""
TargetSelector.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetSelector.TextSize = 11
TargetSelector.TextXAlignment = Enum.TextXAlignment.Center
TargetSelector.PlaceholderText = "Agregar target (mínimo 3 letras)"
TargetSelector.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)

-- Botón ON/OFF dentro de la GUI
local ToggleButton = Instance.new("TextButton")
ToggleButton.Parent = CenterContainer
ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleButton.BorderColor3 = Color3.fromRGB(180, 0, 0)
ToggleButton.BorderSizePixel = 1
ToggleButton.Size = UDim2.new(0, 112, 0, 32)
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.Text = "OFF"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 14

-- Frame para tamaño
local SizeFrame = Instance.new("Frame")
SizeFrame.Parent = CenterContainer
SizeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SizeFrame.BorderColor3 = Color3.fromRGB(180, 0, 0)
SizeFrame.BorderSizePixel = 1
SizeFrame.Size = UDim2.new(0, 224, 0, 44)

local SizeLabel = Instance.new("TextLabel")
SizeLabel.Parent = SizeFrame
SizeLabel.BackgroundTransparency = 1
SizeLabel.Size = UDim2.new(1, 0, 0, 16)
SizeLabel.Position = UDim2.new(0, 0, 0, 4)
SizeLabel.Font = Enum.Font.Gotham
SizeLabel.Text = "Hitbox Size: 7"
SizeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
SizeLabel.TextSize = 11
SizeLabel.TextXAlignment = Enum.TextXAlignment.Center

local SizeSlider = Instance.new("TextBox")
SizeSlider.Parent = SizeFrame
SizeSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SizeSlider.BorderColor3 = Color3.fromRGB(180, 0, 0)
SizeSlider.BorderSizePixel = 1
SizeSlider.Size = UDim2.new(0, 192, 0, 20)
SizeSlider.Position = UDim2.new(0.5, -96, 0, 20)
SizeSlider.Font = Enum.Font.Gotham
SizeSlider.Text = "7"
SizeSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
SizeSlider.TextSize = 11
SizeSlider.TextXAlignment = Enum.TextXAlignment.Center
SizeSlider.PlaceholderText = "1 - 50"
SizeSlider.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)

-- Frame para Transparencia
local TransparencyFrame = Instance.new("Frame")
TransparencyFrame.Parent = CenterContainer
TransparencyFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TransparencyFrame.BorderColor3 = Color3.fromRGB(180, 0, 0)
TransparencyFrame.BorderSizePixel = 1
TransparencyFrame.Size = UDim2.new(0, 224, 0, 36)

local TransparencyLabel = Instance.new("TextLabel")
TransparencyLabel.Parent = TransparencyFrame
TransparencyLabel.BackgroundTransparency = 1
TransparencyLabel.Size = UDim2.new(0, 128, 0, 16)
TransparencyLabel.Position = UDim2.new(0, 8, 0, 10)
TransparencyLabel.Font = Enum.Font.Gotham
TransparencyLabel.Text = "Modo Transparencia:"
TransparencyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TransparencyLabel.TextSize = 10

local TransparencyButton = Instance.new("TextButton")
TransparencyButton.Parent = TransparencyFrame
TransparencyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TransparencyButton.BorderColor3 = Color3.fromRGB(180, 0, 0)
TransparencyButton.BorderSizePixel = 1
TransparencyButton.Size = UDim2.new(0, 56, 0, 20)
TransparencyButton.Position = UDim2.new(0, 160, 0, 8)
TransparencyButton.Font = Enum.Font.GothamBold
TransparencyButton.Text = "65%"
TransparencyButton.TextColor3 = Color3.fromRGB(0, 255, 0)
TransparencyButton.TextSize = 11

-- Panel Targets
local TargetsPanel = Instance.new("Frame")
TargetsPanel.Parent = HEHITBOXV2
TargetsPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TargetsPanel.Position = UDim2.new(0, 0, 0, 32)
TargetsPanel.Size = UDim2.new(1, 0, 0, 224)
TargetsPanel.Visible = false

local DeleteAllButton = Instance.new("TextButton")
DeleteAllButton.Parent = TargetsPanel
DeleteAllButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
DeleteAllButton.BorderSizePixel = 0
DeleteAllButton.Size = UDim2.new(0, 224, 0, 28)
DeleteAllButton.Position = UDim2.new(0.5, -112, 0, 4)
DeleteAllButton.Font = Enum.Font.GothamBold
DeleteAllButton.Text = "Eliminar Todos"
DeleteAllButton.TextColor3 = Color3.fromRGB(255, 255, 255)
DeleteAllButton.TextSize = 11

local TargetsList = Instance.new("ScrollingFrame")
TargetsList.Parent = TargetsPanel
TargetsList.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TargetsList.BorderColor3 = Color3.fromRGB(180, 0, 0)
TargetsList.BorderSizePixel = 1
TargetsList.Size = UDim2.new(0, 224, 0, 180)
TargetsList.Position = UDim2.new(0.5, -112, 0, 36)
TargetsList.CanvasSize = UDim2.new(0, 0, 0, 0)

local TargetsListLayout = Instance.new("UIListLayout")
TargetsListLayout.Parent = TargetsList
TargetsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TargetsListLayout.Padding = UDim.new(0, 4)

-- Ventana de selección múltiple
local SelectionGui = Instance.new("Frame")
SelectionGui.Parent = PrincipalPanel
SelectionGui.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SelectionGui.BackgroundTransparency = 0.3
SelectionGui.Size = UDim2.new(1, 0, 1, 0)
SelectionGui.Position = UDim2.new(0, 0, 0, 0)
SelectionGui.Visible = false
SelectionGui.ZIndex = 10

local SelectionBox = Instance.new("Frame")
SelectionBox.Parent = SelectionGui
SelectionBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SelectionBox.BorderColor3 = Color3.fromRGB(180, 0, 0)
SelectionBox.BorderSizePixel = 2
SelectionBox.Size = UDim2.new(0, 224, 0, 160)
SelectionBox.Position = UDim2.new(0.5, -112, 0.5, -80)
SelectionBox.ZIndex = 11
SelectionBox.ClipsDescendants = true

local SelectionTitle = Instance.new("TextLabel")
SelectionTitle.Parent = SelectionBox
SelectionTitle.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
SelectionTitle.Size = UDim2.new(1, 0, 0, 32)
SelectionTitle.Position = UDim2.new(0, 0, 0, 0)
SelectionTitle.Font = Enum.Font.GothamBold
SelectionTitle.Text = "Selecciona un jugador"
SelectionTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
SelectionTitle.TextSize = 13
SelectionTitle.TextXAlignment = Enum.TextXAlignment.Center
SelectionTitle.ZIndex = 11

local SelectionList = Instance.new("ScrollingFrame")
SelectionList.Parent = SelectionBox
SelectionList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
SelectionList.BorderColor3 = Color3.fromRGB(180, 0, 0)
SelectionList.BorderSizePixel = 1
SelectionList.Size = UDim2.new(0, 208, 0, 88)
SelectionList.Position = UDim2.new(0, 8, 0, 40)
SelectionList.ZIndex = 11
SelectionList.CanvasSize = UDim2.new(0, 0, 0, 0)

local SelectionListLayout = Instance.new("UIListLayout")
SelectionListLayout.Parent = SelectionList
SelectionListLayout.SortOrder = Enum.SortOrder.LayoutOrder
SelectionListLayout.Padding = UDim.new(0, 4)

local CancelButton = Instance.new("TextButton")
CancelButton.Parent = SelectionBox
CancelButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
CancelButton.BorderColor3 = Color3.fromRGB(180, 0, 0)
CancelButton.BorderSizePixel = 1
CancelButton.Size = UDim2.new(0, 80, 0, 24)
CancelButton.Position = UDim2.new(0.5, -40, 1, -32)
CancelButton.Font = Enum.Font.GothamBold
CancelButton.Text = "Cancelar"
CancelButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CancelButton.TextSize = 11
CancelButton.ZIndex = 11

-- Variables
local player = game.Players.LocalPlayer
local SavedTargets = {}
local HitboxExtender = {
    Enabled = false;
    HitboxSize = 7;
    TransparentMode = "soft";
    AllTargets = false;
}
local isGuiVisible = true
local isEverythingHidden = false

-- Función para resetear hitbox a estado normal
local function ResetHitbox(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        return
    end
    
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end
    
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Transparency = 1
    hrp.Color = Color3.fromRGB(255, 255, 255)
    hrp.Material = Enum.Material.Plastic
    hrp.Reflectance = 0
    
    local mesh = hrp:FindFirstChild("SpecialMesh")
    if mesh then
        mesh:Destroy()
    end
end

-- Función para resetear TODOS los jugadores
local function ResetAllHitboxes()
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= player then
            ResetHitbox(v)
        end
    end
end

-- Función para actualizar la hitbox de un jugador específico (INSTANTÁNEO)
local function UpdateHitboxForPlayer(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then
        return
    end
    
    local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end
    
    local mesh = hrp:FindFirstChild("SpecialMesh")
    
    if not mesh then
        mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Brick
        mesh.Parent = hrp
    end
    
    if HitboxExtender.Enabled then
        hrp.Size = Vector3.new(HitboxExtender.HitboxSize, HitboxExtender.HitboxSize, HitboxExtender.HitboxSize)
        mesh.Scale = Vector3.new(1, 1, 1)
        
        if HitboxExtender.TransparentMode == "soft" then
            hrp.Transparency = 0.65
            hrp.Material = Enum.Material.SmoothPlastic
            hrp.Reflectance = 0.3
        else
            hrp.Transparency = 1
            hrp.Material = Enum.Material.SmoothPlastic
            hrp.Reflectance = 0.1
        end
        
        hrp.Color = Color3.fromRGB(255, 50, 50)
        hrp.CanCollide = false
    else
        ResetHitbox(targetPlayer)
    end
end

-- Función para actualizar todos los targets (INSTANTÁNEO)
local function UpdateAllTargets()
    if HitboxExtender.AllTargets and #SavedTargets == 0 then
        -- Aplicar a TODOS los jugadores instantáneamente
        for _, v in pairs(game.Players:GetPlayers()) do
            if v ~= player then
                UpdateHitboxForPlayer(v)
            end
        end
    else
        -- Aplicar solo a los targets guardados instantáneamente
        for _, target in ipairs(SavedTargets) do
            local targetPlayer = game.Players:GetPlayerByUserId(target.UserId)
            if targetPlayer then
                UpdateHitboxForPlayer(targetPlayer)
            end
        end
    end
end

-- Función principal para activar/desactivar el hitbox (INSTANTÁNEA)
local function ToggleHitbox()
    if HitboxExtender.Enabled then
        -- Apagar hitbox
        HitboxExtender.Enabled = false
        HitboxExtender.AllTargets = false
        MiniToggleButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        MiniToggleButton.Text = "OFF"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        ToggleButton.Text = "OFF"
        
        -- Resetear todos los jugadores instantáneamente
        ResetAllHitboxes()
    else
        -- Encender hitbox
        HitboxExtender.Enabled = true
        
        -- Si no hay targets guardados, activar modo "todos"
        if #SavedTargets == 0 then
            HitboxExtender.AllTargets = true
        else
            HitboxExtender.AllTargets = false
        end
        
        MiniToggleButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        MiniToggleButton.Text = "ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        ToggleButton.Text = "ON"
        
        -- Aplicar a todos los targets instantáneamente
        UpdateAllTargets()
    end
end

-- Función para buscar jugadores que coincidan
local function FindPlayersByName(inputName)
    if string.len(inputName) < 3 then
        return {}
    end
    
    inputName = string.lower(inputName)
    local matches = {}
    
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= player then
            local playerName = string.lower(v.DisplayName)
            local playerUserName = string.lower(v.Name)
            
            if playerName == inputName or playerUserName == inputName then
                return {v}
            end
            
            if string.find(playerName, inputName, 1, true) then
                table.insert(matches, v)
            elseif string.find(playerUserName, inputName, 1, true) then
                table.insert(matches, v)
            end
        end
    end
    
    return matches
end

-- Función para ordenar targets alfabéticamente
local function SortTargets()
    table.sort(SavedTargets, function(a, b)
        return string.lower(a.DisplayName) < string.lower(b.DisplayName)
    end)
end

-- Función para mostrar ventana de selección
local function ShowSelectionDialog(matches, callback)
    for _, child in pairs(SelectionList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    for _, match in pairs(matches) do
        local playerButton = Instance.new("TextButton")
        playerButton.Parent = SelectionList
        playerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        playerButton.BorderColor3 = Color3.fromRGB(180, 0, 0)
        playerButton.BorderSizePixel = 1
        playerButton.Size = UDim2.new(0, 192, 0, 28)
        playerButton.Font = Enum.Font.Gotham
        playerButton.Text = match.DisplayName .. " (@ " .. match.Name .. ")"
        playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        playerButton.TextSize = 10
        playerButton.ZIndex = 11
        
        playerButton.MouseButton1Click:Connect(function()
            SelectionGui.Visible = false
            callback(match)
        end)
    end
    
    local buttonCount = #matches
    local newHeight = math.min(88, buttonCount * 32)
    SelectionList.Size = UDim2.new(0, 208, 0, newHeight)
    SelectionList.CanvasSize = UDim2.new(0, 0, 0, buttonCount * 32)
    
    SelectionGui.Visible = true
end

-- Función para guardar target
local function SaveTarget(targetPlayer)
    -- Si hay al menos un target guardado, desactivar el modo "todos"
    if HitboxExtender.AllTargets then
        HitboxExtender.AllTargets = false
        if HitboxExtender.Enabled then
            ResetAllHitboxes()
        end
    end
    
    for _, target in ipairs(SavedTargets) do
        if target.UserId == targetPlayer.UserId then
            return false
        end
    end
    
    table.insert(SavedTargets, {
        UserId = targetPlayer.UserId,
        Name = targetPlayer.Name,
        DisplayName = targetPlayer.DisplayName
    })
    
    SortTargets()
    if TargetsPanel.Visible then
        RefreshTargetsList()
    end
    
    -- Si el hitbox está encendido, actualizar instantáneamente
    if HitboxExtender.Enabled then
        UpdateHitboxForPlayer(targetPlayer)
    end
    
    return true
end

-- Función para eliminar target
local function RemoveTarget(targetUserId)
    local targetToRemove = nil
    local targetPlayer = nil
    
    for i, target in ipairs(SavedTargets) do
        if target.UserId == targetUserId then
            targetToRemove = i
            targetPlayer = game.Players:GetPlayerByUserId(targetUserId)
            break
        end
    end
    
    if targetToRemove then
        if targetPlayer then
            ResetHitbox(targetPlayer)
        end
        
        table.remove(SavedTargets, targetToRemove)
        
        -- Si ya no hay targets, activar modo "todos" si el hitbox está encendido
        if #SavedTargets == 0 and HitboxExtender.Enabled then
            HitboxExtender.AllTargets = true
            UpdateAllTargets()
        end
        
        if TargetsPanel.Visible then
            RefreshTargetsList()
        end
        return true
    end
    
    return false
end

-- Función para eliminar todos
local function RemoveAllTargets()
    -- Resetear hitboxes de los targets específicos
    for _, target in ipairs(SavedTargets) do
        local targetPlayer = game.Players:GetPlayerByUserId(target.UserId)
        if targetPlayer then
            ResetHitbox(targetPlayer)
        end
    end
    
    SavedTargets = {}
    
    -- Si el hitbox está encendido, activar modo "todos"
    if HitboxExtender.Enabled then
        HitboxExtender.AllTargets = true
        UpdateAllTargets()
    end
    
    if TargetsPanel.Visible then
        RefreshTargetsList()
    end
end

-- Función para limpiar TODOS los elementos del TargetsList
local function ClearTargetsList()
    local children = TargetsList:GetChildren()
    for i = #children, 1, -1 do
        local child = children[i]
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
end

-- Función para actualizar la lista de targets
local function RefreshTargetsList()
    ClearTargetsList()
    
    if #SavedTargets == 0 then
        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.Name = "EmptyLabel"
        emptyLabel.Parent = TargetsList
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Size = UDim2.new(0, 208, 0, 40)
        emptyLabel.Position = UDim2.new(0, 8, 0, 8)
        emptyLabel.Font = Enum.Font.Gotham
        emptyLabel.Text = "No hay targets guardados - Se aplicará a TODOS"
        emptyLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        emptyLabel.TextSize = 10
        emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
        emptyLabel.TextYAlignment = Enum.TextYAlignment.Center
        
        TargetsList.CanvasSize = UDim2.new(0, 0, 0, 56)
        return
    end
    
    for i, target in ipairs(SavedTargets) do
        local targetFrame = Instance.new("Frame")
        targetFrame.Parent = TargetsList
        targetFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        targetFrame.BorderColor3 = Color3.fromRGB(180, 0, 0)
        targetFrame.BorderSizePixel = 1
        targetFrame.Size = UDim2.new(0, 208, 0, 28)
        
        local targetLabel = Instance.new("TextLabel")
        targetLabel.Parent = targetFrame
        targetLabel.BackgroundTransparency = 1
        targetLabel.Size = UDim2.new(0, 168, 0, 28)
        targetLabel.Position = UDim2.new(0, 8, 0, 0)
        targetLabel.Font = Enum.Font.Gotham
        targetLabel.Text = target.DisplayName .. " (@ " .. target.Name .. ")"
        targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        targetLabel.TextSize = 10
        targetLabel.TextXAlignment = Enum.TextXAlignment.Left
        targetLabel.TextYAlignment = Enum.TextYAlignment.Center
        
        local deleteButton = Instance.new("TextButton")
        deleteButton.Parent = targetFrame
        deleteButton.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        deleteButton.BorderSizePixel = 0
        deleteButton.Size = UDim2.new(0, 24, 0, 20)
        deleteButton.Position = UDim2.new(0, 176, 0, 4)
        deleteButton.Font = Enum.Font.GothamBold
        deleteButton.Text = "X"
        deleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        deleteButton.TextSize = 13
        
        local userId = target.UserId
        deleteButton.MouseButton1Click:Connect(function()
            RemoveTarget(userId)
        end)
    end
    
    local totalHeight = #SavedTargets * 32 + 4
    TargetsList.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

-- Función para toggle de visibilidad de la GUI
local function ToggleGuiVisibility()
    if isEverythingHidden then return end
    
    isGuiVisible = not isGuiVisible
    HEHITBOXV2.Visible = isGuiVisible
    
    if isGuiVisible then
        MiniToggleButton.Visible = false
        ToggleGuiButton.Text = "H"
        ToggleGuiButton.BackgroundTransparency = 0.7
    else
        MiniToggleButton.Visible = true
        ToggleGuiButton.Text = "S"
        ToggleGuiButton.BackgroundTransparency = 0.3
    end
end

-- Función para ocultar TODO
local function HideEverything()
    isEverythingHidden = true
    isGuiVisible = false
    HEHITBOXV2.Visible = false
    ToggleGuiButton.Visible = false
    MiniToggleButton.Visible = false
end

-- Función para mostrar TODO
local function ShowEverything()
    isEverythingHidden = false
    isGuiVisible = true
    HEHITBOXV2.Visible = true
    ToggleGuiButton.Visible = true
    ToggleGuiButton.Text = "H"
    ToggleGuiButton.BackgroundTransparency = 0.7
    MiniToggleButton.Visible = false
end

-- Evento del botón flotante
ToggleGuiButton.MouseButton1Click:Connect(function()
    ToggleGuiVisibility()
end)

-- Evento del mini botón ON/OFF
MiniToggleButton.MouseButton1Click:Connect(function()
    ToggleHitbox()
end)

-- Evento de teclas
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.K then
        if isEverythingHidden then
            ShowEverything()
        else
            HideEverything()
        end
    elseif input.KeyCode == Enum.KeyCode.E then
        ToggleHitbox()
    end
end)

-- Eventos de pestañas
PrincipalTab.MouseButton1Click:Connect(function()
    PrincipalPanel.Visible = true
    TargetsPanel.Visible = false
    PrincipalTab.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    TargetsTab.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
end)

TargetsTab.MouseButton1Click:Connect(function()
    PrincipalPanel.Visible = false
    TargetsPanel.Visible = true
    PrincipalTab.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
    TargetsTab.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    RefreshTargetsList()
end)

CancelButton.MouseButton1Click:Connect(function()
    SelectionGui.Visible = false
end)

-- Agregar target con selección múltiple
TargetSelector.FocusLost:Connect(function(enterPressed)
    local searchName = TargetSelector.Text
    if string.len(searchName) < 3 then
        return
    end
    
    local matches = FindPlayersByName(searchName)
    
    if #matches == 0 then
        return
    elseif #matches == 1 then
        local foundPlayer = matches[1]
        if SaveTarget(foundPlayer) then
            TargetSelector.Text = ""
        else
            TargetSelector.Text = ""
        end
    else
        ShowSelectionDialog(matches, function(selectedPlayer)
            if SaveTarget(selectedPlayer) then
                TargetSelector.Text = ""
            else
                TargetSelector.Text = ""
            end
        end)
    end
end)

-- Eventos de tamaño
SizeSlider.FocusLost:Connect(function(enterPressed)
    local value = tonumber(SizeSlider.Text)
    if value then
        value = math.clamp(value, 1, 50)
        HitboxExtender.HitboxSize = value
        SizeSlider.Text = tostring(value)
        SizeLabel.Text = "Hitbox Size: " .. value
        if HitboxExtender.Enabled then
            UpdateAllTargets()
        end
    else
        SizeSlider.Text = tostring(HitboxExtender.HitboxSize)
    end
end)

-- Evento de transparencia
TransparencyButton.MouseButton1Click:Connect(function()
    if HitboxExtender.TransparentMode == "soft" then
        HitboxExtender.TransparentMode = "full"
        TransparencyButton.Text = "100%"
        TransparencyButton.TextColor3 = Color3.fromRGB(150, 150, 255)
        TransparencyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
    else
        HitboxExtender.TransparentMode = "soft"
        TransparencyButton.Text = "65%"
        TransparencyButton.TextColor3 = Color3.fromRGB(0, 255, 0)
        TransparencyButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
    
    if HitboxExtender.Enabled then
        UpdateAllTargets()
    end
end)

-- Botón ON/OFF dentro de la GUI
ToggleButton.MouseButton1Click:Connect(function()
    ToggleHitbox()
end)

-- Botón Eliminar Todos
DeleteAllButton.MouseButton1Click:Connect(function()
    RemoveAllTargets()
end)

-- Detectar nuevos jugadores que se unen (aplicación instantánea)
game.Players.PlayerAdded:Connect(function(newPlayer)
    if HitboxExtender.Enabled then
        if HitboxExtender.AllTargets and #SavedTargets == 0 then
            task.wait(0.5) -- Pequeña espera para que el personaje cargue
            UpdateHitboxForPlayer(newPlayer)
        end
    end
end)

-- Bucle de mantenimiento (cada 1 segundo, pero solo para mantener jugadores nuevos)
task.spawn(function()
    while task.wait(1) do
        if HitboxExtender.Enabled then
            pcall(function()
                -- Solo para asegurar que los jugadores que se unieron recientemente tengan la hitbox
                if HitboxExtender.AllTargets and #SavedTargets == 0 then
                    for _, v in pairs(game.Players:GetPlayers()) do
                        if v ~= player then
                            local hrp = v.Character and v.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and hrp.Size ~= Vector3.new(HitboxExtender.HitboxSize, HitboxExtender.HitboxSize, HitboxExtender.HitboxSize) then
                                UpdateHitboxForPlayer(v)
                            end
                        end
                    end
                else
                    for _, target in ipairs(SavedTargets) do
                        local targetPlayer = game.Players:GetPlayerByUserId(target.UserId)
                        if targetPlayer then
                            local hrp = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and hrp.Size ~= Vector3.new(HitboxExtender.HitboxSize, HitboxExtender.HitboxSize, HitboxExtender.HitboxSize) then
                                UpdateHitboxForPlayer(targetPlayer)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- Inicializar la lista
RefreshTargetsList()
