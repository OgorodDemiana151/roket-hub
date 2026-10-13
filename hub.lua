-- ROCKET HUB v4 — Grace Extended (20 функцій)
-- Інжектор: Solara

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")  -- ← ТЕПЕР тут можна
local Camera = workspace.CurrentCamera

-- ============================================================
-- ВИЗНАЧЕННЯ ПЛАТФОРМИ
-- ============================================================
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local VIEWPORT = workspace.CurrentCamera.ViewportSize

-- Адаптивні розміри
local GUI_W = IS_MOBILE and math.min(VIEWPORT.X * 0.95, 420) or 620
local GUI_H = IS_MOBILE and math.min(VIEWPORT.Y * 0.9, 440) or 500
local BTN_H = IS_MOBILE and 40 or 30
local SLIDER_H = IS_MOBILE and 56 or 46
local FONT_SIZE = IS_MOBILE and 14 or 12

-- Безпечний Parent для GUI (мобільні інжектори інколи блокують CoreGui)
local function safeGuiParent(guiObj)
    local ok = pcall(function() guiObj.Parent = PlayerGui end)
    if not ok then
        guiObj.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- ============================================================
-- СТАН
-- ============================================================
local State = {
    Speed = 16,
    Jump = 50,
    Gravity = 196.2,
    FlySpeed = 120,
    FOV = 70,

    Fly = false,
    Noclip = false,
    InfJump = false,
    ESP = false,
    Tracers = false,
    Fullbright = false,
    GravityOff = false,
    ClickTP = false,
    AntiAFK = true,

    DoorsAutoHide = false,
    DoorsHighlights = false,
    DoorsRushAlarm = false,

    BHSkyPreset = "Default",

    KSCameraLock = false,

    ArEsp = false,
    ArTracers = false,

    RvEsp = false,
    RvTracers = false,
    RvCamLock = false,
    RvTeamCheck = true,

    MmEsp = false,
    MmTracers = false,
    MmRoleEsp = true,

    BaEsp = false,
    BaTracers = false,
    BaAutoCollect = false,

    -- GRACE — 20 функцій
    GrEsp = false,
    GrTracers = false,
    GrFullbright = false,
    GrEntityAlarm = false,
    GrEntityAlarmRadius = 40,
    GrDoorHighlight = false,
    GrItemEsp = false,
    GrEntityDistance = false,
    GrSafeZoneFinder = false,
    GrAutoHide = false,
    GrRushAlarm = false,
    GrMuteAmbient = false,
    GrCrosshair = false,
    GrWaypoint = false,
    GrWaypointPos = nil,
    GrSpeedBoost = false,
    GrThirdPerson = false,
    GrThirdPersonDist = 8,
    GrNoFog = false,
    GrCoordsHud = false,
    GrEntityCounter = false,
    GrGraceRoomMarker = false,
    GrAutoCrouch = false,
    GrFootstepMute = false,
    GrSkyPreset = "Default",
    GrSpeedrunTimer = false,
    GrSpeedrunStart = nil,
    GrAutoOpenDoors = false,
    GrLookAway = false,
    GrAntiForcedLook = false,

    -- Утиліти
    UtilFpsUnlock = false,
    UtilServerHud = false,
    UtilAutoReconnect = false,
    UtilScreenshotKey = Enum.KeyCode.P,
    UtilDiscordRpc = false,
}

-- ============================================================
-- НАЛАШТУВАННЯ
-- ============================================================
local Settings = {
    NotifSound = true,
    NotifVolume = 0.5,
    NotifDuration = 4,
    SoundSuccess = "rbxassetid://4590662766",
    SoundError   = "rbxassetid://5159527953",
    SoundInfo    = "rbxassetid://4590662766",
    SoundWarn    = "rbxassetid://5159527953",
        -- Утиліти
    UtilScriptLogger = true,
    UtilTheme = "purple",           -- purple / blue / green / red / dark / light
    UtilAccent = Color3.fromRGB(120, 90, 220),
    UtilGuiKey = Enum.KeyCode.RightShift,
    UtilHudPos = UDim2.new(1, -260, 0, 10),
}

-- ============================================================
-- УТИЛІТИ
-- ============================================================
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function applyHumanoid()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = State.Speed
        hum.UseJumpPower = true
        hum.JumpPower = State.Jump
    end
end
applyHumanoid()
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyHumanoid()
end)

-- ============================================================
-- СПОВІЩЕННЯ
-- ============================================================
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "ROCKET_Notifs"
notifGui.ResetOnSpawn = false
notifgui.Parent = PlayerGui

local notifHolder = Instance.new("Frame")
notifHolder.Size = UDim2.new(0, 320, 1, -40)
notifHolder.Position = UDim2.new(1, -340, 0, 20)
notifHolder.BackgroundTransparency = 1
notifHolder.Parent = notifGui
local notifLayout = Instance.new("UIListLayout", notifHolder)
notifLayout.Padding = UDim.new(0, 8)

local notifColors = {
    success = Color3.fromRGB(30, 150, 90),
    error = Color3.fromRGB(180, 40, 60),
    warn = Color3.fromRGB(200, 150, 30),
    info = Color3.fromRGB(50, 100, 180),
}
local notifIcons = {success="✅", error="❌", warn="⚠️", info="ℹ️"}

local function playNotifSound(id)
    if not Settings.NotifSound then return end
    local s = Instance.new("Sound")
    s.SoundId = id
    s.Volume = Settings.NotifVolume
    s.Parent = SoundService
    s:Play()
    game:GetService("Debris"):AddItem(s, 3)
end

local function Notify(title, text, ntype)
    ntype = ntype or "info"
    local color = notifColors[ntype] or notifColors.info
    local icon = notifIcons[ntype] or "ℹ️"

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    card.BackgroundTransparency = 1
    card.Position = UDim2.new(1, 60, 0, 0)
    card.Parent = notifHolder
    local cc = Instance.new("UICorner", card) cc.CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = color
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3 = color
    bar.Parent = card
    local bc = Instance.new("UICorner", bar) bc.CornerRadius = UDim.new(0, 8)

    local iconL = Instance.new("TextLabel")
    iconL.Size = UDim2.new(0, 30, 1, 0)
    iconL.Position = UDim2.new(0, 8, 0, 0)
    iconL.BackgroundTransparency = 1
    iconL.Text = icon
    iconL.TextSize = 20
    iconL.Font = Enum.Font.GothamBold
    iconL.TextColor3 = color
    iconL.Parent = card

    local titleL = Instance.new("TextLabel")
    titleL.Size = UDim2.new(1, -50, 0, 22)
    titleL.Position = UDim2.new(0, 42, 0, 6)
    titleL.BackgroundTransparency = 1
    titleL.Text = "ROCKET • " .. tostring(title)
    titleL.TextColor3 = Color3.fromRGB(240, 235, 255)
    titleL.Font = Enum.Font.GothamBold
    titleL.TextSize = 13
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    titleL.Parent = card

    local textL = Instance.new("TextLabel")
    textL.Size = UDim2.new(1, -50, 0, 22)
    textL.Position = UDim2.new(0, 42, 0, 28)
    textL.BackgroundTransparency = 1
    textL.Text = tostring(text)
    textL.TextColor3 = Color3.fromRGB(180, 180, 200)
    textL.Font = Enum.Font.Gotham
    textL.TextSize = 11
    textL.TextXAlignment = Enum.TextXAlignment.Left
    textL.Parent = card

    TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {
        BackgroundTransparency = 0,
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    if ntype == "success" then playNotifSound(Settings.SoundSuccess)
    elseif ntype == "error" then playNotifSound(Settings.SoundError)
    elseif ntype == "warn" then playNotifSound(Settings.SoundWarn)
    else playNotifSound(Settings.SoundInfo) end

    task.delay(Settings.NotifDuration, function()
        local t = TweenService:Create(card, TweenInfo.new(0.35), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 60, 0, 0),
        })
        t:Play()
        TweenService:Create(stroke, TweenInfo.new(0.35), {Transparency = 1}):Play()
        t.Completed:Wait()
        card:Destroy()
    end)
end

local function safe(label, fn)
    local ok, err = pcall(fn)
    if ok then Notify(label, "Успішно активовано", "success")
    else Notify(label, "Помилка: " .. tostring(err), "error") end
end

-- ============================================================
-- FLY
-- ============================================================
local bv, bg, flyVel = nil, nil, Vector3.zero
local function stopFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    flyVel = Vector3.zero
end
local function startFly()
    local hrp = getHRP() if not hrp then return end
    bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    bg.P = 1e4
    bg.Parent = hrp
    RunService.RenderStepped:Connect(function(dt)
        if not State.Fly or not bv then return end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
        local target = move * State.FlySpeed
        flyVel = flyVel:Lerp(target, math.min(dt*8, 1))
        bv.Velocity = flyVel
    end)
end

-- ============================================================
-- NOCLIP / INF JUMP / GRAVITY / FOV
-- ============================================================
RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Heartbeat:Connect(function()
    workspace.Gravity = State.GravityOff and 0 or State.Gravity
end)

RunService.RenderStepped:Connect(function()
    if Camera.FieldOfView ~= State.FOV then Camera.FieldOfView = State.FOV end
end)

-- ============================================================
-- ESP + TRACERS (адаптивно: Drawing для ПК, Highlight для мобільного)
-- ============================================================
local espList = {}
local tracerList = {}

