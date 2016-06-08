local cwAPI = require("cwapi");

local cwCleric = {};

local log = cwAPI.util.log;

-- ======================================================
--	settings
-- ======================================================

cwCleric.settings = {};
cwCleric.settings.partyid = -1;
cwCleric.settings.waitingLeave = false;

-- ======================================================
--	attibute list
-- ======================================================

cwCleric.attributes = {};
cwCleric.attributes.HealRemoveDamage = 401016;

-- ======================================================
--	leave party
-- ======================================================

function cwCleric_toggleHealRemoveDamageOff() 
	cwAPI.attributes.toggleOff(cwCleric.attributes.HealRemoveDamage);
end

function cwCleric.leftParty(atrState) 
	if (atrState == 1) then
		local msgtitle = 'cwCleric{nl}'..'-----------{nl}';
		local msgalert = 'You just left a party but your "Heal: Remove Damage" is ON. Do you want to toggle it off?';
		ui.MsgBox(msgtitle..msgalert,'cwCleric_toggleHealRemoveDamageOff()',"None");	
	end
end

-- ======================================================
--	join party
-- ======================================================

function cwCleric_toggleHealRemoveDamageOn() 
	cwAPI.attributes.toggleOn(cwCleric.attributes.HealRemoveDamage);
end

function cwCleric.joinedParty(atrState) 
	if (atrState == 0) then
		local msgtitle = 'cwCleric{nl}'..'-----------{nl}';
		local msgalert = 'You just joined a party but your "Heal: Remove Damage" is OFF. Do you want to toggle it on?';
		ui.MsgBox(msgtitle..msgalert,'cwCleric_toggleHealRemoveDamageOn()',"None");	
	end
end

-- ======================================================
--	check what happened
-- ======================================================

function cwCleric.forceLeave()
	cwCleric.settings.waitingLeave = true;
end

function cwCleric.partyMsgUpdate() 
	if (cwCleric.settings.waitingLeave) then
		cwCleric.settings.waitingLeave = false;
		cwCleric.checkIfPartyChanged();		
	end
end

function cwCleric.checkPartyPropertyUpdate(frame, msg, str, num)
	if (str == 'CreateTime') then cwCleric.checkIfPartyChanged(); end
	if (msg == 'PARTY_INST_UPDATE') then cwCleric.checkIfPartyChanged(); end
end

function cwCleric.checkIfPartyChanged()
	local abilName, abilID, atrState = cwAPI.attributes.getData(cwCleric.attributes.HealRemoveDamage);
	if (abilName == nil) then return; end

	local pcparty = session.party.GetPartyInfo();	
	
	local newpartyid = -1;
	if (pcparty ~= nil) then newpartyid = pcparty.info:GetPartyID(); end

	if (newpartyid ~= cwCleric.settings.partyid) then
		if (newpartyid == -1) then
			cwCleric.leftParty(atrState);
		else
			cwCleric.joinedParty(atrState);
		end		
	end

	cwCleric.settings.partyid = newpartyid;
end 

-- ======================================================
--	LOADER
-- ======================================================
local isLoaded = false;

function CWCLERIC_ON_INIT()
	if not isLoaded then
		-- checking dependences
		if (not cwAPI) then
			ui.SysMsg('[cwCleric] requires cwAPI to run.');
			return false;
		end

		-- executing onload
		cwAPI.events.on('ON_PARTY_PROPERTY_UPDATE',cwCleric.checkPartyPropertyUpdate,1);	
		cwAPI.events.on('ON_PARTYINFO_INST_UPDATE',cwCleric.checkPartyPropertyUpdate,1);	
				
		cwAPI.events.on('PARTY_MSG_UPDATE',cwCleric.partyMsgUpdate,1);
		cwAPI.events.on('OUT_PARTY',cwCleric.forceLeave,1);	
		cwCleric.checkIfPartyChanged();

		isLoaded = true;
		cwAPI.util.log('[cwCleric] loaded.');
	end
end
