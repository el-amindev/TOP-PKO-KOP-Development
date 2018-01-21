--[[ 
 -------------------------------------------
	HOOKING "Library"
 -------------------------------------------
 Hook library allows to modify existing treatement by
 by replacing the way a method call is processed.
 This can be achieved in 3 main ways:
    * Substituing a method code with another (Replacement)
    * Addind calls prior to the method call execution. (Pre-Processors)
    * Adding calls after the core method call exeuction. (Post-Processors)
 The three methods can be combined at will.

 REPLACEMENT:
 Replacement method is unique. It must expect the same parameters and have
 the same return type as the replaced method.
 
 PRE_PROCESSOR:
 A method can be associated several pre-processor methods.
 Each pre-processor method must have the same input parameter and should return a boolean value.
 If the pre-processor returns true, the next pre-processor or the core method is executed.
 If the pre-processor returns false, the execution chain is stopped.

 POST_PROCESSOR:
 A method can be associated several post-processor methods.
 Each post-processor will have as first parameter an array containing the list of values returned
 by the core method call. Following that parameter, the list of orinigal input parameters will be provided.
 If a post-processor does not provide return values, the return values of the previous method called in chain
 will be kept. If the post-processor return some values, they will override and replace the return value chain.
 
 SUMMARY:
 Use replacement if you want to substitute your code to an existing one.
 Use pre processing if you want to conditionnaly disable the original method call.
 Use post processing if you want to achieve an action after the key handling was done or if you want to alter 
 its return values on thefly.
 
 =================
 Public interface:
 =================
 *  Hook:AddReplacementHook(<String> originalFctName, <Function> newFct)
    Replace all calls to the method named 'originalFctName' by the provided function 'newFct'.
	If another function is already registered as a replacement function, the new registered function replacing the previous one.
	
 *  Hook:RemoveReplacementHook(<String> originalFctName) <== NOT IMPLEMENTED YET
    Remove a replacement call and restore the original behavior of the function named "originalFctName"
    
 *  Hook:AddPreHook(<String> originalFctName, <Function> hookFct, <Int> priorityOrder)
    Register the function 'hookFct' as a pre-processing method for the function named 'originalFctName'. 
	The priority order defines the execution order of the pre-processing methods, the lowest numbering being executed first. 
	In case of equal priorityOrder, the execution order is not insured.
	
 *  Hook:RemovePreHook(<String> originalFctName, <Function> hookFct, <Int> priorityOrder) <== NOT IMPLEMENTED YET
    Remove an already defined Pre-processing method.
	
 *  Hook:AddPostHook(<String> originalFctName, <Function> hookFct, <Int> priorityOrder)
    Register the function 'hookFct' as a post-processing method for the function named 'originalFctName'. 
	The priority order defines the execution order of the post-processing methods, the lowest numbering being executed first. 
	In case of equal priorityOrder, the execution order is not insured.
	
 *  Hook:RemovePostHook(<String> originalFctName, <Function> hookFct, <Int> priorityOrder)
    Remove an already defined Post-processing method.
	
 *  Hook:DisableHooks(<String> originalFctName)
    Disable all the existing hooks (replacement, pre-processor, post-processor) associated to the function named 'originalFctName'.
	The original behavior of the method is restored while the whole hook configuration is preserved and can be restored with a call 
	to Hook:EnableHooks()
	
 *  Hook:EnableHooks(<String> originalFctName)
    Restore all the existing hooks (replacement, pre-processor, post-processor) associated to the function named 'originalFctName' 
	that got disabled by a call to Hook:DisableHooks
	
 *  Hook:ClearHooks(<String> originalFctName)
    Disable all the existing hooks (replacement, pre-processor, post-processor) associated to the function named 'originalFctName'.
	The original behavior of the method is restored and the whole hook configuration is lost.
	
 *  Hook:ClearAllHooks()  <== NOT IMPLEMENTED YET
    Disable all the existing hooks (replacement, pre-processor, post-processor);
	The original behavior of the all the hooked methods are restored and the whole hook configuration is lost.
	
 *  Hook:DisableAllHooks()
    Disable all the existing hooks (replacement, pre-processor, post-processor).
	The original behavior of the all the hooked methods are restored while the whole hook configuration is preserved and can be 
	restored with a call to Hook:EnableAllHooks()
	
 *  Hook:EnableAllHooks()
    Restore all the existing hooks (replacement, pre-processor, post-processor) that got disabled by a call to Hook:DisableAllHooks().
	
 *  Hook:LoadHookFile(<String> filename)  <== NOT IMPLEMENTED YET
	Create a set if hook based on a text file content.
	Text file must have one hook per line with the following syntax:
	HOOK_TYPE|ORIGINAL_FUNCTION_NAME|HOOK_FUNCTION_NAME|PRIORITY_ORDER
	HOOK_TYPE => PRE/POST/REPLACE
	ORIGINAL_FUNCTION_NAME => The pointed function must be accessible within the global scope
	HOOK_FUNCTION_NAME => The pointed function must be accessible within the global scope
	PRIORITY_ORDER => Ignored in replace mode (Can be omitted).
	
 ]]

 
