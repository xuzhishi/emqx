%%--------------------------------------------------------------------
%% Copyright (c) 2021 EMQ Technologies Co., Ltd. All Rights Reserved.
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

-module(emqx_gateway_api_listeners).

-behaviour(minirest_api).

-include_lib("typerefl/include/types.hrl").

-define(BAD_REQUEST, 'BAD_REQUEST').
-define(NOT_FOUND, 'NOT_FOUND').
-define(INTERNAL_ERROR, 'INTERNAL_SERVER_ERROR').

-import(hoconsc, [mk/2, ref/1, ref/2]).
-import(emqx_dashboard_swagger, [error_codes/2]).

-import(emqx_gateway_http,
        [ return_http_error/2
        , with_gateway/2
        , checks/2
        ]).

-import(emqx_gateway_api_authn, [schema_authn/0]).

%% minirest/dashbaord_swagger behaviour callbacks
-export([ api_spec/0
        , paths/0
        , schema/1
        ]).

-export([ roots/0
        , fields/1
        ]).

%% http handlers
-export([ listeners/2
        , listeners_insta/2
        , listeners_insta_authn/2
        ]).

%%--------------------------------------------------------------------
%% minirest behaviour callbacks
%%--------------------------------------------------------------------

api_spec() ->
    emqx_dashboard_swagger:spec(?MODULE, #{check_schema => true}).

paths() ->
    [ "/gateway/:name/listeners"
    , "/gateway/:name/listeners/:id"
    , "/gateway/:name/listeners/:id/authentication"
    ].

%%--------------------------------------------------------------------
%% http handlers

listeners(get, #{bindings := #{name := Name0}}) ->
    with_gateway(Name0, fun(GwName, _) ->
        {200, emqx_gateway_conf:listeners(GwName)}
    end);

listeners(post, #{bindings := #{name := Name0}, body := LConf}) ->
    with_gateway(Name0, fun(GwName, Gateway) ->
        RunningConf = maps:get(config, Gateway),
        %% XXX: check params miss? check badly data tpye??
        _ = checks([<<"type">>, <<"name">>, <<"bind">>], LConf),

        Type = binary_to_existing_atom(maps:get(<<"type">>, LConf)),
        LName = binary_to_atom(maps:get(<<"name">>, LConf)),

        Path = [listeners, Type, LName],
        case emqx_map_lib:deep_get(Path, RunningConf, undefined) of
            undefined ->
                ListenerId = emqx_gateway_utils:listener_id(
                               GwName, Type, LName),
                ok = emqx_gateway_http:add_listener(ListenerId, LConf),
                {204};
            _ ->
                return_http_error(400, "Listener name has occupied")
        end
    end).

listeners_insta(delete, #{bindings := #{name := Name0, id := ListenerId0}}) ->
    ListenerId = emqx_mgmt_util:urldecode(ListenerId0),
    with_gateway(Name0, fun(_GwName, _) ->
        ok = emqx_gateway_http:remove_listener(ListenerId),
        {204}
    end);
listeners_insta(get, #{bindings := #{name := Name0, id := ListenerId0}}) ->
    ListenerId = emqx_mgmt_util:urldecode(ListenerId0),
    with_gateway(Name0, fun(_GwName, _) ->
        case emqx_gateway_conf:listener(ListenerId) of
            {ok, Listener} ->
                {200, Listener};
            {error, not_found} ->
                return_http_error(404, "Listener not found");
            {error, Reason} ->
                return_http_error(500, Reason)
        end
    end);
listeners_insta(put, #{body := LConf,
                       bindings := #{name := Name0, id := ListenerId0}
                      }) ->
    ListenerId = emqx_mgmt_util:urldecode(ListenerId0),
    with_gateway(Name0, fun(_GwName, _) ->
        ok = emqx_gateway_http:update_listener(ListenerId, LConf),
        {204}
    end).

listeners_insta_authn(get, #{bindings := #{name := Name0,
                                           id := ListenerId0}}) ->
    ListenerId = emqx_mgmt_util:urldecode(ListenerId0),
    with_gateway(Name0, fun(GwName, _) ->
        try
            emqx_gateway_http:authn(GwName, ListenerId)
        of
            Authn -> {200, Authn}
        catch
            error : {config_not_found, _} ->
                {204}
        end
    end);
listeners_insta_authn(post, #{body := Conf,
                              bindings := #{name := Name0,
                                            id := ListenerId0}}) ->
    ListenerId = emqx_mgmt_util:urldecode(ListenerId0),
    with_gateway(Name0, fun(GwName, _) ->
        ok = emqx_gateway_http:add_authn(GwName, ListenerId, Conf),
        {204}
    end);
