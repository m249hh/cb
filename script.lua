local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- =====================
-- COLORS
-- =====================
local chamColor    = Color3.fromRGB(114, 137, 218)
local BG_DEEP      = Color3.fromRGB(10, 10, 13)
local BG_MID       = Color3.fromRGB(14, 14, 18)
local BG_RAISED    = Color3.fromRGB(19, 19, 25)
local BG_HOVER     = Color3.fromRGB(25, 25, 33)
local BG_SIDEBAR   = Color3.fromRGB(11, 11, 15)
local BORDER       = Color3.fromRGB(33, 33, 43)
local BORDER_LIGHT = Color3.fromRGB(48, 48, 62)
local TEXT_PRIMARY = Color3.fromRGB(210, 210, 225)
local TEXT_DIM     = Color3.fromRGB(80, 80, 100)
local TEXT_SECTION = Color3.fromRGB(52, 52, 68)
local UI_ACCENT    = Color3.fromRGB(255, 255, 255)

-- =====================
-- STATE
-- =====================
local allHighlights      = {}
local allCheckLabels     = {}
local selfHighlight      = nil
local enemyHighlights    = {}
local colorCorrection    = nil
local selfChamsOn        = false
local enemyChamsOn       = false
local viewmodelChamsOn   = false
local lightingOn         = false
local rageBotOn          = false
local triggerbotOn       = false
local currentParticles   = nil
local particleType       = "Rain"
local rageFOVOn          = false
local rageFOVRadius      = 60
local rageFOVVisible     = false
local rageBone           = "Head"
local lockedTarget       = nil
local shootCooldown      = false
local thirdPersonOn      = false
local thirdPersonDistance = 10
local vanillaTPOn        = false
local bhopOn             = false
local noclipOn           = false
local currentFOV         = 90
local fovCircle          = nil
local rageFOVCircle      = nil
local spinbotOn          = false
local spinAngle          = 0
local antiAimOn          = false
local antiAimPitch       = 0
local antiAimYaw         = 180
local antiAimDirectional = false

local legitAimOn     = false
local legitTriggerOn = false
local legitFOVOn     = false
local legitSmoothing = 5
local legitFOVRadius = 80
local legitAimKey    = Enum.KeyCode.LeftAlt
local legitBone      = "Head"

local weaponStates = {
    NoSpread=false,InstantEquip=false,InstantReload=false,
    FastFirerate=false,MaxRange=false,MaxRangeMod=false,
    MaxDamage=false,MaxPenetration=false,MaxAmmoPen=false,
    MaxBullets=false,MaxAmmo=false,AlwaysAuto=false,AlwaysScoped=false,
}

-- =====================
-- CONFIG
-- =====================
local CONFIG_PATH = "private_cfg.cfg"
local foundConfigs = {}

local function getConfig()
    return {
        chamColorR=chamColor.R,chamColorG=chamColor.G,chamColorB=chamColor.B,
        rageFOVRadius=rageFOVRadius,legitSmoothing=legitSmoothing,
        legitFOVRadius=legitFOVRadius,legitBone=legitBone,rageBone=rageBone,
        thirdPersonDistance=thirdPersonDistance,currentFOV=currentFOV,
        antiAimYaw=antiAimYaw,antiAimPitch=antiAimPitch,
        noSpread=weaponStates.NoSpread,instantEquip=weaponStates.InstantEquip,
        instantReload=weaponStates.InstantReload,fastFirerate=weaponStates.FastFirerate,
        maxRange=weaponStates.MaxRange,maxRangeMod=weaponStates.MaxRangeMod,
        maxDamage=weaponStates.MaxDamage,maxPenetration=weaponStates.MaxPenetration,
        maxAmmoPen=weaponStates.MaxAmmoPen,maxBullets=weaponStates.MaxBullets,
        maxAmmo=weaponStates.MaxAmmo,alwaysAuto=weaponStates.AlwaysAuto,
        alwaysScoped=weaponStates.AlwaysScoped,
    }
end

local function applyConfigData(d)
    if d.chamColorR then chamColor=Color3.new(d.chamColorR,d.chamColorG,d.chamColorB) end
    rageFOVRadius=d.rageFOVRadius or 60
    legitSmoothing=d.legitSmoothing or 5
    legitFOVRadius=d.legitFOVRadius or 80
    legitBone=d.legitBone or "Head"
    rageBone=d.rageBone or "Head"
    thirdPersonDistance=d.thirdPersonDistance or 10
    currentFOV=d.currentFOV or 90
    antiAimYaw=d.antiAimYaw or 180
    antiAimPitch=d.antiAimPitch or 0
    weaponStates.NoSpread=d.noSpread or false
    weaponStates.InstantEquip=d.instantEquip or false
    weaponStates.InstantReload=d.instantReload or false
    weaponStates.FastFirerate=d.fastFirerate or false
    weaponStates.MaxRange=d.maxRange or false
    weaponStates.MaxRangeMod=d.maxRangeMod or false
    weaponStates.MaxDamage=d.maxDamage or false
    weaponStates.MaxPenetration=d.maxPenetration or false
    weaponStates.MaxAmmoPen=d.maxAmmoPen or false
    weaponStates.MaxBullets=d.maxBullets or false
    weaponStates.MaxAmmo=d.maxAmmo or false
    weaponStates.AlwaysAuto=d.alwaysAuto or false
    weaponStates.AlwaysScoped=d.alwaysScoped or false
end

local function saveConfig()
    pcall(function()
        writefile(CONFIG_PATH,HttpService:JSONEncode(getConfig()))
    end)
end

local function loadConfigFile(path)
    pcall(function()
        local encoded=readfile(path)
        if not encoded or encoded=="" then return end
        local d=HttpService:JSONDecode(encoded)
        if not d then return end
        applyConfigData(d)
    end)
end

local function scanConfigs()
    foundConfigs={}
    pcall(function()
        local files=listfiles("")
        for _,f in ipairs(files) do
            if f:lower():find("%.cfg") then
                table.insert(foundConfigs,f)
            end
        end
    end)
    return foundConfigs
end

local function loadConfig()
    pcall(function()
        local encoded=readfile(CONFIG_PATH)
        if not encoded or encoded=="" then return end
        local d=HttpService:JSONDecode(encoded)
        if not d then return end
        applyConfigData(d)
    end)
end

-- =====================
-- CHAMS
-- =====================
local function updateAllHighlightColors()
    for _,h in ipairs(allHighlights) do if h and h.Parent then h.FillColor=chamColor end end
end

local function makeHighlight(adornee)
    local existing=adornee:FindFirstChildOfClass("Highlight")
    if existing then existing.FillColor=chamColor return existing end
    local h=Instance.new("Highlight")
    h.Adornee=adornee h.FillColor=chamColor h.FillTransparency=0 h.OutlineTransparency=1 h.Parent=adornee
    table.insert(allHighlights,h) return h
end

local function enableSelfChams()
    local char=player.Character if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.LocalTransparencyModifier=1 end
    selfHighlight=makeHighlight(char)
end

local function disableSelfChams()
    if selfHighlight then selfHighlight:Destroy() selfHighlight=nil end
end

local function enableEnemyChams()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=player and p.Character then
            enemyHighlights[p.Name]=makeHighlight(p.Character)
        end
    end
end

local function disableEnemyChams()
    for _,h in pairs(enemyHighlights) do if h then h:Destroy() end end
    enemyHighlights={}
end

