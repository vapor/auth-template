import Authentication
import Crypto
import FluentSQLite
import Vapor

/// An ephermal authentication token that identifies a registered user.
final class UserToken: SQLiteModel {
    /// Creates a new `UserToken` for a given user.
    static func create(userID: User.ID) throws -> UserToken {
        // generate a random 128-bit, base64-encoded string.
        let string = try CryptoRandom().generateData(count: 16).base64EncodedString()
        // init a new `UserToken` from that string.
        return .init(string: string, userID: userID)
    }
    
    /// See `Model`.
    static var deletedAtKey: TimestampKey? { return \.expiresAt }
    
    /// UserToken's unique identifier.
    var id: Int?
    
    /// Unique token string.
    var string: String
    
    /// Reference to user that owns this token.
    var userID: User.ID
    
    /// Expiration date. Token will no longer be valid after this point.
    var expiresAt: Date?
    
    /// Creates a new `UserToken`.
    init(id: Int? = nil, string: String, userID: User.ID) {
        self.id = id
        self.string = string
        // set token to expire after 5 hours
        self.expiresAt = Date.init(timeInterval: 60 * 60 * 5, since: .init())
        self.userID = userID
    }
}

extension UserToken {
    /// Fluent relation to the user that owns this token.
    var user: Parent<UserToken, User> {
        return parent(\.userID)
    }
}

/// Allows this model to be used as a TokenAuthenticatable's token.
extension UserToken: Token {
    /// See `Token`.
    typealias UserType = User
    
    /// See `Token`.
    static var tokenKey: WritableKeyPath<UserToken, String> {
        return \.string
    }
    
    /// See `Token`.
    static var userIDKey: WritableKeyPath<UserToken, User.ID> {
        return \.userID
    }
}

/// Allows `UserToken` to be used as a Fluent migration.
extension UserToken: Migration {
    /// See `Migration`.
    static func prepare(on conn: SQLiteConnection) -> Future<Void> {
        return SQLiteDatabase.create(UserToken.self, on: conn) { builder in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.string)
            builder.field(for: \.userID)
            builder.field(for: \.expiresAt)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}

/// Allows `UserToken` to be encoded to and decoded from HTTP messages.
extension UserToken: Content { }

/// Allows `UserToken` to be used as a dynamic parameter in route definitions.
extension UserToken: Parameter { }
