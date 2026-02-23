local HttpService = game:GetService("HttpService")

local Utils = {}

function Utils.weightedRandom(weights: { [string]: number }): string
	local totalWeight = 0
	for _, w in weights do
		totalWeight += w
	end

	local roll = math.random() * totalWeight
	local lastKey = nil
	for key, w in weights do
		lastKey = key
		roll -= w
		if roll <= 0 then
			return key
		end
	end

	return lastKey :: string
end

function Utils.generateId(): string
	return HttpService:GenerateGUID(false)
end

function Utils.formatNumber(n: number): string
	local suffixes = {
		{ 1e12, "T" },
		{ 1e9, "B" },
		{ 1e6, "M" },
		{ 1e3, "K" },
	}

	for _, entry in suffixes do
		if n >= entry[1] then
			return string.format("%.1f%s", n / entry[1], entry[2])
		end
	end

	return tostring(math.floor(n))
end

function Utils.deepCopy(t: { [any]: any }): { [any]: any }
	if type(t) ~= "table" then
		return t
	end

	local copy = {}
	for key, value in t do
		copy[key] = Utils.deepCopy(value)
	end
	return copy
end

return Utils
