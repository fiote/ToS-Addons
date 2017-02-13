local cwAPI = require("cwapi");
local acutil = require('acutil');

cwSet = {};
local log = cwAPI.util.log;

-- ======================================================
--	Sets
-- ======================================================

cwSet.sets = cwAPI.json.load('cwset','cwset',true);
if (not cwSet.sets) then cwSet.sets = {}; end

-- ======================================================
--	Actions
-- ======================================================

cwSet.actions = {};

function cwSet.actions.save(setname) 	
	log('cwSet ['..setname..'] saving...');
	local equiplist = session.GetEquipItemList();

	local setList = {};

	for i = 0, equiplist:Count() - 1 do
		local equipItem = equiplist:Element(i);
		local spotName = item.GetEquipSpotName(equipItem.equipSpot);
		if (not string.match(spotName,'ADD')) then
			local itemGuid = equipItem:GetIESID();
			setList[spotName] = itemGuid;
		end
	end

	cwSet.sets[setname] = setList;
	log('cwSet ['..setname..'] saved!');
	cwAPI.json.save(cwSet.sets,'cwset');
end

function cwSet.actions.dochanges() 
	local change = table.remove(cwSet.actions.changeList,1);
	if (change ~= nil) then
		if (change.type == 'equip') then 
			log('Equipping '..change.spot..'...');
			ITEM_EQUIP_MSG(change.item,change.spot); 
		end
		if (change.type == 'unequip') then 
			log('Unequipping '..change.spot..'...');
			item.UnEquip(item.GetEquipSpotNum(change.spot));
		end
	else
		if (cwSet.equipping) then
			log('cwSet ['..cwSet.equipping..'] loaded!');
			cwSet.equipping = nil;
		end
	end
end

function cwSet.actions.load(setname) 
	local setList = cwSet.sets[setname];
	if (not setList) then
		local msgtitle = 'cwSet{nl}'..'-----------{nl}';
		local msgbody = 'Set ['..setname..'] not found.';
		return ui.MsgBox(msgtitle..msgbody);
	end

	log('cwSet ['..setname..'] loading...');
	cwSet.actions.changeList = {};

	for spotName,itemGuid in pairs(setList) do
		if (itemGuid == '0') then		
			local equipItem = session.GetEquipItemBySpot(item.GetEquipSpotNum(spotName));
			if (equipItem ~= nil) then
				itemGuid2 = equipItem:GetIESID();
				if (itemGuid2 ~= '0') then					
					local change = {};
					change.type = 'unequip';
					change.spot = spotName;
					change.guid = itemGuid2;
					table.insert(cwSet.actions.changeList,change);				
				end
			end
		else
			local invItem = session.GetInvItemByGuid(itemGuid);
			if (invItem ~= nil and 0 < GetIES(invItem:GetObject()).Dur) then
				local change = {};
				change.type = 'equip';
				change.spot = spotName;
				change.item = invItem;
				table.insert(cwSet.actions.changeList,change);
			end

			local equipItem = session.GetEquipItemByGuid(itemGuid);
			if (equipItem == nil and invItem == nil) then
				log('Saved item for '..spotName..' is missing. Maybe it was sold/stored?');
			end
		end
	end

	cwSet.equipping = setname;
	cwSet.actions.dochanges();
end


-- ======================================================
--	Commands
-- ======================================================

function cwSet.checkCommand(words)
	local cmd = table.remove(words,1);
	local msgtitle = 'cwSet{nl}'..'-----------{nl}';
	
	if (cmd == 'save' or cmd == 'load') then
		local setname = table.remove(words,1);
		return cwSet.actions[cmd](setname); 
	end

	if (not cmd) then
		local msgcmd = '';
		local msgcmd = msgcmd .. '/set save <name>{nl}'..'Save the current gear as a <name> set.{nl}'..'-----------{nl}';
		local msgcmd = msgcmd .. '/set load <name>{nl}'..'Search for the previously saved set and equip it.{nl}';
		
		return ui.MsgBox(msgtitle..msgcmd,"","Nope");
	end

	local msgerr = 'Command not valid.{nl}'..'Type "/set" for help.';
	ui.MsgBox(msgtitle..msgerr,"","Nope");

end


-- ======================================================
--	LOADER
-- ======================================================
local isLoaded = false;

function CWSET_ON_INIT()
	if not isLoaded then
		-- checking dependences
		if (not cwAPI) then
			ui.SysMsg('[cwSet] requires cwAPI to run.');
			return false;
		end

		cwAPI.events.on('SET_EQUIP_LIST',cwSet.actions.dochanges,1);
		
		cwSet.equipping = nil;
		cwSet.actions.changeList = {};

		acutil.slashCommand('/set',cwSet.checkCommand);

		isLoaded = true;
		cwAPI.util.log('[cwSet] loaded.');
	end
end