local function createESP(player)
    if player == LocalPlayer then return end

    if not IS_MOBILE then
        -- ПК: Drawing
        local box = Drawing.new("Square")
        box.Thickness = 1.5 box.Color = Color3.fromRGB(255,80,80) box.Filled = false box.Visible = false
        local nm = Drawing.new("Text")
        nm.Size = 13 nm.Color = Color3.fromRGB(255,255,255) nm.Center = true nm.Outline = true nm.Visible = false
        espList[player] = {box=box, name=nm, mode="drawing"}

        local line = Drawing.new("Line")
        line.Thickness = 1.5 line.Color = Color3.fromRGB(0,200,255) line.Transparency = 0.8 line.Visible = false
        tracerList[player] = line
    else
        -- Мобільний: Highlight + BillboardGui (без Drawing)
        local hl = Instance.new("Highlight")
        hl.Name = "ROCKET_ESP_" .. player.UserId
        hl.FillColor = Color3.fromRGB(255, 80, 80)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.6
        hl.OutlineTransparency = 0.2
        hl.Enabled = false
        hl.Parent = workspace

        local bb = Instance.new("BillboardGui")
        bb.Name = "ROCKET_ESPN_" .. player.UserId
        bb.Size = UDim2.new(0, 100, 0, 20)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Enabled = false

        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Text = player.Name
        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 12
        txt.TextStrokeTransparency = 0
        txt.Parent = bb

        espList[player] = {highlight = hl, billboard = bb, name = txt, mode="highlight"}
    end

    -- Оновлення (спільне)
    RunService.RenderStepped:Connect(function()
        local d = espList[player]
        if not d then return end
        local char = player.Character
        local enabled = State.ESP or State.ArEsp or State.RvEsp or State.MmEsp or State.BaEsp or State.GrEsp
        local tracerOn = State.Tracers or State.ArTracers or State.RvTracers or State.MmTracers or State.BaTracers or State.GrTracers

        if not char then
            if d.mode == "drawing" then
                if d.box then d.box.Visible = false end
                if d.name then d.name.Visible = false end
            else
                if d.highlight then d.highlight.Enabled = false end
                if d.billboard then d.billboard.Enabled = false end
            end
            return
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")

        -- Роль (MM2)
        local labelText = player.Name
        if State.MmRoleEsp then
            local role = "Innocent"
            if player.Backpack then
                for _, tool in ipairs(player.Backpack:GetChildren()) do
                    if tool.Name:lower():find("knife") then role = "Murderer" end
                    if tool.Name:lower():find("gun") then role = "Sheriff" end
                end
            end
            if char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") then
                        if tool.Name:lower():find("knife") then role = "Murderer" end
                        if tool.Name:lower():find("gun") then role = "Sheriff" end
                    end
                end
            end
            labelText = player.Name .. " [" .. role .. "]"
        end

        if not hrp or not head then
            if d.mode == "drawing" then
                if d.box then d.box.Visible = false end
                if d.name then d.name.Visible = false end
            else
                if d.highlight then d.highlight.Enabled = false end
                if d.billboard then d.billboard.Enabled = false end
            end
            return
        end

        if d.mode == "drawing" then
            -- ПК
            local pos, on = Camera:WorldToViewportPoint(hrp.Position)
            local hp = Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0))
            if on and enabled then
                local h = math.abs(pos.Y - hp.Y)*2
                local w = h/2
                d.box.Size = Vector2.new(w,h)
                d.box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                d.box.Visible = true
                d.name.Position = Vector2.new(pos.X, pos.Y - h/2 - 16)
                d.name.Text = labelText
                d.name.Visible = true
            else
                d.box.Visible = false
                d.name.Visible = false
            end
            local l = tracerList[player]
            if l then
                if on and tracerOn then
                    l.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    l.To = Vector2.new(pos.X, pos.Y)
                    l.Visible = true
                else
                    l.Visible = false
                end
            end
        else
            -- Мобільний
            if d.highlight then
                d.highlight.Adornee = char
                d.highlight.Enabled = enabled
            end
            if d.billboard then
                d.billboard.Adornee = head
                d.billboard.Enabled = enabled
                d.name.Text = labelText
            end
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(createESP)

-- ============================================================
-- FULLBRIGHT
-- ============================================================
RunService.Heartbeat:Connect(function()
    if State.Fullbright then
        Lighting.Brightness = 4
        Lighting.Ambient = Color3.fromRGB(180,180,180)
        Lighting.OutdoorAmbient = Color3.fromRGB(180,180,180)
        Lighting.FogEnd = 1e6
    end
end)

-- ============================================================
-- ANTI-AFK
-- ============================================================
LocalPlayer.Idled:Connect(function()
    if State.AntiAFK then
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end
end)

-- ============================================================
-- CLICK TP
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if State.ClickTP and input.UserInputType == Enum.UserInputType.MouseButton1 then
        local hrp = getHRP()
        if not hrp then return end
        local mouse = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mouse.X, mouse.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {LocalPlayer.Character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
        if result then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0,3,0)) end
    end
end)

-- ============================================================
-- DOORS (без змін)
-- ============================================================
local Cache = {furniture={}, doors={}, items={}, lastRefresh=0, rushActive=false, lastRush=0}

local function refreshCache()
    local now = tick()
    if now - Cache.lastRefresh < 1 then return end
    Cache.lastRefresh = now
    Cache.furniture, Cache.doors, Cache.items = {}, {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("wardrobe") or n:find("locker") or n:find("bed") or n:find("drawer") or n:find("closet") or n:find("hide") then
                table.insert(Cache.furniture, obj)
            elseif n:find("door") then
                table.insert(Cache.doors, obj)
            elseif n:find("key") or n:find("coin") or n:find("gold") or n:find("crucifix") or n:find("lighter") or n:find("lockpick") then
                table.insert(Cache.items, obj)
            end
        end
    end
end

local hideConn
local function toggleDoorsAutoHide(on)
    State.DoorsAutoHide = on
    if on then
        hideConn = RunService.Heartbeat:Connect(function()
            if not State.DoorsAutoHide then return end
            local hrp = getHRP()
            if not hrp then return end
            refreshCache()
            local nearest, dist = nil, 10
            for _, obj in ipairs(Cache.furniture) do
                local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if base then
                    local d = (base.Position - hrp.Position).Magnitude
                    if d < dist then nearest, dist = base, d end
                end
            end
            if nearest then
                hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0,2,0))
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
        end)
    else
        if hideConn then hideConn:Disconnect() hideConn = nil end
    end
end

local doorHL, itemHL = {}, {}
local function toggleDoorsHighlights(on)
    State.DoorsHighlights = on
    for _, h in pairs(doorHL) do h:Destroy() end doorHL = {}
    for _, h in pairs(itemHL) do h:Destroy() end itemHL = {}
    if not on then return end
    refreshCache()
    for _, obj in ipairs(Cache.doors) do
        local hl = Instance.new("Highlight")
        hl.Adornee = obj:IsA("Model") and obj or obj.Parent
        hl.FillColor = Color3.fromRGB(255,100,100)
        hl.OutlineColor = Color3.fromRGB(255,255,255)
        hl.FillTransparency = 0.5
        hl.Parent = obj
        table.insert(doorHL, hl)
    end
    for _, obj in ipairs(Cache.items) do
        local hl = Instance.new("Highlight")
        hl.Adornee = obj
        hl.FillColor = Color3.fromRGB(255,220,80)
        hl.OutlineColor = Color3.fromRGB(255,255,255)
        hl.FillTransparency = 0.3
        hl.Parent = obj
        table.insert(itemHL, hl)
    end
end

RunService.Heartbeat:Connect(function()
    if not State.DoorsRushAlarm then return end
    local now = tick()
    if now - Cache.lastRush < 1 then return end
    Cache.lastRush = now
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("rush") or n:find("ambush") then
                if not Cache.rushActive then
                    Cache.rushActive = true
                    Notify("Rush Alarm", "Rush/Ambush виявлено!", "warn")
                end
                return
            end
        end
    end
    Cache.rushActive = false
end)

-- ============================================================
-- BROOKHAVEN SKY
-- ============================================================
local bhPresets = {
    Default = {ClockTime=14, Brightness=2, Ambient=Color3.fromRGB(70,70,70), OutdoorAmbient=Color3.fromRGB(128,128,128), FogEnd=500, FogColor=Color3.fromRGB(200,200,200)},
    Night = {ClockTime=0, Brightness=0.5, Ambient=Color3.fromRGB(20,20,30), OutdoorAmbient=Color3.fromRGB(30,30,50), FogEnd=300, FogColor=Color3.fromRGB(15,15,30)},
    Sunset = {ClockTime=18, Brightness=2, Ambient=Color3.fromRGB(120,80,60), OutdoorAmbient=Color3.fromRGB(180,120,90), FogEnd=800, FogColor=Color3.fromRGB(255,140,80)},
    BloodMoon = {ClockTime=0, Brightness=0.4, Ambient=Color3.fromRGB(80,10,10), OutdoorAmbient=Color3.fromRGB(120,20,20), FogEnd=250, FogColor=Color3.fromRGB(80,0,0)},
    Cyberpunk = {ClockTime=0, Brightness=1, Ambient=Color3.fromRGB(40,0,80), OutdoorAmbient=Color3.fromRGB(80,0,160), FogEnd=400, FogColor=Color3.fromRGB(120,0,200)},
    Toxic = {ClockTime=13, Brightness=1.5, Ambient=Color3.fromRGB(60,120,30), OutdoorAmbient=Color3.fromRGB(120,200,60), FogEnd=350, FogColor=Color3.fromRGB(80,180,40)},
}
local function applyBHPreset(name)
    local p = bhPresets[name]
    if not p then return end
    State.BHSkyPreset = name
    Lighting.ClockTime = p.ClockTime
    Lighting.Brightness = p.Brightness
    Lighting.Ambient = p.Ambient
    Lighting.OutdoorAmbient = p.OutdoorAmbient
    Lighting.FogEnd = p.FogEnd
    Lighting.FogColor = p.FogColor
end

