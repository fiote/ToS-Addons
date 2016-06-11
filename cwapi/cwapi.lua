-- ======================================================
--	settings
-- ======================================================

local cwAPI = {};
cwAPI.devMode = false;

-- ======================================================
--	imports
-- ======================================================

local JSON = require('json');
local acutil = require('acutil');

-- ======================================================
--	util	
-- ======================================================

cwAPI.util = {};

function cwAPI.util.log(msg) 
	CHAT_SYSTEM(getvarvalue(msg));  
end 

function cwAPI.util.dev(msg,flag) 
	if (flag) then cwAPI.util.log(msg) end;
end 

function cwAPI.util.splitString(s,type)
	if (not type) then type = ' '; end
	local words = {};
	local m = type;
	if (type == ' ') then m = "%S+" end;
	if (type == '.') then m = "%." end;
	for word in s:gmatch(m) do table.insert(words, word) end
	return words;
end

function cwAPI.util.notepad(object,flagMeta)
	if (flagMeta) then object = getmetatable(object); end
	TestNotePad(object);
end

function cwAPI.util.tablelength(T)
  	local count = 0
  	for _ in pairs(T) do count = count + 1 end
  	return count
end

function getvarvalue(var)
	if (var == nil) then return 'nil'; end	
	local tp = type(var); 
	if (tp == 'string' or tp == 'number') then 
		return var; 
	end
	if (tp == 'boolean') then 
		if (var) then 
			return 'true';
		else
			return 'false';
		end
	end
	return tp;
end

-- ======================================================
--	EVENTS
-- ======================================================

cwAPI.events = {};
cwAPI.evorig = '_original';

function cwAPI.events.original(event) 
	return _G[event..cwAPI.evorig];	
end

function cwAPI.events.on(event,callback,order) 
	if _G[event] == nil then 
		cwAPI.util.dev('Global '..event..' does not exists.',cwAPI.devMode);
		return;
	end

	cwAPI.events.store(event);

	_G[event] = function(...)
		local t = {...};
		if (order == -1) then
			callback(unpack(t));
		end
		if (order ~= 0) then
			local fn = cwAPI.events.original(event);
			local ret = fn(unpack(t));
		end
		if (order == 0) then			
			local ret = callback(unpack(t));
		end
		if (order == 1) then
			callback(unpack(t));
		end

		return ret;
	end

	cwAPI.util.dev('api.events on '..event,cwAPI.devMode);
end

function cwAPI.events.reset(event)
	if _G[event] == nil then 
		cwAPI.util.dev('Global '..event..' does not exists.',cwAPI.devMode);
		return;
	end
	local fn = cwAPI.events.original(event);
	if fn ~= nil then
		cwAPI.util.dev('Reseting '..event,cwAPI.devMode);
		_G[event] = fn;
		_G[event..cwAPI.evorig] = nil;
	end
end

function cwAPI.events.resetAll() 
	for key,value in pairs(_G) do
		if (type(value) == 'function' and not string.match(key,cwAPI.evorig)) then
			cwAPI.events.reset(key);
		end
	end
end

function cwAPI.events.store(event) 
	if _G[event] == nil then 
		cwAPI.util.dev('Global '..event..' does not exists.',cwAPI.devMode);
		return;
	end
	local fn = cwAPI.events.original(event);
	if fn == nil then
		cwAPI.util.dev('Storing '..event,cwAPI.devMode);
		_G[event..cwAPI.evorig] = _G[event];
	end
end

function cwAPI.events.listen(event) 	
	if _G[event] == nil then 
		cwAPI.util.log('Global '..event..' does not exists.');
		return;
	end
	cwAPI.events.reset(event);
	cwAPI.events.store(event);

	_G[event] = function(a,b,c,d,e,f,g)
		cwAPI.util.log('> '..event);
		cwAPI.events.printParams(a,b,c,e,d,f,g);
		local fn = cwAPI.events.original(event);
		cwAPI.util.log('> fn');
		local ret = fn(a);
		cwAPI.util.log('> ret');
		return ret;
	end
	cwAPI.util.log('api.events listening to '..event);
end

function cwAPI.events.printParams(a,b,c,e,d,f,g) 	
	if (a) then cwAPI.util.dev('a) '..getvarvalue(a),cwAPI.devMode); end
	if (b) then cwAPI.util.dev('b) '..getvarvalue(b),cwAPI.devMode); end
	if (c) then cwAPI.util.dev('c) '..getvarvalue(c),cwAPI.devMode); end
	if (d) then cwAPI.util.dev('d) '..getvarvalue(d),cwAPI.devMode); end
	if (e) then cwAPI.util.dev('e) '..getvarvalue(e),cwAPI.devMode); end
	if (f) then cwAPI.util.dev('f) '..getvarvalue(f),cwAPI.devMode); end
	if (g) then cwAPI.util.dev('g) '..getvarvalue(g),cwAPI.devMode); end
