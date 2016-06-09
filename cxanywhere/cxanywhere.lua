local cwAPI = require("cwapi");
local acutil = require('acutil');

local cxAnywhere = {};

local log = cwAPI.util.log;

function cxAnywhere.openRepair() 
	SHOP_REPAIR_ITEM();
end

function cxAnywhere.fakeSell() 
	local frame = ui.GetFrame("shop");	

	local invItemList = session.GetInvItemList();
	local index = invItemList:Head();
	local itemCount = session.GetInvItemList():Count();

	local firstsell = nil;

	for i = 0, itemCount - 1 do		
		local invItem = invItemList:Element(index);
		local clsItem = GetClassByType("Item",invItem.type);
		local itemProp = geItemTable.GetPropByName(clsItem.ClassName);
		if (not firstsell and itemProp:IsTradable() == true) then firstsell = invItem; end
		index = invItemList:Next(index);
	end

	if (firstsell) then 
		SHOP_SELL(firstsell,1); 
		SHOP_BUTTON_BUYSELL(frame);
	end
end

function cxAnywhere.openSell() 
	local frame = ui.GetFrame("shop");	
	frame:ShowWindow(1);
	if (session.GetSoldItemList():Count() == 0) then
		ui.MsgBox("No sold items detected. That probably means you're opening a shop for the first time. Do you want to fake-sell a random item? That will enable this shop.","cxAnywhere.fakeSell()","Nope");
	end
end

function cxAnywhere.openMarket() 
	MARKET_BUYMODE();
end

function cxAnywhere.openTPShop()
	local frame = ui.GetFrame("tpitem");
	frame:ShowWindow(1);
end

function cxAnywhere.openStorage()	
	ui.OpenFrame("warehouse");
end

-- ======================================================
--	Commands
-- ======================================================

function cxAnywhere.checkCommand(words)
	local cmd = table.remove(words,1);
	local msgtitle = 'cxAnywhere{nl}'..'-----------{nl}';

	if (not cmd) then
		local msgcmd = '';
		local msgcmd = msgcmd .. '/repair{nl}';
		local msgcmd = msgcmd .. '/sell{nl}';
		local msgcmd = msgcmd .. '/market{nl}';
		local msgcmd = msgcmd .. '/tpshop{nl}';
		local msgcmd = msgcmd .. '/storage{nl}';		
		return ui.MsgBox(msgtitle..msgcmd,"","Nope");
	end

	local msgerr = 'Command not valid.{nl}'..'Type "/anywhere" for help.';
	ui.MsgBox(msgtitle..msgerr,"","Nope");

end

-- ======================================================
--	LOADER
-- ======================================================
local isLoaded = false;

function CXANYWHERE_ON_INIT()
	if not isLoaded then
		-- checking dependences
		if (not cwAPI) then
			ui.SysMsg('[cxAnywhere] requires cwAPI to run.');
			return false;
		end

		acutil.slashCommand('/repair',cxAnywhere.openRepair);
		acutil.slashCommand('/sell',cxAnywhere.openSell);
		acutil.slashCommand('/market',cxAnywhere.openMarket);
		acutil.slashCommand('/tpshop',cxAnywhere.openTPShop);
		acutil.slashCommand('/storage',cxAnywhere.openStorage);

		acutil.slashCommand('/anywhere',cxAnywhere.checkCommand);

		isLoaded = true;
		ui.SysMsg('[cxAnywhere] loaded. Spread the word so IMC can fix this! Type /anywhere for help.');
	end
end