print("Loading Hook.lua");

if (Hook ~= nil) then
	Hook:ClearAllHooks()
end

Hook = { hookList = {}, enabled = true }

function Hook:AddReplacementHook(originalFctName, newFct)
	local hookDef = self.hookList[originalFctName]
	if (hookDef == nil) then
		hookDef = Hook:InitHook(originalFctName)
	end
	hookDef.replacement = newFct
end


function Hook:RemoveReplacementHook(originalFct)
	local hookDef = self.hookList[originalFctName]
	if (hookDef ~= nil) then
		hookDef.replacement = nil
	end
end

-- PRIVATE
function Hook:GenericHook(originalFctName, ...)
	local hookDef = self.hookList[originalFctName]
	if (hookDef ~= nil) then
		if (self.enabled == true and hookDef.enabled == true) then
			-- Execute pre filters
			local pre_filter_count = table.getn(hookDef.pre)
			for i=1, pre_filter_count do
				local returnedValue = hookDef.pre[i].fct(unpack(arg))
				if (returnedValue == false) then
					return;
				end
			end
			
			-- Execute key function (either original or replacement)
			local returnedValues = nil
			if (hookDef.replacement ~= nil) then
				returnedValues = { hookDef.replacement(unpack(arg)) }
			else
				returnedValues = { hookDef.original(unpack(arg)) }
			end
			
			-- Execute post filters
			local post_filter_count = table.getn(hookDef.post)
			for i=1, post_filter_count do
				newReturnedValues = { hookDef.post[i].fct(returnedValues, unpack(arg)) }
				if (newReturnedValues ~= nil and table.getn(newReturnedValues) > 0 ) then
					returnedValues = newReturnedValues
				end
			end
			
			local a, b, c =  unpack(returnedValues)
			return unpack(returnedValues)
		else
			return hookDef.original(unpack(arg))
		end
	end
end

-- PRIVATE
function Hook:InitHook(originalFctName)
	local hookDef = { pre={} , post={} , original=nil, replacement=nil, enabled=true }
	self.hookList[originalFctName] = hookDef
	hookDef.original = _G[originalFctName]
	_G[originalFctName] =  	function (...) 
								return Hook:GenericHook(originalFctName, unpack(arg) )
							end
	return hookDef
end


function Hook:AddPreHook(originalFctName, hookFct, priorityOrder)
	local hookDef = self.hookList[originalFctName]
	if (hookDef == nil) then
		hookDef = Hook:InitHook(originalFctName)
	end
	-- Avoid undefined priorityOrder
	if (priorityOrder == nil) then
		priorityOrder = 999999
	end
	-- Check if the hook is already recorded
	local hookCount = table.getn(hookDef.pre)
	local found = false
	for i=1, hookCount do
		if (hookDef.pre[i].fct == hookFct) then
			found = true
			hookDef.pre[i].order = priorityOrder
		end
	end
	if (found == false) then
		table.insert(hookDef.pre, {fct = hookFct, order = priorityOrder} )
	end
	-- Force a re-sorting of hooks to handle execution order
	Hook:SortHooks(hookDef.pre)
end

-- TODO
function Hook:RemovePreHook(originalFctName, hookFct, priorityOrder)
	print("ERROR >> Hook:RemovePreHook() is not yet implemented !!")
end



function Hook:AddPostHook(originalFctName, hookFct, priorityOrder)
	local hookDef = self.hookList[originalFctName]
	if (hookDef == nil) then
		hookDef = Hook:InitHook(originalFctName)
	end
	-- Avoid undefined priorityOrder
	if (priorityOrder == nil) then
		priorityOrder = 999999
	end
	-- Check if the hook is already recorded
	local hookCount = table.getn(hookDef.post)
	local found = false
	for i=1, hookCount do
		if (hookDef.post[i].fct == hookFct) then
			found = true
			hookDef.post[i].order = priorityOrder
		end
	end
	if (found == false) then
		table.insert(hookDef.post, {fct = hookFct, order = priorityOrder} )
	end
	-- Force a re-sorting of hooks to handle execution order
	Hook:SortHooks(hookDef.post)