local function enableViewmodelChams()
    local function chamDesc(obj)
        for _,v in ipairs(obj:GetDescendants()) do
            if (v:IsA("BasePart") or v:IsA("MeshPart")) and not v:FindFirstChild("ViewmodelCham") then
                local h=makeHighlight(v) h.Name="ViewmodelCham"
            end
        end
    end
    chamDesc(workspace.CurrentCamera)
    for _,obj in ipairs(workspace:GetDescendants()) do
        local n=obj.Name:lower()
        if n:find("viewmodel") or n:find("vm") or n:find("arms") or n:find("firstperson") then chamDesc(obj) end
    end
    workspace.DescendantAdded:Connect(function(obj)
        if not viewmodelChamsOn then return end
        local n=obj.Name:lower()
        if n:find("viewmodel") or n:find("vm") or n:find("arms") or n:find("firstperson") then chamDesc(obj) end
        if obj:IsDescendantOf(workspace.CurrentCamera) then
            if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and not obj:FindFirstChild("ViewmodelCham") then
                local h=makeHighlight(obj) h.Name="ViewmodelCham"
            end
        end
    end)
end

local function disableViewmodelChams()
    for _,obj in ipairs(workspace:GetDescendants()) do
        local h=obj:FindFirstChild("ViewmodelCham") if h then h:Destroy() end
    end
    for _,obj in ipairs(workspace.CurrentCamera:GetDescendants()) do
        local h=obj:FindFirstChild("ViewmodelCham") if h then h:Destroy() end
    end
end

-- Brute force re-apply every 0.5s
task.spawn(function()
    while true do
        task.wait(0.5)
        if enemyChamsOn then
            for _,p in ipairs(Players:GetPlayers()) do
                if p==player then continue end
                local char=p.Character if not char then continue end
                local h=char:FindFirstChildOfClass("Highlight")
                if not h or h.FillColor~=chamColor then
                    if h then h:Destroy() end
                    local newH=Instance.new("Highlight")
                    newH.Adornee=char newH.FillColor=chamColor
                    newH.FillTransparency=0 newH.OutlineTransparency=1
                    newH.Parent=char
                    enemyHighlights[p.Name]=newH
                    table.insert(allHighlights,newH)
                end
            end
        end
        if selfChamsOn then
            local char=player.Character if not char then continue end
            local hrp=char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.LocalTransparencyModifier=1 end
            local h=char:FindFirstChildOfClass("Highlight")
            if not h or h.FillColor~=chamColor then
                if h then h:Destroy() end
                local newH=Instance.new("Highlight")
                newH.Adornee=char newH.FillColor=chamColor
                newH.FillTransparency=0 newH.OutlineTransparency=1
                newH.Parent=char
                selfHighlight=newH
                table.insert(allHighlights,newH)
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(char)
        if enemyChamsOn then task.wait(0.1) enemyHighlights[p.Name]=makeHighlight(char) end
    end)
end)

-- =====================
-- THIRD PERSON
-- =====================
local function disableThirdPerson()
    player.CameraMinZoomDistance=0.5 player.CameraMaxZoomDistance=400
end
local function enableVanillaTP()
    local tp=workspace:FindFirstChild("ThirdPerson")
    if tp and tp:IsA("BoolValue") then tp.Value=true end
end
local function disableVanillaTP()
    local tp=workspace:FindFirstChild("ThirdPerson")
    if tp and tp:IsA("BoolValue") then tp.Value=false end
end
RunService.RenderStepped:Connect(function()
    if not thirdPersonOn then return end
    player.CameraMode=Enum.CameraMode.Classic
    player.CameraMinZoomDistance=thirdPersonDistance
    player.CameraMaxZoomDistance=thirdPersonDistance
    camera.FieldOfView=currentFOV
end)

-- =====================
-- LIGHTING
-- =====================
local function enableLighting()
    for _,v in ipairs(Lighting:GetChildren()) do if v:IsA("ColorCorrectionEffect") then v:Destroy() end end
    Lighting.Ambient=Color3.fromRGB(80,20,100) Lighting.OutdoorAmbient=Color3.fromRGB(60,10,80)
    Lighting.Brightness=0.5 Lighting.ClockTime=0 Lighting.GeographicLatitude=0
    colorCorrection=Instance.new("ColorCorrectionEffect")
    colorCorrection.Brightness=0.05 colorCorrection.Contrast=0.1
    colorCorrection.Saturation=0.6 colorCorrection.TintColor=chamColor
    colorCorrection.Parent=Lighting
end
local function disableLighting()
    Lighting.Ambient=Color3.fromRGB(127,127,127) Lighting.OutdoorAmbient=Color3.fromRGB(127,127,127)
    Lighting.Brightness=2 Lighting.ClockTime=14
    if colorCorrection then colorCorrection:Destroy() colorCorrection=nil end
end
task.spawn(function() while true do task.wait(5) if lightingOn then enableLighting() end end end)

-- =====================
-- PARTICLES
-- =====================
local particleSettings={
    Rain={rate=200,speed=NumberRange.new(30,50),lifetime=NumberRange.new(0.5,1),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.05),NumberSequenceKeypoint.new(1,0.05)}),
        rotation=NumberRange.new(90,90),spread=Vector2.new(180,10),
        color=ColorSequence.new(Color3.fromRGB(180,200,255)),glow=0},
    Snow={rate=100,speed=NumberRange.new(3,8),lifetime=NumberRange.new(3,6),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(1,0.05)}),
        rotation=NumberRange.new(0,360),spread=Vector2.new(180,180),
        color=ColorSequence.new(Color3.fromRGB(240,245,255)),glow=0},
    Ash={rate=80,speed=NumberRange.new(1,4),lifetime=NumberRange.new(4,8),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.1),NumberSequenceKeypoint.new(1,0.02)}),
        rotation=NumberRange.new(0,360),spread=Vector2.new(180,180),
        color=ColorSequence.new(Color3.fromRGB(100,100,100)),glow=0},
    Embers={rate=60,speed=NumberRange.new(2,6),lifetime=NumberRange.new(2,4),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.08),NumberSequenceKeypoint.new(1,0)}),
        rotation=NumberRange.new(0,360),spread=Vector2.new(180,180),
        color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,100,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,200,0))}),glow=0.8},
    Leaves={rate=40,speed=NumberRange.new(2,5),lifetime=NumberRange.new(3,6),
        size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.2),NumberSequenceKeypoint.new(1,0.1)}),
        rotation=NumberRange.new(0,360),spread=Vector2.new(180,180),
        color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(80,140,40)),ColorSequenceKeypoint.new(1,Color3.fromRGB(180,100,20))}),glow=0},
}
local particleConn=nil
local function spawnParticles(pType)
    if currentParticles then currentParticles:Destroy() currentParticles=nil end
    if particleConn then particleConn:Disconnect() particleConn=nil end
    local s=particleSettings[pType] if not s then return end
    local part=Instance.new("Part")
    part.Size=Vector3.new(2048,1,2048) part.Anchored=true part.CanCollide=false
    part.Transparency=1 part.Name="ParticleEmitterPart" part.Parent=workspace
    local char=player.Character local hrp=char and char:FindFirstChild("HumanoidRootPart")
    part.Position=hrp and Vector3.new(hrp.Position.X,hrp.Position.Y+40,hrp.Position.Z) or Vector3.new(0,40,0)
    local e=Instance.new("ParticleEmitter")
    e.Texture="rbxasset://textures/particles/sparkles_main.dds"
    e.Rate=s.rate e.Speed=s.speed e.Lifetime=s.lifetime e.Size=s.size
    e.Rotation=s.rotation e.SpreadAngle=s.spread e.Color=s.color
    e.LightEmission=s.glow e.VelocityInheritance=0 e.Parent=part
    currentParticles=part
    particleConn=RunService.RenderStepped:Connect(function()
        if not currentParticles then return end
        local c=player.Character local h=c and c:FindFirstChild("HumanoidRootPart")
        if h then currentParticles.Position=Vector3.new(h.Position.X,h.Position.Y+40,h.Position.Z) end
    end)
