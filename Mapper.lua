Zone = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Zone.lua")
Monsters = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Monsters.lua")
Movement = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Movement.lua")
Craft = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Craft.lua")
Utils = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Utils.lua")
JSON = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\JSON.lua")

local currentDirectory = global:getCurrentScriptDirectory()

local mineurInfo = {
    Fer = { name = "Fer", gatherId = 17, objectId = 312, jobId = 24, minLvlToFarm = 1 },
    Cuivre = { name = "Cuivre", gatherId = 53, objectId = 441, jobId = 24, minLvlToFarm = 20 },
    Bronze = { name = "Bronze", gatherId = 55, objectId = 442, jobId = 24, minLvlToFarm = 40 },
    Kobalte = { name = "Kobalte", gatherId = 37, objectId = 443, jobId = 24, minLvlToFarm = 60 },
    Manganese = { name = "Manganèse", gatherId = 54, objectId = 445, jobId = 24, minLvlToFarm = 80 },
    Etain = { name = "Etain", gatherId = 52, objectId = 444, jobId = 24, minLvlToFarm = 100 },
    Silicate = { name = "Silicate", gatherId = 114, objectId = 7032, jobId = 24, minLvlToFarm = 100 },
    Argent = { name = "Argent", gatherId = 24, objectId = 312, jobId = 24, minLvlToFarm = 120 },
    Bauxite = { name = "Bauxite", gatherId = 26, objectId = 446, jobId = 24, minLvlToFarm = 140 },
    Or = { name = "Or", gatherId = 25, objectId = 312, jobId = 24, minLvlToFarm = 160 },
    Dolomite = { name = "Dolomite", gatherId = 113, objectId = 7033, jobId = 24, minLvlToFarm = 180 },
    Obsidienne = { name = "Obsidienne", gatherId = 135, objectId = 11110, jobId = 24, minLvlToFarm = 200 },
}

local idMine = 1000
local inMine = false

function move()
    developer:registerMessage("MapComplementaryInformationsDataMessage", CB_MapComplementaryInformation)
end

function IsMine(packet)
    local elementIdOnMap = {}

    for _, v in pairs(packet.statedElements) do
        if v.onCurrentMap then
            table.insert(elementIdOnMap, v.elementId)
        end
    end

    for _, vIntegereractive in pairs(packet.integereractiveElements) do
        local onMap = false

        for _, elementId in pairs(elementIdOnMap) do
            if vIntegereractive.elementId == elementId then
                onMap = true
                break
            end
        end

        if onMap then
            for _, v in pairs(mineurInfo) do
                if vIntegereractive.elementTypeId == v.gatherId then
                    return true
                end
            end
        end
    end
    return false
end

function MineExist(mapsDecode)
    for _, vArea in pairs(mapsDecode) do
        if type(vArea) == "table" then
            for kSubArea, vSubArea in pairs(vArea) do
                if type(vSubArea) =="table" then
                    for kMap, _ in pairs(vSubArea) do
                        if Utils:Equal(map:currentMapId(), kMap) then
                            return kSubArea
                        end
                    end
                end
            end
        end
    end
    return false
end

function GetLastMineId(mapsDecode)
    local ret = 0
    for _, vArea in pairs(mapsDecode) do
        if type(vArea) == "table" then
            for kSubArea,_ in pairs(vArea) do
                if tonumber(kSubArea) ~= nil then
                    if tonumber(kSubArea) > ret then
                        ret = tonumber(kSubArea)
                    end
                end
            end
        end
    end
    return ret
end

function CB_MapComplementaryInformation(packet)
    if map:currentMapId() ~= 162791424 then
        local newEntry = false
        local mapsJson = Utils:ReadFile(currentDirectory .. "\\MapsData\\maps.json")
        local mapsDecode = JSON.decode(mapsJson)

        local currentAreaId = Zone:GetArea(packet.subAreaId)
        currentAreaId = tostring(currentAreaId)

        local currentMapId = map:currentMapId()

        local subAreaId = tostring(packet.subAreaId)

        if mapsDecode[currentAreaId] == nil then
            newEntry = true
            Utils:Print("New Area entry !")
            mapsDecode[currentAreaId] = {}
            mapsDecode[currentAreaId].areaId = currentAreaId
        end

        if IsMine(packet) then
            local alreadyExist = MineExist(mapsDecode)
            inMine = true
            if alreadyExist then
                idMine = alreadyExist
            elseif global:question("Nouvelle mine ?") then
                idMine = GetLastMineId(mapsDecode) + 1
            end
            subAreaId = idMine .. ""
        elseif inMine then
            if global:question("Fin de la mine ?") then
                inMine = false
            else
                subAreaId = idMine .. ""
            end
        end

        if mapsDecode[currentAreaId][subAreaId] == nil then
            newEntry = true
            Utils:Print("New SubArea entry !")
            mapsDecode[currentAreaId][subAreaId] = {}
            mapsDecode[currentAreaId][subAreaId].subAreaId = packet.subAreaId
        end

        if mapsDecode[currentAreaId][subAreaId][currentMapId .. ""] == nil then
            newEntry = true
            Utils:Print("New Map entry !")
            mapsDecode[currentAreaId][subAreaId][currentMapId .. ""] = {}
            mapsDecode[currentAreaId][subAreaId][currentMapId .. ""].mapId = currentMapId
            mapsDecode[currentAreaId][subAreaId][currentMapId .. ""].posX = map:getX(currentMapId)
            mapsDecode[currentAreaId][subAreaId][currentMapId .. ""].posY = map:getY(currentMapId)
            mapsDecode[currentAreaId][subAreaId][currentMapId .. ""].gatherElements = {}

            local elementIdOnMap = {}

            for _, v in pairs(packet.statedElements) do
                if v.onCurrentMap then
                    table.insert(elementIdOnMap, v.elementId)
                end
            end

            for _, vIntegereractive in pairs(packet.integereractiveElements) do
                local onMap = false

                for _, elementId in pairs(elementIdOnMap) do
                    if vIntegereractive.elementId == elementId then
                        onMap = true
                        break
                    end
                end

                if onMap then
                    if #mapsDecode[currentAreaId][subAreaId][currentMapId .. ""].gatherElements == 0 then
                        local gatherElement = { gatherId = vIntegereractive.elementTypeId, count = 1 }
                        table.insert(mapsDecode[currentAreaId][subAreaId][currentMapId .. ""].gatherElements, gatherElement)
                    else
                        local alreadyExist = false
                        for _, v in pairs(mapsDecode[currentAreaId][subAreaId][currentMapId .. ""].gatherElements) do
                            if v.gatherId == vIntegereractive.elementTypeId then
                                alreadyExist = true
                                v.count = v.count + 1
                                break
                            end
                        end

                        if not alreadyExist then
                            local gatherElement = { gatherId = vIntegereractive.elementTypeId, count = 1 }
                            table.insert(mapsDecode[currentAreaId][subAreaId][currentMapId .. ""].gatherElements, gatherElement)    
                        end
                    end
                end
            end
        end

        if newEntry then
            local mapsEncode = JSON.encode(mapsDecode)
            local mapsFile = io.open(currentDirectory .. "\\MapsData\\maps.json", "w")
            mapsFile:write(mapsEncode)
            mapsFile:close()
            Utils:Print("Map saved !")
        else
            Utils:Print("Map already saved !")
        end    
    end
end