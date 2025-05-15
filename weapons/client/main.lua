-- Painel minimalista estilo CS:GO/COD para customização de armas
-- Corrigido: input trade, drag&drop, debounce, feedback, modularidade para expansão

local sx, sy = guiGetScreenSize()
local panel = {open=false, tab=1, tabs={"Armas","Skins","Attachments","Upgrades","Lootboxes","Crafting","Troca","Conquistas","Stats"}}
local userData = {}
local dragItem = nil
local dragType = nil
local dragOrigin = nil
local dragActive = false
local tradeTarget = ""
local notifyText, notifyTimer = "", 0
local debounce = 0

-- Input handler para trade (registrado só uma vez)
local function onCharInput(c)
    if panel.open and panel.tab == 7 and #tradeTarget < 18 then
        tradeTarget = tradeTarget..c
    end
end
local function onBackspace()
    if panel.open and panel.tab == 7 then
        tradeTarget = tradeTarget:sub(1,#tradeTarget-1)
    end
end
local inputRegistered = false

local function registerInput()
    if not inputRegistered then
        addEventHandler("onClientCharacter", root, onCharInput)
        bindKey("backspace", "down", onBackspace)
        inputRegistered = true
    end
end
local function unregisterInput()
    if inputRegistered then
        removeEventHandler("onClientCharacter", root, onCharInput)
        unbindKey("backspace", "down", onBackspace)
        inputRegistered = false
    end
end

-- Abrir painel
bindKey("F2", "down", function()
    panel.open = not panel.open
    showCursor(panel.open)
    if panel.open then
        triggerServerEvent("panel:requestSync", resourceRoot)
        registerInput()
    else
        unregisterInput()
        dragItem, dragType, dragOrigin, dragActive = nil, nil, nil, false
    end
end)

addEvent("painel:customizararma", true)
addEventHandler("painel:customizararma", root, function()
    panel.open = true
    showCursor(true)
    triggerServerEvent("panel:requestSync", resourceRoot)
    registerInput()
end)

addEvent("panel:sync", true)
addEventHandler("panel:sync", root, function(data)
    userData = data or {}
end)

addEvent("panel:notify", true)
addEventHandler("panel:notify", root, function(msg)
    notifyText, notifyTimer = msg, getTickCount()
end)

addEvent("panel:lootboxResult", true)
addEventHandler("panel:lootboxResult", root, function(reward)
    notifyText, notifyTimer = "Você ganhou: "..reward.id, getTickCount()
end)

addEvent("panel:equipped", true)
addEventHandler("panel:equipped", root, function(weaponId, skinId, upgrades, attachments)
    -- Troca o TXD da arma e aplica attachments
    if weaponId == "ak47" then
        if skinId == "gold" then
            local goldTxd = engineLoadTXD("models/ak47_gold.txd")
            if goldTxd then engineImportTXD(goldTxd, 355) end
        else
            local txd = engineLoadTXD("models/ak47.txd")
            if txd then engineImportTXD(txd, 355) end
        end
        if attachments and attachments["scope"] then
            local scopeTxd = engineLoadTXD("models/ak47_scope.txd")
            if scopeTxd then engineImportTXD(scopeTxd, 355) end
        end
        if attachments and attachments["silencer"] then
            local silencerTxd = engineLoadTXD("models/ak47_silencer.txd")
            if silencerTxd then engineImportTXD(silencerTxd, 355) end
        end
    end
end)

-- Utilitário para checar mouse
function isMouseIn(x,y,w,h)
    if not isCursorShowing() then return false end
    local mx,my = getCursorPosition()
    mx, my = mx*sx, my*sy
    return mx >= x and mx <= x+w and my >= y and my <= y+h
end

function debounceClick()
    if getTickCount() - debounce < 350 then return false end
    debounce = getTickCount()
    return true
end

function drawCard(img, name, x, y, w, h, selected, sub)
    dxDrawRectangle(x, y, w, h, selected and tocolor(60,160,255,180) or tocolor(32,32,45,180), false)
    if img and fileExists(img) then dxDrawImage(img, x+10, y+10, h-20, h-20, img) end
    dxDrawText(name, x+h, y+10, x+w-10, y+h-10, tocolor(255,255,255), 1, "default-bold", "left", "top", false,false,false,true)
    if sub then
        dxDrawText(sub, x+h, y+h/2, x+w-10, y+h-10, tocolor(170,200,255), .85, "default-bold", "left", "bottom")
    end
end

addEventHandler("onClientRender", root, function()
    if not panel.open then return end
    dxDrawRectangle(sx*0.07, sy*0.07, sx*0.86, sy*0.86, tocolor(20,24,32,230), false)
    dxDrawRectangle(sx*0.07, sy*0.07, sx*0.86, 52, tocolor(16,20,28,255), false)
    -- Tabs
    for i, name in ipairs(panel.tabs) do
        local tw = sx*0.86/#panel.tabs
        local tx = sx*0.07 + (i-1)*tw
        dxDrawRectangle(tx, sy*0.07, tw, 52, panel.tab==i and tocolor(60,160,255,100) or tocolor(0,0,0,0))
        dxDrawText(name, tx, sy*0.07, tx+tw, sy*0.07+52, tocolor(255,255,255), 1.15, "default-bold", "center", "center")
        if isMouseIn(tx, sy*0.07, tw, 52) and getKeyState("mouse1") and debounceClick() then panel.tab = i end
    end
    dxDrawText("Dinheiro: $"..(userData.money or 0), sx*0.84, sy*0.07+10, sx*0.91, sy*0.07+52, tocolor(200,255,120), 1.1, "default-bold", "right", "center")
    -- Notificação
    if notifyTimer > 0 and getTickCount() - notifyTimer < 3500 then
        dxDrawRectangle(sx/2-200, sy*0.07+60, 400, 40, tocolor(40,180,120,210))
        dxDrawText(notifyText, sx/2-200, sy*0.07+60, sx/2+200, sy*0.07+100, tocolor(255,255,255), 1.1, "default-bold", "center", "center")
    end
    -- Abas
    local px, py, pw, ph = sx*0.09, sy*0.15, sx*0.82, sy*0.76
    if panel.tab == 1 then drawTabWeapons(px,py,pw,ph) end
    if panel.tab == 2 then drawTabSkins(px,py,pw,ph) end
    if panel.tab == 3 then drawTabAttachments(px,py,pw,ph) end
    if panel.tab == 4 then drawTabUpgrades(px,py,pw,ph) end
    if panel.tab == 5 then drawTabLootboxes(px,py,pw,ph) end
    if panel.tab == 6 then drawTabCrafting(px,py,pw,ph) end
    if panel.tab == 7 then drawTabTrade(px,py,pw,ph) end
    if panel.tab == 8 then drawTabAchievements(px,py,pw,ph) end
    if panel.tab == 9 then drawTabStats(px,py,pw,ph) end
    -- Drag & Drop visual
    if dragItem and dragType and dragOrigin then
        local mx,my = getCursorPosition()
        mx,my = mx*sx, my*sy
        drawCard(dragType=="attachments" and "img/attachments/"..dragItem..".png" or "img/skins/"..dragItem..".png", dragItem, mx-40, my-40, 120, 60, true)
    end
end)

function drawTabWeapons(x, y, w, h)
    dxDrawText("Suas Armas", x+10, y, x+w, y+40, tocolor(255,255,180), 1.1, "default-bold", "left", "top")
    local weapons = userData.inventory and userData.inventory.weapons or {}
    local idx = 0
    for weaponId, amt in pairs(weapons) do
        idx=idx+1
        drawCard("img/weapons/"..weaponId..".png", weaponId:upper().." x"..amt, x+30, y+40+idx*70, 330, 60, false)
        -- Botão equipar
        if isMouseIn(x+300, y+40+idx*70, 60, 40) then
            dxDrawRectangle(x+300, y+40+idx*70, 60, 40, tocolor(60,185,100,220))
        else
            dxDrawRectangle(x+300, y+40+idx*70, 60, 40, tocolor(30,120,40,200))
        end
        dxDrawText("Equipar", x+300, y+40+idx*70, x+360, y+80+idx*70, tocolor(255,255,255), 1, "default-bold", "center", "center")
        if isMouseIn(x+300, y+40+idx*70, 60, 40) and getKeyState("mouse1") and debounceClick() then
            triggerServerEvent("panel:equip", resourceRoot, weaponId, nil, {}, {})
        end
    end
    dxDrawText("Comprar Arma:", x+410, y+10, x+w, y+40, tocolor(255,255,180), 1, "default-bold", "left", "top")
    drawCard("img/weapons/ak47.png", "AK-47\n$1000", x+420, y+50, 170, 60, false)
    if isMouseIn(x+520, y+70, 70, 30) then
        dxDrawRectangle(x+520, y+70, 70, 30, tocolor(60,185,100,220))
    else
        dxDrawRectangle(x+520, y+70, 70, 30, tocolor(30,120,40,200))
    end
    dxDrawText("Comprar", x+520, y+70, x+590, y+100, tocolor(255,255,255), 1, "default-bold", "center", "center")
    if isMouseIn(x+520, y+70, 70, 30) and getKeyState("mouse1") and debounceClick() then
        triggerServerEvent("panel:buyItem", resourceRoot, "weapons", "ak47", 1000)
    end
end

function drawTabSkins(x, y, w, h)
    dxDrawText("Skins da arma equipada", x+10, y, x+w, y+40, tocolor(255,255,200), 1.1, "default-bold", "left", "top")
    local equipped = userData.equipped or {}
    local skins = userData.inventory and userData.inventory.skins or {}
    local idx = 0
    for skinId, amt in pairs(skins) do
        idx=idx+1
        drawCard("img/skins/"..skinId..".png", skinId:upper().." x"..amt, x+30, y+40+idx*70, 220, 60, equipped.skin == skinId)
        if isMouseIn(x+30, y+40+idx*70, 220, 60) and getKeyState("mouse1") then
            dragItem, dragType, dragOrigin, dragActive = skinId, "skins", {tab=2, slot=idx}, true
        end
        if isMouseIn(x+200, y+40+idx*70, 60, 40) then
            dxDrawRectangle(x+200, y+40+idx*70, 60, 40, tocolor(60,185,100,220))
        else
            dxDrawRectangle(x+200, y+40+idx*70, 60, 40, tocolor(30,120,40,200))
        end
        dxDrawText("Aplicar", x+200, y+40+idx*70, x+260, y+80+idx*70, tocolor(255,255,255), 1, "default-bold", "center", "center")
        if isMouseIn(x+200, y+40+idx*70, 60, 40) and getKeyState("mouse1") and debounceClick() then
            triggerServerEvent("panel:equip", resourceRoot, "ak47", skinId, equipped.upgrades or {}, equipped.attachments or {})
        end
    end
    drawCard("img/skins/gold.png", "Gold\n$500", x+300, y+50, 170, 60, false)
    if isMouseIn(x+400, y+70, 70, 30) then
        dxDrawRectangle(x+400, y+70, 70, 30, tocolor(60,185,100,220))
    else
        dxDrawRectangle(x+400, y+70, 70, 30, tocolor(30,120,40,200))
    end
    dxDrawText("Comprar", x+400, y+70, x+470, y+100, tocolor(255,255,255), 1, "default-bold", "center", "center")
    if isMouseIn(x+400, y+70, 70, 30) and getKeyState("mouse1") and debounceClick() then
        triggerServerEvent("panel:buyItem", resourceRoot, "skins", "gold", 500)
    end
end

function drawTabAttachments(x, y, w, h)
    dxDrawText("Acessórios Equipados", x+10, y, x+w, y+40, tocolor(255,255,200), 1.1, "default-bold", "left", "top")
    local equipped = userData.equipped or {}
    local attachments = userData.inventory and userData.inventory.attachments or {}
    local slots = {"scope","silencer"}
    for i, slot in ipairs(slots) do
        local att = equipped.attachments and equipped.attachments[slot]
        drawCard("img/attachments/"..slot..".png", slot:upper(), x+30+i*180, y+60, 120, 60, att)
        if att and isMouseIn(x+30+i*180, y+60, 120, 60) and getKeyState("mouse1") then
            dragItem, dragType, dragOrigin, dragActive = slot, "attachments", {tab=3, slot=i}, true
        end
        if dragItem and dragType=="attachments" and isMouseIn(x+30+i*180, y+60, 120, 60) and getKeyState("mouse1") and not att and dragActive then
            triggerServerEvent("panel:applyAttachment", resourceRoot, "ak47", dragItem, true)
            dragItem, dragType, dragOrigin, dragActive = nil,nil,nil,false
        end
        if dragItem and dragType=="attachments" and att and dragActive and not isMouseIn(x+30+i*180, y+60, 120, 60) and not getKeyState("mouse1") then
            -- Remove attachment ao soltar fora
            triggerServerEvent("panel:applyAttachment", resourceRoot, "ak47", dragItem, false)
            dragItem, dragType, dragOrigin, dragActive = nil,nil,nil,false
        end
    end
    local idx=0
    for attId, amt in pairs(attachments) do
        idx=idx+1
        drawCard("img/attachments/"..attId..".png", attId:upper().." x"..amt, x+30, y+140+idx*70, 160, 60, false)
        if isMouseIn(x+30, y+140+idx*70, 160, 60) and getKeyState("mouse1") then
            dragItem, dragType, dragOrigin, dragActive = attId, "attachments", {tab=3, slot=idx}, true
        end
        if isMouseIn(x+150, y+140+idx*70, 60, 40) then
            dxDrawRectangle(x+150, y+140+idx*70, 60, 40, tocolor(60,185,100,220))
        else
            dxDrawRectangle(x+150, y+140+idx*70, 60, 40, tocolor(30,120,40,200))
        end
        dxDrawText("Equipar", x+150, y+140+idx*70, x+210, y+180+idx*70, tocolor(255,255,255), 1, "default-bold", "center", "center")
        if isMouseIn(x+150, y+140+idx*70, 60, 40) and getKeyState("mouse1") and debounceClick() then
            triggerServerEvent("panel:applyAttachment", resourceRoot, "ak47", attId, true)
        end
    end
    drawCard("img/attachments/scope.png", "Mira\n$250", x+350, y+180, 170, 60, false)
    if isMouseIn(x+430, y+200, 70, 30) then
        dxDrawRectangle(x+430, y+200, 70, 30, tocolor(60,185,100,220))
    else
        dxDrawRectangle(x+430, y+200, 70, 30, tocolor(30,120,40,200))
    end
    dxDrawText("Comprar", x+430, y+200, x+500, y+230, tocolor(255,255,255), 1, "default-bold", "center", "center")
    if isMouseIn(x+430, y+200, 70, 30) and getKeyState("mouse1") and debounceClick() then
        triggerServerEvent("panel:buyItem", resourceRoot, "attachments", "scope", 250)
    end
end

function drawTabUpgrades(x, y, w, h)
    dxDrawText("Upgrades", x+10, y, x+w, y+40, tocolor(255,255,200), 1.1, "default-bold", "left", "top")
    drawCard(nil, "Dano +10%\n$350", x+30, y+60, 160, 60, false)
    if isMouseIn(x+150, y+80, 70, 30) then
        dxDrawRectangle(x+150, y+80, 70, 30, tocolor(60,185,100,220))
    else
        dxDrawRectangle(x+150, y+80, 70, 30, tocolor(30,120,40,200))
    end
    dxDrawText("Comprar", x+150, y+80, x+220, y+110, tocolor(255,255,255), 1, "default-bold", "center", "center")
    if isMouseIn(x+150, y+80, 70, 30) and getKeyState("mouse1") and debounceClick() then
        triggerServerEvent("panel:buyItem", resourceRoot, "upgrades", "damage1", 350)
    end
end

function drawTabLootboxes(x, y, w, h)
    dxDrawText("Lootboxes", x+10, y, x+w, y+40, tocolor(255,255,200), 1.1, "default-bold", "left", "top")
    local lootboxes = userData.inventory and userData.inventory.lootboxes or {}
    local idx = 0
    for boxId, amt in pairs(lootboxes) do
        idx=idx+1
        drawCard("img/ui/lootbox.png", boxId:upper().." x"..amt, x+30, y+40+idx*70, 180, 60, false)
        if isMouseIn(x+150, y+40+idx*70, 60, 40) then
            dxDrawRectangle(x+150, y+40+idx*70, 60, 40, tocolor(60,185,100,220))
        else
            dxDrawRectangle(x+150, y+40+idx*70, 60, 40, tocolor(30,120,40,200))
        end
        dxDrawText("Abrir", x+150, y+40+idx*70, x+210, y+80+idx*70, tocolor(255,255,255), 1, "default-bold", "center", "center")
        if isMouseIn(x+150, y+40+idx*70, 60, 40) and getKeyState("mouse1") and debounceClick() then
            local rewards = {
                {type="weapons", id="ak47"},
                {type="skins", id="gold"},
                {type="attachments", id="scope"}
            }
            triggerServerEvent("panel:openLootbox", resourceRoot, boxId, rewards)
        end
    end
    drawCard("img/ui/lootbox.png", "Caixa\n$300", x+300, y+60, 170, 60, false)
    if isMouseIn(x+380, y+80, 70, 30) then
        dxDrawRectangle(x+380, y+80, 70, 30, tocolor(60,185,100,220))
    else
        dxDrawRectangle(x+380, y+80, 70, 30, tocolor(30,120,40,200))
    end
    dxDrawText("Comprar", x+380, y+80, x+450, y+110, tocolor(255,255,255), 1, "default-bold", "center", "center")
    if isMouseIn(x+380, y+80, 70, 30) and getKeyState("mouse1") and debounceClick() then
        triggerServerEvent("panel:buyItem", resourceRoot, "lootboxes", "box1", 300)
    end
end

function drawTabCrafting(x, y, w, h)
    dxDrawText("Crafting", x+10, y, x+w, y+40, tocolor(255,255,200), 1.1, "default-bold", "left", "top")
    drawCard("img/weapons/ak47.png", "AK-47 Dourada\nRequer: AK-47 + Gold", x+30, y+60, 260, 60, false)
    if isMouseIn(x+260, y+80, 70, 30) then
        dxDrawRectangle(x+260, y+80, 70, 30, tocolor(60,185,100,220))
    else
        dxDrawRectangle(x+260, y+80, 70, 30, tocolor(30,120,40,200))
    end
    dxDrawText("Craftar", x+260, y+80, x+330, y+110, tocolor(255,255,255), 1, "default-bold", "center", "center")
    if isMouseIn(x+260, y+80, 70, 30) and getKeyState("mouse1") and debounceClick() then
        local recipe = {
            need = {
                {type="weapons",id="ak47",amount=1},
                {type="skins",id="gold",amount=1}
            },
            result = {type="weapons",id="ak47_gold"}
        }
        triggerServerEvent("panel:craft", resourceRoot, recipe)
    end
end

function drawTabTrade(x, y, w, h)
    dxDrawText("Enviar Item para Jogador", x+10, y, x+w, y+40, tocolor(255,255,200), 1.1, "default-bold", "left", "top")
    dxDrawRectangle(x+30, y+50, 200, 36, tocolor(30,30,40,200))
    dxDrawText(tradeTarget, x+40, y+50, x+230, y+86, tocolor(255,255,255), 1, "default-bold", "left", "center")
    drawCard("img/attachments/scope.png", "Scope", x+250, y+50, 120, 60, false)
    if isMouseIn(x+400, y+70, 70, 30) then
        dxDrawRectangle(x+400, y+70, 70, 30, tocolor(60,185,100,220))
    else
        dxDrawRectangle(x+400, y+70, 70, 30, tocolor(30,120,40,200))
    end
    dxDrawText("Enviar", x+400, y+70, x+470, y+100, tocolor(255,255,255), 1, "default-bold", "center", "center")
    if isMouseIn(x+400, y+70, 70, 30) and getKeyState("mouse1") and debounceClick() then
        triggerServerEvent("panel:tradeItem", resourceRoot, tradeTarget, "attachments", "scope", 1)
    end
end

function drawTabAchievements(x, y, w, h)
    dxDrawText("Conquistas", x+10, y, x+w, y+40, tocolor(255,255,200), 1.1, "default-bold", "left", "top")
    local ach = userData.achievements or {}
    local idx = 0
    for id, unlocked in pairs(ach) do
        idx=idx+1
        drawCard(nil, id, x+30, y+40+idx*70, 230, 60, unlocked)
    end
end

function drawTabStats(x, y, w, h)
    dxDrawText("Estatísticas", x+10, y, x+w, y+40, tocolor(255,255,200), 1.1, "default-bold", "left", "top")
    dxDrawText("Kills: 0\nHeadshots: 0\nAbates: 0", x+30, y+60, x+330, y+200, tocolor(255,255,255), 1, "default-bold", "left", "top")
end

addEventHandler("onClientResourceStart", resourceRoot, function()
    local txd = engineLoadTXD("models/ak47.txd")
    if txd then engineImportTXD(txd, 355) end
    local dff = engineLoadDFF("models/ak47.dff", 355)
    if dff then engineReplaceModel(dff, 355) end
end)