listeners_insta_authn(put, #{body := Conf,
                             bindings := #{name := Name0,
                                           id := ListenerId0}}) ->
    ListenerId = emqx_mgmt_util:urldecode(ListenerId0),
    with_gateway(Name0, fun(GwName, _) ->
        ok = emqx_gateway_http:update_authn(GwName, ListenerId, Conf),
        {204}
    end);
listeners_insta_authn(delete, #{bindings := #{name := Name0,
                                              id := ListenerId0}}) ->
    ListenerId = emqx_mgmt_util:urldecode(ListenerId0),
    with_gateway(Name0, fun(GwName, _) ->
        ok = emqx_gateway_http:remove_authn(GwName, ListenerId),
        {204}
    end).

%%--------------------------------------------------------------------
%% Swagger defines
%%--------------------------------------------------------------------

schema("/gateway/:name/listeners") ->
    #{ 'operationId' => listeners,
       get =>
         #{ description => <<"Get the gateway listeners">>
          , parameters => params_gateway_name_in_path()
          , responses =>
             #{ 400 => error_codes([?BAD_REQUEST], <<"Bad Request">>)
              , 404 => error_codes([?NOT_FOUND], <<"Not Found">>)
              , 500 => error_codes([?INTERNAL_ERROR],
                                   <<"Ineternal Server Error">>)
              , 200 => emqx_dashboard_swagger:schema_with_examples(
                         hoconsc:array(ref(listener)),
                         examples_listener_list())
              }
          },
       post =>
         #{ description => <<"Create the gateway listener">>
          , parameters => params_gateway_name_in_path()
          , 'requestBody' => emqx_dashboard_swagger:schema_with_examples(
                             ref(listener),
                             examples_listener())
          , responses =>
             #{ 400 => error_codes([?BAD_REQUEST], <<"Bad Request">>)
              , 404 => error_codes([?NOT_FOUND], <<"Not Found">>)
              , 500 => error_codes([?INTERNAL_ERROR],
                                   <<"Ineternal Server Error">>)
              , 204 => <<"Created">>
              }
          }
     };
schema("/gateway/:name/listeners/:id") ->
    #{ 'operationId' => listeners_insta,
       get =>
         #{ description => <<"Get the gateway listener configurations">>
          , parameters => params_gateway_name_in_path()
                          ++ params_listener_id_in_path()
          , responses =>
             #{ 400 => error_codes([?BAD_REQUEST], <<"Bad Request">>)
              , 404 => error_codes([?NOT_FOUND], <<"Not Found">>)
              , 500 => error_codes([?INTERNAL_ERROR],
                                   <<"Ineternal Server Error">>)
              , 200 => emqx_dashboard_swagger:schema_with_examples(
                         ref(listener),
                         examples_listener())
              }
           },
       delete =>
         #{ description => <<"Delete the gateway listener">>
          , parameters => params_gateway_name_in_path()
                          ++ params_listener_id_in_path()
          , responses =>
             #{ 400 => error_codes([?BAD_REQUEST], <<"Bad Request">>)
              , 404 => error_codes([?NOT_FOUND], <<"Not Found">>)
              , 500 => error_codes([?INTERNAL_ERROR],
                                   <<"Ineternal Server Error">>)
              , 204 => <<"Deleted">>
              }
           },
       put =>
         #{ description => <<"Update the gateway listener">>
          , parameters => params_gateway_name_in_path()
                          ++ params_listener_id_in_path()
          , 'requestBody' => emqx_dashboard_swagger:schema_with_examples(
                             ref(listener),
                             examples_listener())
          , responses =>
             #{ 400 => error_codes([?BAD_REQUEST], <<"Bad Request">>)
              , 404 => error_codes([?NOT_FOUND], <<"Not Found">>)
              , 500 => error_codes([?INTERNAL_ERROR],
                                   <<"Ineternal Server Error">>)
              , 200 => <<"Updated">>
              }
          }
     };