end
local function stopParticles()
    if currentParticles then currentParticles:Destroy() currentParticles=nil end
    if particleConn then particleConn:Disconnect() particleConn=nil end
end

-- =====================
-- WEAPON VALUES
-- =====================
local function fuzz(b) return b+(math.random()*0.0004-0.0002) end

local function getFirerate()
    local weapons=RS:FindFirstChild("Weapons") if not weapons then return 0.1 end
    local char=player.Character if not char then return 0.1 end
    local equippedVal=char:FindFirstChild("EquippedTool")
    if not equippedVal or equippedVal.Value=="" then return 0.1 end
    local weapon=weapons:FindFirstChild(equippedVal.Value) if not weapon then return 0.1 end
    local fr=weapon:FindFirstChild("Firerate")
    if fr then return math.max(0.05,fr.Value) end
    return 0.1
end

task.spawn(function()
    while true do
        task.wait(1.5+math.random())
        local weapons=RS:FindFirstChild("Weapons") if not weapons then continue end
        local char=player.Character if not char then continue end
        local equippedVal=char:FindFirstChild("EquippedTool")
        if not equippedVal or equippedVal.Value=="" then continue end
        local weapon=weapons:FindFirstChild(equippedVal.Value) if not weapon then continue end

        local function set(name,val)
            local v=weapon:FindFirstChild(name)
            if v then pcall(function() v.Value=val end) end
        end
        local function setBool(name,val)
            local v=weapon:FindFirstChild(name)
            if v and v:IsA("BoolValue") then pcall(function() v.Value=val end) end
        end

        if weaponStates.NoSpread then
            local spread=weapon:FindFirstChild("Spread") if spread then
                for _,n in ipairs({"Crouch","Fire","InitialJump","Jump","Ladder","Land","Move","Recoil","Stand"}) do
                    local v=spread:FindFirstChild(n)
                    if v then pcall(function() v.Value=fuzz(0.001) end) end
                end
                local rt=spread:FindFirstChild("RecoveryTime")
                if rt then
                    pcall(function() rt.Value=fuzz(0.001) end)
                    local cr=rt:FindFirstChild("Crouched")
                    if cr then pcall(function() cr.Value=fuzz(0.001) end) end
                end
            end
        end

        if weaponStates.InstantEquip   then set("EquipTime",       fuzz(0.001)) end
        if weaponStates.InstantReload  then set("ReloadTime",      fuzz(0.001)) end
        if weaponStates.FastFirerate   then set("Firerate",        0.05)        end
        if weaponStates.MaxRange       then set("Range",           9999)        end
        if weaponStates.MaxRangeMod    then set("RangeModifier",   1)           end
        if weaponStates.MaxDamage      then set("Dmg",             9999)        end
        if weaponStates.MaxPenetration then set("Penetration",     9999)        end
        if weaponStates.MaxAmmoPen     then set("AmmoPenetration", 9999)        end
        if weaponStates.MaxBullets     then set("Bullets",         999)         end
        if weaponStates.MaxAmmo        then set("Ammo",            999)         end
        if weaponStates.AlwaysAuto     then setBool("Auto",        true)        end
        if weaponStates.AlwaysScoped   then setBool("Scoped",      true)        end
    end
end)

-- =====================
-- WALLCHECK (ragebot only)
-- =====================
local function hasLineOfSight(targetPart)
    local char=player.Character if not char then return false end
    local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return false end
    local rp=RaycastParams.new()
    rp.FilterDescendantsInstances={char,targetPart.Parent}
    rp.FilterType=Enum.RaycastFilterType.Exclude
    return workspace:Raycast(hrp.Position,targetPart.Position-hrp.Position,rp)==nil
end

-- =====================
-- TRIGGERBOT (no wallcheck, instant)
-- =====================
RunService.Stepped:Connect(function()
    if not triggerbotOn then return end
    if not UIS.WindowFocused then return end
    local unitRay=camera:ScreenPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    local rp=RaycastParams.new()
    rp.FilterDescendantsInstances={player.Character}
    rp.FilterType=Enum.RaycastFilterType.Exclude
    local result=workspace:Raycast(unitRay.Origin,unitRay.Direction*math.huge,rp)
    if result and result.Instance then
        local model=result.Instance:FindFirstAncestorOfClass("Model")
        if model then
            for _,p in ipairs(Players:GetPlayers()) do
                if p==player then continue end
                if player.Team and p.Team==player.Team then continue end
                if p.Character==model then
                    local hum=model:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health>0 then
                        mouse1press()
                        mouse1release()
                    end
                    break
                end
            end
        end
    end
end)

-- =====================
-- LEGITBOT
-- =====================
local function getClosestEnemy(fovRadius,bone)
    local closest=nil local closestDist=fovRadius
    local center=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if p==player then continue end
        if player.Team and p.Team==player.Team then continue end
        local char=p.Character if not char then continue end
        local boneP=char:FindFirstChild(bone) or char:FindFirstChild("HumanoidRootPart")
        local hum=char:FindFirstChildOfClass("Humanoid")
        if not boneP or not hum or hum.Health<=0 then continue end
        if not hasLineOfSight(boneP) then continue end
        local screenPos,onScreen=camera:WorldToViewportPoint(boneP.Position)
        if not onScreen then continue end
        local dist=(Vector2.new(screenPos.X,screenPos.Y)-center).Magnitude
        if dist<closestDist then closestDist=dist closest={p=p,screenPos=Vector2.new(screenPos.X,screenPos.Y),bone=boneP} end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not legitAimOn then return end
    if not UIS.WindowFocused then return end
    if not UIS:IsKeyDown(legitAimKey) then return end
    local target=getClosestEnemy(legitFOVRadius,legitBone) if not target then return end
    local center=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    local delta=target.screenPos-center
    mousemoverel(delta.X/math.max(1,legitSmoothing),delta.Y/math.max(1,legitSmoothing))
    if legitTriggerOn and delta.Magnitude<8 then mouse1press() mouse1release() end
end)

-- =====================
-- RAGEBOT (wallcheck enabled)
-- =====================
local function getTargetPosition()
    if not lockedTarget then return nil end
    local pchar=lockedTarget.Character if not pchar then return nil end
    local bone=pchar:FindFirstChild(rageBone) or pchar:FindFirstChild("HumanoidRootPart")
    local hum=pchar:FindFirstChildOfClass("Humanoid")
    if not bone or not hum or hum.Health<=0 then return nil end
    if not hasLineOfSight(bone) then return nil end
    return bone.Position
end

RunService.Stepped:Connect(function()
    if not rageFOVOn then return end
    if not UIS.WindowFocused then return end
    if shootCooldown then return end
    local center=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    if lockedTarget then
        local pchar=lockedTarget.Character
        local bone=pchar and (pchar:FindFirstChild(rageBone) or pchar:FindFirstChild("HumanoidRootPart"))
        local hum=pchar and pchar:FindFirstChildOfClass("Humanoid")
        if not pchar or not bone or not hum or hum.Health<=0 or not hasLineOfSight(bone) then
            lockedTarget=nil
        else
            local sp,on=camera:WorldToViewportPoint(bone.Position)
            if not on or (Vector2.new(sp.X,sp.Y)-center).Magnitude>rageFOVRadius then lockedTarget=nil end
        end
    end
    if not lockedTarget then
        local cd=rageFOVRadius
        for _,p in ipairs(Players:GetPlayers()) do
            if p==player then continue end
            if player.Team and p.Team==player.Team then continue end
            local pc=p.Character if not pc then continue end
            local bone=pc:FindFirstChild(rageBone) or pc:FindFirstChild("HumanoidRootPart")
            local hum=pc:FindFirstChildOfClass("Humanoid")
            if not bone or not hum or hum.Health<=0 then continue end
            if not hasLineOfSight(bone) then continue end
            local sp,on=camera:WorldToViewportPoint(bone.Position)
            if not on then continue end
            local dist=(Vector2.new(sp.X,sp.Y)-center).Magnitude
            if dist<cd then cd=dist lockedTarget=p end
        end
    end
end)

