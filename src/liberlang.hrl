%%%-------------------------------------------------------------------
%%% @author heyoka
%%% @copyright (C) 2022, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Jan 2022 09:59
%%%-------------------------------------------------------------------
-author("heyoka").

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

-record(mem_queue, {
  q,
  max,
  current
}).
