package game

main :: proc() {
    game := create_game()
    defer delete_game(&game)
    run_game(&game)
}