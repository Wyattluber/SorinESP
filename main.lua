-- SorinESP v1.5 (Body Highlight + Hacker Detection + Dual Watermark)
-- Author: SorinSoftware Services | scripts.sorinservice.online/sorin/ESP.lua

print("SorinESP loaded successfully.")
print("View source code: scripts.sorinservice.online/sorin/ESP.lua")
print("Easy ESP script. Toggle with 'F4'")


if getgenv().SorinESP_Active then
    warn("[SorinESP] Already running.")
    return
end
getgenv().SorinESP_Active = true

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Config
local ESP_ENABLED = true
local COLOR_NORMAL = Color3.fromRGB(120, 85, 255) -- Sorin violet
local COLOR_EXPLOITER = Color3.fromRGB(255, 60, 60)
local OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local FILL_TRANSPARENCY = 0.75
local OUTLINE_TRANSPARENCY = 0.15
local FLY_THRESHOLD = 3 -- seconds flying above ground before flagged

--// Watermark (top + bottom center)
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

local function createHighlight(player)
    if not player.Character then return end
    if ESP_POOL[player] then return end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = COLOR_NORMAL
    highlight.FillTransparency = FILL_TRANSPARENCY
    highlight.OutlineColor = OUTLINE_COLOR
    highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
    highlight.Adornee = player.Character
    highlight.Enabled = true
    highlight.Parent = player.Character

    local tag = Drawing.new("Text")
    tag.Size = 14
    tag.Center = true
    tag.Outline = true
    tag.Color = Color3.fromRGB(255, 255, 255)
    tag.Text = player.DisplayName .. "\n@" .. player.Name
    tag.Visible = false

    ESP_POOL[player] = {
        Highlight = highlight,
        Tag = tag,
        FlyTime = 0,
        Flagged = false
    }
end

local function removeHighlight(player)
    local entry = ESP_POOL[player]
    if not entry then return end
    if entry.Highlight then entry.Highlight:Destroy() end
    if entry.Tag then entry.Tag:Remove() end
    ESP_POOL[player] = nil
end

--// Player events
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        createHighlight(p)
    end)
end)
Players.PlayerRemoving:Connect(removeHighlight)

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createHighlight(p)
    end
end

--// Utility: detect if player is flying (no ground below)
local function isFlying(player)
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local rayOrigin = hrp.Position
    local rayDirection = Vector3.new(0, -25, 0)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {char}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return result == nil -- no ground detected within 25 studs
end

--// Render loop
RunService.RenderStepped:Connect(function(dt)
    if not ESP_ENABLED then
        for _, v in pairs(ESP_POOL) do
            if v.Highlight then v.Highlight.Enabled = false end
            if v.Tag then v.Tag.Visible = false end
        end
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local entry = ESP_POOL[player]
        if not entry then continue end
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")

        if not (char and hrp and head) then
            if entry.Highlight then entry.Highlight.Enabled = false end
            if entry.Tag then entry.Tag.Visible = false end
            continue
        end

        -- Flying detection
        if isFlying(player) then
            entry.FlyTime += dt
            if entry.FlyTime >= FLY_THRESHOLD and not entry.Flagged then
                entry.Flagged = true
                warn("[SorinESP] Possible exploiter detected:", player.Name)
            end
        else
            entry.FlyTime = 0
        end

        -- Update colors depending on flagged state
        if entry.Flagged then
            entry.Highlight.FillColor = COLOR_EXPLOITER
        else
            entry.Highlight.FillColor = COLOR_NORMAL
        end

        entry.Highlight.Adornee = char
        entry.Highlight.Enabled = true

        -- Name tag update
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
        if onScreen then
            local tagText = string.format("%s\n@%s", player.DisplayName, player.Name)
            if entry.Flagged then
                tagText = "⚠ " .. tagText .. "\nPossible Exploiter"
                entry.Tag.Color = Color3.fromRGB(255, 90, 90)
            else
                entry.Tag.Color = Color3.fromRGB(255, 255, 255)
            end
            entry.Tag.Text = tagText
            entry.Tag.Position = Vector2.new(pos.X, pos.Y)
            entry.Tag.Visible = true
        else
            entry.Tag.Visible = false
        end
    end
end)

--// Toggle ESP (F4)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F4 then
        ESP_ENABLED = not ESP_ENABLED
        warn("[SorinESP] ESP toggled:", ESP_ENABLED)
    end
end)
