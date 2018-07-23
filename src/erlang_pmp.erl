%%==============================================================================
%% Copyright 2018 Erlang Solutions Ltd.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%==============================================================================

-module(erlang_pmp).
-author('konrad.zemek@erlang-solutions.com').

%% API exports
-export([profile/1]).

%%====================================================================
%% API functions
%%====================================================================

profile(Opts) ->
    Duration = proplists:get_value(duration, Opts, 60),
    Processes = proplists:get_value(processes, Opts, all),
    Sleep = proplists:get_value(sleep, Opts, 10),
    ShowPid = proplists:get_value(show_pid, Opts, false),
    Filename = proplists:get_value(filename, Opts, "/tmp/erlang_pmp.trace"),
    IncludedStatuses = proplists:get_value(include_statuses, Opts, all),
    ShowStatus = proplists:get_value(show_status, Opts, false),

    End = erlang:monotonic_time() + erlang:convert_time_unit(Duration, seconds, native),
    spawn_link(fun() -> profile(End, Processes, Sleep, ShowPid, Filename, IncludedStatuses, ShowStatus, #{}) end).

%%====================================================================
%% Internal functions
%%====================================================================

profile(End, Processes, Sleep, ShowPid, Filename, IncludedStatuses, ShowStatus, State) ->
    case erlang:monotonic_time() > End of
        true ->
            case file:open(Filename, [raw, write, delayed_write, {encoding, utf8}]) of
                {error, _} = Err -> Err;
                {ok, File} ->
                    write_state(File, State),
                    ok = file:close(File)
            end;

        false ->
            State2 = single_pass(process_list(Processes), ShowPid, IncludedStatuses, ShowStatus, State),
            sleep(Sleep),
            profile(End, Processes, Sleep, ShowPid, Filename, IncludedStatuses, ShowStatus, State2)
    end.

write_state(File, State) ->
    lists:foreach(
      fun({Trace, Count}) ->
              Elems =
                  lists:map(
                    fun
                        ({M, F, A}) -> [atom_to_list(M), $:, atom_to_list(F), $/, integer_to_list(A)];
                        (Pid) when is_pid(Pid) -> pid_to_list(Pid);
                        (Atom) when is_atom(Atom) -> atom_to_list(Atom)
                    end,
                    Trace),
              ok = file:write(File, [lists:join($;, Elems), $ , integer_to_list(Count), $\n])
      end,
      maps:to_list(State)).

single_pass(Processes, ShowPid, IncludedStatuses, ShowStatus, State) ->
    lists:foldl(
      fun(Pid, Acc) ->
              case trace(Pid, ShowPid, IncludedStatuses, ShowStatus) of
                  [] -> Acc;
                  Trace -> maps:update_with(Trace, fun(V) -> V + 1 end, 1, Acc)
              end
      end, State, Processes).

trace(Pid, ShowPid, IncludedStatuses, ShowStatus) ->
    case erlang:process_info(Pid, [status, registered_name, current_stacktrace]) of
        undefined -> [];
        [{status, Status}, {registered_name, Name}, {current_stacktrace, Stack}] ->
            case IncludedStatuses == all orelse lists:member(Status, IncludedStatuses) of
                false -> [];
                true ->
                    RevTrace = lists:map(fun({M, F, A, _Loc}) -> {M, F, A} end, Stack),
                    WithStatus = case ShowStatus of true -> [Status | RevTrace]; false -> RevTrace end,
                    Trace = lists:reverse(WithStatus),
                    case ShowPid of true -> [to_name(Name, Pid) | Trace]; false -> Trace end
            end
    end.

sleep(0) -> ok;
sleep(Time) -> timer:sleep(Time).

to_name([] = _Name, Pid) -> Pid;
to_name(Name, _Pid) when is_atom(Name) -> Name.

process_list(all) -> erlang:processes();
process_list([Pid | _] = Processes) when is_pid(Pid) -> Processes.
