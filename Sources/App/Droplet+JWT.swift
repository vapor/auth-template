import Foundation
import Vapor
import JWT

extension Droplet {
    func createJwtToken(_ userId: String)  throws -> String {
        guard  let sig = self.signer else {
            throw Abort.unauthorized
        }
        
        let timeToLive = 5 * 60.0 // 5 minutes
        let claims:[Claim] = [
            SubjectClaim(string: userId),
            ExpirationTimeClaim(date: Date().addingTimeInterval(timeToLive)),
            // You can add more claims
            // IssuerClaim(string: "JWT"),
            // AudienceClaim(string: "some audience"),
            // NotBeforeClaim(date:  Date().addingTimeInterval(60)), // valid in 1 minute from now
            // IssuedAtClaim(), // now
            // JWTIDClaim(string: UUID().uuidString)
        ]
        
        let payload = JSON(claims)
        let jwt = try JWT(payload: payload, signer: sig)
        
        return try jwt.createToken()
    }
}
