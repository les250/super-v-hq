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
        local il=Instance.new("TextLabel"); il.Size=UDim2.new(0,36,1,0)
        il.BackgroundTransparency=1; il.TextScaled=true; il.Font=Enum.Font.GothamBold
        il.Text=def.icon; il.Parent=row
        local rarityCol = ItemData.RARITY_COLOR[def.rarity] or Color3.new(1,1,1)
        local nl=Instance.new("TextLabel"); nl.Size=UDim2.new(1,-40,0.55,0)
        nl.Position=UDim2.new(0,36,0,0); nl.BackgroundTransparency=1
        nl.TextColor3=rarityCol; nl.TextScaled=true; nl.Font=Enum.Font.GothamBold
        nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Text=def.name; nl.Parent=row
        local dl=Instance.new("TextLabel"); dl.Size=UDim2.new(1,-40,0.45,0)
        dl.Position=UDim2.new(0,36,0.55,0); dl.BackgroundTransparency=1
        dl.TextColor3=Color3.fromRGB(180,160,200); dl.TextScaled=true; dl.Font=Enum.Font.Gotham
        dl.TextXAlignment=Enum.TextXAlignment.Left; dl.Text=def.description; dl.Parent=row
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