RunService:BindToRenderStep("RageAim",Enum.RenderPriority.Camera.Value+1,function()
    if not rageFOVOn then return end
    if not UIS.WindowFocused then return end
    local targetPos=getTargetPosition() if not targetPos then return end
    camera.CFrame=CFrame.lookAt(camera.CFrame.Position,targetPos)
    local center=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
    local sp=camera:WorldToViewportPoint(targetPos)
    local delta=Vector2.new(sp.X,sp.Y)-center
    if delta.Magnitude>0.5 then mousemoverel(delta.X,delta.Y) end
    if triggerbotOn and delta.Magnitude<5 and not shootCooldown then
        local char=lockedTarget and lockedTarget.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            mouse1press() mouse1release()
            shootCooldown=true
            task.delay(getFirerate(),function() shootCooldown=false end)
        end
    end
end)

-- =====================
-- SPINBOT
-- =====================
RunService.RenderStepped:Connect(function()
    if not spinbotOn then return end
    spinAngle=(spinAngle+20)%360
    camera.CFrame=camera.CFrame*CFrame.Angles(0,math.rad(20),0)
end)

-- =====================
-- ANTI AIM
-- =====================
RunService.Stepped:Connect(function()
    if not antiAimOn then return end
    local char=player.Character if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local upperTorso=char:FindFirstChild("UpperTorso")
    if not hrp or not upperTorso then return end
    local waist=upperTorso:FindFirstChild("Waist")
    local neck=upperTorso:FindFirstChild("Neck")
    if not waist then return end
    local camLook=camera.CFrame.LookVector
    local camYaw=math.deg(math.atan2(-camLook.X,-camLook.Z))
    local finalYaw=camYaw+antiAimYaw
    if antiAimDirectional then
        local vel=hrp.AssemblyLinearVelocity
        local flatVel=Vector3.new(vel.X,0,vel.Z)
        if flatVel.Magnitude>0.5 then
            finalYaw=math.deg(math.atan2(flatVel.X,flatVel.Z))+antiAimYaw+90
        end
    end
    local hrpYaw=math.deg(math.atan2(-hrp.CFrame.LookVector.X,-hrp.CFrame.LookVector.Z))
    local relYaw=finalYaw-hrpYaw
    waist.Transform=CFrame.Angles(math.rad(antiAimPitch),math.rad(relYaw),0)
    if neck then neck.Transform=CFrame.Angles(math.rad(-antiAimPitch),math.rad(-relYaw),0) end
end)

-- =====================
-- BHOP
-- =====================
local BHOP={Speed=100,Smoothness=0.2,RayDistance=-4}
RunService.Heartbeat:Connect(function()
    if not bhopOn then return end
    local char=player.Character if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then
        local rp=RaycastParams.new()
        rp.FilterDescendantsInstances={char} rp.FilterType=Enum.RaycastFilterType.Exclude
        local ground=workspace:Raycast(hrp.Position,Vector3.new(0,BHOP.RayDistance,0),rp)
        if ground then hum.Jump=true end
    end
    local ok,dir=pcall(function()
        local d=Vector3.zero
        local look=camera.CFrame.LookVector local right=camera.CFrame.RightVector
        if UIS:IsKeyDown(Enum.KeyCode.W) then d+=look end
        if UIS:IsKeyDown(Enum.KeyCode.S) then d-=look end
        if UIS:IsKeyDown(Enum.KeyCode.A) then d-=right end
        if UIS:IsKeyDown(Enum.KeyCode.D) then d+=right end
        return Vector3.new(d.X,0,d.Z).Unit
    end)
    if ok and dir.Magnitude>0 then
        local vel=hrp.AssemblyLinearVelocity
        local move=dir*BHOP.Speed
        hrp.AssemblyLinearVelocity=Vector3.new(
            vel.X+(move.X-vel.X)*BHOP.Smoothness,vel.Y,
            vel.Z+(move.Z-vel.Z)*BHOP.Smoothness)
    end
end)

-- =====================
-- NOCLIP
-- =====================
RunService.Heartbeat:Connect(function()
    if not noclipOn then return end
    local char=player.Character if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local moveDir=Vector3.zero
    local look=camera.CFrame.LookVector
    local right=camera.CFrame.RightVector
    if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir+=look end
    if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir-=look end
    if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir-=right end
    if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir+=right end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir+=Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir-=Vector3.new(0,1,0) end
    if moveDir.Magnitude>0 then hrp.CFrame=hrp.CFrame+moveDir.Unit*1.5 end
    hrp.Velocity=Vector3.zero
    hrp.RotVelocity=Vector3.zero
end)

local function enableRageBot()
    loadstring(game:HttpGet("https://pastebin.com/raw/Wgknj1kR"))()
end

-- =====================
-- UI HELPERS
-- =====================
local function makeCorner(p,r) local c=Instance.new("UICorner",p) c.CornerRadius=UDim.new(0,r or 4) return c end
local function makeStroke(p,c,t)
    local s=Instance.new("UIStroke",p) s.Color=c or BORDER s.Thickness=t or 1
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border return s
end
local function makePadding(p,t,b,l,r)
    local pad=Instance.new("UIPadding",p)
    pad.PaddingTop=UDim.new(0,t or 0) pad.PaddingBottom=UDim.new(0,b or 0)
    pad.PaddingLeft=UDim.new(0,l or 0) pad.PaddingRight=UDim.new(0,r or 0)
end

-- =====================
-- UI ROOT
-- =====================
local screenGui=Instance.new("ScreenGui")
screenGui.Name="NL" screenGui.ResetOnSpawn=false screenGui.IgnoreGuiInset=true
screenGui.DisplayOrder=9999 screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
screenGui.Parent=player.PlayerGui

fovCircle=Drawing.new("Circle")
fovCircle.Visible=false fovCircle.Radius=legitFOVRadius fovCircle.Color=Color3.fromRGB(255,255,255)
fovCircle.Thickness=1 fovCircle.Filled=false fovCircle.NumSides=64
fovCircle.Position=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)

rageFOVCircle=Drawing.new("Circle")
rageFOVCircle.Visible=false rageFOVCircle.Radius=rageFOVRadius
rageFOVCircle.Color=Color3.fromRGB(255,80,80) rageFOVCircle.Thickness=1
rageFOVCircle.Filled=false rageFOVCircle.NumSides=64
rageFOVCircle.Position=Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)

RunService.RenderStepped:Connect(function()
    local cx=camera.ViewportSize.X/2 local cy=camera.ViewportSize.Y/2
    if fovCircle then fovCircle.Position=Vector2.new(cx,cy) fovCircle.Radius=legitFOVRadius end
    if rageFOVCircle then rageFOVCircle.Position=Vector2.new(cx,cy) rageFOVCircle.Radius=rageFOVRadius end
end)

local window=Instance.new("Frame",screenGui)
window.Size=UDim2.new(0,720,0,440)
window.Position=UDim2.new(0.5,-360,0.5,-220)
window.BackgroundColor3=BG_MID window.BorderSizePixel=0
window.Active=true window.Draggable=false
makeCorner(window,5) makeStroke(window,BORDER,1)

local shadow=Instance.new("ImageLabel",window)
shadow.Size=UDim2.new(1,40,1,40) shadow.Position=UDim2.new(0,-20,0,-20)
shadow.BackgroundTransparency=1 shadow.Image="rbxassetid://5028857084"
shadow.ImageColor3=Color3.new(0,0,0) shadow.ImageTransparency=0.75
shadow.ScaleType=Enum.ScaleType.Slice shadow.SliceCenter=Rect.new(24,24,276,276)
shadow.ZIndex=0

