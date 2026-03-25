package game

import "core:net"
import "core:fmt"
import rl "vendor:raylib"
import mu "vendor:microui"
import "../rlmu"

Game :: struct {
    player: Player,
    camera: [2]f32,
    background: GameBackground,
    net_con: NetConnection,
    input_locked: bool,
}

create_game :: proc() -> Game {
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT, .WINDOW_HIGHDPI })
    rl.SetTraceLogLevel(.WARNING)
    rl.InitWindow(1000, 600, "Overtake 2")
    rlmu.init()

    return Game{
        player = create_player(),
        camera = [2]f32{0, 0},
        background = create_background(),
        net_con = create_net_con(),
        input_locked = false,
    }
}

delete_game :: proc(game: ^Game) {
    delete_net_con(&game.net_con)
    rlmu.destroy()
    rl.CloseWindow()
}

run_game :: proc(game: ^Game) {
    for !rl.WindowShouldClose() {
        defer free_all(context.temp_allocator)

        update_game(game)

        rl.BeginDrawing()
        defer rl.EndDrawing()

        rl.ClearBackground({160, 200, 255, 255})
        draw_game(game)
        draw_mu(game)
    }
}

game_to_screen :: proc(camera: [2]f32, position: [2]f32) -> [2]f32 {
    scren_size := [2]f32{f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())}
    return position - camera + scren_size / 2
}

update_game :: proc(game: ^Game) {
    if !game.input_locked do update_player(&game.player)
    game.camera = game.player.position
    update_net_con(game)
}

draw_game :: proc(game: ^Game) {
    draw_background(game)
    draw_net_players(&game.net_con, game.camera)
    draw_player(&game.player, game.camera)
}

draw_mu :: proc(game: ^Game) {
    ctx := rlmu.begin()
    defer rlmu.end()

    if mu.begin_window(ctx, "overtake2", { 100, 100, 300, 150 }, { .NO_CLOSE }) {
        defer mu.end_window(ctx)
        
        mu.layout_row(ctx, { -1 })
        mu.label(ctx, "Hello world")
        
        mu.layout_row(ctx, { 100, -1 })

        @(static, rodata) default_buf := "127.0.0.1:9868"
        @(static) buf_init := false
        @(static) buf: [256]u8 
        @(static) text_len: int

        if !buf_init {
            buf_init = true
            copy(buf[:], default_buf)
            text_len = len(default_buf)
        }

        mu.label(ctx, "Server address")
        mu.textbox(ctx, buf[:], &text_len)

        mu.layout_row(ctx, { -1 })
        if .SUBMIT in mu.button(ctx, "Connect") {
            connect_to_server(game, string(buf[:text_len]))
        }
        mu.label(ctx, fmt.tprintf("ctx.focus_id %v", ctx.focus_id))
    }

    game.input_locked = ctx.focus_id != 0
}

connect_to_server :: proc(game: ^Game, addr: string) {
    endpoint, ok := net.parse_endpoint(addr)
    if !ok {
        fmt.printfln("%v is an invalid address", addr)
        return
    }

    connect_net_con(&game.net_con, endpoint)
}