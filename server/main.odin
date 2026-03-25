package server

import "core:thread"
import "core:net"
import "core:fmt"
import "core:slice"
import "../game"

clients: ClientsStore

main :: proc() {
    fmt.println("Hello from server")

    endpoint, _ := net.parse_endpoint("0.0.0.0:9868");
    sock, _ := net.listen_tcp(endpoint)
    defer net.close(sock)

    clients = create_clients()
    defer delete_clients(&clients)

    fmt.printfln("Listening on %s", net.endpoint_to_string(endpoint))
    listen_for_cons(sock)
}

listen_for_cons :: proc(sock: net.TCP_Socket) {
    next_id: i32 = 1

    for {
        client, _, err := net.accept_tcp(sock)
        if err != nil {
            fmt.printfln("net.accept_tcp error %v", err)
            break
        }

        id := next_id
        next_id += 1
        fmt.printfln("%v connected", id)
        send_current_clients(client)
        clients_set(&clients, client, id)
        broadcast_player_connect(client, id)
        thread.create_and_start_with_poly_data(client, handle_con, self_cleanup = true)
    }
}

send_event :: proc(client: net.TCP_Socket, event: ^game.ClientEvent) {
    buf := slice.bytes_from_ptr(event, size_of(game.ClientEvent))
    _, err := net.send_tcp(client, buf)
    if err != nil {
        fmt.printfln("net.send_tcp error %v", err)
    }
}

send_current_clients :: proc(client: net.TCP_Socket) {
    for cl, id in clients_lock_and_get_store(&clients) {
        if cl == client do continue
        event := game.create_player_connect_event(id)
        send_event(client, &event)
    }

    clients_unlock(&clients)
}

broadcast_event :: proc(event: ^game.ClientEvent, except: net.TCP_Socket = 0) {
    for client in clients_lock_and_get_store(&clients) {
        if client == except do continue
        send_event(client, event)
    }

    clients_unlock(&clients)
}

broadcast_player_connect :: proc(client: net.TCP_Socket, id: i32) {
    event := game.create_player_connect_event(id)
    broadcast_event(&event, client)
}

handle_con :: proc(client: net.TCP_Socket) {
    defer disconnect_client(client)
    buffer: [512]u8
    offset := 0
    id, _ := clients_get(&clients, client)

    for {
        bytes_recv, err := net.recv_tcp(client, buffer[:])
        if err != nil {
            fmt.printfln("net.recp_tcp error %v", err)
            break
        }
        if bytes_recv == 0 do break
        offset += bytes_recv

        if offset >= size_of(game.ServerEvent) {
            event := cast(^game.ServerEvent)raw_data(buffer[:size_of(game.ServerEvent)])
            handle_server_event(client, id, event)

            copy(buffer[:], buffer[size_of(game.ServerEvent):offset])
            offset -= size_of(game.ServerEvent)
        }
    }
}

disconnect_client :: proc(client: net.TCP_Socket) {
    err := net.shutdown(client, .Both)
    if err != nil do fmt.printfln("net.shutdown error %v", err)
    net.close(client)
    _, id := clients_erase(&clients, client)
    fmt.printfln("%v disconnected", id)
    event := game.create_player_disconnect_event(id)
    broadcast_event(&event)
}

handle_server_event :: proc(client: net.TCP_Socket, id: i32, event: ^game.ServerEvent) {
    switch event.type {
    case .PLAYER_UPDATE:
        client_event := game.ClientEvent {
            type = .PLAYER_UPDATE,
            player_update = game.PlayerUpdateClientEvent {
                id = id,
                position = event.player_update.position,
                rotation = event.player_update.rotation,
            },
        }

        broadcast_event(&client_event, client)
    }
}