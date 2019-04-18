local total_basebalance = 0;

function handle_record(record)
    if record:get('TYPE') == 'Assets' then
        pertype = record:get('PER_TYPE');
        if pertype ~= 'None' then
            year, month, day = string.match(record:get('PRICEDATE'), "(%d+)-(%d+)-(%d+)");
            cyear, cmonth, cday = string.match(os.date ("%Y-%m-%d"), "(%d+)-(%d+)-(%d+)");
            numyears = cyear - year;
            if (cmonth < month) then
                numyears = numyears - 1;
            else
                if (cmonth == month) and (cday < day) then
                    numyears = numyears - 1;
                end
            end
            if pertype == 'Depreciates' then
                calcd_value  = tonumber(record:get('BALANCE')) * (1-tonumber(record:get('PER_RATE'))/100) ^ numyears;
            else
                calcd_value  = tonumber(record:get('BALANCE')) * (1+tonumber(record:get('PER_RATE'))/100) ^ numyears;
            end
            record:set('BALANCE', calcd_value);
            record:set('BASEBALANCE', calcd_value); -- same value can be added in BALANCE and BASEBALANCE as Asset values are in base currency.
            record:set('COMMENT', 'Value ' .. pertype .. ' after ' .. numyears .. ' years ' );
        end
    end
    total_basebalance = total_basebalance + record:get('BASEBALANCE');
end

function complete(result)
    result:set('TOTAL_BASEBALANCE', total_basebalance);
end
