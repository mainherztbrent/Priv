local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

local USUARIOS_FORZADOS = {
    "liiz3tt3",
    "Papanuel0277",
    "papanuel02789",
    "Papanuel027799",
    "Papanuel02781",
    "Papanuel0271",
    "Papanuel0279",
    "papanuel02788",
    "Papanuel02791",
    "Papanuel0278",
    "nobodylikeme_35",
    "nobodylikeme_361",
    "botfuerte1",
    "botfuerte2",
    "botfuerte3",
    "botfuerte4",
    "botfuerte5",
    "botfuerte6",
    "botfuerte7",
  
    "lIIllIllllIIIlIlIll",
    "lIIllIllllIIIlIlIlII",
    "lIIllIllllIIIlIlIlI",
    "lIIllIllllIIIlIlIl",
    "lIIllIllllIIIlIlII",
  
    "mailu_7500",
    "mailu_5700",
    "zdiogobreno042",
    "mzainlh",
    "gatitblox",
    "Httpsitalian",
    "zyn77773",
    "Dan7Infinix",
    "mmelii_rdz",
    "Poeta_9pm",
    "nixxsteall",
}

local function normalizar(s)
    return string.lower(tostring(s))
end

local function esForzado(nombre)
    local n = normalizar(nombre)
    for _, u in ipairs(USUARIOS_FORZADOS) do
        if normalizar(u) == n then return true end
    end
    return false
end

local activo = false
local conexiones = {}
local heartbeatConn = nil

local function eliminarPersonaje(character)
    if not character or not character.Parent then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function()
            humanoid:ChangeState(Enum.HumanoidStateType.Dead)
            humanoid.Health = 0
        end)
    end

    for _, obj in ipairs(character:GetDescendants()) do
        pcall(function() obj:Destroy() end)
    end

    pcall(function() character:Destroy() end)
end

local function eliminarJugador(plr)
    if not plr or plr == localPlayer then return end
    if not esForzado(plr.Name) then return end
    if plr.Character then
        eliminarPersonaje(plr.Character)
    end
end

local function conectarJugador(plr)
    if plr == localPlayer then return end
    if not esForzado(plr.Name) then return end

    eliminarJugador(plr)

    table.insert(conexiones, plr.CharacterAdded:Connect(function(char)
        if not activo then return end
        task.wait(0.05)
        if not activo then return end
        eliminarPersonaje(char)
    end))
end

local function activar()
    if activo then return end
    activo = true

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and esForzado(plr.Name) then
            conectarJugador(plr)
        end
    end

    table.insert(conexiones, Players.PlayerAdded:Connect(function(plr)
        if activo and esForzado(plr.Name) then conectarJugador(plr) end
    end))

    heartbeatConn = RunService.Heartbeat:Connect(function()
        if not activo then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= localPlayer and esForzado(plr.Name) and plr.Character then
                eliminarPersonaje(plr.Character)
            end
        end
    end)
end

local function desactivar()
    if not activo then return end
    activo = false

    for _, conn in ipairs(conexiones) do
        pcall(function() conn:Disconnect() end)
    end
    conexiones = {}

    if heartbeatConn then
        heartbeatConn:Disconnect()
        heartbeatConn = nil
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "EliminarJugadoresGui"
gui.ResetOnSpawn = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Parent = gui
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.new(1, -15, 0, 15)
button.Size = UDim2.new(0, 38, 0, 38)
button.BackgroundTransparency = 0.2
button.TextSize = 20
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Text = "❌"

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = button

local function updateButton()
    if activo then
        button.Text = "✔️"
        button.BackgroundColor3 = Color3.fromRGB(50, 170, 80)
    else
        button.Text = "❌"
        button.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    end
end

local function toggle()
    if activo then desactivar() else activar() end
    updateButton()
end

button.Activated:Connect(toggle)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        toggle()
    end
end)

updateButton()
