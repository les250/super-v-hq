-- src/StarterPlayerScripts/TradeController.client.luau
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Remotes      = require(game.ReplicatedStorage.Remotes)
local ItemData     = require(game.ReplicatedStorage.ItemData)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
task.wait(2)

local screen = Instance.new("ScreenGui")
screen.Name="TradeUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

-- Trade offer panel (bottom-left, toggled from inventory)
local offerPanel = Instance.new("Frame")
offerPanel.Name="TradeOffer"; offerPanel.Size=UDim2.new(0,280,0,0)
offerPanel.AutomaticSize=Enum.AutomaticSize.Y
offerPanel.Position=UDim2.new(0,104,1,-300)
offerPanel.BackgroundColor3=Color3.fromRGB(10,20,40); offerPanel.BackgroundTransparency=0.1
offerPanel.Visible=false; offerPanel.Parent=screen
Instance.new("UICorner",offerPanel).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",offerPanel).Color=Color3.fromRGB(0,140,220)

local offerTitle=Instance.new("TextLabel"); offerTitle.Size=UDim2.new(1,0,0,30)
offerTitle.BackgroundTransparency=1; offerTitle.TextColor3=Color3.fromRGB(80,200,255)
offerTitle.TextScaled=true; offerTitle.Font=Enum.Font.GothamBold; offerTitle.Text="🤝 TRADE"
offerTitle.Parent=offerPanel

local offerList=Instance.new("Frame"); offerList.Size=UDim2.new(1,-8,0,0)
offerList.AutomaticSize=Enum.AutomaticSize.Y
offerList.Position=UDim2.new(0,4,0,34); offerList.BackgroundTransparency=1; offerList.Parent=offerPanel
Instance.new("UIListLayout",offerList).Padding=UDim.new(0,4)

-- Incoming trade request dialog
local incomingFrame=Instance.new("Frame")
incomingFrame.Size=UDim2.new(0,340,0,140); incomingFrame.Position=UDim2.new(0.5,-170,0.5,-70)
incomingFrame.BackgroundColor3=Color3.fromRGB(15,15,35); incomingFrame.BackgroundTransparency=0.05
incomingFrame.Visible=false; incomingFrame.Parent=screen
Instance.new("UICorner",incomingFrame).CornerRadius=UDim.new(0,12)
Instance.new("UIStroke",incomingFrame).Color=Color3.fromRGB(0,160,220)

local inTitle=Instance.new("TextLabel"); inTitle.Size=UDim2.new(1,0,0,35)
inTitle.Position=UDim2.new(0,0,0,5); inTitle.BackgroundTransparency=1
inTitle.TextColor3=Color3.fromRGB(255,220,50); inTitle.TextScaled=true
inTitle.Font=Enum.Font.GothamBold; inTitle.Text="Incoming Trade"; inTitle.Parent=incomingFrame

local inBody=Instance.new("TextLabel"); inBody.Size=UDim2.new(1,-16,0,55)
inBody.Position=UDim2.new(0,8,0,42); inBody.BackgroundTransparency=1
inBody.TextColor3=Color3.fromRGB(220,200,255); inBody.TextScaled=true
inBody.Font=Enum.Font.Gotham; inBody.TextWrapped=true; inBody.Parent=incomingFrame

local acceptBtn=Instance.new("TextButton"); acceptBtn.Size=UDim2.new(0.45,0,0,36)
acceptBtn.Position=UDim2.new(0.05,0,1,-44); acceptBtn.BackgroundColor3=Color3.fromRGB(0,100,0)
acceptBtn.TextColor3=Color3.new(1,1,1); acceptBtn.TextScaled=true
acceptBtn.Font=Enum.Font.GothamBold; acceptBtn.Text="✅ Accept"; acceptBtn.Parent=incomingFrame
Instance.new("UICorner",acceptBtn).CornerRadius=UDim.new(0,8)

