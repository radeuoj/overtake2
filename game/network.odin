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
        last_update = time.tick_now(),
        net_players = make(map[i32]Player),
    }
}

delete_net_con :: proc(net_con: ^NetConnection) {
    if net_con.is_connected do close_net_con(net_con)
    delete(net_con.net_players)
}

connect_net_con :: proc(net_con: ^NetConnection, endpoint: net.Endpoint) {
    sock, _ := net.dial_tcp(endpoint)
    net_con.sock = sock
    net_con.is_connected = true

    ch, _ := chan.create(chan.Chan(ClientEvent), context.allocator)
    net_con.rx = ch
    thread.create_and_start_with_poly_data2(net_con, chan.as_send(ch), net_con_recv_task)
}

close_net_con :: proc(net_con: ^NetConnection) {
    net.close(net_con.sock)
    net_con.is_connected = false
    clear(&net_con.net_players)
    thread.destroy(net_con.rx_thread)
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

    buffer := slice.from_ptr(transmute(^u8)(&event), size_of(ServerEvent))
    net.send_tcp(game.net_con.sock, buffer)
}

recv_net_con_update :: proc(net_con: ^NetConnection) {
    for {
        event, ok := chan.try_recv(net_con.rx)
        if !ok do break

        switch event.type {
        case .PLAYER_UPDATE:
            player := &net_con.net_players[event.player_update.id]
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
    buffer: [256]u8

    for {
        bytes_recv, _ := net.recv_tcp(net_con.sock, buffer[:])
        received := buffer[:bytes_recv]

        if bytes_recv == 0 do break

        event := transmute(^ClientEvent)(raw_data(received))
        chan.send(tx, event^)
    }
}

draw_net_players :: proc(net_con: ^NetConnection, camera: [2]f32) {
    for id, &player in net_con.net_players {
        draw_player(&player, camera)
    }
}
