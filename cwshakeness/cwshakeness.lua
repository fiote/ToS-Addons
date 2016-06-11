local acutil = require('acutil');

-- ======================================================
--	Settings
-- ======================================================

cwShakeness = {};
cwShakeness.optionsFile = '../addons/cwshakeness/options.json';
cwShakeness.originalName = 'cwShakeness_originalShockwave';

-- ======================================================
--	Options
-- ======================================================

-- defaults
local defaults = {};
defaults.maxEnabled = 1;

-- loading options
cwShakeness.options = acutil.loadJSON(cwShakeness.optionsFile,defaults,true);

-- ======================================================
--	storing
-- ======================================================

function cwShakeness.storeShockwave() 
	-- storing the original shockwave function in a safe place
	-- that means we can restore it later, if we need to
	local fname = cwShakeness.originalName;
	if (_G[fname] == nil) then _G[fname] = world.ShockWave; end
end 
-- ======================================================
--	replacing
-- ======================================================

function cwShakeness.replaceShockwave() 
	-- replacing the shockwave function
	local fname = cwShakeness.originalName;
	world.ShockWave = function(actor, type, range, intensity, time, freq, something)
		-- if the intensity of the shockwave is smaller than what is enabled
		if (intensity <= cwShakeness.options.maxEnabled) then
			-- then we carry on and execute it using the original stored shockwave
			local fn = _G[fname];
			fn(actor, type, range, intensity, time, freq, something);
		end
	end
end

-- ======================================================
--	commands
-- ======================================================

function cwShakeness.slash_updateMaxEnabled(params)
	cwShakeness.options.maxEnabled = tonumber(params[0]);
	acutil.saveJSON(cwShakeness.optionsFile,cwShakeness.options);
	local msgupd = 'Allowed value updated{nl}'..'Intensity now: '..cwShakeness.options.maxEnabled;
	return msgupd;
end

function cwShakeness.slash_Help()
	local msgcmd = '/skn max $value{nl}'..'Set the max intensity allowed{nl}'..'-----------{nl}';
	local msgint = 'Intensity now: '..cwShakeness.options.maxEnabled;			
	return msgcmd..msgint, '', 'Nope';
end

cwShakeness.slashSet = {
	base = '/skn',
	title = 'cwShakeness',
	cmds = {
		max = {fn = cwShakeness.slash_updateMaxEnabled, nparams = 1},
	},
	empty = cwShakeness.slash_Help
};

-- ======================================================
--	LOADER
-- ======================================================

local isLoaded = false;

function CWSHAKENESS_ON_INIT()
	if not isLoaded then
		-- executing onload
		cwShakeness.storeShockwave();
		cwShakeness.replaceShockwave();
		acutil.slashSet(cwShakeness.slashSet);
		acutil.log('[cwShakeness] loaded. Type /skn for help.');
		isLoaded = true;
	end
end