local declineBtn=Instance.new("TextButton"); declineBtn.Size=UDim2.new(0.45,0,0,36)
declineBtn.Position=UDim2.new(0.5,0,1,-44); declineBtn.BackgroundColor3=Color3.fromRGB(100,0,0)
declineBtn.TextColor3=Color3.new(1,1,1); declineBtn.TextScaled=true
declineBtn.Font=Enum.Font.GothamBold; declineBtn.Text="❌ Decline"; declineBtn.Parent=incomingFrame
Instance.new("UICorner",declineBtn).CornerRadius=UDim.new(0,8)

local pendingFromUserId = 0

-- Toast
local function showToast(msg, success)
    local f=Instance.new("Frame",screen)
    f.Size=UDim2.new(0,320,0,48); f.Position=UDim2.new(0.5,-160,0,140)
    f.BackgroundColor3=success and Color3.fromRGB(20,60,20) or Color3.fromRGB(60,20,20)
    f.BackgroundTransparency=0.1
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-8,1,0); l.Position=UDim2.new(0,4,0,0)
    l.BackgroundTransparency=1; l.TextColor3=Color3.new(1,1,1); l.TextScaled=true
    l.Font=Enum.Font.GothamBold; l.TextWrapped=true; l.Text=msg
    game:GetService("Debris"):AddItem(f,3)
end

-- Open offer panel with current inventory items
local function openOfferPanel(targetUserId, targetName)
    for _,c in ipairs(offerList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    offerTitle.Text = "🤝 Trade with " .. targetName

    local data = Remotes.GetPlayerData:InvokeServer()
    local inv = data and data.inventory or {}
    if #inv == 0 then
        local el=Instance.new("TextLabel"); el.Size=UDim2.new(1,0,0,36)
        el.BackgroundTransparency=1; el.TextColor3=Color3.fromRGB(180,160,200)
        el.TextScaled=true; el.Font=Enum.Font.Gotham; el.Text="No items to trade"
        el.Parent=offerList
    else
        for _, itemId in ipairs(inv) do
            local def = ItemData.get(itemId)
            if not def then continue end
            local rb=Instance.new("TextButton"); rb.Size=UDim2.new(1,0,0,36)
            rb.BackgroundColor3=Color3.fromRGB(0,25,45); rb.BackgroundTransparency=0.3
            rb.TextColor3=Color3.fromRGB(255,255,255); rb.TextScaled=true; rb.Font=Enum.Font.Gotham
            rb.TextXAlignment=Enum.TextXAlignment.Left
            rb.Text="  " .. def.icon .. "  " .. def.name; rb.Parent=offerList
            Instance.new("UICorner",rb).CornerRadius=UDim.new(0,4)
            rb.Activated:Connect(function()
                Remotes.SendTrade:FireServer(targetUserId, itemId)
                offerPanel.Visible = false
                showToast("Trade offer sent to " .. targetName .. "!", true)
            end)
        end
    end
    offerPanel.Visible = true
end

-- Incoming trade request
Remotes.TradeRequest.OnClientEvent:Connect(function(fromUserId, fromName, itemId, itemName)
    pendingFromUserId = fromUserId
    local def = ItemData.get(itemId)
    inBody.Text = string.format("%s wants to give you:\n%s  %s", fromName,
        def and def.icon or "📦", itemName)
    incomingFrame.Visible = true
end)

acceptBtn.Activated:Connect(function()
    if pendingFromUserId == 0 then return end
    Remotes.TradeResponse:FireServer(pendingFromUserId, true)
    incomingFrame.Visible = false; pendingFromUserId = 0
end)

declineBtn.Activated:Connect(function()
    if pendingFromUserId == 0 then return end
    Remotes.TradeResponse:FireServer(pendingFromUserId, false)
    incomingFrame.Visible = false; pendingFromUserId = 0
end)

-- Trade outcomes
Remotes.TradeCancelled.OnClientEvent:Connect(function(reason)
    showToast("❌ Trade cancelled: " .. reason, false)
    incomingFrame.Visible = false; pendingFromUserId = 0
end)

Remotes.TradeComplete.OnClientEvent:Connect(function(itemName, otherName)
    showToast("✅ Trade complete! " .. itemName .. " with " .. otherName, true)
    incomingFrame.Visible = false; pendingFromUserId = 0
end)

-- Expose openOfferPanel so InventoryPanel can call it
_G.TradeController = { openOffer = openOfferPanel }
