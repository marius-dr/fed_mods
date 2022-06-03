--[[
Copyright (C) Achimobil, 2022

Author: Achimobil
Date: 02.05.2022
Version: 0.2.0.0

Contact:
https://forum.giants-software.com
https://discord.gg/Va7JNnEkcW

History:
V 0.1.0.0 @ 24.04.2022 - First Version.
V 0.2.0.0 @ 02.05.2022 - Added simple CollisionMash Change on Visible Change

Important:
Free for use in other mods - no permission needed, only provide my name.
No changes are to be made to this script without permission from Achimobil.

Frei verwendbar - keine erlaubnis nötig, Namensnennung im Mod erforderlich.
An diesem Skript dürfen ohne Genehmigung von Achimobil keine Änderungen vorgenommen werden.
]]

SiloObjectFillLevelSpezialisation = {};

function SiloObjectFillLevelSpezialisation.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(PlaceableSilo, specializations);
end

function SiloObjectFillLevelSpezialisation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", SiloObjectFillLevelSpezialisation);
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", SiloObjectFillLevelSpezialisation);
	SpecializationUtil.registerEventListener(placeableType, "onPostFinalizePlacement", SiloObjectFillLevelSpezialisation);
end

function SiloObjectFillLevelSpezialisation.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateObjectFillLevels", SiloObjectFillLevelSpezialisation.updateObjectFillLevels);
end

function SiloObjectFillLevelSpezialisation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SiloDisplay");
    
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".silo.siloObjectFillLevels.siloObjectFillLevel(?)#rootNode", "Root Node, all directChilds are taken from as filltype");
	schema:register(XMLValueType.STRING, basePath .. ".silo.siloObjectFillLevels.siloObjectFillLevel(?)#fillType", "Filltype name for the Display to show amount");
	schema:register(XMLValueType.STRING, basePath .. ".silo.siloObjectFillLevels.siloObjectFillLevel(?)#maxAtFillLevel", "this fill level is showing all childs");
    
	schema:setXMLSpecializationType();
end

function SiloObjectFillLevelSpezialisation:onLoad(savegame)
    self.spec_siloObjectFillLevel = {};
	local spec = self.spec_siloObjectFillLevel;
	local xmlFile = self.xmlFile;

	spec.siloObjectFillLevels = {};
	local i = 0;

	while true do
		local siloObjectFillLevelKey = string.format("placeable.silo.siloObjectFillLevels.siloObjectFillLevel(%d)", i);

		if not xmlFile:hasProperty(siloObjectFillLevelKey) then
			break;
		end
        
        local siloObjectFillLevel = {};
        
		local rootNode = self.xmlFile:getValue(siloObjectFillLevelKey .. "#rootNode", nil, self.components, self.i3dMappings);
        siloObjectFillLevel.rootNode = rootNode;
        
        -- get childs
		local numChildren = getNumOfChildren(rootNode)

        siloObjectFillLevel.ChildNodeIds = {};
		for i = 0, numChildren - 1 do
			table.insert(siloObjectFillLevel.ChildNodeIds, getChildAt(rootNode, i))
		end        
        
        local fillTypeName = xmlFile:getValue(siloObjectFillLevelKey .. "#fillType");
        siloObjectFillLevel.fillTypeId = g_fillTypeManager:getFillTypeIndexByName(fillTypeName);
        siloObjectFillLevel.maxAtFillLevel = xmlFile:getValue(siloObjectFillLevelKey .. "#maxAtFillLevel");
        siloObjectFillLevel.fillLevelStep = siloObjectFillLevel.maxAtFillLevel / numChildren;
        
        table.insert(spec.siloObjectFillLevels, siloObjectFillLevel);

		i = i + 1;
	end
    
	function spec.fillLevelChangedCallback(fillType, delta)
        self:updateObjectFillLevels();
	end    
end

function SiloObjectFillLevelSpezialisation:onFinalizePlacement(savegame)
	local spec = self.spec_siloObjectFillLevel;
	for _, sourceStorage in pairs(self.spec_silo.loadingStation:getSourceStorages()) do
        sourceStorage:addFillLevelChangedListeners(spec.fillLevelChangedCallback);
    end
end

function SiloObjectFillLevelSpezialisation:onPostFinalizePlacement(savegame)
    self:updateObjectFillLevels();
end


function SiloObjectFillLevelSpezialisation:updateObjectFillLevels()
	local spec = self.spec_siloObjectFillLevel;
	local farmId = self:getOwnerFarmId();
    
	for _, siloObjectFillLevel in pairs(spec.siloObjectFillLevels) do
		local fillLevel = self.spec_silo.loadingStation:getFillLevel(siloObjectFillLevel.fillTypeId, farmId);
        
        --  hier bestimmen, was alles sichtbar oder unsichtbar sein soll
        local current = 1;
        for _, childNodeId in pairs(siloObjectFillLevel.ChildNodeIds) do
            if fillLevel >= (current * siloObjectFillLevel.fillLevelStep) then
                setVisibility(childNodeId, true);
                
                setCollisionMask(childNodeId, 1001002)
                local numChildren = getNumOfChildren(childNodeId)
                for i = 0, numChildren - 1 do
                    setCollisionMask(getChildAt(childNodeId, i), 1001002)
                end        
                
            else
                setVisibility(childNodeId, false);
                
                setCollisionMask(childNodeId, 0)
                local numChildren = getNumOfChildren(childNodeId)
                for i = 0, numChildren - 1 do
                    setCollisionMask(getChildAt(childNodeId, i), 0)
                end        
            end
            current = current + 1;
        end
        
	end
end