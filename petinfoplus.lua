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
_addon.version  = '3.0.1';

require 'common'
require 'settings'
require 'tableex'
require 'stringex'
require 'ffxi.targets'
require 'ffxi.enums'
require 'ffxi.recast'

--print(TargetEntityId.ClaimServerId)
--print(player.ServerId)
--TargetName = TargetEntityId.Name
--TargetHealth = TargetEntityId.HealthPercent

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
					TargetTargetServerId = ashita.bits.unpack_be(packet, 150, 32);
					if TargetTargetServerId ~= TargetServerId  then
						TargetTargetEntityId = GetEntityByServerId(TargetTargetServerId)
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

WindowY = 100

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

    local pettp = AshitaCore:GetDataManager():GetPlayer():GetPetTP();
    local petmp = AshitaCore:GetDataManager():GetPlayer():GetPetMP();
	local pett  = AshitaCore:GetDataManager():GetTarget():GetTargetName();
    
    imgui.Text(pet.Name);
	imgui.SameLine(60.0);
	imgui.Text('Distance:');
    imgui.SameLine();
	imgui.Text(math.floor(pet.Distance));
	imgui.SameLine();
	imgui.Text('Yalm');
    imgui.Separator();
    
    -- Set the progressbar color for health..
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, 1.0, 0.61, 0.61, 0.6);
    imgui.Text('HP:');
    imgui.SameLine();
    imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
    imgui.ProgressBar(pet.HealthPercent / 100, -1, 14);
    imgui.PopStyleColor(2);
    
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, 0.0, 0.61, 0.61, 0.6);
    imgui.Text('MP:');
    imgui.SameLine();
    imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
    imgui.ProgressBar(petmp / 100, -1, 14);
    imgui.PopStyleColor(2);
    
    imgui.PushStyleColor(ImGuiCol_PlotHistogram, 0.4, 1.0, 0.4, 0.6);
    imgui.Text('TP:');
    imgui.SameLine();
    imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
    imgui.ProgressBar(pettp / 3000, -1, 14, tostring(pettp));
    imgui.PopStyleColor(2);
	
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
		WindowY = 139
		imgui.Separator();
		imgui.PushStyleColor(ImGuiCol_PlotHistogram, 1.0, 0.61, 0.61, 0.6);
		imgui.Text('Target:');
		imgui.SameLine();
		imgui.Text(TargetName);

		imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
		imgui.ProgressBar(tonumber(TargetHealth) / 100, -1, 14);
		imgui.PopStyleColor(2);
		
		if (TargetHealth ~= 0 and pet.Status == 1 and TargetTargetEntityId ~= nil) then
			WindowY = 178
			imgui.Separator();
			imgui.PushStyleColor(ImGuiCol_PlotHistogram, 1.0, 0.61, 0.61, 0.6);
			imgui.Text('Target-Target:');
			imgui.SameLine();
			imgui.Text(TargetTargetName);

			imgui.PushStyleColor(ImGuiCol_Text, 1.0, 1.0, 1.0, 1.0);
			imgui.ProgressBar(tonumber(TargetTargetHealth) / 100, -1, 14);
			imgui.PopStyleColor(2);
		else
			WindowY = 139
		end
		
	else
		WindowY = 100
	end
    

	
    imgui.End();
end);