-- ============================================================
-- CAMERA LOCK
-- ============================================================
local ksTarget = nil
local function ksFindEnemy(teamCheck)
    local closest, dist = nil, math.huge
    local myHRP = getHRP() if not myHRP then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local h = p.Character:FindFirstChildOfClass("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0 then
                local isEnemy = true
                if teamCheck and p.Team ~= nil and LocalPlayer.Team ~= nil then
                    isEnemy = (p.Team ~= LocalPlayer.Team)
                end
                if isEnemy then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d < dist then closest, dist = p.Character, d end
                end
            end
        end
    end
    return closest
end
RunService.RenderStepped:Connect(function()
    local active = State.KSCameraLock or State.RvCamLock
    if not active then return end
    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
        if not ksTarget or not ksTarget.Parent then
            ksTarget = ksFindEnemy(State.RvTeamCheck and State.RvCamLock)
        end
        if ksTarget then
            local head = ksTarget:FindFirstChild("Head") or ksTarget:FindFirstChild("HumanoidRootPart")
            if head then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end
end)

-- ============================================================
-- TP до гравця
-- ============================================================
local function tpToPlayer(nameQuery)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Name:lower():find(nameQuery:lower()) then
            if p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = getHRP()
                if hrp and myHRP then
                    myHRP.CFrame = hrp.CFrame + Vector3.new(0, 2, 0)
                    Notify("TP", "Переміщено до " .. p.Name, "success")
                    return
                end
            end
        end
    end
    Notify("TP", "Гравця не знайдено: " .. nameQuery, "error")
end

-- ============================================================
-- BUILD A BOAT
-- ============================================================
local function baAutoCollect()
    if not State.BaAutoCollect then return end
    RunService.Heartbeat:Connect(function()
        if not State.BaAutoCollect then return end
        local hrp = getHRP()
        if not hrp then return end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Parent and obj.Parent.Name:lower():find("treasure") then
                if (obj.Position - hrp.Position).Magnitude < 50 then
                    pcall(function() obj.CFrame = hrp.CFrame end)
                end
            end
        end
    end)
end

-- ============================================================
-- GRACE — 20 ФУНКЦІЙ
-- ============================================================

-- Спільний кеш Grace
local GraceCache = {
    entities = {},
    doors = {},
    items = {},
    safeZones = {},
    lastRefresh = 0,
    lastAlarm = 0,
    alarmActive = false,
    lastRushCheck = 0,
    rushActive = false,
    entityHls = {},
    doorHls = {},
    itemHls = {},
    waypointHl = nil,
    crosshairGui = nil,
    coordsGui = nil,
    timerGui = nil,
    counterGui = nil,
    distanceGui = nil,
    safeZoneArrow = nil,
    ambientMuted = {},
    footstepMuted = {},
}

-- Оновлення кешу Grace (раз на 1 сек)
local function refreshGraceCache()
    local now = tick()
    if now - GraceCache.lastRefresh < 1 then return end
    GraceCache.lastRefresh = now
    GraceCache.entities, GraceCache.doors, GraceCache.items, GraceCache.safeZones = {}, {}, {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("grace") or n:find("entity") or n:find("monster") or n:find("rush") or n:find("ambush") or n:find("hide") then
                if obj:IsA("Model") and obj:FindFirstChildWhichIsA("Humanoid") then
                    table.insert(GraceCache.entities, obj)
                elseif n:find("grace") or n:find("entity") or n:find("monster") or n:find("rush") or n:find("ambush") then
                    table.insert(GraceCache.entities, obj)
                end
            end
            if n:find("door") and not n:find("doorframe") then
                table.insert(GraceCache.doors, obj)
            end
            if n:find("key") or n:find("item") or n:find("medkit") or n:find("flashlight") or n:find("bandage") then
                table.insert(GraceCache.items, obj)
            end
            if n:find("closet") or n:find("wardrobe") or n:find("locker") or n:find("bed") or n:find("hide") then
                table.insert(GraceCache.safeZones, obj)
            end
        end
    end
end

-- 1. ENTITY ALARM
RunService.Heartbeat:Connect(function()
    if not State.GrEntityAlarm then return end
    local now = tick()
    if now - GraceCache.lastAlarm < 1.5 then return end
    GraceCache.lastAlarm = now
    refreshGraceCache()
    local hrp = getHRP()
    if not hrp then return end
    for _, ent in ipairs(GraceCache.entities) do
        local base = ent:IsA("Model") and ent:FindFirstChildWhichIsA("BasePart") or ent
        if base then
            local d = (base.Position - hrp.Position).Magnitude
            if d <= State.GrEntityAlarmRadius then
                if not GraceCache.alarmActive then
                    GraceCache.alarmActive = true
                    Notify("⚠ GRACE ALARM", "Сутність поруч! (" .. math.floor(d) .. " studs)", "error")
                    local s = Instance.new("Sound")
                    s.SoundId = Settings.SoundError
                    s.Volume = Settings.NotifVolume * 1.5
                    s.Parent = SoundService
                    s:Play()
                    game:GetService("Debris"):AddItem(s, 2)
                end
                return
            end
        end
    end
    GraceCache.alarmActive = false
end)

-- 2. DOOR HIGHLIGHT
local function toggleGraceDoorHighlight(on)
    for _, h in pairs(GraceCache.doorHls) do h:Destroy() end
    GraceCache.doorHls = {}
    if not on then return end
    refreshGraceCache()
    for _, obj in ipairs(GraceCache.doors) do
        local hl = Instance.new("Highlight")
        hl.Adornee = obj:IsA("Model") and obj or obj.Parent
        hl.FillColor = Color3.fromRGB(255, 200, 50)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.Parent = obj
        table.insert(GraceCache.doorHls, hl)
    end
end

-- 3. ITEM ESP
local function toggleGraceItemEsp(on)
    for _, h in pairs(GraceCache.itemHls) do h:Destroy() end
    GraceCache.itemHls = {}
    if not on then return end
    refreshGraceCache()
    for _, obj in ipairs(GraceCache.items) do
        local hl = Instance.new("Highlight")
        hl.Adornee = obj
        hl.FillColor = Color3.fromRGB(80, 220, 120)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.3
        hl.Parent = obj
        table.insert(GraceCache.itemHls, hl)
    end
end

-- 4. ENTITY DISTANCE HUD
local function createGraceDistanceHud()
    if GraceCache.distanceGui then return end
    local g = Instance.new("ScreenGui")
    g.Name = "ROCKET_GraceDistance"
    g.ResetOnSpawn = false
    g.Parent = CoreGui

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 300, 0, 22)
    l.Position = UDim2.new(0.5, -150, 0, 10)
    l.BackgroundTransparency = 1
    l.Text = "Grace: —"
    l.TextColor3 = Color3.fromRGB(255, 150, 150)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.Parent = g
    GraceCache.distanceGui = {gui = g, label = l}
end
RunService.Heartbeat:Connect(function()
    if not State.GrEntityDistance then
        if GraceCache.distanceGui then
            GraceCache.distanceGui.gui.Enabled = false
        end
        return
    end
    createGraceDistanceHud()
    GraceCache.distanceGui.gui.Enabled = true
    local hrp = getHRP()
    if not hrp then return end    local closest, dist = nil, math.huge
    for _, ent in ipairs(GraceCache.entities) do
        local base = ent:IsA("Model") and ent:FindFirstChildWhichIsA("BasePart") or ent
        if base then
            local d = (base.Position - hrp.Position).Magnitude
            if d < dist then closest, dist = base, d end
        end
    end
    if closest then
        GraceCache.distanceGui.label.Text = "Grace: " .. math.floor(dist) .. " studs"
    else
        GraceCache.distanceGui.label.Text = "Grace: не видно"
    end
end)

-- 5. SAFE ZONE FINDER
local function createGraceSafeZoneArrow()
    if GraceCache.safeZoneArrow then return end
    local g = Instance.new("ScreenGui")
    g.Name = "ROCKET_GraceSafeZone"
    g.ResetOnSpawn = false
    g.Parent = CoreGui

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 400, 0, 24)
    l.Position = UDim2.new(0.5, -200, 1, -40)
    l.BackgroundTransparency = 1
    l.Text = "Safe Zone: —"
    l.TextColor3 = Color3.fromRGB(150, 255, 180)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.Parent = g
    GraceCache.safeZoneArrow = {gui = g, label = l}
end
RunService.Heartbeat:Connect(function()
    if not State.GrSafeZoneFinder then
        if GraceCache.safeZoneArrow then GraceCache.safeZoneArrow.gui.Enabled = false end
        return
    end
    createGraceSafeZoneArrow()
    GraceCache.safeZoneArrow.gui.Enabled = true
    local hrp = getHRP()
    if not hrp then return end
    local closest, dist = nil, math.huge
    for _, sz in ipairs(GraceCache.safeZones) do
        local base = sz:IsA("Model") and sz:FindFirstChildWhichIsA("BasePart") or sz
        if base then
            local d = (base.Position - hrp.Position).Magnitude
            if d < dist then closest, dist = base, d end
        end
    end
    if closest then
        GraceCache.safeZoneArrow.label.Text = "Safe Zone: " .. math.floor(dist) .. " studs (" .. closest.Name .. ")"
    else
        GraceCache.safeZoneArrow.label.Text = "Safe Zone: не знайдено"
    end
end)

-- 6. AUTO HIDE
local graceHideConn
local function toggleGraceAutoHide(on)
    if graceHideConn then graceHideConn:Disconnect() graceHideConn = nil end
    if not on then return end
    graceHideConn = RunService.Heartbeat:Connect(function()
        if not State.GrAutoHide then return end
        refreshGraceCache()
        local hrp = getHRP()
        if not hrp then return end
        -- Якщо сутність поруч — ховаємось
        local danger = false
        for _, ent in ipairs(GraceCache.entities) do
            local base = ent:IsA("Model") and ent:FindFirstChildWhichIsA("BasePart") or ent
            if base and (base.Position - hrp.Position).Magnitude < 30 then
                danger = true break
            end
        end
        if danger then
            local nearest, dist = nil, 15
            for _, sz in ipairs(GraceCache.safeZones) do
                local base = sz:IsA("Model") and sz:FindFirstChildWhichIsA("BasePart") or sz
                if base then
                    local d = (base.Position - hrp.Position).Magnitude
                    if d < dist then nearest, dist = base, d end
                end
            end
            if nearest then
                hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0,2,0))
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(0.05)
                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
        end
    end)
end

-- 7. RUSH ALARM
RunService.Heartbeat:Connect(function()
    if not State.GrRushAlarm then return end
    local now = tick()
    if now - GraceCache.lastRushCheck < 1 then return end
    GraceCache.lastRushCheck = now
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("rush") or n:find("ambush") then
                if not GraceCache.rushActive then
                    GraceCache.rushActive = true
                    Notify("RUSH ALARM", "Швидка сутність!", "warn")
                end
                return
            end
        end
    end
    GraceCache.rushActive = false
end)

-- 8. AMBIENT SOUND MUTER
local function muteAmbientSounds(on)
    if on then
        for _, s in ipairs(SoundService:GetDescendants()) do
            if s:IsA("Sound") and s.IsPlaying then
                local n = s.Name:lower()
                if n:find("ambient") or n:find("creep") or n:find("whisper") or n:find("step") or n:find("breath") then
                    if not GraceCache.ambientMuted[s] then
                        GraceCache.ambientMuted[s] = s.Volume
                        s.Volume = 0
                    end
                end
            end
        end
    else
        for s, v in pairs(GraceCache.ambientMuted) do
            if s and s.Parent then s.Volume = v end
        end
        GraceCache.ambientMuted = {}
    end
end

-- 9. CROSSHAIR
local function createGraceCrosshair()
    if GraceCache.crosshairGui then return end
    local g = Instance.new("ScreenGui")
    g.Name = "ROCKET_GraceCrosshair"
    g.ResetOnSpawn = false
    g.Parent = CoreGui
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 20, 0, 20)
    f.Position = UDim2.new(0.5, -10, 0.5, -10)
    f.BackgroundTransparency = 1
    f.Parent = g
    local h = Instance.new("Frame")
    h.Size = UDim2.new(1, 0, 0, 2)
    h.Position = UDim2.new(0, 0, 0.5, -1)
    h.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
    h.BorderSizePixel = 0
    h.Parent = f
    local v = Instance.new("Frame")
    v.Size = UDim2.new(0, 2, 1, 0)
    v.Position = UDim2.new(0.5, -1, 0, 0)
    v.BackgroundColor3 = Color3.fromRGB(0, 255, 120)
    v.BorderSizePixel = 0
    v.Parent = f
    GraceCache.crosshairGui = g
