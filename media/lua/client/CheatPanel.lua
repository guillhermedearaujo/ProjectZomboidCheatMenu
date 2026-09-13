if CheatPanelLoaded then return end

require "ISUI/ISCollapsableWindow"
require "ISUI/ISTabPanel"
require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISPanel"

CheatPanel = {}
CheatPanel.key = Keyboard.KEY_F7
CheatPanel.bindingName = "Painel de Cheats"
CheatPanel.instance = nil
CheatPanel.built = false

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER = 10
local ROW_HGT = FONT_HGT_SMALL + 6

local FIREARM_FULL_NAMES = {
    "Base.Pistol", "Base.Pistol2", "Base.Pistol3",
    "Base.Revolver", "Base.Revolver_Short", "Base.Revolver_Long",
    "Base.Shotgun", "Base.Shotgun2", "Base.PumpShotgun",
    "Base.DoubleBarrelShotgun",
    "Base.JS2000Shotgun", "Base.SawnoffJS2000", "Base.SawnoffDoubleBarrel",
    "Base.Rifle", "Base.VarmintRifle",
    "Base.HuntingRifle", "Base.MSR788", "Base.MSR700",
    "Base.M14", "Base.M16", "Base.M16A2",
    "Base.M9", "Base.M1911", "Base.M36",
    "Base.SniperRifle", "Base.TrapperCarbine",
    "Base.AssaultRifle", "Base.AssaultRifle2", "Base.AssaultRifle_Bayonet",
    "Base.M249", "Base.Mini14",
}

local ITEMS_CATS = {
    Tool = true, Material = true, VehicleMaintenance = true,
    Electronics = true, Container = true,
}

local CONSTRUCTION_FULL_NAMES = {
    "Base.Plank", "Base.Hammer", "Base.Saw",
    "Base.Nails", "Base.NailsBox",
    "Base.Screws", "Base.ScrewsBox",
    "Base.PropaneTank", "Base.BlowTorch",
}

local function isFirearm(name)
    return CheatPanel._firearmSet and CheatPanel._firearmSet[name]
end

local function safeInstance(fullName)
    if not fullName then return nil end
    local ok, res = pcall(instanceItem, fullName)
    return ok and res or nil
end

local function tryScriptItem(fullName)
    if not fullName then return nil end
    local ok, item = pcall(function() return getScriptManager():FindItem(fullName) end)
    return ok and item or nil
end

local function iconForScript(scriptItem)
    if not scriptItem then return nil end
    local ok1, icons = pcall(function() return scriptItem:getIconsForTexture() end)
    if ok1 and icons and not icons:isEmpty() then
        local ok2, first = pcall(function() return icons:get(0) end)
        if ok2 and first then return first end
    end
    local ok3, icon = pcall(function() return scriptItem:getIcon() end)
    return (ok3 and icon) and icon or nil
end

local function isWeaponScript(scriptItem)
    local ok1, cat = pcall(function() return scriptItem:getDisplayCategory() end)
    if ok1 and cat and string.find(tostring(cat), "Weapon", 1, true) then return true end
    local ok2, itemType = pcall(function() local t = scriptItem:getItemType(); return t and tostring(t) end)
    if ok2 and itemType and (itemType:lower() == "weapon") then return true end
    return false
end

local function toFullTypeName(x)
    if x == nil then return nil end
    if type(x) == "string" then
        if x == "" then return nil end
        return x
    end
    local ok, n = pcall(function() return x:getFullName() end)
    if ok and n then return n end
    local ok2, k = pcall(function() return x:getItemKey() end)
    if ok2 and k then return k end
    return nil
end

local function resolveItemFullName(key)
    if not key then return nil end
    if string.find(key, ".", 1, true) then
        if tryScriptItem(key) then return key end
    else
        local full = "Base." .. key
        if tryScriptItem(full) then return full end
    end
    return nil
end

local function fillMagazineIfAny(item)
    if not item then return end
    if instanceof(item, "HandWeapon") then return end
    local okMax, mx = pcall(function() return item:getMaxAmmo() end)
    if okMax and mx and mx > 0 then
        pcall(function() item:setCurrentAmmoCount(mx) end)
    end
end

local function giveItemToPlayer(fullName, qty)
    local player = getPlayer()
    if not player then return false end
    local inv = player:getInventory()
    local count = math.max(1, math.min(qty or 1, 999))
    local gave = 0
    for i = 1, count do
        local item = safeInstance(fullName)
        if item then
            pcall(function() fillMagazineIfAny(item) end)
            pcall(function() inv:AddItem(item) end)
            gave = gave + 1
        end
    end
    return gave > 0
