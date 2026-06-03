-- src/StarterPlayerScripts/CraftingController.client.luau
local Players  = game:GetService("Players")
local Remotes  = require(game.ReplicatedStorage.Remotes)
local ItemData = require(game.ReplicatedStorage.ItemData)
local Config   = require(game.ReplicatedStorage.Config)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

task.wait(2)

local CRAFT_RECIPES = {
    chemistry   = {itemId="stim_pack",      cost=2000},
    electronics = {itemId="emp_grenade",    cost=3000},
    biology     = {itemId="armor_chip",     cost=4000},
    physics     = {itemId="vault_override", cost=6000},
    weapons     = {itemId="minion_core",    cost=5000},
}

-- Toast notification
local screen = Instance.new("ScreenGui")
screen.Name="CraftingUI"; screen.ResetOnSpawn=false; screen.Parent=playerGui

local function showNotif(msg, success)
    local f=Instance.new("Frame",screen)
    f.Size=UDim2.new(0,300,0,50); f.Position=UDim2.new(0.5,-150,0,90)
    f.BackgroundColor3=success and Color3.fromRGB(20,60,20) or Color3.fromRGB(60,20,20)
    f.BackgroundTransparency=0.1
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,8)
    local l=Instance.new("TextLabel",f); l.Size=UDim2.new(1,-8,1,0)
    l.Position=UDim2.new(0,4,0,0); l.BackgroundTransparency=1
    l.TextColor3=Color3.new(1,1,1); l.TextScaled=true; l.Font=Enum.Font.GothamBold
    l.TextWrapped=true; l.Text=msg
    game:GetService("Debris"):AddItem(f, 3)
end

-- Wire ProximityPrompts on CraftKiosk_ parts in player's plot
local function getMyPlot()
    while true do
        for _,obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Folder") and obj.Name:match("^Plot_%d+$") then
                local oid=obj:FindFirstChild("OwnerId")
                if oid and oid.Value==player.UserId then return obj end
            end
        end; task.wait(0.5)
    end
end

task.spawn(function()
    local plot = getMyPlot()
    local function wireCraftKiosk(obj)
        if not obj:IsA("Part") then return end
        local dept = obj.Name:match("^CraftKiosk_(.+)$")
        if not dept then return end
        if obj:FindFirstChildOfClass("ProximityPrompt") then return end
        local recipe = CRAFT_RECIPES[dept]
        if not recipe then return end
        local def = ItemData.get(recipe.itemId)
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText = string.format("Craft %s (💰%d)", def and def.name or recipe.itemId, recipe.cost)
        prompt.ObjectText = "Crafting Station"
        prompt.HoldDuration = 1
        prompt.MaxActivationDistance = 8
        prompt.Parent = obj
        prompt.Triggered:Connect(function()
            local result = Remotes.CraftItem:InvokeServer(dept)
            showNotif((result.ok and "✅ " or "❌ ") .. result.message, result.ok)
        end)
    end
    for _,obj in ipairs(plot:GetDescendants()) do wireCraftKiosk(obj) end
    plot.DescendantAdded:Connect(wireCraftKiosk)
end)
