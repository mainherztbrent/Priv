local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remoteY = ReplicatedStorage
    :WaitForChild("Packages")
    :WaitForChild("Knit")
    :WaitForChild("Services")
    :WaitForChild("CombatService")
    :WaitForChild("RF")
    :WaitForChild("y")

task.spawn(function()
    while true do
        local ok, err = pcall(function()
            remoteY:InvokeServer(true)
        end)
        if not ok then
            warn("[RF.y Auto] Error:", err)
        end
        task.wait(0.1)
    end
end)

print("[RF.y Auto] Iniciado. Invocando (true) cada 0.1s.")