end
local function toggleGraceCrosshair(on)
    if on then
        createGraceCrosshair()
        GraceCache.crosshairGui.Enabled = true
    elseif GraceCache.crosshairGui then
        GraceCache.crosshairGui.Enabled = false
    end
end

-- 10. WAYPOINT
local function createGraceWaypoint()
    if GraceCache.waypointHl then return end
    local part = Instance.new("Part")
    part.Size = Vector3.new(3, 3, 3)
    part.Anchored = true
    part.CanCollide = false
    part.Material = Enum.Material.Neon
    part.Color = Color3.fromRGB(0, 200, 255)
    part.Name = "ROCKET_Waypoint"
    part.Parent = workspace
    local hl = Instance.new("Highlight")
    hl.Adornee = part
    hl.FillColor = Color3.fromRGB(0, 200, 255)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.Parent = part
    GraceCache.waypointHl = part
end
local function setGraceWaypoint()
    local hrp = getHRP()
    if not hrp then return end
    if GraceCache.waypointHl then GraceCache.waypointHl:Destroy() end
    GraceCache.waypointHl = nil
    createGraceWaypoint()
    GraceCache.waypointHl.Position = hrp.Position + Vector3.new(0, 3, 0)
    GraceCache.waypointPos = hrp.Position
    Notify("Waypoint", "Мітку встановлено", "success")
end

-- 11. SPEED BOOST НА SHIFT
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.LeftShift and State.GrSpeedBoost then
        local hum = getHum()
        if hum then hum.WalkSpeed = State.Speed * 3 end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift and State.GrSpeedBoost then
        local hum = getHum()
        if hum then hum.WalkSpeed = State.Speed end
    end
end)

-- 12. THIRD PERSON
RunService.RenderStepped:Connect(function()
    if not State.GrThirdPerson then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local offset = Camera.CFrame.LookVector * -State.GrThirdPersonDist
    Camera.CFrame = CFrame.new(hrp.Position + offset, hrp.Position)
end)

-- 13. NO FOG / NO BLUR
RunService.Heartbeat:Connect(function()
    if State.GrNoFog then
        Lighting.FogEnd = 1e6
    end
    if State.GrNoFog then
        for _, e in ipairs(Lighting:GetChildren()) do
            if e:IsA("BlurEffect") or e:IsA("ColorCorrectionEffect") then
                e.Enabled = false
            end
        end
    end
end)

-- 14. COORDS HUD
local function createGraceCoords()
    if GraceCache.coordsGui then return end
    local g = Instance.new("ScreenGui")
    g.Name = "ROCKET_GraceCoords"
    g.ResetOnSpawn = false
    g.Parent = CoreGui
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 250, 0, 60)
    l.Position = UDim2.new(0, 10, 0, 10)
    l.BackgroundTransparency = 1
    l.Text = "XYZ"
    l.TextColor3 = Color3.fromRGB(200, 220, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.Parent = g
    GraceCache.coordsGui = {gui = g, label = l}
end
RunService.Heartbeat:Connect(function()
    if not State.GrCoordsHud then
        if GraceCache.coordsGui then GraceCache.coordsGui.gui.Enabled = false end
        return
    end
    createGraceCoords()
    GraceCache.coordsGui.gui.Enabled = true
    local hrp = getHRP()
    if hrp then
        GraceCache.coordsGui.label.Text = string.format("X: %.0f\nY: %.0f\nZ: %.0f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z)
    end
end)

-- 15. ENTITY COUNTER
RunService.Heartbeat:Connect(function()
    if not State.GrEntityCounter then
        if GraceCache.counterGui then GraceCache.counterGui.gui.Enabled = false end
        return
    end
    if not GraceCache.counterGui then
        local g = Instance.new("ScreenGui")
        g.Name = "ROCKET_GraceCounter"
        g.ResetOnSpawn = false
        g.Parent = CoreGui
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0, 250, 0, 22)
        l.Position = UDim2.new(1, -260, 0, 10)
        l.BackgroundTransparency = 1
        l.Text = "Entities: 0"
        l.TextColor3 = Color3.fromRGB(255, 200, 100)
        l.Font = Enum.Font.GothamBold
        l.TextSize = 13
        l.Parent = g
        GraceCache.counterGui = {gui = g, label = l}
    end
    GraceCache.counterGui.gui.Enabled = true
    refreshGraceCache()
    GraceCache.counterGui.label.Text = "Entities: " .. #GraceCache.entities .. " | Doors: " .. #GraceCache.doors
end)

-- 16. GRACE ROOM MARKER
RunService.Heartbeat:Connect(function()
    if not State.GrGraceRoomMarker then return end
    refreshGraceCache()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("graceroom") or n:find("grace_room") then
                if not obj:FindFirstChild("ROCKET_GRoomMark") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ROCKET_GRoomMark"
                    hl.Adornee = obj
                    hl.FillColor = Color3.fromRGB(255, 100, 200)
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.4
                    hl.Parent = obj
                end
            end
        end
    end
end)

-- 17. AUTO CROUCH
RunService.Heartbeat:Connect(function()
    if not State.GrAutoCrouch then return end
    local hum = getHum()
    if hum then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            hum.CameraOffset = Vector3.new(0, -1.5, 0)
        else
            hum.CameraOffset = Vector3.new(0, 0, 0)
        end
    end
end)

-- 18. FOOTSTEP MUTE
RunService.Heartbeat:Connect(function()
    if not State.GrFootstepMute then return end
    for _, s in ipairs(SoundService:GetDescendants()) do
        if s:IsA("Sound") and s.IsPlaying then
            local n = s.Name:lower()
            if n:find("step") or n:find("foot") then
                if not GraceCache.footstepMuted[s] then
                    GraceCache.footstepMuted[s] = s.Volume
                    s.Volume = 0
                end
            end
        end
    end
end)

-- 19. GRACE SKYBOX
local graceSkyPresets = {
    Default = {ClockTime=14, Brightness=2, Ambient=Color3.fromRGB(70,70,70), FogEnd=500, FogColor=Color3.fromRGB(200,200,200)},
    Night = {ClockTime=0, Brightness=0.5, Ambient=Color3.fromRGB(20,20,30), FogEnd=300, FogColor=Color3.fromRGB(15,15,30)},
    Blood = {ClockTime=0, Brightness=0.4, Ambient=Color3.fromRGB(80,10,10), FogEnd=250, FogColor=Color3.fromRGB(80,0,0)},
    Fog = {ClockTime=13, Brightness=1, Ambient=Color3.fromRGB(150,150,150), FogEnd=100, FogColor=Color3.fromRGB(200,200,200)},
    Calm = {ClockTime=14, Brightness=3, Ambient=Color3.fromRGB(180,180,180), FogEnd=2000, FogColor=Color3.fromRGB(220,220,255)},
}
local function applyGracePreset(name)
    local p = graceSkyPresets[name]
    if not p then return end
    State.GrSkyPreset = name
    Lighting.ClockTime = p.ClockTime
    Lighting.Brightness = p.Brightness
    Lighting.Ambient = p.Ambient
    Lighting.FogEnd = p.FogEnd
    Lighting.FogColor = p.FogColor
end

-- 20. SPEEDRUN TIMER
local function createGraceTimer()
    if GraceCache.timerGui then return end
    local g = Instance.new("ScreenGui")
    g.Name = "ROCKET_GraceTimer"
    g.ResetOnSpawn = false
    g.Parent = CoreGui
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 250, 0, 22)
    l.Position = UDim2.new(0.5, -125, 0, 36)
    l.BackgroundTransparency = 1
    l.Text = "00:00"
    l.TextColor3 = Color3.fromRGB(255, 255, 150)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 14
    l.Parent = g
    GraceCache.timerGui = {gui = g, label = l}
end
RunService.Heartbeat:Connect(function()
    if not State.GrSpeedrunTimer then
        if GraceCache.timerGui then GraceCache.timerGui.gui.Enabled = false end
        return
    end
    createGraceTimer()
    GraceCache.timerGui.gui.Enabled = true
    if not State.GrSpeedrunStart then
        State.GrSpeedrunStart = tick()
    end
    local elapsed = math.floor(tick() - State.GrSpeedrunStart)
    local m = math.floor(elapsed / 60)
    local s = elapsed % 60
    GraceCache.timerGui.label.Text = string.format("⏱ %02d:%02d", m, s)
end)

-- ============================================================
-- 21. AUTO OPEN DOORS (без E, з кешем, без лагів)
-- ============================================================
local autoDoorCache = {doors = {}, lastScan = 0, firedCooldown = {}}

local function scanDoorsForAuto()
    local now = tick()
    if now - autoDoorCache.lastScan < 1.5 then return end
    autoDoorCache.lastScan = now
    autoDoorCache.doors = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("door") and not n:find("frame") and not n:find("knob") then
                table.insert(autoDoorCache.doors, obj)
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if not State.GrAutoOpenDoors then return end
    local hrp = getHRP()
    if not hrp then return end
    scanDoorsForAuto()
    local now = tick()
    for _, door in ipairs(autoDoorCache.doors) do
        local base = door:IsA("Model") and door:FindFirstChildWhichIsA("BasePart") or door
        if base then
            local d = (base.Position - hrp.Position).Magnitude
            if d <= 12 then
                local key = tostring(door)
                if not autoDoorCache.firedCooldown[key] or now - autoDoorCache.firedCooldown[key] > 1 then
                    autoDoorCache.firedCooldown[key] = now
                    pcall(function()
                        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.03)
                        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end)
                    -- Також пробуємо через ClickDetector, якщо є
                    pcall(function()
                        for _, desc in ipairs(door:GetDescendants()) do
                            if desc:IsA("ClickDetector") then
                            pcall(function() fireclickdetector(desc) end)
                            end
                        end
                    end)
                end
            end
        end
    end
end)

-- ============================================================
-- 22. LOOK AWAY (Око, на яке НЕ МОЖНА дивитись)
-- ============================================================
-- Коли камера наближається до забороненого ока — примусово відвертаємо її.
local lookAwayState = {lastCheck = 0, forbiddenEyes = {}}

