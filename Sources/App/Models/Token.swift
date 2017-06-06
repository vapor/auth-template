import Vapor
import FluentProvider
import Crypto

final class Token: Model {
    let storage = Storage()

    /// The actual token
    let token: String

    /// The identifier of the user to which the token belongs
    let userId: Identifier

    /// Creates a new Token
    init(string: String, user: User) throws {
        token = string
        userId = try user.assertExists()
    }

    // MARK: Row

    init(row: Row) throws {
        token = try row.get("token")
        userId = try row.get(User.foreignIdKey)
    }

    func makeRow() throws -> Row {
        var row = Row()
        try row.set("token", token)
        try row.set(User.foreignIdKey, userId)
        return row
    }
}

// MARK: Convenience

extension Token {
    /// Generates a new token for the supplied User.
    static func generate(for user: User) throws -> Token {
        // generate 128 random bits using OpenSSL
        let random = try Crypto.Random.bytes(count: 16)

        // create and return the new token
        return try Token(string: random.base64Encoded.makeString(), user: user)
    }
}

// MARK: Relations

extension Token {
    /// Fluent relation for accessing the user
    var user: Parent<Token, User> {
        return parent(id: userId)
    }
}

// MARK: Preparation

extension Token: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Tokens
    static func prepare(_ database: Database) throws {
        try database.create(Token.self) { builder in
            builder.id()
            builder.string("token")
            builder.foreignId(for: User.self)
        }
    }

    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(Token.self)
    }
}

// MARK: JSON

/// Allows the token to convert to JSON.
extension Token: JSONRepresentable {
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("token", token)
        return json
    }
}

// MARK: HTTP

/// Allows the Token to be returned directly in route closures.
extension Token: ResponseRepresentable { }