local titlebar=Instance.new("Frame",window)
titlebar.Size=UDim2.new(1,0,0,48) titlebar.BackgroundColor3=BG_DEEP
titlebar.BorderSizePixel=0 titlebar.ZIndex=2 titlebar.Active=true
makeCorner(titlebar,5)
local titleFill=Instance.new("Frame",titlebar)
titleFill.Size=UDim2.new(1,0,0,8) titleFill.Position=UDim2.new(0,0,1,-8)
titleFill.BackgroundColor3=BG_DEEP titleFill.BorderSizePixel=0 titleFill.ZIndex=2
local logoDot=Instance.new("ImageLabel",titlebar)
logoDot.Size=UDim2.new(0,32,0,32) logoDot.Position=UDim2.new(0,10,0.5,-16)
logoDot.BackgroundTransparency=1 logoDot.Image="rbxassetid://126303338963508"
logoDot.ZIndex=3
local titleText=Instance.new("TextLabel",titlebar)
titleText.Size=UDim2.new(1,-56,1,0) titleText.Position=UDim2.new(0,50,0,0)
titleText.BackgroundTransparency=1 titleText.Text="reduxware"
titleText.TextColor3=Color3.fromRGB(210,210,225) titleText.TextSize=15
titleText.Font=Enum.Font.GothamBold titleText.TextXAlignment=Enum.TextXAlignment.Left
titleText.ZIndex=3

local dragging,dragStart,startPos=false,nil,nil
titlebar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true dragStart=i.Position startPos=window.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-dragStart
        window.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
end)

local accentBar=Instance.new("Frame",window)
accentBar.Size=UDim2.new(1,0,0,1) accentBar.Position=UDim2.new(0,0,0,48)
accentBar.BackgroundColor3=UI_ACCENT accentBar.BackgroundTransparency=0.5
accentBar.BorderSizePixel=0 accentBar.ZIndex=2

local sidebar=Instance.new("Frame",window)
sidebar.Size=UDim2.new(0,110,1,-49) sidebar.Position=UDim2.new(0,0,0,49)
sidebar.BackgroundColor3=BG_SIDEBAR sidebar.BorderSizePixel=0 sidebar.ZIndex=2

local sidebarLine=Instance.new("Frame",window)
sidebarLine.Size=UDim2.new(0,1,1,-49) sidebarLine.Position=UDim2.new(0,110,0,49)
sidebarLine.BackgroundColor3=BORDER sidebarLine.BorderSizePixel=0 sidebarLine.ZIndex=2

local tabList=Instance.new("UIListLayout",sidebar)
tabList.Padding=UDim.new(0,1) tabList.HorizontalAlignment=Enum.HorizontalAlignment.Center
makePadding(sidebar,6,6,0,0)

local contentArea=Instance.new("Frame",window)
contentArea.Size=UDim2.new(1,-111,1,-49) contentArea.Position=UDim2.new(0,111,0,49)
contentArea.BackgroundTransparency=1 contentArea.BorderSizePixel=0
contentArea.ClipsDescendants=true

-- =====================
-- TAB SYSTEM
-- =====================
local tabs={} local pages={} local activeTab=nil

local function newPage()
    local page=Instance.new("ScrollingFrame",contentArea)
    page.Size=UDim2.new(1,0,1,0) page.BackgroundTransparency=1
    page.BorderSizePixel=0 page.ScrollBarThickness=2
    page.ScrollBarImageColor3=UI_ACCENT page.ScrollBarImageTransparency=0.5
    page.CanvasSize=UDim2.new(0,0,0,0) page.AutomaticCanvasSize=Enum.AutomaticSize.Y
    page.Visible=false
    local cols=Instance.new("Frame",page)
    cols.Size=UDim2.new(1,0,1,0) cols.BackgroundTransparency=1 cols.BorderSizePixel=0
    makePadding(cols,10,10,12,12)
    local cl=Instance.new("UIListLayout",cols)
    cl.FillDirection=Enum.FillDirection.Horizontal cl.Padding=UDim.new(0,10)
    cl.VerticalAlignment=Enum.VerticalAlignment.Top
    local col1=Instance.new("Frame",cols)
    col1.Size=UDim2.new(0.5,-5,1,0) col1.BackgroundTransparency=1 col1.BorderSizePixel=0
    local l1=Instance.new("UIListLayout",col1) l1.Padding=UDim.new(0,3)
    local col2=Instance.new("Frame",cols)
    col2.Size=UDim2.new(0.5,-5,1,0) col2.BackgroundTransparency=1 col2.BorderSizePixel=0
    local l2=Instance.new("UIListLayout",col2) l2.Padding=UDim.new(0,3)
    return page,col1,col2
end

local function selectTab(name)
    for n,data in pairs(tabs) do
        local isActive=n==name
        data.btn.BackgroundColor3=isActive and BG_HOVER or BG_SIDEBAR
        data.btn.TextColor3=isActive and TEXT_PRIMARY or TEXT_DIM
        data.accent.Visible=isActive
        pages[n].page.Visible=isActive
    end
    activeTab=name
end

local function addTab(name)
    local btn=Instance.new("TextButton",sidebar)
    btn.Size=UDim2.new(1,-2,0,30) btn.BackgroundColor3=BG_SIDEBAR
    btn.BorderSizePixel=0 btn.Text=name btn.TextColor3=TEXT_DIM
    btn.TextSize=11 btn.Font=Enum.Font.GothamBold btn.ZIndex=3
    makeCorner(btn,3)
    local accent=Instance.new("Frame",btn)
    accent.Size=UDim2.new(0,2,0.6,0) accent.Position=UDim2.new(0,0,0.2,0)
    accent.BackgroundColor3=UI_ACCENT accent.BorderSizePixel=0 accent.Visible=false
    makeCorner(accent,2)
    btn.MouseEnter:Connect(function()
        if activeTab~=name then
            TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=BG_RAISED,TextColor3=Color3.fromRGB(140,140,160)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab~=name then
            TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=BG_SIDEBAR,TextColor3=TEXT_DIM}):Play()
        end
    end)
    local page,col1,col2=newPage()
    tabs[name]={btn=btn,accent=accent}
    pages[name]={page=page,col1=col1,col2=col2}
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return col1,col2
end

-- =====================
-- COMPONENTS
-- =====================
local function addSection(col,text)
    local wrap=Instance.new("Frame",col)
    wrap.Size=UDim2.new(1,0,0,24) wrap.BackgroundTransparency=1 wrap.BorderSizePixel=0
    local lbl=Instance.new("TextLabel",wrap)
    lbl.Size=UDim2.new(1,0,0,13) lbl.Position=UDim2.new(0,0,1,-14)
    lbl.BackgroundTransparency=1 lbl.Text=text:upper() lbl.TextColor3=TEXT_SECTION
    lbl.TextSize=9 lbl.Font=Enum.Font.GothamBold lbl.TextXAlignment=Enum.TextXAlignment.Left
    local line=Instance.new("Frame",wrap)
    line.Size=UDim2.new(1,0,0,1) line.Position=UDim2.new(0,0,1,-1)
    line.BackgroundColor3=BORDER line.BorderSizePixel=0
end