schema("/gateway/:name/listeners/:id/authentication") ->
    #{ 'operationId' => listeners_insta_authn,
       get =>
         #{ description => <<"Get the listener's authentication info">>
          , parameters => params_gateway_name_in_path()
                          ++ params_listener_id_in_path()
          , responses =>
             #{ 400 => error_codes([?BAD_REQUEST], <<"Bad Request">>)
              , 404 => error_codes([?NOT_FOUND], <<"Not Found">>)
              , 500 => error_codes([?INTERNAL_ERROR],
                                   <<"Ineternal Server Error">>)
              , 200 => schema_authn()
              , 204 => <<"Authentication does not initiated">>
              }
          },
       post =>
         #{ description => <<"Add authentication for the listener">>
          , parameters => params_gateway_name_in_path()
                          ++ params_listener_id_in_path()
          , 'requestBody' => schema_authn()
          , responses =>
             #{ 400 => error_codes([?BAD_REQUEST], <<"Bad Request">>)
              , 404 => error_codes([?NOT_FOUND], <<"Not Found">>)
              , 500 => error_codes([?INTERNAL_ERROR],
                                   <<"Ineternal Server Error">>)
              , 204 => <<"Added">>
              }
          },
       put =>
         #{ description => <<"Update authentication for the listener">>
          , parameters => params_gateway_name_in_path()
                          ++ params_listener_id_in_path()
          , 'requestBody' => schema_authn()
          , responses =>
             #{ 400 => error_codes([?BAD_REQUEST], <<"Bad Request">>)
              , 404 => error_codes([?NOT_FOUND], <<"Not Found">>)
              , 500 => error_codes([?INTERNAL_ERROR],
                                   <<"Ineternal Server Error">>)
              , 204 => <<"Updated">>
              }
          },
       delete =>
         #{ description => <<"Remove authentication for the listener">>
          , parameters => params_gateway_name_in_path()
                          ++ params_listener_id_in_path()
          , responses =>
             #{ 400 => error_codes([?BAD_REQUEST], <<"Bad Request">>)
              , 404 => error_codes([?NOT_FOUND], <<"Not Found">>)
              , 500 => error_codes([?INTERNAL_ERROR],
                                   <<"Ineternal Server Error">>)
              , 204 => <<"Deleted">>
              }
          }
     }.

%%--------------------------------------------------------------------
%% params defines

params_gateway_name_in_path() ->
    [{name,
      mk(binary(),
         #{ in => path
          , desc => <<"Gateway Name">>
          })}
    ].

params_listener_id_in_path() ->
    [{id,
      mk(binary(),
         #{ in => path
          , desc => <<"Listener ID">>
          })}
    ].

%%--------------------------------------------------------------------
%% schemas

roots() ->
    [ listener
    ].

fields(listener) ->
    common_listener_opts() ++
    [ {tcp,
       mk(ref(tcp_listener_opts),
          #{ nullable => {true, recursively}
           , desc => <<"The tcp socket options for tcp or ssl listener">>
           })}
    , {ssl,
       mk(ref(ssl_listener_opts),
          #{ nullable => {true, recursively}
           , desc => <<"The ssl socket options for ssl listener">>
           })}
    , {udp,
       mk(ref(udp_listener_opts),
          #{ nullable => {true, recursively}
           , desc => <<"The udp socket options for udp or dtls listener">>
           })}
    , {dtls,
       mk(ref(dtls_listener_opts),
          #{ nullable => {true, recursively}
           , desc => <<"The dtls socket options for dtls listener">>
           })}
    ];