end

local function giveWeaponBundle(fullName, qty)
    local player = getPlayer()
    if not player then return false end
    local inv = player:getInventory()
    local count = math.max(1, math.min(qty or 1, 999))
    local gaveWeapon = false
    for i = 1, count do
        local weapon = safeInstance(fullName)
        if weapon then
            local okMag, magType = pcall(function() return weapon:getMagazineType() end)
            local magFull = okMag and toFullTypeName(magType) or nil
            if magFull then
                local okFill, mx = pcall(function() return weapon:getMaxAmmo() end)
                if okFill and mx then pcall(function() weapon:setCurrentAmmoCount(mx) end) end
                if tryScriptItem(magFull) then
                    local magItem = safeInstance(magFull)
                    if magItem then
                        pcall(function() magItem:setCurrentAmmoCount(magItem:getMaxAmmo()) end)
                        pcall(function() inv:AddItem(magItem) end)
                    end
                end
            else
                local okFill2, mx2 = pcall(function() return weapon:getMaxAmmo() end)
                if okFill2 and mx2 then pcall(function() weapon:setCurrentAmmoCount(mx2) end) end
            end
            local okCond, mx3 = pcall(function() return weapon:getConditionMax() end)
            if okCond and mx3 then pcall(function() weapon:setCondition(mx3) end) end
            pcall(function() inv:AddItem(weapon) end)
            gaveWeapon = true
            local ammoFull
            local okAmmo, ammoType = pcall(function() return weapon:getAmmoType() end)
            if okAmmo and ammoType then
                local okKey, key = pcall(function() return ammoType:getItemKey() end)
                if okKey and key then
                    ammoFull = resolveItemFullName(tostring(key))
                end
            end
            if ammoFull then
                for j = 1, 3 do
                    local bullet = safeInstance(ammoFull)
                    if bullet then pcall(function() inv:AddItem(bullet) end) end
                end
            end
        end
    end
    return gaveWeapon
end

local function spawnVehicleHere(scriptName)
    local player = getPlayer()
    if not player then return end
    local spawned = false
    local ok, vehicle = pcall(function()
        return addVehicle(tostring(scriptName), player:getX(), player:getY(), player:getZ())
    end)
    if ok and vehicle then
        spawned = true
        pcall(function()
            local key = vehicle:createVehicleKey()
            if key then
                player:getInventory():AddItem(key)
            end
        end)
        pcall(function() vehicle:setKeysInIgnition(true) end)
        pcall(function()
            local tank = vehicle:getPartById("GasTank")
            if tank then
                local cap = tank:getContainerCapacity()
                if cap and cap > 0 then
                    tank:setContainerContentAmount(cap)
                    vehicle:transmitPartModData(tank)
                end
            end
        end)
    end
    if not spawned and isClient() then
        SendCommandToServer("/addvehicle " .. tostring(scriptName))
    end
end

CheatTab = ISPanel:derive("CheatTab")
CheatTab.list = nil
CheatTab.searchBox = nil
CheatTab.qtyEntry = nil
CheatTab.giveBtn = nil
CheatTab.dataRows = {}
CheatTab.kind = "items"

function CheatTab:initialise()
    ISPanel.initialise(self)
end

function CheatTab:createChildren()
    ISPanel.createChildren(self)
    local searchW = 250
    self.searchLabel = ISLabel:new(UI_BORDER, UI_BORDER, ROW_HGT, "Buscar:", 1,1,1,1, UIFont.Small, true)
    self:addChild(self.searchLabel)
    self.searchBox = ISTextEntryBox:new("", UI_BORDER + getTextManager():MeasureStringX(UIFont.Small, "Buscar:") + 8, UI_BORDER, searchW, ROW_HGT)
    self.searchBox.onTextChange = function() self:onFilterChanged() end
    self.searchBox.target = self
    self:addChild(self.searchBox)
    self.searchBox:setClearButton(true)
    local listY = UI_BORDER + ROW_HGT + UI_BORDER
    local footerHgt = ROW_HGT + UI_BORDER + ROW_HGT
    self.list = ISScrollingListBox:new(0, listY, self.width, self.height - listY - footerHgt)
    self.list.itemheight = ROW_HGT
    self.list.selected = 0
    self.list.font = UIFont.Small
    self.list.drawBorder = true
    self.list.doDrawItem = function(s, y, item, alt) return self:drawRow(y, item, alt) end
    self:addChild(self.list)
    self.list:setOnMouseDoubleClick(self, function(tab, data) tab:onGive() end)
    local btnY = self.list:getBottom() + UI_BORDER
    local lblX = UI_BORDER
    self.qtyLabel = ISLabel:new(lblX, btnY, ROW_HGT, "Quantidade:", 1,1,1,1, UIFont.Small, true)
    self:addChild(self.qtyLabel)
    local qtyX = lblX + getTextManager():MeasureStringX(UIFont.Small, "Quantidade:") + 8
    self.qtyEntry = ISTextEntryBox:new("1", qtyX, btnY, 60, ROW_HGT)
    self:addChild(self.qtyEntry)
    self.qtyEntry:setOnlyNumbers(true)