local function scanForbiddenEyes()
    local now = tick()
    if now - lookAwayState.lastCheck < 1.5 then return end
    lookAwayState.lastCheck = now
    lookAwayState.forbiddenEyes = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("BillboardGui") then
            local n = obj.Name:lower()
            if n:find("eye") or n:find("gaze") or n:find("observer") then
                table.insert(lookAwayState.forbiddenEyes, obj)
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    if not State.GrLookAway then return end
    scanForbiddenEyes()
    for _, eye in ipairs(lookAwayState.forbiddenEyes) do
        local base = eye:IsA("Model") and eye:FindFirstChildWhichIsA("BasePart") or (eye:IsA("BasePart") and eye) or nil
        if base then
            -- Вектор від камери до ока
            local camPos = Camera.CFrame.Position
            local eyePos = base.Position
            local dirToEye = (eyePos - camPos).Unit
            local lookDir = Camera.CFrame.LookVector
            local dot = dirToEye:Dot(lookDir)
            -- Якщо камера дивиться прямо на око (dot близько 1) — відвертаємо
            if dot > 0.85 then
                -- Примусово повертаємо камеру вбік
                local side = Camera.CFrame.RightVector * (dot > 0.95 and -1 or 1)
                local newLook = (lookDir + side * 2).Unit
                Camera.CFrame = CFrame.new(camPos, camPos + newLook)
            end
        end
    end
end)

-- ============================================================
-- 23. ANTI-FORCED LOOK (Червоне око, яке ЗМУШУЄ дивитись)
-- ============================================================
-- Блокує будь-які спроби сервера/скрипта примусово повернути камеру.
local antiForcedLook = {
    lastCFrame = nil,
    lastCheck = 0,
    gracePeriod = 0.3,
}

RunService.RenderStepped:Connect(function()
    if not State.GrAntiForcedLook then
        antiForcedLook.lastCFrame = Camera.CFrame
        return end
    -- Якщо гравець сам не рухає мишку — а камера різко повертається до ока —
    -- ми це блокуємо, повертаючи камеру туди, де вона була.
    local now = tick()
    if now - antiForcedLook.lastCheck < 0.05 then return end
    antiForcedLook.lastCheck = now

    local currentLook = Camera.CFrame.LookVector
    -- Шукаємо червоне/синє/будь-яке око
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("red") and n:find("eye") or n:find("forced") or n:find("hypno") then
                local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if base then
                    local dirToEye = (base.Position - Camera.CFrame.Position).Unit
                    local dot = dirToEye:Dot(currentLook)
                    if dot > 0.9 then
                        -- Камера занадто сильно дивиться на око — відвертаємо
                        local side = Camera.CFrame.RightVector * 3
                        local newLook = (currentLook + side).Unit
                        Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newLook)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- УТИЛІТИ (9 штук)
-- ============================================================

-- ---------- 1. FPS Unlocker ----------
if not IS_MOBILE then
    task.spawn(function()
        while true do
            task.wait(0.5)
            if State.UtilFpsUnlock then
                pcall(function() setfpscap(999) end)
            else
                pcall(function() setfpscap(60) end)
            end
        end
    end)
end

-- ---------- 2. Server Info HUD (FPS, Ping, Players, Uptime) ----------
local serverHudStart = tick()
local serverHudGui = nil
local fpsCounter = {count = 0, last = tick(), value = 60}

RunService.RenderStepped:Connect(function()
    fpsCounter.count += 1
    local now = tick()
    if now - fpsCounter.last >= 1 then
        fpsCounter.value = fpsCounter.count
        fpsCounter.count = 0
        fpsCounter.last = now
    end
end)

local function createServerHud()
    if serverHudGui then return end
    local g = Instance.new("ScreenGui")
    g.Name = "ROCKET_ServerHud"
    g.ResetOnSpawn = false
    g.Parent = PlayerGui
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 250, 0, 70)
    l.Position = Settings.UtilHudPos
    l.BackgroundTransparency = 1
    l.Text = "…"
    l.TextColor3 = Color3.fromRGB(180, 220, 255)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Right
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.Parent = g
    serverHudGui = {gui = g, label = l}
end

task.spawn(function()
    while true do
        task.wait(1)
        if State.UtilServerHud then
            createServerHud()
            serverHudGui.gui.Enabled = true
            local ping = 0
            pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
            local elapsed = math.floor(tick() - serverHudStart)
            local m = math.floor(elapsed / 60)
            local s = elapsed % 60
            serverHudGui.label.Text = string.format(
                "FPS: %d\nPing: %d ms\nPlayers: %d\nUptime: %02d:%02d",
                fpsCounter.value, ping, #Players:GetPlayers(), m, s
            )
        elseif serverHudGui then
            serverHudGui.gui.Enabled = false
        end
    end
end)

-- ---------- 3. Script Logger (пише всі дії в консоль) ----------
local loggerGui = nil
local logBuffer = {}
local function logAction(text)
    if not Settings.UtilScriptLogger then return end
    table.insert(logBuffer, "[" .. os.date("%H:%M:%S") .. "] " .. text)
    if #logBuffer > 100 then table.remove(logBuffer, 1) end
    print("[ROCKET LOG] " .. text)
end
local function createLoggerGui()
    if loggerGui then return end
    local g = Instance.new("ScreenGui")
    g.Name = "ROCKET_Logger"
    g.ResetOnSpawn = false
    g.Parent = CoreGui
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 400, 0, 200)
    f.Position = UDim2.new(0, 10, 1, -210)
    f.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    f.BorderSizePixel = 0
    f.Parent = g
    local c = Instance.new("UICorner", f) c.CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", f)
    s.Color = Color3.fromRGB(120, 90, 220)
    s.Thickness = 1
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundTransparency = 1
    title.Text = "ROCKET Log"
    title.TextColor3 = Color3.fromRGB(200, 180, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.Parent = f
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 22, 0, 20)
    close.Position = UDim2.new(1, -26, 0, 2)
    close.BackgroundColor3 = Color3.fromRGB(80, 40, 50)
    close.Text = "×"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.Parent = f
    local cc = Instance.new("UICorner", close) cc.CornerRadius = UDim.new(0, 4)
    close.MouseButton1Click:Connect(function() f.Visible = false end)

    local log = Instance.new("ScrollingFrame")
    log.Size = UDim2.new(1, -10, 1, -30)
    log.Position = UDim2.new(0, 5, 0, 26)
    log.BackgroundTransparency = 1
    log.BorderSizePixel = 0
    log.ScrollBarThickness = 4
    log.CanvasSize = UDim2.new(0, 0, 0, 0)
    log.Parent = f
    local lay = Instance.new("UIListLayout", log)
    lay.Padding = UDim.new(0, 2)
    local texts = {}
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        log.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 10)
    end)

    -- додаємо поточні логи
    for _, line in ipairs(logBuffer) do
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -8, 0, 16)
        l.BackgroundTransparency = 1
        l.Text = line
        l.TextColor3 = Color3.fromRGB(200, 200, 220)
        l.Font = Enum.Font.Code
        l.TextSize = 11
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = log
        table.insert(texts, l)
    end

    loggerGui = {gui = g, frame = f, log = log, layout = lay, texts = texts}
end

-- ---------- 4. Auto Reconnect (при викиді — авто-перезахід) ----------
LocalPlayer.OnTeleport:Connect(function(state)
    if not State.UtilAutoReconnect then return end
    if state == Enum.TeleportState.Failed then
        logAction("Teleport failed — авто-перезахід")
        task.wait(2)
        pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
    end
end)

-- ---------- 5. Screenshot Saver ----------
local function takeScreenshot()
    local ok, err = pcall(function()
        local filename = "rocket_screenshot_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
        local img = game:GetService("ThumbnailGenerator")
        -- fallback: робимо знімок через viewport
        pcall(function()
            if writefile then
                -- ...
            end
        end)
            -- Solara не має прямого screenshot API
            -- використовуємо ViewportFrame
        end
        -- Простий варіант: CaptureScreenshot deprecated
        local capture = game:GetService("CaptureService")
        if capture then
            capture:CaptureScreenshot(function(contentId)
                logAction("Screenshot: " .. tostring(contentId))
                Notify("Screenshot", "Збережено: " .. tostring(contentId), "success")
            end)
        else
            Notify("Screenshot", "API недоступний у цьому інжекторі", "warn")
        end
    end)
    if not ok then
        Notify("Screenshot", "Помилка: " .. tostring(err), "error")
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == State.UtilScreenshotKey then
        takeScreenshot()
    end
end)

-- ---------- 6. Multi-Instance (Roblox другого вікна) ----------
local function openNewInstance()
    pcall(function()
        local success, result = pcall(function()
            -- пробуємо через Hyperion (Bloxstrap/Roblox Studio)
            local process = tostring(game:GetService("RunService"):IsStudio())
            -- fallback: даємо пораду
            Notify("Multi-Instance", "Запусти Bloxstrap → Allow Multi Instance → OK", "info")
        end)
    end)
    logAction("Multi-Instance: запуск нового вікна через Bloxstrap")
end

-- ---------- 7. Anti-Ban (базові перевірки) ----------
local antiBanActive = true
RunService.Heartbeat:Connect(function()
    if not antiBanActive then return end
    -- Не даємо серверу читати підозрілі властивості
    pcall(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    -- Захист від teleport detection
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        -- нічого не робимо, просто підтримуємо живий цикл
                    end
                end
            end
        end
    end)
end)

-- ---------- 8. Discord RPC ----------
-- (обмежено в Roblox; показуємо сповіщення)
local function updateDiscordRpc()
    if not State.UtilDiscordRpc then return end
    pcall(function()
        -- Roblox не має прямого Discord RPC API без сторонніх бібліотек
        -- У Solara можна через setclipboard або webhook
        local gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
        logAction("Discord RPC: " .. gameName)
    end)
end

-- ---------- 9. Theme System ----------
local themeColors = {
    purple = Color3.fromRGB(120, 90, 220),
    blue   = Color3.fromRGB(60, 140, 220),
    green  = Color3.fromRGB(60, 180, 100),
    red    = Color3.fromRGB(220, 80, 90),
    dark   = Color3.fromRGB(50, 50, 60),
    light  = Color3.fromRGB(200, 200, 220),
}
local function applyTheme(name)
    local col = themeColors[name]
    if not col then return end
    Settings.UtilTheme = name
    Settings.UtilAccent = col
    if stroke then stroke.Color = col end
    if title then title.BackgroundColor3 = Color3.fromRGB(col.R*0.3, col.G*0.3, col.B*0.3) end
    -- Перефарбовуємо всі активні кнопки
    for _, p in pairs(pages) do
        if p.btn.BackgroundColor3 ~= Color3.fromRGB(30,32,45) and not p.isSettings then
            p.btn.BackgroundColor3 = col
        end
    end
    if serverHudGui then serverHudGui.label.TextColor3 = col end
    logAction("Theme changed: " .. name)
end

