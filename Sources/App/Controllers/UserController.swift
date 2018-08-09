import Crypto
import Vapor
import FluentSQLite

final class UserController {
    func login(_ req: Request) throws -> Future<UserToken> {
        let user = try req.requireAuthenticated(User.self)
        let token = try UserToken.create(userID: user.requireID())
        return token.save(on: req)
    }
    
    func create(_ req: Request) throws -> Future<UserResponse> {
        return try req.content.decode(CreateUserRequest.self).flatMap { user -> Future<User> in
            guard user.password == user.verifyPassword else {
                throw Abort(.badRequest, reason: "Password and verification must match.")
            }
            
            return User.query(on: req).filter(\.email == user.email).count().map { count -> Void in
                guard count == 0 else {
                    throw Abort(.badRequest, reason: "A user with that email already exists.")
                }
            }.flatMap {
                let hash = try BCrypt.hash(user.password)
                return User(id: nil, name: user.name, email: user.email, passwordHash: hash)
                    .save(on: req)
            }
            
        }.map { user in
            return try UserResponse(id: user.requireID(), name: user.name, email: user.email)
        }
    }
}

// MARK: Content

struct CreateUserRequest: Content {
    var name: String
    var email: String
    var password: String
    var verifyPassword: String
}

struct UserResponse: Content {
    var id: Int
    var name: String
    var email: String
}