end


-- TODO
function Hook:RemovePostHook(originalFctName, hookFct, priorityOrder)
	rint("ERROR >> Hook:RemovePostHook() is not yet implemented !!")
end



function Hook:DisableHooks(originalFctName)
	local hookDef = self.hookList[originalFctName]
	if (hookDef ~= nil) then
		hookDef.enabled = false
	end
end



function Hook:EnableHooks(originalFctName)
	local hookDef = self.hookList[originalFctName]
	if (hookDef ~= nil) then
		hookDef.enabled = true
	end
end



function Hook:ClearHooks(originalFctName)
	local hookDef = self.hookList[originalFctName]
	if (hookDef ~= nil) then
		hookDef.enabled = true
	end
	_G[originalFctName] = hookDef.original
	self.hookList[originalFctName] = nil
end


-- TODO
function Hook:ClearAllHooks()
	--print("ERROR >> Hook:ClearAllHooks() is not yet implemented !!")
	for i,v in pairs(self.hookList) do
		Hook:ClearHooks(i)
	end
end


function Hook:DisableAllHooks()
	self.enabled = false
end


function Hook:EnableAllHooks()
	self.enabled = true
end


function Hook:LoadHookFile(filename)
	
	local split = 	function (str, delim, maxNb)
						-- Eliminate bad cases...
						if string.find(str, delim) == nil then
							return { str }
						end
						if maxNb == nil or maxNb < 1 then
							maxNb = 0    -- No limit
						end
						local result = {}
						local pat = "(.-)" .. delim .. "()"
						local nb = 0
						local lastPos
						for part, pos in string.gfind(str, pat) do
							nb = nb + 1
							result[nb] = part
							lastPos = pos
							if nb == maxNb then break end
						end
						-- Handle the last field
						if nb ~= maxNb then
							result[nb + 1] = string.sub(str, lastPos)
						end
						return result
					end


 
	file = assert(io.open(filename, "r"))
	for line in file:lines() do 
		lineData = split(line, "|",3)
		
		-- Make sure original function is defined
		if (_G[lineData[2]] ~= nil) then
			-- Make sure target function is defined
			if (_G[lineData[3]] ~= nil) then
				if (lineData[1] == "REPLACE") then
					Hook:AddReplacementHook(lineData[2], _G[lineData[3]])
				elseif (lineData[1] == "PRE") then
					Hook:AddPreHook(lineData[2], _G[lineData[3]], lineData[4])
				elseif (lineData[1] == "POST") then
					Hook:AddPostHook(lineData[2], _G[lineData[3]], lineData[4])
				else
					print("ERROR >> Hook:LoadHookFile() : Unrecongized type of hook ["..lineData[1].."] !!")
				end
			else
				print("ERROR >> Hook:LoadHookFile() : Function ["..lineData[3].."] is not defined !!")
			end
		else
			print("ERROR >> Hook:LoadHookFile() : Function ["..lineData[2].."] is not defined !!")
		end
	end
	io.close(file)
end


function Hook:SetHookPattern(pattern, hookType, hookFct, priority)
	-- make sure hook fct is defined
	if (hookFct == nil) then
		print("ERROR >> Hook:SetHookPattern() : Hook function is not defined ["..hookFct.."] !!")	
		return
	end
	-- Browse global def list
	for key, value in pairs(_G) do
		-- Filter to retrieve only functions
		if (type(value) == "function") then
			-- Check the global function toward the provided pattern
			if (string.find(key, pattern) ~= nil) then
				if (hookType == "REPLACE") then
					Hook:AddReplacementHook(key, hookFct)
				elseif (hookType == "PRE") then
					Hook:AddPreHook(key, hookFct, priority)
				elseif (hookType == "POST") then
					Hook:AddPostHook(key, hookFct, priority)
				else
					print("ERROR >> Hook:SetHookPattern() : Unrecongized type of hook ["..hookType.."] !!")
				end
			end
		end
	end
end
	
	
-- PRIVATE
function Hook:SortHooks(hookList)
	local compareFct = 	function (a,b)
							return a.order < b.order
						end
	table.sort(hookList, compareFct)
end