local giveText = (self.kind == "vehicles") and "Spawnar aqui" or ((self.kind == "recipes") and "Aprender" or "Dar")
    self.giveBtn = ISButton:new(self.width - 140, btnY, 130, ROW_HGT, giveText, self, self.onGive)
    self.giveBtn.borderColor = {r=0.7, g=0.7, b=0.7, a=0.5}
    self:addChild(self.giveBtn)
    if self.kind == "recipes" then
        self.allBtn = ISButton:new(self.width - 280, btnY, 130, ROW_HGT, "Aprender Tudo", self, self.onLearnAll)
        self.allBtn.borderColor = {r=0.7, g=0.7, b=0.7, a=0.5}
        self:addChild(self.allBtn)
    end
end

function CheatTab:drawRow(y, item, alt)
    local lh = self.list.itemheight
    if y + self.list:getYScroll() + lh < 0 or y + self.list:getYScroll() >= self.list.height then
        return y + lh
    end
    local a = 0.9
    if self.list.selected == item.index then
        self.list:drawRect(0, y, self.list:getWidth(), lh, 0.3, 0.7, 0.35, 0.15)
    elseif alt then
        self.list:drawRect(0, y, self.list:getWidth(), lh, 0.3, 0.6, 0.5, 0.5)
    end
    self.list:drawRectBorder(0, y, self.list:getWidth(), lh, a, self.list.borderColor.r, self.list.borderColor.g, self.list.borderColor.b)
    local data = item.item or {}
    local iconTex = nil
    if type(data.icon) == "string" and data.icon ~= "" then
        iconTex = tryGetTexture("Item_" .. data.icon)
    end
    if iconTex then
        self.list:drawTextureScaledAspect2(iconTex, 2, y + (lh - FONT_HGT_SMALL) / 2, FONT_HGT_SMALL, FONT_HGT_SMALL, 1,1,1,1)
    end
    local text = item.text or "?"
    self.list:drawText(text, iconTex and (FONT_HGT_SMALL + 8) or 4, y + 3, 1,1,1,a, self.list.font)
    return y + lh
end

function CheatTab:getSelectedFullName()
    if self.list.selected > 0 and self.list.selected <= #self.list.items then
        local row = self.list.items[self.list.selected]
        if row and row.item and row.item.fullName then return row.item.fullName end
    end
    return nil
end

function CheatTab:getValueQty()
    local txt = self.qtyEntry and self.qtyEntry:getText() or "1"
    local n = tonumber(txt)
    if not n or n < 1 then n = 1 end
    return math.min(math.floor(n), 999)
end

local function supplyItemToList(target, fullName)
    if not fullName or not tryScriptItem(fullName) then return end
    local scriptItem = tryScriptItem(fullName)
    local label = fullName
    pcall(function() label = scriptItem:getDisplayName() end)
    table.insert(target, {fullName = fullName, label = label, icon = iconForScript(scriptItem), isFirearm = false})
end

