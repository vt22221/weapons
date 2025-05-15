-- Lógica principal do resource: armas, skins, attachments, upgrades, lootboxes, crafting, conquistas, transferências

local function getAccountSafe(p)
    local acc = getPlayerAccount(p)
    if acc and not isGuestAccount(acc) then return getAccountName(acc) end
    return false
end

-- Sincronização de todos os dados do jogador para o painel
addEvent("panel:requestSync", true)
addEventHandler("panel:requestSync", root, function()
    local acc = getAccountSafe(client)
    if not acc then return end
    triggerClientEvent(client, "panel:sync", resourceRoot, {
        inventory = getInventory(acc),
        equipped = getEquipped(acc, "ak47"), -- Exemplo para AK-47, pode expandir para outras armas
        money = getMoney(acc),
        achievements = getAchievements(acc)
    })
end)

-- Comprar qualquer item (arma, skin, attachment, lootbox, upgrade)
addEvent("panel:buyItem", true)
addEventHandler("panel:buyItem", root, function(itemType, itemId, price)
    local acc = getAccountSafe(client)
    if not acc then return end
    if getMoney(acc) < price then
        triggerClientEvent(client, "panel:notify", resourceRoot, "Dinheiro insuficiente.")
        return
    end
    takeMoney(acc, price)
    addInventory(acc, itemType, itemId, 1)
    triggerClientEvent(client, "panel:notify", resourceRoot, "Compra realizada!")
    triggerEvent("panel:requestSync", client)
end)

-- Equipar arma/skin/attachments/upgrades
addEvent("panel:equip", true)
addEventHandler("panel:equip", root, function(weaponId, skinId, upgrades, attachments)
    local acc = getAccountSafe(client)
    if not acc then return end
    setEquipped(acc, weaponId, skinId, upgrades or {}, attachments or {})
    triggerClientEvent(client, "panel:equipped", resourceRoot, weaponId, skinId, upgrades or {}, attachments or {})
    triggerEvent("panel:requestSync", client)
end)

-- Aplicar/remover attachment (adicionar/remove do inventário, atualizar arma equipada)
addEvent("panel:applyAttachment", true)
addEventHandler("panel:applyAttachment", root, function(weaponId, attachmentId, apply)
    local acc = getAccountSafe(client)
    if not acc then return end
    local inv = getInventory(acc)
    local eq = getEquipped(acc, weaponId)
    if apply then
        if not hasInventory(acc, "attachments", attachmentId, 1) then
            triggerClientEvent(client, "panel:notify", resourceRoot, "Você não possui esse acessório.")
            return
        end
        eq.attachments[attachmentId] = true
        removeInventory(acc, "attachments", attachmentId, 1)
    else
        if eq.attachments[attachmentId] then
            eq.attachments[attachmentId] = nil
            addInventory(acc, "attachments", attachmentId, 1)
        end
    end
    setEquipped(acc, weaponId, eq.skin, eq.upgrades, eq.attachments)
    triggerClientEvent(client, "panel:notify", resourceRoot, apply and "Acessório equipado!" or "Acessório removido!")
    triggerClientEvent(client, "panel:equipped", resourceRoot, weaponId, eq.skin, eq.upgrades, eq.attachments)
    triggerEvent("panel:requestSync", client)
end)

-- Troca de attachments ou skins entre jogadores
addEvent("panel:tradeItem", true)
addEventHandler("panel:tradeItem", root, function(targetPlayerName, itemType, itemId, amount)
    local acc = getAccountSafe(client)
    if not acc then return end
    local pTarget
    for _, p in ipairs(getElementsByType("player")) do
        if getPlayerName(p):gsub("#%x%x%x%x%x%x", ""):lower() == targetPlayerName:lower() then
            pTarget = p
            break
        end
    end
    if not pTarget then
        triggerClientEvent(client, "panel:notify", resourceRoot, "Jogador não encontrado.")
        return
    end
    local accTarget = getAccountSafe(pTarget)
    if not accTarget then
        triggerClientEvent(client, "panel:notify", resourceRoot, "Jogador alvo não autenticado.")
        return
    end
    if not hasInventory(acc, itemType, itemId, amount) then
        triggerClientEvent(client, "panel:notify", resourceRoot, "Você não possui quantidade suficiente.")
        return
    end
    if tradeItem(acc, accTarget, itemType, itemId, amount) then
        triggerClientEvent(client, "panel:notify", resourceRoot, "Item enviado com sucesso!")
        triggerClientEvent(pTarget, "panel:notify", resourceRoot, "Você recebeu um item de "..getPlayerName(client))
        triggerEvent("panel:requestSync", client)
        triggerEvent("panel:requestSync", pTarget)
    else
        triggerClientEvent(client, "panel:notify", resourceRoot, "Falha ao enviar item.")
    end
end)

-- Abrir lootbox
addEvent("panel:openLootbox", true)
addEventHandler("panel:openLootbox", root, function(boxId, rewards)
    local acc = getAccountSafe(client)
    if not acc then return end
    if not hasInventory(acc, "lootboxes", boxId, 1) then return end
    removeInventory(acc, "lootboxes", boxId, 1)
    local reward = rewards[math.random(1, #rewards)]
    addInventory(acc, reward.type, reward.id, 1)
    triggerClientEvent(client, "panel:lootboxResult", resourceRoot, reward)
    triggerEvent("panel:requestSync", client)
end)

-- Crafting
addEvent("panel:craft", true)
addEventHandler("panel:craft", root, function(recipe)
    local acc = getAccountSafe(client)
    if not acc then return end
    for _, need in ipairs(recipe.need) do
        if not hasInventory(acc, need.type, need.id, need.amount or 1) then
            triggerClientEvent(client, "panel:notify", resourceRoot, "Você não tem os materiais!")
            return
        end
    end
    for _, need in ipairs(recipe.need) do
        removeInventory(acc, need.type, need.id, need.amount or 1)
    end
    addInventory(acc, recipe.result.type, recipe.result.id, 1)
    triggerClientEvent(client, "panel:notify", resourceRoot, "Craft realizado!")
    triggerEvent("panel:requestSync", client)
end)

-- Ganhar conquista
addEvent("panel:unlockAchievement", true)
addEventHandler("panel:unlockAchievement", root, function(achId)
    local acc = getAccountSafe(client)
    if not acc then return end
    unlockAchievement(acc, achId)
    triggerEvent("panel:requestSync", client)
end)

-- Ganhar dinheiro (exemplo, pode ser por kill/atividade)
addEvent("panel:giveMoney", true)
addEventHandler("panel:giveMoney", root, function(amount)
    local acc = getAccountSafe(client)
    if not acc then return end
    giveMoney(acc, amount)
    triggerClientEvent(client, "panel:notify", resourceRoot, "Você recebeu $"..amount.."!")
    triggerEvent("panel:requestSync", client)
end)