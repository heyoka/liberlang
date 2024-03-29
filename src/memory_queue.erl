%%%-------------------------------------------------------------------
%%% @author heyoka
%%% @copyright (C) 2021
%%% @doc
%%% bounded in-memory queue
%%% used for simple in-memory queuing, can also be used as a kind of circular buffer
%%% @end
%%% Created : 08. Feb 2021 18:53
%%%-------------------------------------------------------------------
-module(memory_queue).
-author("heyoka").

-include("liberlang.hrl").
%% API
-export([enq/2, deq/1, to_list/1, new/1, to_list_reset/1, new/0, member/2]).

-type mem_queue() :: #mem_queue{}.
-export_type([mem_queue/0]).

-define(Q_MAX_SIZE, 100).

-spec new() -> mem_queue().
new() ->
  new(?Q_MAX_SIZE).

-spec new(non_neg_integer()) -> mem_queue().
new(Size) when Size =< 0 ->
  #mem_queue{q = queue:new(), max = 0, current = 0};
new(Size) ->
  #mem_queue{q = queue:new(), max = Size, current = 0}.

-spec enq(term()|list(term()), mem_queue()) -> mem_queue().
enq(_NewItem, Q=#mem_queue{max = 0}) ->
  Q;
enq(Items, Q) when is_list(Items) ->
  lists:foldl(fun(Item, Queue) -> enq(Item, Queue) end, Q, Items);
enq(NewItem, Q=#mem_queue{q = Queue, max = MaxQLen, current = Len}) ->
  {NewQ, NewQLen} =
    case Len >= MaxQLen of
      true -> {queue:drop(Queue), Len - 1};
      false -> {Queue, Len}
    end,
  QueueNew = queue:in(NewItem, NewQ),
  Q#mem_queue{q = QueueNew, current = NewQLen + 1}.

-spec deq(mem_queue()) -> {ok, term(), mem_queue()} | {empty, mem_queue()}.
deq(Q=#mem_queue{max = 0}) ->
  {empty, Q};
deq(Q=#mem_queue{q = Queue, current = Len}) ->
  case queue:out(Queue) of
    {{value, Item}, Queue2 }  ->
      {ok, Item, Q#mem_queue{q = Queue2, current = Len - 1}};
    {empty, _Queue1} ->
      {empty, Q}
  end.

%% @doc Return true or false depending on if Item is in queue
-spec member(term(), mem_queue()) -> true|false.
member(Item, #mem_queue{q = Queue}) ->
  queue:member(Item, Queue).

-spec to_list(mem_queue()) -> list().
to_list(#mem_queue{q = Queue}) ->
  queue:to_list(Queue).

-spec to_list_reset(mem_queue()) -> {list(), #mem_queue{}}.
to_list_reset(Q = #mem_queue{q = Queue}) ->
  {queue:to_list(Queue),
    %% reset, max_size stays the same
    Q#mem_queue{q = queue:new(), current = 0}
  }.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TESTS %%%%%%%%%
-ifdef(TEST).

basic_test() ->
  Q = new(20),
  Q1 = enq(1, Q),
  ?assertEqual(1, Q1#mem_queue.current),
  {ok, Res, Q2} = deq(Q1),
  ?assertEqual(1, Res),
  ?assertEqual(0, Q2#mem_queue.current).

empty_test() ->
  Q = new(1000),
  Q1 = enq(1, Q),
  {ok, 1, Q2} = deq(Q1),
  {R, _Q3} = deq(Q2),
  ?assertEqual(empty, R).

overflow_test() ->
  Q = new(2),
  Q1 = enq(1, Q),
  Q2 = enq(2, Q1),
  Q3 = enq(3, Q2),
  ?assertEqual(2, Q3#mem_queue.current),
  ?assertEqual([2,3], to_list(Q3)).

reset_test() ->
  Q = new(15),
  Q1 = enq(1, Q),
  Q2 = enq(2, Q1),
  Q3 = enq(3, Q2),
  ?assertEqual(3, Q3#mem_queue.current),
  {Res, QNew} = to_list_reset(Q3),
  ?assertEqual([1,2,3], Res),
  ?assertEqual(0, QNew#mem_queue.current),
  ?assertEqual([], to_list(QNew)).

member_test() ->
  Q = new(15),
  Q1 = enq(1, Q),
  Q2 = enq(2, Q1),
  Q3 = enq(3, Q2),
  ?assertEqual(true, member(2, Q3)).

not_member_test() ->
  Q = new(15),
  Q1 = enq(1, Q),
  Q2 = enq(2, Q1),
  Q3 = enq(3, Q2),
  ?assertEqual(false, member(44, Q3)).

enq_list_test() ->
  Q = new(15),
  Q1 = enq(1, Q),
  Q2 = enq(2, Q1),
  Q3 = enq(3, Q2),
  Q4 = enq([4,5,6,7], Q3),
  ?assertEqual([1,2,3,4,5,6,7], to_list(Q4)).

-endif.