local function addToggle(col,label,callback)
    local row=Instance.new("Frame",col)
    row.Size=UDim2.new(1,0,0,24) row.BackgroundColor3=BG_RAISED
    row.BorderSizePixel=0 makeCorner(row,3) makeStroke(row,BORDER,1)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(1,-28,1,0) lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(185,185,200) lbl.TextSize=11
    lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left
    local box=Instance.new("Frame",row)
    box.Size=UDim2.new(0,11,0,11) box.Position=UDim2.new(1,-18,0.5,-5)
    box.BackgroundColor3=BG_MID box.BorderSizePixel=0
    makeCorner(box,2) makeStroke(box,BORDER_LIGHT,1)
    local check=Instance.new("TextLabel",box)
    check.Size=UDim2.new(1,0,1,0) check.BackgroundTransparency=1
    check.Text="✓" check.TextColor3=UI_ACCENT check.TextSize=8
    check.Font=Enum.Font.GothamBold check.Visible=false
    table.insert(allCheckLabels,check)
    local on=false
    local btn=Instance.new("TextButton",row)
    btn.Size=UDim2.new(1,0,1,0) btn.BackgroundTransparency=1 btn.Text="" btn.ZIndex=2
    btn.MouseEnter:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.08),{BackgroundColor3=BG_HOVER}):Play()
        TweenService:Create(lbl,TweenInfo.new(0.08),{TextColor3=TEXT_PRIMARY}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(row,TweenInfo.new(0.08),{BackgroundColor3=BG_RAISED}):Play()
        TweenService:Create(lbl,TweenInfo.new(0.08),{TextColor3=Color3.fromRGB(185,185,200)}):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        on=not on check.Visible=on
        if on then
            box.BackgroundColor3=Color3.fromRGB(18,28,48)
            TweenService:Create(box:FindFirstChildOfClass("UIStroke"),TweenInfo.new(0.1),{Color=UI_ACCENT}):Play()
            TweenService:Create(lbl,TweenInfo.new(0.1),{TextColor3=TEXT_PRIMARY}):Play()
        else
            box.BackgroundColor3=BG_MID
            TweenService:Create(box:FindFirstChildOfClass("UIStroke"),TweenInfo.new(0.1),{Color=BORDER_LIGHT}):Play()
            TweenService:Create(lbl,TweenInfo.new(0.1),{TextColor3=Color3.fromRGB(185,185,200)}):Play()
        end
        callback(on)
    end)
end

local function addButton(col,label,callback)
    local btn=Instance.new("TextButton",col)
    btn.Size=UDim2.new(1,0,0,24) btn.BackgroundColor3=BG_RAISED
    btn.BorderSizePixel=0 btn.Text=label btn.TextColor3=UI_ACCENT
    btn.TextSize=11 btn.Font=Enum.Font.GothamBold
    makeCorner(btn,3) makeStroke(btn,BORDER,1)
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=BG_HOVER}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=BG_RAISED}):Play() end)
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

local function addColorSlider(col,label)
    local container=Instance.new("Frame",col)
    container.Size=UDim2.new(1,0,0,40) container.BackgroundColor3=BG_RAISED
    container.BorderSizePixel=0 makeCorner(container,3) makeStroke(container,BORDER,1)
    local lbl=Instance.new("TextLabel",container)
    lbl.Size=UDim2.new(0.6,0,0,16) lbl.Position=UDim2.new(0,8,0,3)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(185,185,200) lbl.TextSize=11
    lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left
    local preview=Instance.new("Frame",container)
    preview.Size=UDim2.new(0,9,0,9) preview.Position=UDim2.new(1,-17,0,4)
    preview.BackgroundColor3=chamColor preview.BorderSizePixel=0 makeCorner(preview,2)
    local track=Instance.new("Frame",container)
    track.Size=UDim2.new(1,-16,0,5) track.Position=UDim2.new(0,8,0,26)
    track.BackgroundColor3=Color3.fromRGB(22,22,30) track.BorderSizePixel=0
    track.Active=true makeCorner(track,99)
    local grad=Instance.new("UIGradient",track)
    grad.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(255,0,0)),
        ColorSequenceKeypoint.new(0.17,Color3.fromRGB(255,165,0)),
        ColorSequenceKeypoint.new(0.33,Color3.fromRGB(255,255,0)),
        ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,255,0)),
        ColorSequenceKeypoint.new(0.67,Color3.fromRGB(0,120,255)),
        ColorSequenceKeypoint.new(0.83,Color3.fromRGB(114,0,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(255,0,200)),
    })
    local handle=Instance.new("Frame",track)
    handle.Size=UDim2.new(0,9,0,9) handle.AnchorPoint=Vector2.new(0.5,0.5)
    handle.Position=UDim2.new(0.67,0,0.5,0) handle.BackgroundColor3=Color3.fromRGB(240,240,245)
    handle.BorderSizePixel=0 handle.ZIndex=4 makeCorner(handle,99) makeStroke(handle,Color3.fromRGB(45,45,60),1)
    local hueStops={{0,Color3.fromRGB(255,0,0)},{0.17,Color3.fromRGB(255,165,0)},{0.33,Color3.fromRGB(255,255,0)},
        {0.5,Color3.fromRGB(0,255,0)},{0.67,Color3.fromRGB(0,120,255)},{0.83,Color3.fromRGB(114,0,255)},{1,Color3.fromRGB(255,0,200)}}
    local function lerpC(a,b,t) return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t) end
    local function getC(t)
        t=math.clamp(t,0,1)
        for i=1,#hueStops-1 do
            local t0,c0=hueStops[i][1],hueStops[i][2]
            local t1,c1=hueStops[i+1][1],hueStops[i+1][2]
            if t>=t0 and t<=t1 then return lerpC(c0,c1,(t-t0)/(t1-t0)) end
        end
        return hueStops[#hueStops][2]
    end
    local function applyC(t)
        local color=getC(t) chamColor=color
        handle.Position=UDim2.new(t,0,0.5,0) preview.BackgroundColor3=color
        updateAllHighlightColors()
        if colorCorrection then colorCorrection.TintColor=color end
    end
    local isDragging=false
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            isDragging=true
            applyC(math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1))
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if isDragging and i.UserInputType==Enum.UserInputType.MouseMovement then
            applyC(math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1))
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then isDragging=false end
    end)
end

local function addSlider(col,label,min,max,default,callback)
    local container=Instance.new("Frame",col)
    container.Size=UDim2.new(1,0,0,40) container.BackgroundColor3=BG_RAISED
    container.BorderSizePixel=0 makeCorner(container,3) makeStroke(container,BORDER,1)
    local lbl=Instance.new("TextLabel",container)
    lbl.Size=UDim2.new(0.6,0,0,16) lbl.Position=UDim2.new(0,8,0,3)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(185,185,200) lbl.TextSize=11
    lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left
    local valLbl=Instance.new("TextLabel",container)
    valLbl.Size=UDim2.new(0.4,-8,0,16) valLbl.Position=UDim2.new(0.6,0,0,3)
    valLbl.BackgroundTransparency=1 valLbl.Text=tostring(default)
    valLbl.TextColor3=UI_ACCENT valLbl.TextSize=10
    valLbl.Font=Enum.Font.GothamBold valLbl.TextXAlignment=Enum.TextXAlignment.Right
    local track=Instance.new("Frame",container)
    track.Size=UDim2.new(1,-16,0,4) track.Position=UDim2.new(0,8,0,27)
    track.BackgroundColor3=Color3.fromRGB(22,22,30) track.BorderSizePixel=0
    track.Active=true makeCorner(track,99)
    local fill=Instance.new("Frame",track)
    fill.Size=UDim2.new((default-min)/(max-min),0,1,0) fill.BackgroundColor3=UI_ACCENT
    fill.BorderSizePixel=0 makeCorner(fill,99)
    local handle=Instance.new("Frame",track)
    handle.Size=UDim2.new(0,9,0,9) handle.AnchorPoint=Vector2.new(0.5,0.5)
    handle.Position=UDim2.new((default-min)/(max-min),0,0.5,0)
    handle.BackgroundColor3=Color3.fromRGB(240,240,245) handle.BorderSizePixel=0
    handle.ZIndex=4 makeCorner(handle,99) makeStroke(handle,Color3.fromRGB(45,45,60),1)
    local isDragging=false
    local function update(x)
        local t=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
        local val=math.floor(min+(max-min)*t)
        handle.Position=UDim2.new(t,0,0.5,0) fill.Size=UDim2.new(t,0,1,0)
        valLbl.Text=tostring(val) callback(val)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then isDragging=true update(i.Position.X) end
    end)
    UIS.InputChanged:Connect(function(i)
        if isDragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then isDragging=false end
    end)
