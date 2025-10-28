-- SorinESP v2.2 (TeamColor ESP + Minimal Display + Watermark)
-- Author: SorinSoftware Services | scripts.sorinservice.online/sorin/ESP.lua

if getgenv().SorinESP_Active then
    warn("[SorinESP] Already running.")
    return
end
getgenv().SorinESP_Active = true

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Config
local ESP_ENABLED = true
local SHOW_DISTANCE = true
local SHOW_TOOL = true

local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local FILL_TRANSPARENCY = 0.75
local OUTLINE_TRANSPARENCY = 0.15

--// Watermark
local function createWatermark()
    local text = "SorinESP — scripts.sorinservice.online/sorin/ESP.lua"
    local wmTop = Drawing.new("Text")
    wmTop.Text = text
    wmTop.Size = 17
    wmTop.Color = Color3.fromRGB(200, 180, 255)
    wmTop.Outline = true
    wmTop.OutlineColor = Color3.new(0, 0, 0)
    wmTop.Center = true
    wmTop.Visible = true

    local wmBottom = Drawing.new("Text")
    wmBottom.Text = text
    wmBottom.Size = 17
    wmBottom.Color = wmTop.Color
    wmBottom.Outline = true
    wmBottom.OutlineColor = wmTop.OutlineColor
    wmBottom.Center = true
    wmBottom.Visible = true

    RunService.RenderStepped:Connect(function()
        local size = Camera.ViewportSize
        wmTop.Position = Vector2.new(size.X / 2, 8)
        wmBottom.Position = Vector2.new(size.X / 2, size.Y - 28)
    end)
end
createWatermark()

--// ESP pool
local ESP_POOL = {}

local function createESP(player)
    if not player.Character then return end
    if ESP_POOL[player] then return end

    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = FILL_TRANSPARENCY
    highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.fromRGB(160, 120, 255)
    highlight.OutlineColor = OUTLINE_COLOR
    highlight.Parent = player.Character

    local tag = Drawing.new("Text")
    tag.Center = true
    tag.Outline = true
    tag.Size = 14
    tag.Visible = false

    ESP_POOL[player] = {Highlight = highlight, Tag = tag}
end

local function destroyESP(player)
    local entry = ESP_POOL[player]
    if not entry then return end
    if entry.Highlight then entry.Highlight:Destroy() end
    if entry.Tag then entry.Tag:Remove() end
    ESP_POOL[player] = nil
end

--// Player lifecycle
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.4)
        createESP(p)
    end)
end)
Players.PlayerRemoving:Connect(destroyESP)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createESP(p)
    end
end

--// Distance
local function getDistance(player)
    local char = player.Character
    local lchar = LocalPlayer.Character
    if not (char and lchar and char:FindFirstChild("HumanoidRootPart") and lchar:FindFirstChild("HumanoidRootPart")) then
        return 0
    end
    local pos = char.HumanoidRootPart.Position
    local myPos = lchar.HumanoidRootPart.Position
    return (pos - myPos).Magnitude
end

--// Get equipped tool
local function getEquippedTool(player)
    local char = player.Character
    if not char then return "" end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or ""
end

--// Render loop
RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then
        for _, v in pairs(ESP_POOL) do
            v.Highlight.Enabled = false
            v.Tag.Visible = false
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local entry = ESP_POOL[player]
        if not entry or not player.Character then continue end

        local head = player.Character:FindFirstChild("Head")
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if not (head and hum and hum.Health > 0) then
            entry.Tag.Visible = false
            entry.Highlight.Enabled = false
            continue
        end

        -- Team color highlight
        local teamColor = (player.Team and player.Team.TeamColor and player.Team.TeamColor.Color)
            or Color3.fromRGB(160, 120, 255)
        entry.Highlight.FillColor = teamColor
        entry.Highlight.Adornee = player.Character
        entry.Highlight.Enabled = true

        local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
        if onScreen then
            local textLines = {
                string.format("%s", player.DisplayName),
                string.format("@%s", player.Name)
            }

            if SHOW_TOOL then
                local tool = getEquippedTool(player)
                if tool ~= "" then
                    table.insert(textLines, tool)
                end
            end

            if SHOW_DISTANCE then
                local dist = getDistance(player)
                table.insert(textLines, string.format("%.0fm", dist))
            end

            entry.Tag.Text = table.concat(textLines, "\n")
            entry.Tag.Color = teamColor
            entry.Tag.Position = Vector2.new(pos.X, pos.Y)
            entry.Tag.Visible = true
        else
            entry.Tag.Visible = false
        end
    end
end)

--// UI Control (toggle options)
local Panel = {}
local function createControlPanel()
    local baseY = 100
    local spacing = 18
    local options = {
        { "ESP Enabled", function() ESP_ENABLED = not ESP_ENABLED end, function() return ESP_ENABLED end },
        { "Show Distance", function() SHOW_DISTANCE = not SHOW_DISTANCE end, function() return SHOW_DISTANCE end },
        { "Show Tool", function() SHOW_TOOL = not SHOW_TOOL end, function() return SHOW_TOOL end },
    }

    for i, opt in ipairs(options) do
        local t = Drawing.new("Text")
        t.Center = false
        t.Outline = true
        t.Size = 16
        t.Position = Vector2.new(20, baseY + (i - 1) * spacing)
        t.Color = Color3.fromRGB(180, 180, 255)
        t.Text = "[ ] " .. opt[1]
        t.Visible = true
        Panel[opt[1]] = {Obj = t, Action = opt[2], State = opt[3]}
    end

    RunService.RenderStepped:Connect(function()
        for _, entry in pairs(Panel) do
            local state = entry.State()
            entry.Obj.Text = string.format("[%s] %s", state and "x" or " ", entry.Obj.Text:match("%] (.*)"))
            entry.Obj.Color = state and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(200, 180, 255)
        end
    end)

    -- Click toggle
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mouse = UserInputService:GetMouseLocation()
            for _, entry in pairs(Panel) do
                local obj = entry.Obj
                local y = obj.Position.Y
                if mouse.Y >= y - 5 and mouse.Y <= y + 10 then
                    entry.Action()
                end
            end
        end
    end)
end
createControlPanel()

--// F4 Toggle
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F4 then
        ESP_ENABLED = not ESP_ENABLED
        warn("[SorinESP] Toggled:", ESP_ENABLED)
    end
end)

print ("SorinESP loaded successfully")
print ("Toggle ESP with 'F4'")
print ("View source code: scripts.sorinservice.online/sorin/ESP.lua")