local function learnBook(fullName)
    local player = getPlayer()
    if not player or not fullName then return end
    local item = safeInstance(fullName)
    if not item then return end
    local recipes
    pcall(function() recipes = item:getLearnedRecipes() end)
    if recipes and not recipes:isEmpty() then
        for i = 1, recipes:size() do
            local rname = recipes:get(i - 1)
            pcall(function() player:getKnownRecipes():add(rname) end)
            if rname == "Herbalist" then
                pcall(function()
                    if not player:hasTrait(CharacterTrait.HERBALIST) and not player:hasTrait(CharacterTrait.HERBALIST_PROF) then
                        player:hasTrait(CharacterTrait.HERBALIST)
                    end
                end)
            end
        end
    end
    local skillTrained
    pcall(function() skillTrained = item:getSkillTrained() end)
    if skillTrained and SkillBook and SkillBook[skillTrained] then
        local perk = SkillBook[skillTrained].perk
        if perk then
            local maxLvl
            pcall(function() maxLvl = item:getMaxLevelTrained() end)
            if not maxLvl or maxLvl <= 0 then
                local lvl, num = 0, 0
                pcall(function() lvl = item:getLvlSkillTrained() end)
                pcall(function() num = item:getNumLevelsTrained() end)
                maxLvl = lvl + num - 1
            end
            if maxLvl and maxLvl > 0 then
                maxLvl = math.min(math.max(math.floor(maxLvl), 1), 10)
                pcall(function() player:setPerkLevelDebug(perk, maxLvl) end)
                pcall(function() player:getXp():setXPToLevel(perk, maxLvl) end)
            end
        end
    end
end

function CheatTab:onGive()
    local fullName = self:getSelectedFullName()
    if not fullName then return end
    if self.kind == "recipes" then
        learnBook(fullName)
        return
    end
    local qty = self:getValueQty()
    if self.kind == "vehicles" then
        spawnVehicleHere(fullName)
        return
    end
    local data = nil
    for _, r in ipairs(self.dataRows) do
        if r.fullName == fullName then data = r; break end
    end
    if data and data.isFirearm then
        giveWeaponBundle(fullName, qty)
    else
        giveItemToPlayer(fullName, qty)
    end
end

function CheatTab:onLearnAll()
    for _, r in ipairs(self.allRows) do
        if r and r.fullName then
            learnBook(r.fullName)
        end
    end
end

function CheatTab:setData(rows)
    self.allRows = rows or {}
    self:applyFilter()
end

function CheatTab:onFilterChanged()
    self:applyFilter()
end

function CheatTab:applyFilter()
    local filter = (self.searchBox and self.searchBox:getText()) or ""
    filter = string.lower(filter)
    self.list:clear()
    self.dataRows = {}
    for _, r in ipairs(self.allRows) do
        if filter == "" or string.find(string.lower(r.label), filter, 1, true) then
            self.list:addItem(r.label, r)
            table.insert(self.dataRows, r)
        end
    end
end

function CheatTab:setWidthHeight(w, h)
    if self.list then
        self.list:setWidth(w)
        self.list:setHeight(h - self.list:getY() - ROW_HGT - UI_BORDER - ROW_HGT)
    end
end

function CheatTab:new(x, y, w, h, kind)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.kind = kind or "items"
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.backgroundColor = {r=0, g=0, b=0, a=0}
    return o
end

CheatPanelWindow = ISCollapsableWindow:derive("CheatPanelWindow")

function CheatPanelWindow:new(x, y, w, h)
    local o = ISCollapsableWindow:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o:setTitle("Painel de Cheats")
    o.resizable = true
    return o
end

function CheatPanelWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()
    self.tabPanel = ISTabPanel:new(UI_BORDER, th, self.width - UI_BORDER*2, self.height - th - UI_BORDER)
    self.tabPanel.borderColor = {r=0, g=0, b=0, a=0}
    self.tabPanel.equalTabWidth = false
    self:addChild(self.tabPanel)
    self.tabs = {}
local tabDefs = {
        {id = "firearms",   label = "Armas de Fogo", kind = "items"},
        {id = "melee",      label = "Armas Brancas", kind = "items"},
        {id = "ammo",       label = "Municao",       kind = "items"},
        {id = "protection", label = "Protecao",      kind = "items"},
        {id = "backpacks",  label = "Mochilas",      kind = "items"},
        {id = "items",      label = "Itens",         kind = "items"},
        {id = "construction", label = "Construcao", kind = "items"},
        {id = "vehicles",   label = "Veiculos",      kind = "vehicles"},
        {id = "knowledge",  label = "Conhecimento",  kind = "recipes"},
    }
    for _, def in ipairs(tabDefs) do
        local tabW = self.tabPanel.width
        local tabH = self.tabPanel.height - self.tabPanel.tabHeight
        local view = CheatTab:new(0, 0, tabW, tabH, def.kind)
        view:initialise()
        self.tabPanel:addView(def.label, view)
        self.tabs[def.id] = view
    end
end

