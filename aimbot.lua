-- Takım Renkli ESP + Aim (E tuşu)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- AYARLAR --
local Settings = {
    AimKey = Enum.KeyCode.E,
    AimPart = "Head",
    Smoothness = 0.15,
    
    -- Takım renkleri
    TeamColors = {
        YourTeam = Color3.fromRGB(0, 100, 255),  -- Mavi (takım arkadaşları)
        EnemyTeam = Color3.fromRGB(255, 50, 50),  -- Kırmızı (düşmanlar)
        Neutral = Color3.fromRGB(255, 255, 0)     -- Sarı (takımsız)
    }
}

-- ESP EKLEME --
local function AddESP(player)
    if player == LocalPlayer then return end
    
    local function UpdateHighlight(char)
        if not char then return end
        
        -- Mevcut ESP'yi temizle
        if char:FindFirstChild("TeamHighlight") then
            char.TeamHighlight:Destroy()
        end

        -- Yeni ESP ekle
        local highlight = Instance.new("Highlight")
        highlight.Name = "TeamHighlight"
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0
        
        -- Takım kontrolü
        if player.Team then
            highlight.FillColor = player.Team == LocalPlayer.Team 
                and Settings.TeamColors.YourTeam 
                or Settings.TeamColors.EnemyTeam
        else
            highlight.FillColor = Settings.TeamColors.Neutral
        end
        
        highlight.OutlineColor = highlight.FillColor
        highlight.Parent = char
    end

    -- Karakter değişikliklerini takip et
    player.CharacterAdded:Connect(UpdateHighlight)
    if player.Character then
        UpdateHighlight(player.Character)
    end
end

-- TÜM OYUNCULARA ESP EKLE --
for _, player in pairs(Players:GetPlayers()) do
    AddESP(player)
end
Players.PlayerAdded:Connect(AddESP)

-- EN YAKIN DÜŞMANI BUL --
local function GetClosestEnemy()
    local closest, minDist = nil, math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if player.Team == LocalPlayer.Team then continue end -- Sadece düşmanlar
        
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            local hum = player.Character.Humanoid
            local head = player.Character:FindFirstChild("Head")
            
            if hum.Health > 0 and head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - UIS:GetMouseLocation()).Magnitude
                    if dist < minDist then
                        closest = player
                        minDist = dist
                    end
                end
            end
        end
    end
    return closest
end

-- AİM FONKSİYONU --
local function AimAtTarget()
    if not Target or not Target.Character then return end
    
    local part = Target.Character:FindFirstChild(Settings.AimPart)
    if not part then return end
    
    local cam = Camera.CFrame
    Camera.CFrame = CFrame.new(cam.Position, cam.Position:Lerp(part.Position, Settings.Smoothness))
end

-- E TUŞU KONTROLÜ --
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.AimKey then
        Target = GetClosestEnemy()
        if Target then
            print(Target.Name.." hedeflendi!")
            while UIS:IsKeyDown(Settings.AimKey) do
                AimAtTarget()
                RS.RenderStepped:Wait()
            end
        else
            print("Hedef bulunamadı!")
        end
    end
end)

print("Aktif! - E tuşuyla düşmanlara kilitlen")
print("Mavi: Takım Arkadaşı | Kırmızı: Düşman | Sarı: Takımsız")
