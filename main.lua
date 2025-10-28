-- SorinESP v3 (Body Highlight + Dual Watermark)
-- Author: SorinSoftware Services | scripts.sorinservice.online/sorin/ESP/main.lua

if getgenv().SorinESP_Active then
    warn("[SorinESP] Already running.")
    return
end
getgenv().SorinESP_Active = true

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// Config
local ESP_ENABLED = true
local COLOR = Color3.fromRGB(120, 85, 255) -- Sorin violet tone
local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local FILL_TRANSPARENCY = 0.75
local OUTLINE_TRANSPARENCY = 0.15

--// Watermark (Drawing API)
local function createWatermark()
    local wmTop = Drawing.new("Text")
    wmTop.Text = "SorinESP — scripts.sorinservice.online/sorin/ESP/main.lua"
    wmTop.Size = 16
    wmTop.Color = Color3.fromRGB(200, 180, 255)
    wmTop.Position = Vector2.new(10, 8)
    wmTop.Outline = true
    wmTop.OutlineColor = Color3.new(0, 0, 0)
    wmTop.Visible = true

    local wmBottom = Drawing.new("Text")
    wmBottom.Text = wmTop.Text
    wmBottom.Size = 16
    wmBottom.Color = wmTop.Color
    wmBottom.Outline = true
    wmBottom.OutlineColor = wmTop.OutlineColor
    wmBottom.Position = Vector2.new(10, workspace.CurrentCamera.ViewportSize.Y - 28)
    wmBottom.Visible = true

    RunService.RenderStepped:Connect(function()
        -- reposition bottom watermark if window resizes
        pcall(function()
            wmBottom.Position = Vector2.new(10, workspace.CurrentCamera.ViewportSize.Y - 28)
        end)
    end)
end
createWatermark()

--// Highlight management
local ESP_POOL = {}

local function createHighlight(player)
    if not player.Character then return end
    if ESP_POOL[player] then return end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = COLOR
    highlight.FillTransparency = FILL_TRANSPARENCY
    highlight.OutlineColor = OUTLINE_COLOR
    highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
    highlight.Adornee = player.Character
    highlight.Enabled = true
    highlight.Parent = player.Character

    -- floating name tag
    local tag = Drawing.new("Text")
    tag.Size = 14
    tag.Center = true
    tag.Outline = true
    tag.Color = Color3.fromRGB(255, 255, 255)
    tag.Text = player.DisplayName .. "\n@" .. player.Name
    tag.Visible = false

    ESP_POOL[player] = { Highlight = highlight, Tag = tag }
end

local function removeHighlight(player)
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
        createHighlight(p)
    end)
end)
Players.PlayerRemoving:Connect(removeHighlight)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createHighlight(p)
    end
end

--// Visibility + name tracking
RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then
        for _, v in pairs(ESP_POOL) do
            if v.Highlight then v.Highlight.Enabled = false end
            if v.Tag then v.Tag.Visible = false end
        end
        return
    end

    local cam = workspace.CurrentCamera
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local entry = ESP_POOL[player]
        if not entry then continue end

        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not (char and hrp) then
            entry.Highlight.Enabled = false
            entry.Tag.Visible = false
            continue
        end

        entry.Highlight.Adornee = char
        entry.Highlight.Enabled = true

        -- name tag position
        local head = char:FindFirstChild("Head")
        if head then
            local pos, onScreen = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
            if onScreen then
                entry.Tag.Position = Vector2.new(pos.X, pos.Y)
                entry.Tag.Visible = true
            else
                entry.Tag.Visible = false
            end
        end
    end
end)

--// Toggle with F4
game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F4 then
        ESP_ENABLED = not ESP_ENABLED
        warn("[SorinESP] ESP toggled:", ESP_ENABLED)
    end
end)
