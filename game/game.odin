package game

import rl "vendor:raylib"

Game :: struct {
    player: Player,
    camera: [2]f32,
    background: GameBackground,
    net_con: NetConnection,
}

create_game :: proc() -> Game {
    rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
    rl.InitWindow(1600, 900, "Overtake 2")

    return Game{
        player = create_player(),
        camera = [2]f32{0, 0},
        background = create_background(),
        net_con = create_net_con(),
    }
}

delete_game :: proc(game: ^Game) {
    delete_net_con(&game.net_con)
}

run_game :: proc(game: ^Game) {
    for !rl.WindowShouldClose() {
        update_game(game)
        rl.BeginDrawing()
        rl.ClearBackground({160, 200, 255, 255})
        draw_game(game)
        rl.EndDrawing()
    }

    rl.CloseWindow()
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