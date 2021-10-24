Zone = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Zone.lua")
Monsters = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Monsters.lua")
Movement = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Movement.lua")
Craft = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Craft.lua")
Utils = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\Utils.lua")
JSON = dofile(global:getCurrentDirectory() .. "\\YAYA\\Module\\JSON.lua")

local currentDirectory = global:getCurrentScriptDirectory()

function move()
    developer:registerMessage("MapComplementaryInformationsDataMessage", CB_MapComplementaryInformation)
end

function CB_MapComplementaryInformation(packet)
    if map:currentMapId() ~= 162791424 then
        local newEntry = false
        local mapsJson = Utils:ReadFile(currentDirectory .. "\\MapsData\\maps.json")
        local mapsDecode = JSON.decode(mapsJson)

        local currentAreaId = Zone:GetArea(packet.subAreaId)
        currentAreaId = tostring(currentAreaId)

        local currentMapId = map:currentMapId()

        local currentPos = map:getX(currentMapId) .. "," .. map:getY(currentMapId)

        if mapsDecode[currentAreaId] == nil then
            newEntry = true
            Utils:Print("New Area entry !")
            mapsDecode[currentAreaId] = {}
            mapsDecode[currentAreaId].areaId = currentAreaId
        end

        if mapsDecode[currentAreaId][tostring(packet.subAreaId)] == nil then
            newEntry = true
            Utils:Print("New SubArea entry !")
            mapsDecode[currentAreaId][tostring(packet.subAreaId)] = {}
            mapsDecode[currentAreaId][tostring(packet.subAreaId)].subAreaId = packet.subAreaId
        end

        if mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos] == nil then
            newEntry = true
            Utils:Print("New Map entry !")
            mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos] = {}
            mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos].mapId = currentMapId
            mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos].posX = map:getX(currentMapId)
            mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos].posY = map:getY(currentMapId)
            mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos].gatherElements = {}

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
                    if #mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos].gatherElements == 0 then
                        local gatherElement = { gatherId = vIntegereractive.elementTypeId, count = 1 }
                        table.insert(mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos].gatherElements, gatherElement)
                    else
                        local alreadyExist = false
                        for _, v in pairs(mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos].gatherElements) do
                            if v.gatherId == vIntegereractive.elementTypeId then
                                alreadyExist = true
                                v.count = v.count + 1
                                break
                            end
                        end

                        if not alreadyExist then
                            local gatherElement = { gatherId = vIntegereractive.elementTypeId, count = 1 }
                            table.insert(mapsDecode[currentAreaId][tostring(packet.subAreaId)][currentPos].gatherElements, gatherElement)    
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