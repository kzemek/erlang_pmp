## erlang_pmp

[![Hex pm](http://img.shields.io/hexpm/v/erlang_pmp.svg?style=flat)](https://hex.pm/packages/erlang_pmp)

[Poor Man's Profiler](https://poormansprofiler.org/) inspired Erlang profiler.

### Running

```erlang
erlang_pmp:profile(Opts).
```

#### Opts

* `duration`: duration the profiling will run for, in seconds (default: `60`).
* `processes`: list of PIDs that will be profiled, or `all` to use
  [`erlang:processes()`](http://erlang.org/doc/man/erlang.html#processes-0) before taking each sample (default: `all`).
* `sleep`: sleep duration in milliseconds between taking samples (default: `10`).
* `show_pid`: if `true`, PID (or process name if registered) will be prepended to the stack trace (default: `false`).
* `filename`: path under which the profiling results will be saved (default: `/tmp/erlang_pmp.trace`).
* `include_statuses`: a list of process statuses as returned from
  [`erlang:process_info(Pid, status)`](http://erlang.org/doc/man/erlang.html#process_info-2).
  A stack trace will only be counted if the process status belongs to the list, or if `include_statuses` is `all` (default: `all`).
* `show_status`: if `true`, status of the process will be appended to the stack trace (default: `false`)

#### Output

The output of `erlang_pmp` is meant to be used with [FlameGraph stack trace visualizer](https://github.com/brendangregg/FlameGraph):

```
git clone https://github.com/brendangregg/FlameGraph.git
FlameGraph/flamegraph.pl /tmp/erlang_pmp.trace > /tmp/erlang_pmp.svg
```
