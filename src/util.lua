function distanceFrom(x1,y1,x2,y2)

	return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)

end

---------------------------------------------------------------------------------------------------------------------------

function table_to_string(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- Check the key type (ignore any numerical keys - assume its an array)
        if type(k) == "string" then
            result = result.."[\""..k.."\"]".."="
        end

        -- Check the value type
        if type(v) == "table" then
            result = result..table_to_string(v)
        elseif type(v) == "boolean" then
            result = result..tostring(v)
        else
            result = result.."\""..v.."\""
        end
        result = result..", "
    end
    -- Remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len()-2)
    end
    return result.."}"
end

function checkCriterias(criterias)

	if criterias == "" then
		return false
	end

	-- First split the whole criterias string on | symbol

	if string.sub(criterias,#criterias,#criterias) ~= "|" then
		criterias = criterias.."|"
	end
			
	tokens = {}
	for w in criterias:gmatch("([^|]*[|])") do
		if string.sub(w,#w,#w) == "|" then
			w = string.sub(w,1,#w-1)
		end
		table.insert(tokens, w)
	end		

	-- Then split each criteria on the : symbol

	local numCriteriaMet = 0

	for i = 1,#tokens do

		local criteria = tokens[i]

		if string.sub(criteria,#criteria,#criteria) ~= ":" then
			criteria = criteria..":"
		end
				
		segments = {}
		for w in criteria:gmatch("([^:]*[:])") do
			if string.sub(w,#w,#w) == ":" then
				w = string.sub(w,1,#w-1)
			end
			table.insert(segments, w)
		end	

		if globalvariables:check(segments[1], segments[2], segments[3]) then
			numCriteriaMet = numCriteriaMet + 1
		end
	
	end

	if numCriteriaMet == #tokens then
		return true
	end
	
	return false

end

function explode(line, delimiter)

	if string.sub(line,#line,#line) ~= delimiter then
		line = line..delimiter
	end

	result = {}
	for w in line:gmatch("([^"..delimiter.."]*["..delimiter.."])") do
		if string.sub(w,#w,#w) == delimiter then
			w = string.sub(w,1,#w-1)
		end
		table.insert(result, w)
	end		
	
	return result
	
end

function round(num)
    local under = math.floor(num)
    local upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end