end

local function addDropdown(col,label,options,default,callback)
    local container=Instance.new("Frame",col)
    container.Size=UDim2.new(1,0,0,24) container.BackgroundColor3=BG_RAISED
    container.BorderSizePixel=0 container.ClipsDescendants=false container.ZIndex=5
    makeCorner(container,3) makeStroke(container,BORDER,1)
    local lbl=Instance.new("TextLabel",container)
    lbl.Size=UDim2.new(0.5,0,1,0) lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(185,185,200) lbl.TextSize=11
    lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=5
    local dropBtn=Instance.new("TextButton",container)
    dropBtn.Size=UDim2.new(0.5,-8,1,0) dropBtn.Position=UDim2.new(0.5,0,0,0)
    dropBtn.BackgroundTransparency=1 dropBtn.Text=default.."  ▾"
    dropBtn.TextColor3=UI_ACCENT dropBtn.TextSize=10
    dropBtn.Font=Enum.Font.GothamBold dropBtn.TextXAlignment=Enum.TextXAlignment.Right dropBtn.ZIndex=6
    local menu=Instance.new("Frame",container)
    menu.Size=UDim2.new(1,0,0,0) menu.Position=UDim2.new(0,0,1,1)
    menu.BackgroundColor3=BG_DEEP menu.BorderSizePixel=0
    menu.ClipsDescendants=true menu.ZIndex=10 menu.Visible=false
    makeCorner(menu,3) makeStroke(menu,BORDER_LIGHT,1)
    Instance.new("UIListLayout",menu).Padding=UDim.new(0,0)
    local isOpen=false
    for _,opt in ipairs(options) do
        local ob=Instance.new("TextButton",menu)
        ob.Size=UDim2.new(1,0,0,22) ob.BackgroundColor3=BG_DEEP ob.BorderSizePixel=0
        ob.Text=opt ob.TextColor3=Color3.fromRGB(160,160,175) ob.TextSize=10
        ob.Font=Enum.Font.Gotham ob.ZIndex=11
        ob.MouseEnter:Connect(function() TweenService:Create(ob,TweenInfo.new(0.06),{BackgroundColor3=BG_HOVER,TextColor3=TEXT_PRIMARY}):Play() end)
        ob.MouseLeave:Connect(function() TweenService:Create(ob,TweenInfo.new(0.06),{BackgroundColor3=BG_DEEP,TextColor3=Color3.fromRGB(160,160,175)}):Play() end)
        ob.MouseButton1Click:Connect(function()
            dropBtn.Text=opt.."  ▾" isOpen=false menu.Visible=false
            TweenService:Create(menu,TweenInfo.new(0.1),{Size=UDim2.new(1,0,0,0)}):Play()
            callback(opt)
        end)
    end
    dropBtn.MouseButton1Click:Connect(function()
        isOpen=not isOpen menu.Visible=true
        TweenService:Create(menu,TweenInfo.new(0.12),{Size=UDim2.new(1,0,0,isOpen and #options*22 or 0)}):Play()
        if not isOpen then task.delay(0.12,function() menu.Visible=false end) end
    end)
end

local function addKeybind(col,label,default,callback)
    local row=Instance.new("Frame",col)
    row.Size=UDim2.new(1,0,0,24) row.BackgroundColor3=BG_RAISED
    row.BorderSizePixel=0 makeCorner(row,3) makeStroke(row,BORDER,1)
    local lbl=Instance.new("TextLabel",row)
    lbl.Size=UDim2.new(0.5,0,1,0) lbl.Position=UDim2.new(0,8,0,0)
    lbl.BackgroundTransparency=1 lbl.Text=label
    lbl.TextColor3=Color3.fromRGB(185,185,200) lbl.TextSize=11
    lbl.Font=Enum.Font.Gotham lbl.TextXAlignment=Enum.TextXAlignment.Left
    local keyBtn=Instance.new("TextButton",row)
    keyBtn.Size=UDim2.new(0.5,-8,1,0) keyBtn.Position=UDim2.new(0.5,0,0,0)
    keyBtn.BackgroundTransparency=1
    keyBtn.Text="[ "..tostring(default):gsub("Enum.KeyCode.","").." ]"
    keyBtn.TextColor3=UI_ACCENT keyBtn.TextSize=10
    keyBtn.Font=Enum.Font.GothamBold keyBtn.TextXAlignment=Enum.TextXAlignment.Right
    local listening=false
    keyBtn.MouseButton1Click:Connect(function()
        listening=true keyBtn.Text="[ ... ]" keyBtn.TextColor3=Color3.fromRGB(255,200,50)
    end)
    UIS.InputBegan:Connect(function(i)
        if not listening then return end
        if i.UserInputType==Enum.UserInputType.Keyboard then
            listening=false
            keyBtn.Text="[ "..tostring(i.KeyCode):gsub("Enum.KeyCode.","").." ]"
            keyBtn.TextColor3=UI_ACCENT callback(i.KeyCode)
        end
    end)
end

-- =====================
-- BUILD TABS
-- =====================

-- VISUALS
local v1,v2=addTab("Visuals")
addSection(v1,"Chams")
addToggle(v1,"Self Chams",function(on) selfChamsOn=on if on then enableSelfChams() else disableSelfChams() end end)
addToggle(v1,"Enemy Chams",function(on) enemyChamsOn=on if on then enableEnemyChams() else disableEnemyChams() end end)
addToggle(v1,"Viewmodel Chams",function(on) viewmodelChamsOn=on if on then enableViewmodelChams() else disableViewmodelChams() end end)
addSection(v1,"Camera")
addToggle(v1,"Third Person",function(on) thirdPersonOn=on if not on then disableThirdPerson() end end)
addSlider(v1,"Distance",5,50,10,function(val) thirdPersonDistance=val end)
addSlider(v1,"FOV",50,120,90,function(val) currentFOV=val camera.FieldOfView=val end)
addToggle(v1,"Vanilla TP",function(on) vanillaTPOn=on if on then enableVanillaTP() else disableVanillaTP() end end)
addSection(v2,"Color")
addColorSlider(v2,"Chams Color")

-- LEGITBOT
local lb1,lb2=addTab("Legitbot")
addSection(lb1,"Aimbot")
addToggle(lb1,"Enable Aim",function(on) legitAimOn=on end)
addToggle(lb1,"Auto Shoot",function(on) legitTriggerOn=on end)
addToggle(lb1,"Show FOV",function(on) legitFOVOn=on if fovCircle then fovCircle.Visible=on end end)
addSection(lb1,"Settings")
addSlider(lb1,"Smoothing",1,30,5,function(val) legitSmoothing=val end)
addSlider(lb1,"FOV Radius",10,300,80,function(val) legitFOVRadius=val if fovCircle then fovCircle.Radius=val end end)
addSection(lb2,"Bone")
addDropdown(lb2,"Target",{"Head","HumanoidRootPart","UpperTorso","LowerTorso"},"Head",function(val) legitBone=val end)
addSection(lb2,"Key")
addKeybind(lb2,"Aim Key",Enum.KeyCode.LeftAlt,function(key) legitAimKey=key end)

-- RAGEBOT
local r1,r2=addTab("Ragebot")
addSection(r1,"Aimbot")
addToggle(r1,"Enable Aim",function(on) rageFOVOn=on if not on then lockedTarget=nil end end)
addToggle(r1,"Show FOV",function(on) rageFOVVisible=on if rageFOVCircle then rageFOVCircle.Visible=on end end)
addSlider(r1,"FOV Radius",10,300,60,function(val) rageFOVRadius=val if rageFOVCircle then rageFOVCircle.Radius=val end end)
addSection(r1,"Triggerbot")
addToggle(r1,"Triggerbot",function(on) triggerbotOn=on end)
addSection(r1,"Spinbot")
addToggle(r1,"Spinbot",function(on) spinbotOn=on if not on then spinAngle=0 end end)
addSection(r2,"Bone")
addDropdown(r2,"Target",{"Head","HumanoidRootPart","UpperTorso","LowerTorso"},"Head",function(val) rageBone=val lockedTarget=nil end)
addSection(r2,"Anti Aim")
addToggle(r2,"Enable",function(on) antiAimOn=on end)
addToggle(r2,"Directional",function(on) antiAimDirectional=on end)
addSlider(r2,"Yaw",-180,180,180,function(val) antiAimYaw=val end)
addSlider(r2,"Pitch",-89,89,0,function(val) antiAimPitch=val end)
addSection(r2,"Scripts")
addButton(r2,"Execute Rage Bot",function(btn)
    if not rageBotOn then rageBotOn=true btn.Text="Rage Bot  [active]"
        btn.TextColor3=Color3.fromRGB(120,200,120) enableRageBot() end
end)

-- WORLD
local w1,w2=addTab("World")
addSection(w1,"Lighting")
addToggle(w1,"Atmosphere",function(on) lightingOn=on if on then enableLighting() else disableLighting() end end)
addSection(w1,"Particles")
addDropdown(w1,"Type",{"Rain","Snow","Ash","Embers","Leaves"},"Rain",function(val)
    particleType=val if currentParticles then spawnParticles(particleType) end
end)
addToggle(w1,"Enable Particles",function(on) if on then spawnParticles(particleType) else stopParticles() end end)
addSection(w2,"Movement")
addToggle(w2,"Bhop",function(on) bhopOn=on end)
addToggle(w2,"Noclip",function(on) noclipOn=on end)

-- WEAPON
local wp1,wp2=addTab("Weapon")
addSection(wp1,"Spread")
addToggle(wp1,"No Spread",function(on) weaponStates.NoSpread=on end)
addSection(wp1,"Timing")
addToggle(wp1,"Instant Equip",function(on) weaponStates.InstantEquip=on end)
addToggle(wp1,"Instant Reload",function(on) weaponStates.InstantReload=on end)
addToggle(wp1,"Fast Firerate",function(on) weaponStates.FastFirerate=on end)
addSection(wp2,"Damage")
addToggle(wp2,"Max Damage",function(on) weaponStates.MaxDamage=on end)
addToggle(wp2,"Max Penetration",function(on) weaponStates.MaxPenetration=on end)
addToggle(wp2,"Max Ammo Pen",function(on) weaponStates.MaxAmmoPen=on end)
addSection(wp2,"Range / Ammo")
addToggle(wp2,"Max Range",function(on) weaponStates.MaxRange=on end)
addToggle(wp2,"Max RangeMod",function(on) weaponStates.MaxRangeMod=on end)
addToggle(wp2,"Max Bullets",function(on) weaponStates.MaxBullets=on end)
addToggle(wp2,"Max Ammo",function(on) weaponStates.MaxAmmo=on end)
addSection(wp2,"Misc")
addToggle(wp2,"Always Auto",function(on) weaponStates.AlwaysAuto=on end)
addToggle(wp2,"Always Scoped",function(on) weaponStates.AlwaysScoped=on end)

-- CONFIG
local c1,c2=addTab("Config")
addSection(c1,"Save")
addButton(c1,"Save Config",function() saveConfig() end)
addSection(c1,"Load")

local configListLabel=Instance.new("TextLabel",c1)
configListLabel.Size=UDim2.new(1,0,0,20) configListLabel.BackgroundTransparency=1
configListLabel.Text="No configs found" configListLabel.TextColor3=TEXT_DIM
configListLabel.TextSize=10 configListLabel.Font=Enum.Font.Gotham
configListLabel.TextXAlignment=Enum.TextXAlignment.Left

local configScrollFrame=Instance.new("ScrollingFrame",c1)
configScrollFrame.Size=UDim2.new(1,0,0,100) configScrollFrame.BackgroundColor3=BG_DEEP
configScrollFrame.BorderSizePixel=0 configScrollFrame.ScrollBarThickness=2
configScrollFrame.ScrollBarImageColor3=UI_ACCENT configScrollFrame.CanvasSize=UDim2.new(0,0,0,0)
configScrollFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
makeCorner(configScrollFrame,3) makeStroke(configScrollFrame,BORDER,1)
Instance.new("UIListLayout",configScrollFrame).Padding=UDim.new(0,1)

local configButtons={}
local selectedConfig=nil

local function refreshConfigList()
    for _,b in ipairs(configButtons) do b:Destroy() end
    configButtons={} selectedConfig=nil
    configListLabel.Text="Scanning..."
    local configs=scanConfigs()
    if #configs==0 then configListLabel.Text="No .cfg files found" return end
    configListLabel.Text=#configs.." config(s) found"
    for _,path in ipairs(configs) do
        local name=path:match("([^/\\]+)$") or path
        local btn=Instance.new("TextButton",configScrollFrame)
        btn.Size=UDim2.new(1,0,0,22) btn.BackgroundColor3=BG_DEEP
        btn.BorderSizePixel=0 btn.Text=name
        btn.TextColor3=Color3.fromRGB(160,160,175) btn.TextSize=10 btn.Font=Enum.Font.Gotham
        btn.MouseEnter:Connect(function()
            if selectedConfig~=path then
                TweenService:Create(btn,TweenInfo.new(0.06),{BackgroundColor3=BG_HOVER,TextColor3=TEXT_PRIMARY}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if selectedConfig~=path then
                TweenService:Create(btn,TweenInfo.new(0.06),{BackgroundColor3=BG_DEEP,TextColor3=Color3.fromRGB(160,160,175)}):Play()
            end
        end)
        btn.MouseButton1Click:Connect(function()
            for _,b2 in ipairs(configButtons) do
                b2.BackgroundColor3=BG_DEEP b2.TextColor3=Color3.fromRGB(160,160,175)
            end
            selectedConfig=path
            btn.BackgroundColor3=Color3.fromRGB(18,28,48) btn.TextColor3=UI_ACCENT
        end)
        table.insert(configButtons,btn)
    end
end

addButton(c1,"Refresh",function() refreshConfigList() end)
addButton(c1,"Load Selected",function()
    if selectedConfig then loadConfigFile(selectedConfig) end
end)

addSection(c2,"Info")
local infoLbl=Instance.new("TextLabel",c2)
infoLbl.Size=UDim2.new(1,0,0,40) infoLbl.BackgroundColor3=BG_RAISED
infoLbl.BorderSizePixel=0 infoLbl.Text="Saved to:\n"..CONFIG_PATH
infoLbl.TextColor3=TEXT_DIM infoLbl.TextSize=10 infoLbl.Font=Enum.Font.Gotham
infoLbl.TextWrapped=true infoLbl.ZIndex=2 makeCorner(infoLbl,3) makeStroke(infoLbl,BORDER,1)

task.spawn(function()
    while true do task.wait(60) refreshConfigList() end
end)
task.delay(1,refreshConfigList)

selectTab("Visuals")

player.CharacterAdded:Connect(function()
    selfHighlight=nil
    if selfChamsOn then task.wait(0.5) enableSelfChams() end
    lockedTarget=nil
end)

loadConfig()
