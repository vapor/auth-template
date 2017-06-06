import Vapor
import AuthProvider

extension Droplet {
    public func setup() throws {
        try setupPasswordVerifier()
        try setupRoutes()
        // Do any additional droplet setup
    }

    /// Ensure the configured hash type conforms to
    /// password verifier, and set it on the User type.
    private func setupPasswordVerifier() throws {
        /// the BCrypt hasher (as specified in droplet.json)
        /// already conforms to PasswordVerifier.
        guard let verifier = hash as? PasswordVerifier else {
            throw Abort(.internalServerError, reason: "\(type(of: hash)) must conform to PasswordVerifier.")
        }

        User.passwordVerifier = verifier
    }
}
