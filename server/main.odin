package server

/*
    use with `telnet localhost 9868`
*/

import "core:sync"
import "core:thread"
import "core:net"
import "core:fmt"
import "core:slice"
import "../game"

next_id: i32 = 1
clients: map[net.TCP_Socket]i32
clients_mutex: sync.Mutex

broadcast_to_all_except :: proc(except: net.TCP_Socket, buffer: []u8) {
    sync.lock(&clients_mutex)
    for client in clients {
        if client == except do continue
        net.send_tcp(client, buffer)
    }
    sync.unlock(&clients_mutex)
}

broadcast_event_to_all_except :: proc(except: net.TCP_Socket, event: game.ClientEvent) {
    event := event
    buffer := slice.from_ptr(transmute(^u8)(&event), size_of(game.ClientEvent))
    broadcast_to_all_except(except, buffer)
}

handle_con :: proc(client: net.TCP_Socket, source: net.Endpoint) {
    defer {
        net.close(client)
        sync.lock(&clients_mutex)
        delete_key(&clients, client)
        sync.unlock(&clients_mutex)

        broadcast_event_to_all_except(client, game.ClientEvent {
            type = .PLAYER_DISCONNECT,
            player_connect = game.PlayerConnectClientEvent {
                id = next_id,
            },
        })
        
        free_all(context.temp_allocator)
    }
    buffer: [256]u8

    for {
        bytes_recv, _ := net.recv_tcp(client, buffer[:])
        received := buffer[:bytes_recv]

        if bytes_recv == 0 do break

        event := transmute(^game.ServerEvent)(raw_data(received))

        msg := fmt.tprintf("%s : %s\n", net.endpoint_to_string(source), event^)
        // fmt.print(msg)
        // broadcast_to_all_except(client, transmute([]u8)(msg))

        sync.lock(&clients_mutex)
        id := clients[client]
        sync.unlock(&clients_mutex)
        broadcast_event_to_all_except(client, game.ClientEvent {
            type = .PLAYER_UPDATE,
            player_update = game.PlayerUpdateClientEvent {
                id = id,
                position = event.player_update.position,
                rotation = event.player_update.rotation,
            },
        })
    }
}

main :: proc() {
    fmt.println("Hello from server")

    local_addr, _ := net.parse_ip4_address("0.0.0.0");
    endpoint := net.Endpoint {
        address = local_addr,
        port = 9868,
    }
    sock, _ := net.listen_tcp(endpoint)
    defer net.close(sock)

    clients = make(map[net.TCP_Socket]i32)
    defer delete(clients)

    fmt.printfln("Listening on %s", net.endpoint_to_string(endpoint))
    for {
        client, source, _ := net.accept_tcp(sock)
        sync.lock(&clients_mutex)

        for _, id in clients {
            event := game.ClientEvent {
                type = .PLAYER_CONNECT,
                player_connect = game.PlayerConnectClientEvent {
                    id = id,
                },
            }
            buffer := slice.from_ptr(transmute(^u8)(&event), size_of(game.ClientEvent))
            net.send_tcp(client, buffer)
        } 
        clients[client] = next_id

        sync.unlock(&clients_mutex)
        broadcast_event_to_all_except(client, game.ClientEvent {
            type = .PLAYER_CONNECT,
            player_connect = game.PlayerConnectClientEvent {
                id = next_id,
            },
        })
        next_id += 1

        thread.create_and_start_with_poly_data2(client, source, handle_con)
    }
}