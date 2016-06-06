local cwAPI = require("cwapi");
local acutil = require('acutil');

local cwRepair = {};

local log = cwAPI.util.log;

-- ======================================================
--	Options
-- ======================================================

cwRepair.options = cwAPI.json.load('cwrepair','cwrepair',true);

if (not cwRepair.options) then 
	cwRepair.options = {};
	cwRepair.options.auto = true;
	cwRepair.options.minPr = 30;
end

-- ======================================================
--	UI
-- ======================================================

function cwRepair.GetFrame()
	return ui.GetFrame("repair140731");
end


function cwRepair_clickButton()
	cwRepair.autoSelectItems();
end

function cwRepair.createButtonIfNeeded()
	local frame = cwRepair.GetFrame();
	if (frame == nil) then return; end;

	local ctrl = frame:GetChildRecursively("needlisttxt");
	ctrl:ShowWindow(0);

	local ctrl = frame:GetChildRecursively("selectAllBtn");
	ctrl:SetOffset(18,52);

	local dspr = string.format("%d%%", cwRepair.options.minPr);

	local ctrl = frame:CreateOrGetControl('button', 'cwrepair_SELECTMIN', 0, 0, 200, 42);
	ctrl:SetSkinName('test_pvp_btn');
	ctrl:SetGravity(ui.LEFT, ui.TOP);
	ctrl:SetText('{@st66}Select Below '..dspr..'{/}');
	ctrl:Move(0,0);
	ctrl:SetOffset(18,113);
	ctrl:ShowWindow(1);

	ctrl:SetClickSound('button_click_stats');
	ctrl:SetOverSound('button_over');	
	ctrl:SetEventScript(ui.LBUTTONUP,'cwRepair_clickButton()');
end

-- ======================================================
--	Everytime a repair window is open
-- ======================================================

function cwRepair.checkRepairList(frame) 
	cwRepair.createButtonIfNeeded();

	if (cwRepair.options.auto) then
		cwRepair.autoSelectItems();
	end
end

-- ======================================================
--	Auto-selecting items and clicking the repair button
-- ======================================================

function cwRepair.runEquipList() 
	local itemList = session.GetEquipItemList();

	for i = 0, itemList:Count() - 1 do
		local item = itemList:Element(i);
		local tempobj = item:GetObject();
		if tempobj ~= nil then
			local itemobj = GetIES(tempobj);
			if IS_NEED_REPAIR_ITEM(itemobj,0) == true then
				local slot = cwRepair.slotSet:GetSlotByIndex(cwRepair.sloti);
				slot:Select(0); 
				local icon = slot:GetIcon();
				if (icon) then						
					local pr = itemobj.Dur*100/itemobj.MaxDur;
					if (pr < cwRepair.options.minPr) then 
						cwRepair.torepair = cwRepair.torepair+1;
						slot:Select(1); 
					end
				end
				cwRepair.sloti = cwRepair.sloti+1;
			end
		end
	end
end

function cwRepair.runInvList() 
	local invItemList = session.GetInvItemList();


	local i = invItemList:Head();
	while 1 do
		if i == invItemList:InvalidIndex() then
			break;
		end

		local invItem = invItemList:Element(i);		
		i = invItemList:Next(i);
		
		local tempobj = invItem:GetObject();
		if tempobj ~= nil then
			local itemobj = GetIES(tempobj);
			if IS_NEED_REPAIR_ITEM(itemobj,0) == true then
				local slot = cwRepair.slotSet:GetSlotByIndex(cwRepair.sloti);
				while slot == nil do 
					cwRepair.slotSet:ExpandRow();
					slot = cwRepair.slotSet:GetSlotByIndex(cwRepair.sloti);
				end
				slot:Select(0); 
				local icon = slot:GetIcon();
				if (icon) then
					local pr = itemobj.Dur*100/itemobj.MaxDur;
					if (pr < cwRepair.options.minPr) then 
						cwRepair.torepair = cwRepair.torepair+1;
						slot:Select(1); 
					end
				end
				cwRepair.sloti = cwRepair.sloti+1;
			end	
		end

	end

end

function cwRepair.autoSelectItems() 
	local frame = cwRepair.GetFrame();
	local ctrl = frame:GetChildRecursively("selectAllBtn");

	cwRepair.sloti = 0;
	cwRepair.torepair = 0;	
	cwRepair.slotSet = GET_CHILD_RECURSIVELY_AT_TOP(ctrl, "slotlist", "ui::CSlotSet");


	cwRepair.runEquipList();
	cwRepair.runInvList();

	cwRepair.slotSet:MakeSelectionList();
	UPDATE_REPAIR140731_MONEY(frame);

	if (cwRepair.torepair > 0) then
		EXECUTE_REPAIR140731(frame);
	end
end

-- ======================================================
--	Commands
-- ======================================================

function cwRepair.checkCommand(words)
	local cmd = table.remove(words,1);
	local msgtitle = 'cwRepair{nl}'..'-----------{nl}';
	
	if (cmd == 'min') then
		local value = table.remove(words,1);
		cwRepair.options.minPr = tonumber(value);
		cwRepair.createButtonIfNeeded();
		cwAPI.json.save(cwRepair.options,'cwrepair');
		return ui.MsgBox(msgtitle.."Min durability% set to "..value.."%");
	end

	if (cmd == 'auto') then		
		local dsflag = table.remove(words,1);
		if (dsflag == 'on' or dsflag == 'off') then			
			if (dsflag == 'on') then cwRepair.options.auto = true; end 
			if (dsflag == 'off') then cwRepair.options.auto = false; end 
			cwAPI.json.save(cwRepair.options,'cwrepair');
			return ui.MsgBox(msgtitle.."Repair-on-open set to ["..dsflag.."].");
		else
			return ui.MsgBox(msgtitle.."The value should be 'on' or 'off' (without quotes). Not '"..getvarvalue(dsflag).."' as informed.");		
		end
	end

	if (not cmd) then
		local dsflag = ''; if (cwRepair.options.auto) then dsflag = 'on'; else dsflag = 'off'; end
		local dsmin = tonumber(cwRepair.options.minPr);

		local msgcmd = '';
		local msgcmd = msgcmd .. '/rep auto [on/off]{nl}'..'Set if the addon should try to repair items automatically when you open a repair window (now: '..dsflag..').{nl}'..'-----------{nl}';
		local msgcmd = msgcmd .. '/rep min <value(0-100)>{nl}'..'Defines the min durability% to consider a gear "good". Any % lower than that will be repaired (now: '..dsmin..'%).{nl}';
		
		return ui.MsgBox(msgtitle..msgcmd,"","Nope");
	end

	local msgerr = 'Command not valid.{nl}'..'Type "/rep" for help.';
	ui.MsgBox(msgtitle..msgerr,"","Nope");

end


-- ======================================================
--	LOADER
-- ======================================================
local isLoaded = false;

function CWREPAIR_ON_INIT()
	if not isLoaded then
		-- checking dependences
		if (not cwAPI) then
			ui.SysMsg('[cwRepair] requires cwAPI to run.');
			return false;
		end

		cwAPI.events.on('UPDATE_REPAIR140731_LIST',cwRepair.checkRepairList,1);
		acutil.slashCommand('/rep',cwRepair.checkCommand);
		cwRepair.createButtonIfNeeded();

		cwAPI.json.save(cwRepair.options,'cwrepair');
		isLoaded = true;

		cwAPI.util.log('[cwRepair] loaded.');
	end
end