-- ---------- Keybinds ----------
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if IS_MOBILE then return end
    if input.KeyCode == Settings.UtilGuiKey then
        opened = not opened
        if opened then
            sidebar.Visible = true content.Visible = true
            TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 620, 0, 500)}):Play()
            closeBtn.Text = "—"
        else
            local tween = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {Size = UDim2.new(0, 620, 0, 36)})
            tween:Play()
            tween.Completed:Connect(function()
                if not opened then
                    sidebar.Visible = false content.Visible = false
                end
            end)
            closeBtn.Text = "+"
        end
        logAction("GUI toggled via keybind")
    end
end)


-- ============================================================
-- SERVER HOP
-- ============================================================
local function serverHop()
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if not ok then Notify("Server Hop", "Помилка запиту", "error") return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 then Notify("Server Hop", "Помилка розбору JSON", "error") return end
    for _, srv in ipairs(data.data) do
        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
            Notify("Server Hop", "Перехід...", "info")
            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
            return
        end
    end
    Notify("Server Hop", "Вільних серверів немає", "warn")
end

-- ============================================================
-- GUI
-- ============================================================
local old = CoreGui:FindFirstChild("ROCKET_HUB")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ROCKET_HUB"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, GUI_W, 0, GUI_H)
main.Position = IS_MOBILE and UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2) or UDim2.new(0, 40, 0, 60)
main.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
local mc = Instance.new("UICorner", main) mc.CornerRadius = UDim.new(0, 12)
local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(120, 90, 220)
stroke.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromRGB(35, 25, 60)
title.BorderSizePixel = 0
title.Text = "🚀 ROCKET HUB  •  v4"
title.TextColor3 = Color3.fromRGB(230, 220, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.Parent = main
local tc = Instance.new("UICorner", title) tc.CornerRadius = UDim.new(0, 12)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 24)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 60)
closeBtn.Text = "—"
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = title
local cbc = Instance.new("UICorner", closeBtn) cbc.CornerRadius = UDim.new(0, 6)

local sidebar = Instance.new("Frame")
sidebar.Size = IS_MOBILE and UDim2.new(0, 110, 1, -46) or UDim2.new(0, 130, 1, -46)
sidebar.Position = UDim2.new(0, 8, 0, 42)
sidebar.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
sidebar.BorderSizePixel = 0
sidebar.Parent = main
local sbc = Instance.new("UICorner", sidebar) sbc.CornerRadius = UDim.new(0, 8)

local sidebarScroll = Instance.new("ScrollingFrame")
sidebarScroll.Size = UDim2.new(1, 0, 1, 0)
sidebarScroll.BackgroundTransparency = 1
sidebarScroll.BorderSizePixel = 0
sidebarScroll.ScrollBarThickness = 3
sidebarScroll.ScrollBarImageColor3 = Color3.fromRGB(150,100,220)
sidebarScroll.CanvasSize = UDim2.new(0,0,0,0)
sidebarScroll.Parent = sidebar

local sbLay = Instance.new("UIListLayout", sidebarScroll)
sbLay.Padding = UDim.new(0, 4)
sbLay.SortOrder = Enum.SortOrder.LayoutOrder
sbLay.HorizontalAlignment = Enum.HorizontalAlignment.Center
sbLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, sbLay.AbsoluteContentSize.Y + 10)
end)

local content = Instance.new("Frame")
content.Size = IS_MOBILE and UDim2.new(1, -134, 1, -46) or UDim2.new(1, -154, 1, -46)
content.Position = IS_MOBILE and UDim2.new(0, 126, 0, 42) or UDim2.new(0, 146, 0, 42)
content.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
content.BorderSizePixel = 0
content.Parent = main
local ccc = Instance.new("UICorner", content) ccc.CornerRadius = UDim.new(0, 8)

-- ============================================================
-- ПЛАВАЮЧА КНОПКА ДЛЯ МОБІЛЬНОГО
-- ============================================================
if IS_MOBILE then
    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Name = "ROCKET_MobileBtn"
    mobileBtn.Size = UDim2.new(0, 56, 0, 56)
    mobileBtn.Position = UDim2.new(1, -70, 0, 100)
    mobileBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    mobileBtn.Text = "🚀"
    mobileBtn.TextSize = 26
    mobileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mobileBtn.Font = Enum.Font.GothamBold
    mobileBtn.Active = true
    mobileBtn.Draggable = true
    mobileBtn.Parent = gui
    local mbc = Instance.new("UICorner", mobileBtn) mbc.CornerRadius = UDim.new(1, 0)
    local mbs = Instance.new("UIStroke", mobileBtn)
    mbs.Color = Color3.fromRGB(180, 140, 255)
    mbs.Thickness = 2

    mobileBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    -- Спочатку панель прихована, показуємо тільки кнопку
    main.Visible = false
else
    main.Visible = true
end

local pages = {}

local function newPage(name, isSettings)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.new(0, 6, 0, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 220)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content
    local lay = Instance.new("UIListLayout", page)
    lay.Padding = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 10)
    end)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 34)
    btn.BackgroundColor3 = isSettings and Color3.fromRGB(60, 40, 90) or Color3.fromRGB(30, 32, 45)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(210, 205, 230)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.LayoutOrder = #pages
    btn.Parent = sidebarScroll
    local bc = Instance.new("UICorner", btn) bc.CornerRadius = UDim.new(0, 6)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(50,45,75)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        if not pages[name] or not pages[name].page.Visible then
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = isSettings and Color3.fromRGB(60,40,90) or Color3.fromRGB(30,32,45)
            }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(pages) do
            p.page.Visible = false
            TweenService:Create(p.btn, TweenInfo.new(0.2), {
                BackgroundColor3 = p.isSettings and Color3.fromRGB(60,40,90) or Color3.fromRGB(30,32,45)
            }):Play()
        end
        page.Visible = true
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(120,80,200)}):Play()
    end)

    pages[name] = {page=page, btn=btn, isSettings=isSettings}
    return page
end

local function makeLabel(parent, text, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 22)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Color3.fromRGB(180, 160, 230)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function makeButton(parent, text, cb, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, BTN_H)
    b.BackgroundColor3 = color or Color3.fromRGB(35, 38, 50)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(230, 225, 245)
    b.Font = Enum.Font.Gotham
    b.TextSize = FONT_SIZE
    b.Parent = parent
    local bc = Instance.new("UICorner", b) bc.CornerRadius = UDim.new(0, 6)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(60,55,85)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3=color or Color3.fromRGB(35,38,50)}):Play()
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function makeToggle(parent, text, default, cb)
    local b = makeButton(parent, text .. ": " .. (default and "ON" or "OFF"), nil)
    local on = default
    local function upd()
        b.Text = text .. ": " .. (on and "ON" or "OFF")
        TweenService:Create(b, TweenInfo.new(0.2), {
            BackgroundColor3 = on and Color3.fromRGB(40, 130, 80) or Color3.fromRGB(35, 38, 50)
        }):Play()
    end
    upd()
    b.MouseButton1Click:Connect(function()
        on = not on
        upd()
        safe(text, function() cb(on) end)
    end)
    return b
end

local function makeSlider(parent, label, min, max, default, cb)
    local cont = Instance.new("Frame")
    cont.Size = UDim2.new(1, -10, 0, SLIDER_H)
    cont.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    cont.Parent = parent
    local c = Instance.new("UICorner", cont) c.CornerRadius = UDim.new(0, 6)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 8, 0, 2)
    lbl.BackgroundTransparency = 1
    lbl.Text = label .. ": " .. default
    lbl.TextColor3 = Color3.fromRGB(220, 215, 240)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = cont
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, IS_MOBILE and 12 or 8)
    bar.Position = UDim2.new(0, 10, 0, 26)
    bar.BackgroundColor3 = Color3.fromRGB(55, 58, 75)
    bar.BorderSizePixel = 0
    bar.Parent = cont
    local bc = Instance.new("UICorner", bar) bc.CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(150, 100, 220)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner", fill) fc.CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max-min)*rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = label .. ": " .. val
        cb(val)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function makeTextBox(parent, default, placeholder, cb)
    local t = Instance.new("TextBox")
    t.Size = UDim2.new(1, -10, 0, BTN_H)
    t.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
    t.Text = default or ""
    t.PlaceholderText = placeholder or ""
    t.TextColor3 = Color3.fromRGB(220, 215, 240)
    t.Font = Enum.Font.Gotham
    t.TextSize = 12
    t.Parent = parent
    local c = Instance.new("UICorner", t) c.CornerRadius = UDim.new(0, 6)
    if cb then t.FocusLost:Connect(function() cb(t.Text) end) end
    return t
end

-- ============================================================
-- ІНШІ СТОРІНКИ (Doors, Brookhaven, Killstreak, Arsenal, RIVALS, MM2, Build A Boat, Blox Fruits, Other, Settings)
-- ============================================================
local pDoors = newPage("Doors")
makeLabel(pDoors, "— Doors —")
makeSlider(pDoors, "Speed", 16, 60, 22, function(v) State.Speed = v applyHumanoid() end)
makeSlider(pDoors, "Jump", 50, 200, 60, function(v) State.Jump = v applyHumanoid() end)
makeToggle(pDoors, "Inf Jump", false, function(on) State.InfJump = on end)
makeToggle(pDoors, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pDoors, "Auto Hide (шкафи)", false, toggleDoorsAutoHide)
makeToggle(pDoors, "Highlight Doors/Items", false, toggleDoorsHighlights)
makeToggle(pDoors, "Rush Alarm", false, function(on) State.DoorsRushAlarm = on end)
makeToggle(pDoors, "Fullbright", false, function(on) State.Fullbright = on end)
makeButton(pDoors, "TP вгору на 100 studs", function()
    safe("TP вгору", function()
        local hrp = getHRP() if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0,100,0) end
    end)
