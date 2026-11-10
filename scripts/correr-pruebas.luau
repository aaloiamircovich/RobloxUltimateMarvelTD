-- Corre todas las pruebas en Studio (barra de comandos o MCP, en modo edición).
-- Usa copias nuevas de los módulos porque require() cachea en edición y Rojo actualiza el mismo objeto.
local srv = game.ServerScriptService.Server
local sh = game.ReplicatedStorage.Shared
local out = {}
for _, spec0 in srv.Pruebas:GetChildren() do
	if not spec0.Name:match("%.spec$") then
		continue
	end
	local copiaShared = sh:Clone()
	copiaShared.Name = "SharedT"
	copiaShared.Parent = game.ReplicatedStorage
	local copias = {}
	for _, m in srv:GetChildren() do
		if m:IsA("ModuleScript") then
			local c = m:Clone()
			c.Name = m.Name .. "_t"
			c.Parent = srv
			table.insert(copias, c)
		end
	end
	for _, m in srv.Pruebas:GetChildren() do
		if m:IsA("ModuleScript") and not m.Name:match("%.spec$") then
			local c = m:Clone()
			c.Name = m.Name .. "_t"
			c.Parent = srv.Pruebas
			table.insert(copias, c)
		end
	end
	local spec = spec0:Clone()
	local src = spec.Source:gsub('game:GetService%("ReplicatedStorage"%)%.Shared', 'game:GetService("ReplicatedStorage").SharedT'):gsub("RS%.Shared", "RS.SharedT")
	src = src:gsub("Parent%.Parent%.(%w+)%)", "Parent.Parent.%1_t)"):gsub("script%.Parent%.([%w_]+)%)", "script.Parent.%1_t)")
	spec.Source = src
	spec.Parent = srv.Pruebas
	local ok, res = pcall(function()
		return require(spec)()
	end)
	spec:Destroy()
	copiaShared:Destroy()
	for _, c in copias do
		c:Destroy()
	end
	table.insert(out, `{spec0.Name}: {if ok then "✔" else "✘"} {res}`)
end
print(table.concat(out, "\n"))
return table.concat(out, "\n")