fields(tcp_listener_opts) ->
    [ {active_n, mk(integer(), #{})}
    , {backlog, mk(integer(), #{})}
    , {buffer, mk(binary(), #{})}
    , {recbuf, mk(binary(), #{})}
    , {sndbuf, mk(binary(), #{})}
    , {high_watermark, mk(binary(), #{})}
    , {nodelay, mk(boolean(), #{})}
    , {reuseaddr, boolean()}
    , {send_timeout, binary()}
    , {send_timeout_close, boolean()}
    ];
fields(ssl_listener_opts) ->
    [ {cacertfile, binary()}
    , {certfile, binary()}
    , {keyfile, binary()}
    , {verify, binary()}
    , {fail_if_no_peer_cert, boolean()}
    , {server_name_indication, boolean()}
    , {depth, integer()}
    , {password, binary()}
    , {handshake_timeout, binary()}
    , {versions, hoconsc:array(binary())}
    , {ciphers, hoconsc:array(binary())}
    , {user_lookup_fun, binary()}
    , {reuse_sessions, boolean()}
    , {secure_renegotiate, boolean()}
    , {honor_cipher_order, boolean()}
    , {dhfile, binary()}
    ];
fields(udp_listener_opts) ->
    [ {active_n, integer()}
    , {buffer, binary()}
    , {recbuf, binary()}
    , {sndbuf, binary()}
    , {reuseaddr, boolean()}
    ];
fields(dtls_listener_opts) ->
    Ls = lists_key_without(
      [versions,ciphers,handshake_timeout], 1,
      fields(ssl_listener_opts)
     ),
    [ {versions, hoconsc:array(binary())}
    , {ciphers, hoconsc:array(binary())}
    | Ls].

lists_key_without([], _N, L) ->
    L;
lists_key_without([K | Ks], N, L) ->
    lists_key_without(Ks, N, lists:keydelete(K, N, L)).

common_listener_opts() ->
    [ {enable,
       mk(boolean(),
          #{ nullable => true
           , desc => <<"Whether to enable this listener">>})}
    , {id,
       mk(binary(),
          #{ nullable => true
           , desc => <<"Listener Id">>})}
    , {name,
       mk(binary(),
          #{ nullable => true
           , desc => <<"Listener name">>})}
    , {type,
       mk(hoconsc:enum([tcp, ssl, udp, dtls]),
          #{ nullable => true
           , desc => <<"Listener type. Enum: tcp, udp, ssl, dtls">>})}
    , {running,
       mk(boolean(),
          #{ nullable => true
           , desc => <<"Listener running status">>})}
    , {bind,
       mk(binary(),
          #{ nullable => true
           , desc => <<"Listener bind address or port">>})}
    , {acceptors,
       mk(integer(),
          #{ nullable => true
           , desc => <<"Listener acceptors number">>})}
    , {access_rules,
       mk(hoconsc:array(binary()),
          #{ nullable => true
           , desc => <<"Listener Access rules for client">>})}
    , {max_conn_rate,
       mk(integer(),
          #{ nullable => true
           , desc => <<"Max connection rate for the listener">>})}
    , {max_connections,
       mk(integer(),
          #{ nullable => true
           , desc => <<"Max connections for the listener">>})}
    , {mountpoint,
       mk(binary(),
          #{ nullable => true
           , desc =>
<<"The Mounpoint for clients of the listener. "
  "The gateway-level mountpoint configuration can be overloaded "
  "when it is not null or empty string">>})}
    %% FIXME:
    , {authentication,
       mk(emqx_authn_schema:authenticator_type(),
          #{ nullable => {true, recursively}
           , desc => <<"The authenticatior for this listener">>
           })}
    ].

%%--------------------------------------------------------------------
%% examples

examples_listener_list() ->
    [examples_listener()].

examples_listener() ->
    #{id => true}.