function CheatPanelWindow:onResize()
    ISCollapsableWindow.onResize(self)
    if not self.tabPanel then return end
    local th = self:titleBarHeight()
    self.tabPanel:setX(UI_BORDER)
    self.tabPanel:setY(th)
    self.tabPanel:setWidth(self.width - UI_BORDER*2)
    self.tabPanel:setHeight(self.height - th - UI_BORDER)
    for _, view in pairs(self.tabs) do
        local tw = self.tabPanel.width
        local th2 = self.tabPanel.height - self.tabPanel.tabHeight
        if view.list then
            view:setWidthHeight(tw, th2)
        end
    end
end

function CheatPanelWindow:close()
    self:setVisible(false)
end

function CheatPanelWindow:toggle()
    if self:isVisible() then
        self:setVisible(false)
    else
        self:setVisible(true)
        self:bringToTop()
    end
end

function CheatPanel.buildData()
    if CheatPanel.built then return end
    CheatPanel._firearmSet = {}
    for _, name in ipairs(FIREARM_FULL_NAMES) do
        if tryScriptItem(name) then
            CheatPanel._firearmSet[name] = true
        end
    end
local firearms = {}
    local melee = {}
    local ammoList = {}
    local items = {}
    local construction = {}
    local protection = {}
    local backpacks = {}
    local allItems = getAllItems()
    if allItems then
        for i = 0, allItems:size() - 1 do
            local scriptItem = allItems:get(i)
            if scriptItem then
                local fullName
                pcall(function() fullName = scriptItem:getFullName() end)
                if fullName then
                    local obsolete = false
                    pcall(function() obsolete = scriptItem:getObsolete() end)
                    local hidden = false
                    pcall(function() hidden = scriptItem:isHidden() end)
                    if not obsolete and not hidden then
                        local label = fullName
                        pcall(function() label = scriptItem:getDisplayName() end)
                        local icon = iconForScript(scriptItem)
                        local cat
                        pcall(function() cat = scriptItem:getDisplayCategory() end)
                        local row = {fullName = fullName, label = label, icon = icon, isFirearm = false}
if isFirearm(fullName) then
                            row.isFirearm = true
                            table.insert(firearms, row)
                        elseif cat and tostring(cat) == "Ammo" then
                            table.insert(ammoList, row)
                        elseif cat and tostring(cat) == "ProtectiveGear" then
                            table.insert(protection, row)
                        elseif cat and tostring(cat) == "Bag" then
                            table.insert(backpacks, row)
                        elseif cat and tostring(cat) == "Accessory" and (string.find(fullName, "Holster", 1, true) or string.find(fullName, "AmmoStrap", 1, true)) then
                            table.insert(backpacks, row)
elseif ITEMS_CATS[cat] then
                            table.insert(items, row)
                        elseif isWeaponScript(scriptItem) then
                            local isRanged = false
                            local inst = safeInstance(fullName)
                            if inst and instanceof(inst, "HandWeapon") then
                                pcall(function() isRanged = inst:isRanged() end)
                            end
                            if isRanged then
                                row.isFirearm = true
                                table.insert(firearms, row)
                            else
                                table.insert(melee, row)
                            end
                        end
                    end
                end
            end
        end
    end
    local vehicles = {}
    local vehicleScripts = getScriptManager() and getScriptManager():getAllVehicleScripts()
    if vehicleScripts then
        for i = 0, vehicleScripts:size() - 1 do
            local vscript = vehicleScripts:get(i)
            if vscript then
                local vname
                pcall(function() vname = vscript:getName() end)
                if vname then
                    local vnameLower = string.lower(vname)
                    local skip = string.find(vnameLower, "burnt", 1, true) or string.find(vnameLower, "smashed", 1, true)
                    if not skip then
                        local vfull
                        pcall(function() vfull = vscript:getFullName() end)
                        local display = vfull or vname
                        local okTranslate, translated = pcall(function() return getText("IGUI_VehicleName" .. vname) end)
                        if okTranslate and translated and translated ~= ("IGUI_VehicleName" .. vname) then
                            display = translated .. " (" .. vfull .. ")"
                        else
                            display = vfull
                        end
                        table.insert(vehicles, {fullName = vfull, label = display, icon = nil, isFirearm = false})
                    end
                end
            end
        end
    end
