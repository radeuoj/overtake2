package server

import "core:net"
import "core:sync"

ClientsStore :: struct {
    store: map[net.TCP_Socket]i32,
    mutex: sync.RW_Mutex,
}

create_clients :: proc() -> ClientsStore {
    return ClientsStore {
        store = make(map[net.TCP_Socket]i32),
    }
}

delete_clients :: proc(clients: ^ClientsStore) {
    sync.lock(&clients.mutex)
    defer sync.unlock(&clients.mutex)
    delete(clients.store)
}

clients_get :: proc(clients: ^ClientsStore, key: net.TCP_Socket) -> (val: i32, ok: bool) {
    sync.lock(&clients.mutex)
    defer sync.unlock(&clients.mutex)
    return clients.store[key]
}

clients_set :: proc(clients: ^ClientsStore, key: net.TCP_Socket, val: i32) {
    sync.lock(&clients.mutex)
    defer sync.unlock(&clients.mutex)
    clients.store[key] = val
}

clients_erase :: proc(clients: ^ClientsStore, key: net.TCP_Socket) -> (deleted_key: net.TCP_Socket, deleted_val: i32) {
    sync.lock(&clients.mutex)
    defer sync.unlock(&clients.mutex)
    return delete_key(&clients.store, key)
}

clients_lock_and_get_store :: proc(clients: ^ClientsStore) -> ^map[net.TCP_Socket]i32 {
    sync.lock(&clients.mutex)
    return &clients.store
}

clients_unlock :: proc(clients: ^ClientsStore) {
    sync.unlock(&clients.mutex)
}