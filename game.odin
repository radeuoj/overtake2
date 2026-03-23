package main

import "vendor:raylib"

Game :: struct {
    player: Player,
    camera: [2]f32,
    background: GameBackground,
}

create_game :: proc() -> Game {
    raylib.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
    raylib.InitWindow(1600, 900, "Overtake 2")

    return Game{
        player = create_player(),
        camera = [2]f32{0, 0},
        background = create_background(),
    }
}

run_game :: proc(game: ^Game) {
    for !raylib.WindowShouldClose() {
        update_game(game)
        raylib.BeginDrawing()
        raylib.ClearBackground({160, 200, 255, 255})
        draw_game(game)
        raylib.EndDrawing()
    }

    raylib.CloseWindow()
}

game_to_screen :: proc(game: ^Game, position: [2]f32) -> [2]f32 {
    scren_size := [2]f32{f32(raylib.GetScreenWidth()), f32(raylib.GetScreenHeight())}
    return position - game.camera + scren_size / 2
}

update_game :: proc(game: ^Game) {
    update_player(&game.player)

    game.camera = game.player.position
}

draw_game :: proc(game: ^Game) {
    draw_background(game)
    draw_player(game)
}