local knowledge = {}
    local litItems = getScriptManager() and getScriptManager():getAllItems()
    if litItems then
        local seenBooks = {}
        for i = 0, litItems:size() - 1 do
            local scriptItem = litItems:get(i)
            if scriptItem then
                local isLit = false
                pcall(function() isLit = scriptItem:isItemType(ItemType.LITERATURE) end)
                if isLit then
                    local fullName
                    pcall(function() fullName = scriptItem:getFullName() end)
                    if fullName and not seenBooks[fullName] then
                        seenBooks[fullName] = true
                        local skillTrained
                        pcall(function() skillTrained = scriptItem:getSkillTrained() end)
                        local hasRecipes = false
                        pcall(function() hasRecipes = scriptItem:getLearnedRecipes() ~= nil end)
                        if skillTrained or hasRecipes then
                            local label = fullName
                            pcall(function() label = scriptItem:getDisplayName() end)
                            local icon = iconForScript(scriptItem)
                            table.insert(knowledge, {fullName = fullName, label = label, icon = icon, isFirearm = false})
                        end
                    end
                end
            end
        end
    end
    for _, name in ipairs(CONSTRUCTION_FULL_NAMES) do
        supplyItemToList(construction, name)
    end
    table.sort(firearms, function(a, b) return a.label < b.label end)
    table.sort(melee, function(a, b) return a.label < b.label end)
table.sort(ammoList, function(a, b) return a.label < b.label end)
    table.sort(items, function(a, b) return a.label < b.label end)
    table.sort(construction, function(a, b) return a.label < b.label end)
    table.sort(protection, function(a, b) return a.label < b.label end)
    table.sort(backpacks, function(a, b) return a.label < b.label end)
    table.sort(vehicles, function(a, b) return a.label < b.label end)
    table.sort(knowledge, function(a, b) return a.label < b.label end)
    CheatPanel.data = {
        firearms = firearms,
        melee = melee,
        ammo = ammoList,
        items = items,
        construction = construction,
        protection = protection,
        backpacks = backpacks,
        vehicles = vehicles,
        knowledge = knowledge,
    }
    CheatPanel.built = true
end

function CheatPanel.open()
    CheatPanel.buildData()
    if CheatPanel.instance then
        CheatPanel.instance:toggle()
        return
    end
    local w = math.min(900, getCore():getScreenWidth() - 40)
    local h = math.min(600, getCore():getScreenHeight() - 80)
    local x = math.max(20, (getCore():getScreenWidth() - w) / 2)
    local y = math.max(40, (getCore():getScreenHeight() - h) / 2)
    local window = CheatPanelWindow:new(x, y, w, h)
    window:initialise()
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    CheatPanel.instance = window
if CheatPanel.data then
        window.tabs.firearms:setData(CheatPanel.data.firearms)
        window.tabs.melee:setData(CheatPanel.data.melee)
        window.tabs.ammo:setData(CheatPanel.data.ammo)
        window.tabs.protection:setData(CheatPanel.data.protection)
        window.tabs.backpacks:setData(CheatPanel.data.backpacks)
        window.tabs.items:setData(CheatPanel.data.items)
        window.tabs.construction:setData(CheatPanel.data.construction)
        window.tabs.vehicles:setData(CheatPanel.data.vehicles)
        window.tabs.knowledge:setData(CheatPanel.data.knowledge)
    end
end

CheatPanel.hudButton = nil

function CheatPanel.onHudButtonClick(target, button)
    if not getGameTime() then return end
    CheatPanel.open()
end

function CheatPanel.createHudButton()
    if CheatPanel.hudButton then
        CheatPanel.hudButton:removeFromUIManager()
        CheatPanel.hudButton = nil
    end
    local sw = getCore():getScreenWidth()
    local button = ISButton:new(sw - 112, 12, 100, 22, "Cheats", CheatPanel, CheatPanel.onHudButtonClick)
    button.borderColor = {r=0.7, g=0.7, b=0.7, a=0.6}
    button:initialise()
    button:addToUIManager()
    button:setVisible(true)
    CheatPanel.hudButton = button
end

function CheatPanel.onKeyPressed(key)
    local boundKey
    local ok = pcall(function() boundKey = getCore():getKey(CheatPanel.bindingName) end)
    if ok and boundKey and boundKey == key then
        CheatPanel.open()
        return
    end
    if key == CheatPanel.key and (not ok or not boundKey or boundKey == 0) then
        CheatPanel.open()
    end
end

local function initBinding()
    pcall(function() getCore():addKeyBinding(CheatPanel.bindingName, CheatPanel.key, 0, false, false, false) end)
end

local function initGame()
    initBinding()
end

Events.OnGameStart.Add(initGame)
Events.OnKeyPressed.Add(CheatPanel.onKeyPressed)

CheatPanelLoaded = true