import Vapor
import FluentSQLite

final class TodoController {
    func index(_ req: Request) throws -> Future<[Todo]> {
        let user = try req.requireAuthenticated(User.self)
        return try Todo.query(on: req)
            .filter(\.userID == user.requireID()).all()
    }

    func create(_ req: Request) throws -> Future<Todo> {
        let user = try req.requireAuthenticated(User.self)
        return try req.content.decode(CreateTodoRequest.self).flatMap { todo in
            return try Todo(title: todo.title, userID: user.requireID())
                .save(on: req)
        }
    }

    func delete(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        return try req.parameters.next(Todo.self).flatMap { todo -> Future<Void> in
            guard try todo.userID == user.requireID() else {
                throw Abort(.notFound, reason: "No Todo with this ID exists.")
            }
            return todo.delete(on: req)
        }.transform(to: .ok)
    }
}

// MARK: Content

struct CreateTodoRequest: Content {
    var title: String
}
