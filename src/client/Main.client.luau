-- HUD mínimo: oleada, vidas, créditos y mensaje de la partida (atributos de ReplicatedStorage.Estado).
local Players = game:GetService("Players")
local estado = game:GetService("ReplicatedStorage"):WaitForChild("Estado")

local gui = Instance.new("ScreenGui")
gui.Name = "HUD"
gui.ResetOnSpawn = false

local panel = Instance.new("TextLabel")
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 12)
panel.Size = UDim2.fromOffset(520, 56)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
panel.BackgroundTransparency = 0.25
panel.TextColor3 = Color3.new(1, 1, 1)
panel.Font = Enum.Font.GothamBold
panel.TextSize = 18
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local function actualizar()
	panel.Text = `Oleada {estado:GetAttribute("Oleada")}   ·   ❤ {estado:GetAttribute("Vidas")}   ·   💰 {estado:GetAttribute("Creditos")}\n{estado:GetAttribute("Mensaje")}`
end
estado.AttributeChanged:Connect(actualizar)
actualizar()

gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
