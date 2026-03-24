package game

import rl "vendor:raylib"
import mu "vendor:microui"
import "../rlmu"

Game :: struct {
    player: Player,
    camera: [2]f32,
    background: GameBackground,
    net_con: NetConnection,
}

create_game :: proc() -> Game {
    rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT, .WINDOW_HIGHDPI })
    rl.SetTraceLogLevel(.WARNING)
    rl.InitWindow(1600, 900, "Overtake 2")
    rlmu.init()

    return Game{
        player = create_player(),
        camera = [2]f32{0, 0},
        background = create_background(),
        net_con = create_net_con(),
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
    update_player(&game.player)
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

    if mu.begin_window(ctx, "overtake2", { 100, 100, 100, 100 }) {
        defer mu.end_window(ctx)

        mu.label(ctx, "Hello world")
    }
}