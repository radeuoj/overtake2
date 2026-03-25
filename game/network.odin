package game

import "core:thread"
import "core:sync/chan"
import "core:slice"
import "core:fmt"
import "core:time"
import "core:net"

ServerEvent :: struct {
    type: ServerEventType,
    using _: struct #raw_union {
        player_update: PlayerUpdateServerEvent,
    },
}

ServerEventType :: enum {
    PLAYER_UPDATE,
}


PlayerUpdateServerEvent :: struct {
    position: [2]f32,
    rotation: f32,
}

ClientEvent :: struct {
    type: ClientEventType,
    using _: struct #raw_union {
        player_update: PlayerUpdateClientEvent,
        player_connect: PlayerConnectClientEvent,
    },
}

ClientEventType :: enum {
    PLAYER_UPDATE,
    PLAYER_CONNECT,
    PLAYER_DISCONNECT,
}

PlayerUpdateClientEvent :: struct {
    id: i32,
    position: [2]f32,
    rotation: f32,
}

PlayerConnectClientEvent :: struct {
    id: i32,
}

create_player_connect_event :: proc(id: i32) -> ClientEvent {
    return ClientEvent {
        type = .PLAYER_CONNECT,
        player_connect = PlayerConnectClientEvent {
            id = id,
        },
    }
}

create_player_disconnect_event :: proc(id: i32) -> ClientEvent {
    return ClientEvent {
        type = .PLAYER_DISCONNECT,
        player_connect = PlayerConnectClientEvent {
            id = id,
        },
    }
}

NetConnection :: struct {
    is_connected: bool,
    sock: net.TCP_Socket,
    last_update: time.Tick,
    net_players: map[i32]Player,
    rx: chan.Chan(ClientEvent),
    rx_thread: ^thread.Thread,
}

// updates per second
NET_CON_UPS :: 20
NET_CON_DELTA_TIME :: 1.0 / NET_CON_UPS

create_net_con :: proc() -> NetConnection {
    return NetConnection {
        is_connected = false,
        sock = 0,
        last_update = time.tick_now(),
        net_players = make(map[i32]Player),
        rx_thread = nil,
    }
}

delete_net_con :: proc(net_con: ^NetConnection) {
    if net_con.is_connected do close_net_con(net_con)
    delete(net_con.net_players)
}

connect_net_con :: proc(net_con: ^NetConnection, endpoint: net.Endpoint) {
    sock, err := net.dial_tcp(endpoint)
    if err != nil {
        fmt.printfln("net.dial_tcp error %v", err)
        return
    }

    net_con.sock = sock
    net_con.is_connected = true

    ch, _ := chan.create(chan.Chan(ClientEvent), context.allocator)
    net_con.rx = ch
    net_con.rx_thread = thread.create_and_start_with_poly_data2(net_con, chan.as_send(ch), net_con_recv_task)
}

send_event :: proc(net_con: ^NetConnection, event: ^ServerEvent) {
    buf := slice.bytes_from_ptr(event, size_of(ServerEvent))
    _, err := net.send_tcp(net_con.sock, buf)
    if err == .Connection_Closed {
        close_net_con(net_con)
    } else if err != nil {
        fmt.printfln("net.send_tcp error %v", err)
    }
}

close_net_con :: proc(net_con: ^NetConnection) {
    net_con.is_connected = false
    err := net.shutdown(net_con.sock, .Both)
    if err != nil && err != .Invalid_Argument {
        fmt.printfln("net.shutdown error %v", err)
    }
    net.close(net_con.sock)
    thread.destroy(net_con.rx_thread)
    clear(&net_con.net_players)
    chan.destroy(net_con.rx)
}

update_net_con :: proc(game: ^Game) {
    if !game.net_con.is_connected do return

    if time.duration_seconds(time.tick_since(game.net_con.last_update)) >= NET_CON_DELTA_TIME {
        send_net_con_update(game)
        game.net_con.last_update = time.tick_now()
    }

    recv_net_con_update(&game.net_con)
}

send_net_con_update :: proc(game: ^Game) {
    event := ServerEvent {
        type = ServerEventType.PLAYER_UPDATE,
        player_update = PlayerUpdateServerEvent {
            position = game.player.position,
            rotation = game.player.rotation,
        },
    }

    send_event(&game.net_con, &event)
}

recv_net_con_update :: proc(net_con: ^NetConnection) {
    for {
        event, ok := chan.try_recv(net_con.rx)
        if !ok do break

        switch event.type {
        case .PLAYER_UPDATE:
            player, ok := &net_con.net_players[event.player_update.id]
            if !ok do continue
            player.position = event.player_update.position
            player.rotation = event.player_update.rotation
        case .PLAYER_CONNECT:
            fmt.printfln("%v connected", event.player_connect.id)
            net_con.net_players[event.player_connect.id] = create_player()
        case .PLAYER_DISCONNECT:
            fmt.printfln("%v disconnected", event.player_connect.id)
            delete_key(&net_con.net_players, event.player_connect.id)
        }
    }
}

net_con_recv_task :: proc(net_con: ^NetConnection, tx: chan.Chan(ClientEvent, .Send)) {
    buffer: [512]u8
    offset := 0

    for {
        bytes_recv, err := net.recv_tcp(net_con.sock, buffer[offset:])
        if err != nil {
            fmt.printfln("net.recv_tcp error %v", err)
            continue
        }
        if bytes_recv == 0 do break // connection closed
        offset += bytes_recv

        if offset >= size_of(ClientEvent) {
            event := cast(^ClientEvent)raw_data(buffer[:size_of(ClientEvent)])
            chan.send(tx, event^)

            copy(buffer[:], buffer[size_of(ClientEvent):offset])
            offset -= size_of(ClientEvent)
        }
    }
}

draw_net_players :: proc(net_con: ^NetConnection, camera: [2]f32) {
    for id, &player in net_con.net_players {
        draw_player(&player, camera)
    }
}