end

-- ======================================================
--	JSONs
-- ======================================================

cwAPI.json = {};

function cwAPI.json.load(folder,filename,ignoreError)
	if (not filename) then filename = folder; end
	local file, error = io.open("../addons/"..folder.."/"..filename..".json", "r");
	if (error) then
		if (not ignoreError) then ui.SysMsg("Error opening "..folder.."/"..filename.." to load json: "..error); end
		return nil;
	else 
	    local filestring = file:read("*all");
	    local object = JSON.decode(filestring);    
	    io.close(file);
	    return object;
	end
end

function cwAPI.json.quoted(var)
	local tp = type(var);
	local quoted = '';
	if (tp == 'string') then quoted = '"'..var..'"'; end
	if (tp == 'number') then quoted = var; end
	if (tp == 'boolean') then
		quoted = 'false';
		if (var) then quoted = 'true'; end
	end
	return quoted;
end

function cwAPI.json.encode(object,tabs) 
	if (not tabs) then tabs = ''; end
	local tp = type(object);
	local json = '';

	if (tp == 'table') then
		json = json .. '{\n';
		local count = 0;
		local max = cwAPI.util.tablelength(object);

		for atr,vlr in pairs(object) do
			count = count + 1;
			json = json .. tabs .. '\t' .. cwAPI.json.quoted(atr) .. ': ';
			json = json .. cwAPI.json.encode(vlr,tabs..'\t');
			if (count < max) then json = json .. ','; end
			json = json .. '\n';
		end

		json = json .. tabs .. '}';
	else
		json = cwAPI.json.quoted(object);
	end
	return json;
end

function cwAPI.json.save(object,folder,filename,simple)
	if (not filename) then filename = folder; end
	local file, error = io.open("../addons/"..folder.."/"..filename..".json", "w");
	if (error) then
		ui.SysMsg("Error opening "..folder.."/"..filename.." to write json: "..error);
		return false;
	else 
		local filestring = cwAPI.json.encode(object);
		file:write(filestring);
	    io.close(file);
		return filestring;
	end
end

-- ======================================================
--	ATTRIBUTES
-- ======================================================

cwAPI.attributes = {};

function cwAPI.attributes.getData(attrID)
	local topFrame = ui.GetFrame('skilltree');
	topFrame:SetUserValue("CLICK_ABIL_ACTIVE_TIME",imcTime.GetAppTime()-10);

	-- geting the attribute instance
	local abil = session.GetAbility(attrID);
	if (not abil) then return nil; end

	-- loading its IES data
	local abilClass = GetIES(abil:GetObject());

	-- getting its name and ID	
	local abilName = abilClass.ClassName;
	local abilID = abilClass.ClassID;

	-- getting the current state
	local state = abilClass.ActiveState;

	-- returning it
	return abilName, abilID, state;
end

function cwAPI.attributes.toggleOff(attrID)
	local abilName, abilID, state = cwAPI.attributes.getData(attrID);
	cwAPI.util.dev('Disabling ['..abilName..']...',cwAPI.devMode);

	-- if the attribute is already disabled, there's nothing to do
	if (state == 0) then
		cwAPI.util.dev('The attribute is already disabled.',cwAPI.devMode);
		return; 
	end 

	local topFrame = ui.GetFrame('skilltree');
	topFrame:SetUserValue("CLICK_ABIL_ACTIVE_TIME",imcTime.GetAppTime()-10);

	-- calling the toggle function
	local fn = _G['TOGGLE_ABILITY_ACTIVE'];
	fn(nil, nil, abilName, abilID);
	cwAPI.util.dev('Attibute disabled.',cwAPI.devMode);
end

function cwAPI.attributes.toggleOn(attrID)
	local abilName, abilID, state = cwAPI.attributes.getData(attrID);
	cwAPI.util.dev('Enabling ['..abilName..']...',cwAPI.devMode);

	-- if the attribute is already disabled, there's nothing to do
	if (state == 1) then
		cwAPI.util.dev('The attribute is already enabled.',cwAPI.devMode);
		return; 
	end 

	local topFrame = ui.GetFrame('skilltree');
	topFrame:SetUserValue("CLICK_ABIL_ACTIVE_TIME",imcTime.GetAppTime()-10);

	-- calling the toggle function
	local fn = _G['TOGGLE_ABILITY_ACTIVE'];
	fn(nil, nil, abilName, abilID);
	cwAPI.util.dev('Attibute enabled.',cwAPI.devMode);
end

-- ======================================================
--	LOADER
-- ======================================================

cwAPI.events.resetAll();
return cwAPI;


