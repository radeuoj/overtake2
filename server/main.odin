package server

/*
    use with `telnet localhost 9868`
*/

import "core:sync"
import "core:thread"
import "core:net"
import "core:fmt"

clients: map[net.TCP_Socket]struct{}
clients_mutex: sync.Mutex

broadcast_to_all_except :: proc(except: net.TCP_Socket, buffer: []u8) {
    sync.lock(&clients_mutex)
    for client in clients {
        if client == except do continue
        net.send_tcp(client, buffer)
    }
    sync.unlock(&clients_mutex)
}

handle_con :: proc(client: net.TCP_Socket, source: net.Endpoint) {
    defer {
        net.close(client)
        sync.lock(&clients_mutex)
        delete_key(&clients, client)
        sync.unlock(&clients_mutex)
    }
    buffer: [256]u8

    for {
        bytes_recv, _ := net.recv_tcp(client, buffer[:])
        received := buffer[:bytes_recv]

        if bytes_recv == 0 do break

        msg := fmt.tprintf("%s : %s", net.endpoint_to_string(source), received)
        fmt.print(msg)
        broadcast_to_all_except(client, transmute([]u8)(msg))

        free_all(context.temp_allocator)
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

    clients = make(map[net.TCP_Socket]struct{})
    defer delete(clients)

    fmt.printfln("Listening on %s", net.endpoint_to_string(endpoint))
    for {
        client, source, _ := net.accept_tcp(sock)
        sync.lock(&clients_mutex)
        clients[client] = struct{}{}
        sync.unlock(&clients_mutex)
        thread.create_and_start_with_poly_data2(client, source, handle_con)
    }
}