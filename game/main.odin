package game

import "core:fmt"
import "core:os"
import "core:net"

main :: proc() {
    game := create_game()
    defer delete_game(&game)
    local_addr, _ := net.parse_ip4_address("127.0.0.1");
    endpoint := net.Endpoint {
        address = local_addr,
        port = 9868,
    }
    connect_net_con(&game.net_con, endpoint)
    run_game(&game)
}