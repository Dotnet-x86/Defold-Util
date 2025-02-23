--[[bad module]]

local task = {}
local tick = socket.gettime
local memory = {}

local function get_env()
	local env = getfenv(2)

	memory[env] = memory[env] or {}

	return memory[env]

end

function task.defer(func, ...)
	local args = {...}
	local co = coroutine.create(function ()
		func(unpack(args))
	end)

	table.insert(get_env(), co)

	return co

end

function task.spawn(func, ...)
	local co = coroutine.create(func)
	coroutine.resume(co, ...)
	table.insert(get_env(), co)

	return co
end

function task.delay(seconds, func)
	return task.spawn(function ()
		local start = tick()
		while (tick() - start) < seconds do
			coroutine.yield()
		end

		func() 
	end)
end

function task.cancel(thread)
	local env = get_env()
	for i, v in ipairs(env) do
		if v == thread then
			table.remove(env, i)
			return true
		end
	end

	return false
end

function update()
	for _, env in pairs(memory) do
		for i, v in pairs(env) do
			local success, response = coroutine.resume(v)
			if not success or coroutine.status(v) == 'dead' then
				table.remove(env, i)
			end
		end
	end

end

return task