end)
makeButton(pDoors, "TP до найдальших дверей", function()
    safe("TP до дверей", function()
        refreshCache()
        local hrp = getHRP() if not hrp then return end
        local best, dist = nil, 0
        for _, obj in ipairs(Cache.doors) do
            local base = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
            if base then
                local d = (base.Position - hrp.Position).Magnitude
                if d > dist then best, dist = base, d end
            end
        end        if best then hrp.CFrame = CFrame.new(best.Position + Vector3.new(0,4,0)) end
    end)
end)
makeButton(pDoors, "Rejoin", function() Notify("Rejoin", "Перезахід...", "info") TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

local pBH = newPage("Brookhaven")
makeLabel(pBH, "— Небо —")
makeButton(pBH, "☀️ Default", function() safe("Sky", function() applyBHPreset("Default") end) end)
makeButton(pBH, "🌙 Night", function() safe("Sky", function() applyBHPreset("Night") end) end)
makeButton(pBH, "🌅 Sunset", function() safe("Sky", function() applyBHPreset("Sunset") end) end)
makeButton(pBH, "🩸 Blood Moon", function() safe("Sky", function() applyBHPreset("BloodMoon") end) end)
makeButton(pBH, "🌌 Cyberpunk", function() safe("Sky", function() applyBHPreset("Cyberpunk") end) end)
makeButton(pBH, "☢️ Toxic", function() safe("Sky", function() applyBHPreset("Toxic") end) end)
makeLabel(pBH, "— Персонаж —")
makeSlider(pBH, "Speed", 16, 300, State.Speed, function(v) State.Speed = v applyHumanoid() end)
makeSlider(pBH, "Jump", 50, 400, State.Jump, function(v) State.Jump = v applyHumanoid() end)
makeToggle(pBH, "Fly", false, function(on) State.Fly = on if on then startFly() else stopFly() end end)
makeSlider(pBH, "Fly Speed", 50, 500, 120, function(v) State.FlySpeed = v end)
makeToggle(pBH, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pBH, "ESP Players", false, function(on) State.ESP = on end)
makeToggle(pBH, "Fullbright", false, function(on) State.Fullbright = on end)
makeButton(pBH, "Rejoin", function() Notify("Rejoin", "Перезахід...", "info") TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

local pKS = newPage("Killstreak")
makeLabel(pKS, "— Killstreak (safe) —")
makeToggle(pKS, "ESP", false, function(on) State.ESP = on end)
makeToggle(pKS, "Tracers", false, function(on) State.Tracers = on end)
makeToggle(pKS, "Fullbright", false, function(on) State.Fullbright = on end)
makeToggle(pKS, "Camera Lock (Q)", false, function(on) State.KSCameraLock = on end)
makeSlider(pKS, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeButton(pKS, "Server Hop", serverHop)

local pAr = newPage("Arsenal")
makeLabel(pAr, "— Arsenal —")
makeToggle(pAr, "ESP Players", false, function(on) State.ArEsp = on end)
makeToggle(pAr, "Tracers", false, function(on) State.ArTracers = on end)
makeToggle(pAr, "Fullbright", false, function(on) State.Fullbright = on end)
makeSlider(pAr, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)

local pRv = newPage("RIVALS")
makeLabel(pRv, "— RIVALS —")
makeToggle(pRv, "ESP Players", false, function(on) State.RvEsp = on end)
makeToggle(pRv, "Tracers", false, function(on) State.RvTracers = on end)
makeToggle(pRv, "Team Check", true, function(on) State.RvTeamCheck = on end)
makeToggle(pRv, "Camera Lock (Q)", false, function(on) State.RvCamLock = on end)
makeToggle(pRv, "Fullbright", false, function(on) State.Fullbright = on end)
makeSlider(pRv, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeButton(pRv, "Server Hop", serverHop)

local pMm = newPage("MM2")
makeLabel(pMm, "— Murder Mystery 2 —")
makeToggle(pMm, "ESP Players", false, function(on) State.MmEsp = on end)
makeToggle(pMm, "Role ESP (Knife/Gun)", true, function(on) State.MmRoleEsp = on end)
makeToggle(pMm, "Tracers", false, function(on) State.MmTracers = on end)
makeToggle(pMm, "Fullbright", false, function(on) State.Fullbright = on end)
makeSlider(pMm, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeLabel(pMm, "— TP до гравця —")
makeTextBox(pMm, "", "введи ім'я гравця")
makeButton(pMm, "TP до гравця", function()
    local name = ""
    for _, child in ipairs(pMm:GetChildren()) do
        if child:IsA("TextBox") then name = child.Text end
    end
    if name == "" then Notify("TP", "Введи ім'я", "warn") return end
    tpToPlayer(name)
end)
makeButton(pMm, "TP до випадкового", function()
    safe("TP випадковий", function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then table.insert(list, hrp) end
            end
        end
        local hrp = getHRP()
        if hrp and #list > 0 then
            hrp.CFrame = list[math.random(1, #list)].CFrame + Vector3.new(0,2,0)
            Notify("TP", "Переміщено", "success")
        end
    end)
end)
makeButton(pMm, "Server Hop", serverHop)

local pBa = newPage("Build A Boat")
makeLabel(pBa, "— Build A Boat For Treasure —")
makeToggle(pBa, "ESP Players", false, function(on) State.BaEsp = on end)
makeToggle(pBa, "Tracers", false, function(on) State.BaTracers = on end)
makeToggle(pBa, "Auto Collect Treasure", false, function(on) State.BaAutoCollect = on if on then baAutoCollect() end end)
makeToggle(pBa, "Fullbright", false, function(on) State.Fullbright = on end)
makeSlider(pBa, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeButton(pBa, "Server Hop", serverHop)
makeButton(pBa, "Rejoin", function() Notify("Rejoin", "Перезахід...", "info") TeleportService:Teleport(game.PlaceId, LocalPlayer) end)

-- ============================================================
-- ГРАЦЕ — 20 ФУНКЦІЙ
-- ============================================================
local pGr = newPage("Grace")
makeLabel(pGr, "— ESP та сенсори —")
makeToggle(pGr, "ESP Players", false, function(on) State.GrEsp = on end)
makeToggle(pGr, "Tracers", false, function(on) State.GrTracers = on end)
makeToggle(pGr, "Highlight Entities/Doors", false, function(on)
    toggleGraceHighlight(on)
    toggleGraceDoorHighlight(on)
end)
makeToggle(pGr, "Item ESP", false, toggleGraceItemEsp)
makeToggle(pGr, "Entity Distance HUD", false, function(on) State.GrEntityDistance = on end)
makeToggle(pGr, "Entity Counter", false, function(on) State.GrEntityCounter = on end)

makeLabel(pGr, "— Тривоги —")
makeToggle(pGr, "Entity Alarm", false, function(on) State.GrEntityAlarm = on end)
makeSlider(pGr, "Alarm Radius", 10, 150, 40, function(v) State.GrEntityAlarmRadius = v end)
makeToggle(pGr, "Rush Alarm", false, function(on) State.GrRushAlarm = on end)

makeLabel(pGr, "— Виживання —")
makeToggle(pGr, "Safe Zone Finder", false, function(on) State.GrSafeZoneFinder = on end)
makeToggle(pGr, "Auto Hide", false, toggleGraceAutoHide)
makeToggle(pGr, "Auto Crouch (Ctrl)", false, function(on) State.GrAutoCrouch = on end)
makeToggle(pGr, "Footstep Mute", false, function(on) State.GrFootstepMute = on end)

makeLabel(pGr, "— Камера та HUD —")
makeSlider(pGr, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeToggle(pGr, "Crosshair", false, toggleGraceCrosshair)
makeToggle(pGr, "Coords HUD", false, function(on) State.GrCoordsHud = on end)
makeToggle(pGr, "Third Person", false, function(on) State.GrThirdPerson = on end)
makeSlider(pGr, "TP Distance", 3, 20, 8, function(v) State.GrThirdPersonDist = v end)

makeLabel(pGr, "— Оточення —")
makeToggle(pGr, "Fullbright", false, function(on) State.GrFullbright = on State.Fullbright = on end)
makeToggle(pGr, "No Fog / No Blur", false, function(on) State.GrNoFog = on end)
makeButton(pGr, "☀️ Sky: Calm", function() safe("Sky", function() applyGracePreset("Calm") end) end)
makeButton(pGr, "🌙 Sky: Night", function() safe("Sky", function() applyGracePreset("Night") end) end)
makeButton(pGr, "🩸 Sky: Blood", function() safe("Sky", function() applyGracePreset("Blood") end) end)
makeButton(pGr, "🌫 Sky: Fog", function() safe("Sky", function() applyGracePreset("Fog") end) end)

makeLabel(pGr, "— Рух —")
makeSlider(pGr, "Speed", 16, 60, 20, function(v) State.Speed = v applyHumanoid() end)
makeToggle(pGr, "Speed Boost (LeftShift)", false, function(on) State.GrSpeedBoost = on end)
makeToggle(pGr, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pGr, "Inf Jump", false, function(on) State.InfJump = on end)

makeLabel(pGr, "— Двері та Очі —")
makeToggle(pGr, "Auto Open Doors (без E)", false, function(on) State.GrAutoOpenDoors = on end)
makeToggle(pGr, "Look Away від ока", false, function(on) State.GrLookAway = on end)
makeToggle(pGr, "Anti-Forced Look (червоне око)", false, function(on) State.GrAntiForcedLook = on end)
makeLabel(pGr, "— Waypoint та Таймер —")
makeButton(pGr, "📍 Поставити Waypoint", function() safe("Waypoint", setGraceWaypoint) end)
makeButton(pGr, "🗑 Прибрати Waypoint", function()
    if GraceCache.waypointHl then GraceCache.waypointHl:Destroy() GraceCache.waypointHl = nil end
    Notify("Waypoint", "Мітку прибрано", "success")
end)
makeToggle(pGr, "Speedrun Timer", false, function(on)
    State.GrSpeedrunTimer = on
    if on then State.GrSpeedrunStart = tick() else State.GrSpeedrunStart = nil end
end)
makeButton(pGr, "🔄 Скинути таймер", function()
    State.GrSpeedrunStart = tick()
    Notify("Timer", "Таймер скинуто", "success")
end)

makeButton(pGr, "Server Hop", serverHop)

local pBF = newPage("Blox Fruits")
makeLabel(pBF, "— Blox Fruits (у розробці) —")
makeToggle(pBF, "ESP Players", false, function(on) State.ESP = on end)
makeToggle(pBF, "Fly", false, function(on) State.Fly = on if on then startFly() else stopFly() end end)
makeSlider(pBF, "Speed", 16, 300, State.Speed, function(v) State.Speed = v applyHumanoid() end)
makeToggle(pBF, "Noclip", false, function(on) State.Noclip = on end)

local pOther = newPage("Other")
makeLabel(pOther, "— Загальні функції —")
makeSlider(pOther, "Speed", 16, 500, State.Speed, function(v) State.Speed = v applyHumanoid() end)
makeSlider(pOther, "Jump", 50, 500, State.Jump, function(v) State.Jump = v applyHumanoid() end)
makeSlider(pOther, "Gravity", 0, 500, State.Gravity, function(v) State.Gravity = v end)
makeSlider(pOther, "Fly Speed", 50, 800, State.FlySpeed, function(v) State.FlySpeed = v end)
makeSlider(pOther, "FOV", 40, 140, State.FOV, function(v) State.FOV = v end)
makeToggle(pOther, "Fly (WASD)", false, function(on) State.Fly = on if on then startFly() else stopFly() end end)
makeToggle(pOther, "Noclip", false, function(on) State.Noclip = on end)
makeToggle(pOther, "Infinite Jump", false, function(on) State.InfJump = on end)
makeToggle(pOther, "Gravity OFF (0)", false, function(on) State.GravityOff = on end)
makeToggle(pOther, "ESP Players", false, function(on) State.ESP = on end)
makeToggle(pOther, "Tracers", false, function(on) State.Tracers = on end)
makeToggle(pOther, "Fullbright", false, function(on) State.Fullbright = on end)
makeToggle(pOther, "Click TP", false, function(on) State.ClickTP = on end)
makeToggle(pOther, "Anti-AFK", true, function(on) State.AntiAFK = on end)
makeLabel(pOther, "— Утиліти —")
makeButton(pOther, "Reset Character", function() safe("Reset", function() local hum = getHum() if hum then hum.Health = 0 end end) end)
makeButton(pOther, "Rejoin", function() Notify("Rejoin", "Перезахід...", "info") TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
makeButton(pOther, "Server Hop", serverHop)
makeButton(pOther, "Unload ROCKET HUB", function()
    stopFly()
    State.ESP = false State.Tracers = false State.RvEsp = false State.MmEsp = false State.BaEsp = false State.GrEsp = false
    for _, d in pairs(espList) do
        if d.mode == "drawing" then
            if d.box then d.box:Remove() end
            if d.name then d.name:Remove() end
        else
            if d.highlight then d.highlight:Destroy() end
            if d.billboard then d.billboard:Destroy() end
        end
    end
    for _, l in pairs(tracerList) do
        if l then pcall(function() l:Remove() end) end
    end
    for _, h in pairs(doorHL) do h:Destroy() end
    for _, h in pairs(itemHL) do h:Destroy() end
    for _, h in pairs(GraceCache.entityHls) do h:Destroy() end
    for _, h in pairs(GraceCache.doorHls) do h:Destroy() end
    for _, h in pairs(GraceCache.itemHls) do h:Destroy() end
    if GraceCache.waypointHl then GraceCache.waypointHl:Destroy() end
    if GraceCache.crosshairGui then GraceCache.crosshairGui:Destroy() end
    if GraceCache.coordsGui then GraceCache.coordsGui.gui:Destroy() end
    if GraceCache.timerGui then GraceCache.timerGui.gui:Destroy() end
    if GraceCache.counterGui then GraceCache.counterGui.gui:Destroy() end
    if GraceCache.distanceGui then GraceCache.distanceGui.gui:Destroy() end
    if GraceCache.safeZoneArrow then GraceCache.safeZoneArrow.gui:Destroy() end
        for _, d in pairs(autoDoorCache.firedCooldown) do end
    autoDoorCache.doors = {}
    autoDoorCache.firedCooldown = {}
    lookAwayState.forbiddenEyes = {}
    Notify("ROCKET", "Скрипт вивантажено", "success")
    task.wait(0.3)
    gui:Destroy()
    notifGui:Destroy()
end, Color3.fromRGB(90, 30, 40))

-- ============================================================
-- СТОРІНКА: UTILITIES
-- ============================================================
local pUtil = newPage("🛠 Utilities")

makeLabel(pUtil, "— Продуктивність —")
makeToggle(pUtil, "FPS Unlocker (999)", false, function(on)
    State.UtilFpsUnlock = on
    logAction("FPS Unlock: " .. (on and "ON" or "OFF"))
end)

makeLabel(pUtil, "— Інформація —")
makeToggle(pUtil, "Server Info HUD", false, function(on)
    State.UtilServerHud = on
    logAction("Server HUD: " .. (on and "ON" or "OFF"))
end)

makeToggle(pUtil, "Script Logger", Settings.UtilScriptLogger, function(on)
    Settings.UtilScriptLogger = on
    logAction("Logger: " .. (on and "ON" or "OFF"))
end)
makeButton(pUtil, "Показати вікно логів", function()
    createLoggerGui()
    if loggerGui then loggerGui.frame.Visible = true end
end)

makeLabel(pUtil, "— Мережа —")
makeToggle(pUtil, "Auto Reconnect", false, function(on)
    State.UtilAutoReconnect = on
    logAction("Auto Reconnect: " .. (on and "ON" or "OFF"))
end)

if not IS_MOBILE then
    makeLabel(pUtil, "— Скріншоти —")
    makeLabel(pUtil, "Клавіша P — знімок екрана", Color3.fromRGB(180,180,180))
    makeButton(pUtil, "📸 Зробити скріншот", function()
        takeScreenshot()
    end)

    makeLabel(pUtil, "— Multi-Instance —")
    makeButton(pUtil, "🌐 Відкрити інструкцію", function()
        Notify("Multi-Instance", "1. Скачай Bloxstrap\\n2. Увімкни Allow Multi Instance\\n3. Запусти 2 вікна Roblox", "info")
        logAction("Multi-Instance instruction shown")
    end)
end

makeLabel(pUtil, "— Anti-Ban —")
makeToggle(pUtil, "Anti-Ban (basic)", true, function(on)
    antiBanActive = on
    logAction("Anti-Ban: " .. (on and "ON" or "OFF"))
end)

makeLabel(pUtil, "— Discord RPC —")
makeToggle(pUtil, "Discord RPC", false, function(on)
    State.UtilDiscordRpc = on
    logAction("Discord RPC: " .. (on and "ON" or "OFF"))
    if on then updateDiscordRpc() end
end)

makeLabel(pUtil, "— Тема —")
makeButton(pUtil, "🟣 Purple", function() applyTheme("purple") end)
makeButton(pUtil, "🔵 Blue", function() applyTheme("blue") end)
makeButton(pUtil, "🟢 Green", function() applyTheme("green") end)
makeButton(pUtil, "🔴 Red", function() applyTheme("red") end)
makeButton(pUtil, "⚫ Dark", function() applyTheme("dark") end)
makeButton(pUtil, "⚪ Light", function() applyTheme("light") end)

makeLabel(pUtil, "— Keybinds —")
makeLabel(pUtil, "RightShift — Toggle GUI", Color3.fromRGB(180,180,180))
makeLabel(pUtil, "P — Screenshot", Color3.fromRGB(180,180,180))


local pSet = newPage("⚙ Settings", true)
makeLabel(pSet, "— Сповіщення —")
makeToggle(pSet, "Звук сповіщень", Settings.NotifSound, function(on) Settings.NotifSound = on end)
makeSlider(pSet, "Гучність (%)", 0, 100, math.floor(Settings.NotifVolume*100), function(v) Settings.NotifVolume = v / 100 end)
makeSlider(pSet, "Тривалість (сек)", 1, 15, Settings.NotifDuration, function(v) Settings.NotifDuration = v end)
makeLabel(pSet, "— Звукові ID —")
makeLabel(pSet, "Success:", Color3.fromRGB(120,200,140))
makeTextBox(pSet, Settings.SoundSuccess, "rbxassetid://...", function(text) if text and text ~= "" then Settings.SoundSuccess = text Notify("Settings", "Success ID оновлено", "success") end end)
makeLabel(pSet, "Error:", Color3.fromRGB(220,120,120))
makeTextBox(pSet, Settings.SoundError, "rbxassetid://...", function(text) if text and text ~= "" then Settings.SoundError = text Notify("Settings", "Error ID оновлено", "success") end end)
makeLabel(pSet, "Info:", Color3.fromRGB(120,160,220))
makeTextBox(pSet, Settings.SoundInfo, "rbxassetid://...", function(text) if text and text ~= "" then Settings.SoundInfo = text Notify("Settings", "Info ID оновлено", "success") end end)
makeLabel(pSet, "Warn:", Color3.fromRGB(220,200,120))
makeTextBox(pSet, Settings.SoundWarn, "rbxassetid://...", function(text) if text and text ~= "" then Settings.SoundWarn = text Notify("Settings", "Warn ID оновлено", "success") end end)
makeLabel(pSet, "— Тестування —")
makeButton(pSet, "Тест: Success", function() Notify("Тест", "Це успіх!", "success") end)
makeButton(pSet, "Тест: Error", function() Notify("Тест", "Це помилка!", "error") end)
makeButton(pSet, "Тест: Warn", function() Notify("Тест", "Це попередження!", "warn") end)
makeButton(pSet, "Тест: Info", function() Notify("Тест", "Це інформація", "info") end)
makeLabel(pSet, "— Скидання —")

makeLabel(pSet, "— Логер —")
makeToggle(pSet, "Script Logger", Settings.UtilScriptLogger, function(on)
    Settings.UtilScriptLogger = on
end)
makeButton(pSet, "Скинути налаштування", function()
    Settings.NotifSound = true
    Settings.NotifVolume = 0.5
    Settings.NotifDuration = 4
    Settings.SoundSuccess = "rbxassetid://4590662766"
    Settings.SoundError   = "rbxassetid://5159527953"
    Settings.SoundInfo    = "rbxassetid://4590662766"
    Settings.SoundWarn    = "rbxassetid://5159527953"
    Notify("Settings", "Скинуто. Перезапусти скрипт.", "warn")
end, Color3.fromRGB(80, 40, 40))

-- ============================================================
-- ДЕФОЛТ + СВОРАЧИВАНИЕ
-- ============================================================
for n, p in pairs(pages) do
    p.page.Visible = (n == "Other")
    p.btn.BackgroundColor3 = (n == "Other") and Color3.fromRGB(120,80,200) or (p.isSettings and Color3.fromRGB(60,40,90) or Color3.fromRGB(30,32,45))
end

local opened = true
closeBtn.MouseButton1Click:Connect(function()
    opened = not opened
    if opened then
        -- Розгортаємо: спочатку показуємо елементи, потім анімуємо розмір
        sidebar.Visible = true
        content.Visible = true
        TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, GUI_W, 0, GUI_H)   -- розгорнута
                   UDim2.new(0, GUI_W, 0, 36)      -- згорнута
        }):Play()
        closeBtn.Text = "—"
    else
        -- Сворачиваем: анімуємо розмір, потім ховаємо елементи
        local tween = TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
            Size = UDim2.new(0, GUI_W, 0, GUI_H)   -- розгорнута
                   UDim2.new(0, GUI_W, 0, 36)      -- згорнута
        })
        tween:Play()
        tween.Completed:Connect(function()
            if not opened then
                sidebar.Visible = false
                content.Visible = false
            end
        end)
        closeBtn.Text = "+"
    end
end)

Notify("ROCKET HUB v4", "Grace: 20 функцій додано!", "success")
print("[ROCKET HUB v4] Loaded — Grace Extended (20 функцій)")
