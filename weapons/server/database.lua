-- Banco de dados robusto para armas, skins, attachments, upgrades, trocas e dinheiro

local db

function dbInit()
    db = dbConnect("sqlite", "weapon_custom.db")
    -- Inventário geral do jogador (itemType: weapon/skin/attachment/lootbox)
    dbExec(db, [[CREATE TABLE IF NOT EXISTS inventory (
        account TEXT,
        itemType TEXT,
        itemId TEXT,
        amount INTEGER DEFAULT 1,
        PRIMARY KEY (account, itemType, itemId)
    );]])
    -- Dados de armas equipadas: skin, upgrades, attachments (arma=única por vez)
    dbExec(db, [[CREATE TABLE IF NOT EXISTS equipped (
        account TEXT,
        weaponId TEXT,
        skinId TEXT,
        upgrades TEXT,
        attachments TEXT,
        PRIMARY KEY (account, weaponId)
    );]])
    -- Dinheiro do jogador
    dbExec(db, [[CREATE TABLE IF NOT EXISTS money (
        account TEXT PRIMARY KEY,
        amount INTEGER DEFAULT 0
    );]])
    -- Achievements
    dbExec(db, [[CREATE TABLE IF NOT EXISTS achievements (
        account TEXT,
        achievementId TEXT,
        unlockedAt INTEGER,
        PRIMARY KEY (account, achievementId)
    );]])
    -- Log de trocas (opcional para histórico)
    dbExec(db, [[CREATE TABLE IF NOT EXISTS trades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fromAccount TEXT,
        toAccount TEXT,
        itemType TEXT,
        itemId TEXT,
        amount INTEGER,
        tradeTime INTEGER
    );]])
end

addEventHandler("onResourceStart", resourceRoot, dbInit)

-- Helper para pegar nome seguro da account
function getAccountNameSafe(player)
    local acc = getPlayerAccount(player)
    if acc and not isGuestAccount(acc) then return getAccountName(acc) end
    return false
end

-----------------------
-- INVENTÁRIO         --
-----------------------
function getInventory(account)
    local qh = dbQuery(db, "SELECT itemType, itemId, amount FROM inventory WHERE account=?", account)
    local rows = dbPoll(qh, -1)
    local inv = {weapons={},skins={},attachments={},lootboxes={}}
    if type(rows) == "table" then
        for _, row in ipairs(rows) do
            inv[row.itemType][row.itemId] = row.amount
        end
    end
    return inv
end

function addInventory(account, itemType, itemId, amount)
    amount = amount or 1
    local qh = dbQuery(db, "SELECT amount FROM inventory WHERE account=? AND itemType=? AND itemId=?", account, itemType, itemId)
    local rows = dbPoll(qh, -1)
    local current = (rows and rows[1] and rows[1].amount) or 0
    dbExec(db, [[
        INSERT OR REPLACE INTO inventory (account, itemType, itemId, amount)
        VALUES (?, ?, ?, ?)
    ]], account, itemType, itemId, current + amount)
end

function removeInventory(account, itemType, itemId, amount)
    amount = amount or 1
    local qh = dbQuery(db, "SELECT amount FROM inventory WHERE account=? AND itemType=? AND itemId=?", account, itemType, itemId)
    local rows = dbPoll(qh, -1)
    local current = (rows and rows[1] and rows[1].amount) or 0
    local newAmt = math.max(current - amount, 0)
    if newAmt == 0 then
        dbExec(db, "DELETE FROM inventory WHERE account=? AND itemType=? AND itemId=?", account, itemType, itemId)
    else
        dbExec(db, "UPDATE inventory SET amount=? WHERE account=? AND itemType=? AND itemId=?", newAmt, account, itemType, itemId)
    end
end

function hasInventory(account, itemType, itemId, amount)
    local inv = getInventory(account)
    return (inv[itemType][itemId] or 0) >= (amount or 1)
end

-----------------------
-- EQUIPAMENTO DE ARMAS/SKINS/ATTACHMENTS --
-----------------------
function setEquipped(account, weaponId, skinId, upgrades, attachments)
    dbExec(db, [[
        INSERT OR REPLACE INTO equipped (account, weaponId, skinId, upgrades, attachments)
        VALUES (?, ?, ?, ?, ?)
    ]], account, weaponId, skinId or "", toJSON(upgrades or {}), toJSON(attachments or {}))
end

function getEquipped(account, weaponId)
    local qh = dbQuery(db, "SELECT skinId, upgrades, attachments FROM equipped WHERE account=? AND weaponId=?", account, weaponId)
    local rows = dbPoll(qh, -1)
    if rows and #rows > 0 then
        return {
            skin = rows[1].skinId,
            upgrades = fromJSON(rows[1].upgrades) or {},
            attachments = fromJSON(rows[1].attachments) or {}
        }
    end
    return {skin = "", upgrades = {}, attachments = {}}
end

-----------------------
-- DINHEIRO           --
-----------------------
function getMoney(account)
    local qh = dbQuery(db, "SELECT amount FROM money WHERE account=?", account)
    local rows = dbPoll(qh, -1)
    if rows and #rows > 0 then return rows[1].amount end
    return 0
end

function setMoney(account, value)
    dbExec(db, [[INSERT OR REPLACE INTO money (account, amount) VALUES (?, ?)]], account, value)
end

function giveMoney(account, value)
    setMoney(account, getMoney(account) + value)
end

function takeMoney(account, value)
    setMoney(account, math.max(0, getMoney(account) - value))
end

-----------------------
-- ACHIEVEMENTS       --
-----------------------
function getAchievements(account)
    local qh = dbQuery(db, "SELECT achievementId, unlockedAt FROM achievements WHERE account=?", account)
    local rows = dbPoll(qh, -1)
    local achs = {}
    if type(rows) == "table" then
        for _, row in ipairs(rows) do
            achs[row.achievementId] = row.unlockedAt or true
        end
    end
    return achs
end

function unlockAchievement(account, achId)
    dbExec(db, [[INSERT OR REPLACE INTO achievements (account, achievementId, unlockedAt) VALUES (?, ?, ?)]], account, achId, getRealTime().timestamp)
end

-----------------------
-- TROCA ENTRE JOGADORES --
-----------------------
function tradeItem(fromAccount, toAccount, itemType, itemId, amount)
    if not hasInventory(fromAccount, itemType, itemId, amount) then return false end
    removeInventory(fromAccount, itemType, itemId, amount)
    addInventory(toAccount, itemType, itemId, amount)
    dbExec(db, [[INSERT INTO trades (fromAccount, toAccount, itemType, itemId, amount, tradeTime) VALUES (?, ?, ?, ?, ?, ?)]],
        fromAccount, toAccount, itemType, itemId, amount, getRealTime().timestamp)
    return true
end