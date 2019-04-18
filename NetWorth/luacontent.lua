local months = {"Jan", "Feb", "Mar" , "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
local labels = 'labels : [';
local data = 'datasets : [{fillColor:"rgba(255,255,255,0)",strokeColor:"rgba(0,200,225,0.5)",pointColor:"rgba(0,200,225,0.5)",pointStrokeColor:"rgba(255,255,255,0)",data:[';

local balance_sum = 0;

function handle_record(record)
    local year = record:get("YEAR");
    local month = record:get("MONTH");
    local date = months[tonumber(month)] .. ' ' .. year;
    
    local balance = tonumber(record:get("MONTH_BALANCE"));
    balance_sum = balance_sum + balance;

    -- Set variables for table display
    record:set("DATE", date);
    record:set("NET_WORTH", balance_sum);

    -- Add data for chart display
    labels = labels .. '"' .. date .. '",';
    local balance_str = string.format("%.2f", balance_sum);    
    if tonumber(string.sub(balance_str,-1)) == 0  and tonumber(string.sub(balance_str,-2)) ~= 0 then
        data = data .. '\'' .. balance_str .. '\',';
    else
        data = data .. balance_str .. ',';
    end
end

function complete(result)       
    result:set('TREND_DATA', string.sub(labels,1,-2) .. "]," .. string.sub(data,1,-2) .. "]}]");
end
