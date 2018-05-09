%%--------------------------------------------------------------------
%% Copyright (c) 2013-2017 EMQ Enterprise, Inc. (http://emqtt.io)
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(emqx_auth_jwt_app).

-behaviour(application).

-import(application, [get_env/2, get_env/3]).

-export([start/2, stop/1]).

-behaviour(supervisor).

-export([init/1]).

-behaviour(emqx_services).

-export([create/2, destroy/0, description/0]).

-define(APP, emqx_auth_jwt).

start(_Type, _Args) ->
    ok = emqx_services:register(?APP, auth, []),
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

stop(_State) ->
    ok.

%%--------------------------------------------------------------------
%% Dummy Supervisor
%%--------------------------------------------------------------------

init([]) ->
    {ok, { {one_for_all, 1, 10}, []} }.

%%--------------------------------------------------------------------
%% emqx_services callbacks
%%--------------------------------------------------------------------

create(Conf, _Env) ->
    AuthEnv = #{secret => proplists:get_value(secret, Conf, undefined),
                pubkey => read_pubkey(proplists:get_value(pubkey, Conf))},
    ok = emqx_access_control:register_mod(auth, ?APP, AuthEnv),
    emqx_auth_jwt_cfg:register().

destroy() ->
    emqx_access_control:unregister_mod(auth, ?APP),
    emqx_auth_jwt_cfg:unregister().

description() -> "Auth Plugin with JWT".

%%--------------------------------------------------------------------
%% Internal functions
%%--------------------------------------------------------------------

read_pubkey(undefined)  -> undefined;

read_pubkey({ok, Path}) -> {ok, PubKey} = file:read_file(Path), PubKey.

