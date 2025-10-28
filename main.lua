-- SorinESP v2.3 (TeamColor ESP + Range + Auto Reload)
-- Author: SorinSoftware Services | scripts.sorinservice.online/sorin/ESP.lua
-- Discord: endofcircuit (sorinuser06) / in your EH Discord Server :)

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
local MAX_DISTANCE = 2500
local ESP_ENABLED = true
local SHOW_DISTANCE = true
local SHOW_TOOL = true

local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local FILL_TRANSPARENCY = 0.75
local OUTLINE_TRANSPARENCY = 0.15

--------------------------------------------------------------------
-- Watermark
--------------------------------------------------------------------
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

--------------------------------------------------------------------
-- ESP Core
--------------------------------------------------------------------
local ESP_POOL = {}

local function createESP(player)
    if not player.Character then return end
    if ESP_POOL[player] then return end

    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = FILL_TRANSPARENCY
    highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
    highlight.Adornee = player.Character
    highlight.FillColor = player.Team and player.Team.TeamColor.Color or Color3.fromRGB(160, 120, 255)
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

--------------------------------------------------------------------
-- Utility
--------------------------------------------------------------------
local function getDistance(player)
    local char = player.Character
    local lchar = LocalPlayer.Character
    if not (char and lchar) then return math.huge end
    local hrp, lhrp = char:FindFirstChild("HumanoidRootPart"), lchar:FindFirstChild("HumanoidRootPart")
    if not (hrp and lhrp) then return math.huge end
    return (hrp.Position - lhrp.Position).Magnitude
end

local function getTool(player)
    local char = player.Character
    if not char then return "" end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or ""
end

local function refreshESP(player)
    -- create if missing or character respawned
    if not player.Character then return end
    if ESP_POOL[player] and ESP_POOL[player].Highlight and ESP_POOL[player].Highlight.Parent == player.Character then
        return
    end
    destroyESP(player)
    createESP(player)
end

--------------------------------------------------------------------
-- Player lifecycle / auto reload
--------------------------------------------------------------------
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.4)
        refreshESP(p)
    end)
    p.CharacterRemoving:Connect(function()
        destroyESP(p)
    end)
end)

Players.PlayerRemoving:Connect(destroyESP)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        refreshESP(p)
    end
end

--------------------------------------------------------------------
-- Render
--------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then
        for _, e in pairs(ESP_POOL) do
            e.Highlight.Enabled = false
            e.Tag.Visible = false
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        refreshESP(player)
        local entry = ESP_POOL[player]
        if not entry then continue end

        local char = player.Character
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (head and hum and hum.Health > 0) then
            entry.Tag.Visible = false
            entry.Highlight.Enabled = false
            continue
        end

        local distance = getDistance(player)
        if distance > MAX_DISTANCE then
            entry.Highlight.Enabled = false
            entry.Tag.Visible = false
            continue
        end

        local color = player.Team and player.Team.TeamColor and player.Team.TeamColor.Color or Color3.fromRGB(160, 120, 255)
        entry.Highlight.FillColor = color
        entry.Highlight.Enabled = true
        entry.Highlight.Adornee = char

        local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
        if onScreen then
            local textLines = {
                player.DisplayName,
                "@" .. player.Name
            }

            if SHOW_TOOL then
                local tool = getTool(player)
                if tool ~= "" then
                    table.insert(textLines, tool)
                end
            end

            if SHOW_DISTANCE then
                table.insert(textLines, string.format("%.0fm", distance))
            end

            entry.Tag.Text = table.concat(textLines, "\n")
            entry.Tag.Color = color
            entry.Tag.Position = Vector2.new(pos.X, pos.Y)
            entry.Tag.Visible = true
        else
            entry.Tag.Visible = false
        end
    end
end)

--------------------------------------------------------------------
-- F4 toggle
--------------------------------------------------------------------
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
print ("----------")
print ("Discord: endofcircuit (sorinuser06) / in your EH Discord Server :)")
