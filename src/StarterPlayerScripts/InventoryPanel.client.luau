-- src/StarterPlayerScripts/InventoryPanel.client.luau
local Players  = game:GetService("Players")
local Remotes  = require(game.ReplicatedStorage.Remotes)
local ItemData = require(game.ReplicatedStorage.ItemData)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name="InventoryPanelUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

-- Bag toggle button (bottom-left)
local btn = Instance.new("TextButton")
btn.Size=UDim2.new(0,38,0,80); btn.Position=UDim2.new(0,60,1,-96)
btn.BackgroundColor3=Color3.fromRGB(30,0,50); btn.BackgroundTransparency=0.2
btn.TextColor3=Color3.fromRGB(200,150,255); btn.TextScaled=true
btn.Font=Enum.Font.GothamBold; btn.Text="🎒\nBAG"
btn.Parent=screen
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,8)

-- Panel
local panel = Instance.new("Frame")
panel.Size=UDim2.new(0,280,0.5,0); panel.Position=UDim2.new(0,104,0.5,-100)
panel.BackgroundColor3=Color3.fromRGB(15,0,25); panel.BackgroundTransparency=0.1
panel.Visible=false; panel.Parent=screen
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",panel).Color=Color3.fromRGB(160,0,220)

local titleL = Instance.new("TextLabel")
titleL.Size=UDim2.new(1,0,0,32); titleL.BackgroundTransparency=1
titleL.TextColor3=Color3.fromRGB(255,220,50); titleL.TextScaled=true
titleL.Font=Enum.Font.GothamBold; titleL.Text="🎒 INVENTORY"
titleL.Parent=panel

local scroll = Instance.new("ScrollingFrame")
scroll.Size=UDim2.new(1,-8,1,-36); scroll.Position=UDim2.new(0,4,0,34)
scroll.BackgroundTransparency=1; scroll.ScrollBarThickness=4
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; scroll.Parent=panel
Instance.new("UIListLayout",scroll).Padding=UDim.new(0,3)

local currentInventory = {}

local function refreshPanel()
    for _,c in ipairs(scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    if #currentInventory == 0 then
        local el=Instance.new("TextLabel"); el.Size=UDim2.new(1,0,0,50)
        el.BackgroundTransparency=1; el.TextColor3=Color3.fromRGB(150,120,180)
        el.TextScaled=true; el.Font=Enum.Font.Gotham; el.TextWrapped=true
        el.Text="No items yet.\nVisit the Lab to craft!"; el.Parent=scroll
        return
    end
    for _, itemId in ipairs(currentInventory) do
        local def = ItemData.get(itemId)
        if not def then continue end
        local row=Instance.new("Frame"); row.Size=UDim2.new(1,-4,0,44)
        row.BackgroundColor3=Color3.fromRGB(25,0,40); row.BackgroundTransparency=0.3
        row.Parent=scroll
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,4)
        local il=Instance.new("TextLabel"); il.Size=UDim2.new(0,30,1,0)
        il.BackgroundTransparency=1; il.TextScaled=true; il.Font=Enum.Font.GothamBold
        il.Text=def.icon; il.Parent=row
        local rarityCol = ItemData.RARITY_COLOR[def.rarity] or Color3.new(1,1,1)
        local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(0.5,0,0.55,0)
        nl.Position=UDim2.new(0,32,0,0); nl.BackgroundTransparency=1
        nl.TextColor3=rarityCol; nl.TextScaled=true; nl.Font=Enum.Font.GothamBold
        nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Text=def.name; nl.Parent=row
        local dl=Instance.new("TextLabel"); dl.Size=UDim2.new(0.5,-4,0.45,0)
        dl.Position=UDim2.new(0,32,0.55,0); dl.BackgroundTransparency=1
        dl.TextColor3=Color3.fromRGB(180,160,200); dl.TextScaled=true; dl.Font=Enum.Font.Gotham
        dl.TextXAlignment=Enum.TextXAlignment.Left; dl.Text=def.description; dl.Parent=row
        -- Trade button (opens player picker via TradeController)
        local tradeBtn=Instance.new("TextButton"); tradeBtn.Size=UDim2.new(0,52,0,26)
        tradeBtn.Position=UDim2.new(1,-56,0.5,-13)
        tradeBtn.BackgroundColor3=Color3.fromRGB(0,60,100); tradeBtn.BackgroundTransparency=0.2
        tradeBtn.TextColor3=Color3.fromRGB(80,200,255); tradeBtn.TextScaled=true
        tradeBtn.Font=Enum.Font.GothamBold; tradeBtn.Text="🤝 Trade"
        tradeBtn.Parent=row
        Instance.new("UICorner",tradeBtn).CornerRadius=UDim.new(0,4)
        local capturedId = itemId
        tradeBtn.Activated:Connect(function()
            panel.Visible = false
            btn.Text = "🎒\nBAG"
            -- Build player list UI via TradeController
            local tc = _G.TradeController
            if tc then
                local Players2 = game:GetService("Players")
                local picks = Players2:GetPlayers()
                if #picks <= 1 then
                    local notif = Instance.new("ScreenGui",playerGui)
                    local f=Instance.new("Frame",notif); f.Size=UDim2.new(0,280,0,44)
                    f.Position=UDim2.new(0.5,-140,0,140); f.BackgroundColor3=Color3.fromRGB(60,20,20)
                    f.BackgroundTransparency=0.1; Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
                    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,0,1,0)
                    l.BackgroundTransparency=1; l.TextColor3=Color3.new(1,1,1); l.TextScaled=true
                    l.Font=Enum.Font.Gotham; l.Text="No other players online to trade with"
                    game:GetService("Debris"):AddItem(notif,3)
                    return
                end
                -- Show player picker specific to this item
                tc.openOffer(picks[1].UserId, picks[1].DisplayName)
            end
        end)
    end
end

-- Load initial inventory
task.spawn(function()
    local data = Remotes.GetPlayerData:InvokeServer()
    if data then
        currentInventory = data.inventory or {}
        refreshPanel()
    end
end)

-- Update when inventory changes
Remotes.InventoryUpdate.OnClientEvent:Connect(function(inv)
    currentInventory = inv
    refreshPanel()
end)

-- Toggle bag
btn.Activated:Connect(function()
    panel.Visible = not panel.Visible
    btn.Text = panel.Visible and "🎒\n✕" or "🎒\nBAG"
end)
