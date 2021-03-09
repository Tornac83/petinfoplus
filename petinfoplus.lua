--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'Created by atom0s Modified by Tornac';
_addon.name     = 'petinfo';
_addon.version  = '3.0.5';

require 'common'
require 'settings'
require 'tableex'
require 'stringex'
require 'ffxi.targets'
require 'ffxi.enums'
require 'ffxi.recast'

petNames = { "BlackbeardRandy" , "SwoopingZhivago" , "PonderingPeter" }

--print(TargetEntityId.ClaimServerId)
--print(player.ServerId)
--TargetName = TargetEntityId.Name
--TargetHealth = TargetEntityId.HealthPercent

---------------------------------------------------------------
-- sees if any values are in a given table.
---------------------------------------------------------------

function contains(table, val)
   for i=1,#table do
      if table[i] == val then 
         return true
      end
   end
   return false;
end;

----------------------------------------------------------------------------------------------------
-- func: GetItemCount
-- desc: Obtains a item count of a item across all containers.
----------------------------------------------------------------------------------------------------
local function GetItemCount(thing)
    local inv = AshitaCore:GetDataManager():GetInventory();
    local ret = 0;

	for y = 0, 12 do
		for x = 0, 81 do
			local item = inv:GetItem(y, x);
			if (item ~= nil and item.Id == thing and item.Id ~= 65535) then
				ret = item.Count + ret;
			end
		end
	end
    return ret;
end

----------------------------------------------------------------------------------------------------
-- func: GetEquippedItemId
-- desc: Gets the item id of the current equipped item.
----------------------------------------------------------------------------------------------------
function GetEquippedItemId(Slot)
	local eitem = AshitaCore:GetDataManager():GetInventory():GetEquippedItem(Slot);
	local iitem = AshitaCore:GetDataManager():GetInventory():GetItem((bit.band(eitem.ItemIndex, 0xFF00) / 256), (eitem.ItemIndex % 256));
	return iitem.Id;
end;

----------------------------------------------------------------------------------------------------
-- func: GetCharges
-- desc: Gets the charges for on the ready timer.
----------------------------------------------------------------------------------------------------
function GetCharges()
	if (recastTimerPetAbility == 0)then
		return 3
	elseif (recastTimerPetAbility > 1800)then
		return 0
	elseif (recastTimerPetAbility > 900)then
		return 1
	elseif (recastTimerPetAbility <= 900)then
		return 2
	end
	return 42
end;

----------------------------------------------------------------------------------------------------
-- func: GetEntityByServerId
-- desc: Gets the entity of the mob by the server id.
----------------------------------------------------------------------------------------------------
function GetEntityByServerId(id)
    for x = 0, 2303 do
        -- Get the entity..
        local e = GetEntity(x);

        -- Ensure the entity is valid..
        if (e ~= nil and e.WarpPointer ~= 0) then
            if (e.ServerId == id) then
				--print(e.Name)
                return e;
            end
        end
    end
    return nil;
end

ashita.register_event('incoming_packet', function(id, size, packet)

    --Get action packet to use for pets target.
	if id == 0x028 then
	
		   -- Obtain the local player..
		player = GetPlayerEntity();

		if (player.PetTargetIndex == 0) then
		
		else
		   
		   -- Obtain the players pet..
			pet = GetEntity(player.PetTargetIndex);
			if (pet == nil) then
			
			else
			
			actorId = struct.unpack('I', packet, 0x05 + 1)
				if pet.ServerId == actorId then
					TargetServerId = ashita.bits.unpack_be(packet, 150, 32);
					if TargetServerId ~= pet.ServerId then
						TargetEntityId = GetEntityByServerId(TargetServerId)
					end
				end
				if TargetServerId == actorId then
					TargetCount = struct.unpack('b', packet, 0x09 + 1);
					TargetType = ashita.bits.unpack_be(packet, 82, 4);
					TargetParam = ashita.bits.unpack_be(packet, 86, 16);
					TargetTargetServerId = ashita.bits.unpack_be(packet, 150, 32);
					TargetTargetServerIdTest = ashita.bits.unpack_be(packet, 0x16, 6, 4);
					
					if TargetCount > 1 then
						TargetTargetServerIdTwo = ashita.bits.unpack_be(packet, 0x22,  1, 32);
						TargetTargetEntityIdTwo = GetEntityByServerId(TargetTargetServerIdTwo)
					else
						if  (os.time() >= (5 + 0)) then
							objTimer = os.time();
							TargetTargetEntityIdTwo = nil
						end
					end

					--print(TargetServerId)
					--print(TargetTargetServerIdTwo)
					if TargetTargetServerId ~= TargetServerId  then
						TargetTargetEntityId = GetEntityByServerId(TargetTargetServerId)
						TargetTargetEntityIdTest = GetEntityByServerId(TargetTargetServerIdTest)
					end
				end
			end
		end
	end
	return false;
end);


--local r = AshitaCore:GetResourceManager();
--local TargetEntityId = r:GetItemById(8193);
--print(TargetEntityId.Name[0]);

WindowY = 120
AddBar =	20
AddLine	=	18

