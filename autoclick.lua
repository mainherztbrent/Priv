local CLICKS_PER_BURST = 2500
local BURST_INTERVAL = 0.1

local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local mouse = player:GetMouse()

local CLICK_POS_X = 0.995
local CLICK_POS_Y = 0.005

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoClicker"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 80, 0, 80)
button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
button.BorderSizePixel = 0
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 14
button.Font = Enum.Font.GothamBold
button.AutoButtonColor = false
button.Parent = screenGui
button.Text = "Pause AutoClick"

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = button

local shadow = Instance.new("UIStroke")
shadow.Color = Color3.fromRGB(0, 0, 0)
shadow.Thickness = 2
shadow.Transparency = 0.5
shadow.Parent = button

local sx = player:GetAttribute("AutoClickerBtnX")
local sy = player:GetAttribute("AutoClickerBtnY")
button.Position = (type(sx) == "number" and type(sy) == "number" and sx > 0 and sy > 0)
    and UDim2.new(0, sx, 0, sy)
    or UDim2.new(0, 500, 0, 150)

local enabled = false
local clickCount = 0
local clickerThread = nil
local stopRequested = false

local dragging = false
local dragStart = nil
local startPos = nil
local clickStartPos = nil
local isRightClick = false
local threshold = 5

local function getClickPosition()
    local viewSizeX = mouse.ViewSizeX or 800
    local viewSizeY = mouse.ViewSizeY or 600
    local x = viewSizeX * CLICK_POS_X
    local y = viewSizeY * CLICK_POS_Y
    return x, y
end

button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
        clickStartPos = input.Position
        isRightClick = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightClick = true
        clickStartPos = input.Position
    elseif input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = button.Position
        clickStartPos = input.Position
        isRightClick = false
    end
end)

button.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if dragStart and startPos then
            local delta = input.Position - dragStart
            if math.abs(delta.X) + math.abs(delta.Y) > threshold then
                local newX = startPos.X.Offset + delta.X
                local newY = startPos.Y.Offset + delta.Y
                local vx = mouse.ViewSizeX or 800
                local vy = mouse.ViewSizeY or 600
                newX = math.clamp(newX, 0, vx - button.AbsoluteSize.X)
                newY = math.clamp(newY, 0, vy - button.AbsoluteSize.Y)
                button.Position = UDim2.new(0, newX, 0, newY)
                player:SetAttribute("AutoClickerBtnX", newX)
                player:SetAttribute("AutoClickerBtnY", newY)
            end
        end
    end
end)

button.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.Touch then
        local wasDrag = clickStartPos and (math.abs((input.Position - clickStartPos).X) + math.abs((input.Position - clickStartPos).Y) > threshold) or false
        if not wasDrag then
            if isRightClick then
                local x, y = getClickPosition()
                pcall(function()
                    mouse1click(x, y)
                end)
                print("Click de prueba en (" .. x .. ", " .. y .. ")")
            else
                enabled = not enabled
                if enabled then
                    button.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
                    button.Text = "AutoClick"
                    startClicker()
                else
                    button.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
                    button.Text = "Pause AutoClick"
                    stopClicker()
                end
            end
        end
        dragging = false
        clickStartPos = nil
        isRightClick = false
    end
end)

function startClicker()
    if clickerThread then
        stopRequested = true
        clickerThread = nil
    end

    clickCount = 0
    stopRequested = false
    print("AutoClick iniciado: " .. CLICKS_PER_BURST .. " clics cada " .. BURST_INTERVAL .. "s")

    clickerThread = coroutine.create(function()
        local function doBurst()
            local x, y = getClickPosition()
            for _ = 1, CLICKS_PER_BURST do
                if stopRequested or not enabled then break end
                pcall(function()
                    mouse1click(x, y)
                end)
                clickCount = clickCount + 1
                task.wait()
            end
            if clickCount % 1000 == 0 then
                print("Clicks enviados: " .. clickCount)
            end
        end

        doBurst()

        local nextTime = tick() + BURST_INTERVAL
        while not stopRequested and enabled do
            local now = tick()
            if now >= nextTime then
                doBurst()
                nextTime = nextTime + BURST_INTERVAL
                if nextTime < tick() then
                    nextTime = tick() + BURST_INTERVAL
                end
            end
            task.wait()
        end

        print("Hilo de clics finalizado. Total: " .. clickCount)
    end)

    task.spawn(clickerThread)
end

function stopClicker()
    if clickerThread then
        stopRequested = true
        clickerThread = nil
        print("AutoClick detenido. Total clics: " .. clickCount)
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.K then
        screenGui.Enabled = not screenGui.Enabled
    end
end)

print("AutoClicker cargado.")
print("   " .. CLICKS_PER_BURST .. " clics cada " .. BURST_INTERVAL .. "s")
