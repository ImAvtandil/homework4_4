-module(my_cache).

-export([create/1, insert/3, insert/4, lookup/2, delete_obsolete/1]).

-include_lib("stdlib/include/ms_transform.hrl").

create(TableName) ->
    case ets:whereis(TableName) of
        undefined ->
            ets:new(TableName, [named_table, public]);
        _ ->
            ok
    end,
    ok.

insert(TableName, Key, Value) ->
    ets:insert_new(TableName, {Key, 0, Value}),
    ok.

insert(TableName, Key, Value, Expire) ->
    ExpireTime = getCurrentTime() + Expire,
    ets:insert_new(TableName, {Key, ExpireTime, Value}),
    ok.

lookup(TableName, Key) ->
    Time = getCurrentTime(),
    case ets:lookup(TableName, Key) of
        [{Key, Expire, Value}] when Expire > Time ->
            Value;
        [{Key, 0, Value}] ->
            Value;
        _ ->
            undefined
    end.

delete_obsolete(TableName) ->
    Time = getCurrentTime(),
    Select = ets:fun2ms(fun({_, Expire, _}) when Expire =/= 0, Expire < Time -> true end),
    ets:select_delete(TableName, Select),
    ok.

getCurrentTime() ->
    calendar:datetime_to_gregorian_seconds(
        calendar:universal_time()).