----------------------------------------------------------------------------------------------------
-- func: render
-- desc: Called when the addon is rendering.
----------------------------------------------------------------------------------------------------
ashita.register_event('render', function()

    -- Obtain the local player..
    local player = GetPlayerEntity();
    if (player == nil) then
        return;
    end
    
    -- Obtain the players pet index..
    if (player.PetTargetIndex == 0) then
        return;
    end
    
    -- Obtain the players pet..
    local pet = GetEntity(player.PetTargetIndex);
    if (pet == nil) then
        return;
    end
	
    -- Display the pet information..
    imgui.SetNextWindowSize(200, WindowY, ImGuiSetCond_Always);
    if (imgui.Begin('PetInfo') == false) then
        imgui.End();
        return;
    end

    local pettp 			= AshitaCore:GetDataManager():GetPlayer():GetPetTP();
    local petmp 			= AshitaCore:GetDataManager():GetPlayer():GetPetMP();
	local pett  			= AshitaCore:GetDataManager():GetTarget():GetTargetName();
	local MainJob 			= AshitaCore:GetDataManager():GetPlayer():GetMainJob();
	local SubJob			= AshitaCore:GetDataManager():GetPlayer():GetSubJob();
	recastTimerPetAbility  	= ashita.ffxi.recast.get_ability_recast_by_id(102);
    
	--print(GetEquippedItemId(0))
	
	--print(GetItemCount(19252))
				
	--print(GetItemCount(17920))
	
	
    imgui.Text(pet.Name);
	imgui.SameLine(125);
	imgui.Text('Dist: ');
	imgui.SameLine();
	imgui.Text(math.floor(pet.Distance));
	if (MainJob == 9 or SubJob == 9) then
		imgui.Text('PP: ');
		imgui.SameLine();
		imgui.Text(GetItemCount(19252));
		imgui.SameLine();
		imgui.Text('Jug: ');
		imgui.SameLine();
		imgui.Text(GetItemCount(17920));
	else
		WindowY = 100
	end
    imgui.Separator();
    
    -- Set the progressbar color for health..
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, 1.0, 0.61, 0.61, 0.6);
    imgui.Text('HP:');
    imgui.SameLine();
    imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
    imgui.ProgressBar(pet.HealthPercent / 100, -1, 14);
    imgui.PopStyleColor(2);
    
	if  contains(petNames , pet.Name) then
		WindowY = WindowY - AddBar
	else
		--print(petNames[0])
		imgui.PushStyleColor(ImGuiCol_PlotHistogram, 0.0, 0.61, 0.61, 0.6);
		imgui.Text('MP:');
		imgui.SameLine();
		imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
		imgui.ProgressBar(petmp / 100, -1, 14);
		imgui.PopStyleColor(2);
	end
	
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, 0.4, 1.0, 0.4, 0.6);
    imgui.Text('TP:');
    imgui.SameLine();
    imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
    imgui.ProgressBar(pettp / 3000, -1, 14, tostring(pettp));
    imgui.PopStyleColor(2);
	
	
	if (MainJob == 9 or SubJob == 9 and GetCharges() ~= nil ) then
		
		imgui.PushStyleColor(ImGuiCol_PlotHistogram, 0.4, 1.0, 0.4, 0.6);
		imgui.Text('SN:');
		imgui.SameLine();
		imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
		imgui.ProgressBar(GetCharges() / 3, -1, 14, GetCharges());
		imgui.PopStyleColor(2);
	else
		WindowY = 120
	end
	
	
	if TargetEntityId ~= nil then
		TargetName = TargetEntityId.Name
		TargetHealth = TargetEntityId.HealthPercent
	end
	
	if TargetTargetEntityId ~= nil then
		TargetTargetName = TargetTargetEntityId.Name
		TargetTargetHealth = TargetTargetEntityId.HealthPercent
	end
	
	if (pet.Status == 1 and TargetHealth == 0) then
		TargetName = AshitaCore:GetDataManager():GetTarget():GetTargetName()
		TargetHealth = AshitaCore:GetDataManager():GetTarget():GetTargetHealthPercent()
		TargetTargetEntityId = nil
	end
		
	if (TargetHealth ~= 0 and pet.Status == 1 and TargetEntityId ~= nil) then
		WindowY = 179
		imgui.Separator();
		imgui.PushStyleColor(ImGuiCol_PlotHistogram, 1.0, 0.61, 0.61, 0.6);
		imgui.Text('Target:');
		imgui.SameLine();
		imgui.Text(TargetName);

		imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
		imgui.ProgressBar(tonumber(TargetHealth) / 100, -1, 14);
		imgui.PopStyleColor(2);
		
		if (TargetHealth ~= 0 and pet.Status == 1 and TargetTargetEntityId ~= nil) then
			WindowY = 195 --178,210
			imgui.Separator();
			imgui.PushStyleColor(ImGuiCol_PlotHistogram, 1.0, 0.61, 0.61, 0.6);
			imgui.Text('TTarget:');
			imgui.SameLine();
			imgui.Text(TargetTargetName);
			imgui.SameLine();
			imgui.Text('#:');
			imgui.SameLine();
			imgui.Text(TargetCount);
			--imgui.Text(TargetType);
			--imgui.Text(TargetParam);

			imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
			imgui.ProgressBar(tonumber(TargetTargetHealth) / 100, -1, 14);
			imgui.PopStyleColor(2);
			if (TargetTargetEntityIdTwo ~= nil) then
				WindowY = 190 --210
				imgui.Text('TTarget2:');
				imgui.SameLine();
				imgui.Text(TargetTargetEntityIdTwo.Name);
				TargetTargetTwoHealth = TargetTargetEntityIdTwo.HealthPercent;
				imgui.ProgressBar(tonumber(TargetTargetTwoHealth) / 100, -1, 14);
			end
			
		else
			WindowY = 160 --139
		end
		
	else
		WindowY = 120 --100
	end
    

	
    imgui.End();
end);
