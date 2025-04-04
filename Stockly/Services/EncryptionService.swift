import Foundation
import CryptoKit

enum EncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidPassword
    case invalidData
    case keyDerivationFailed
}

/// Service for encrypting and decrypting data
class EncryptionService {
    // PBKDF2 parameters
    private let saltLength = 16
    private let ivLength = 16
    private let pbkdf2Iterations = 100000
    private let pbkdf2KeyLength = 32 // 256 bits
    
    /// Encrypt data with a password
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - password: Password for encryption
    /// - Returns: Encrypted data with salt and IV prepended
    func encrypt(data: Data, withPassword password: String) throws -> Data {
        // Generate random salt and IV
        let salt = generateRandomBytes(length: saltLength)
        let iv = generateRandomBytes(length: ivLength)
        
        // Derive key from password and salt
        guard let key = deriveKey(fromPassword: password, salt: salt) else {
            throw EncryptionError.keyDerivationFailed
        }
        
        // Create a symmetric key from the derived key
        let symmetricKey = SymmetricKey(data: key)
        
        do {
            // Encrypt the data
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey, nonce: AES.GCM.Nonce(data: iv))
            
            // Combine salt, IV, and encrypted data
            var encryptedData = Data()
            encryptedData.append(salt)
            encryptedData.append(iv)
            
            if let combined = sealedBox.combined {
                encryptedData.append(combined)
                return encryptedData
            } else {
                throw EncryptionError.encryptionFailed
            }
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }
    
    /// Decrypt data with a password
    /// - Parameters:
    ///   - encryptedData: Encrypted data with salt and IV prepended
    ///   - password: Password for decryption
    /// - Returns: Decrypted data
    func decrypt(encryptedData: Data, withPassword password: String) throws -> Data {
        // Ensure the data is long enough to contain salt and IV
        guard encryptedData.count > saltLength + ivLength else {
            throw EncryptionError.invalidData
        }
        
        // Extract salt, IV, and encrypted data
        let salt = encryptedData.subdata(in: 0..<saltLength)
        let iv = encryptedData.subdata(in: saltLength..<(saltLength + ivLength))
        let sealedBoxData = encryptedData.subdata(in: (saltLength + ivLength)..<encryptedData.count)
        
        // Derive key from password and salt
        guard let key = deriveKey(fromPassword: password, salt: salt) else {
            throw EncryptionError.keyDerivationFailed
        }
        
        // Create a symmetric key from the derived key
        let symmetricKey = SymmetricKey(data: key)
        
        do {
            // Create a sealed box from the encrypted data
            let sealedBox = try AES.GCM.SealedBox(combined: sealedBoxData)
            
            // Decrypt the data
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return decryptedData
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }
    
    /// Generate random bytes of specified length
    /// - Parameter length: Number of bytes to generate
    /// - Returns: Data containing random bytes
    private func generateRandomBytes(length: Int) -> Data {
        var bytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return Data(bytes)
    }
    
    /// Derive a key from a password and salt using PBKDF2
    /// - Parameters:
    ///   - password: Password to derive key from
    ///   - salt: Salt for key derivation
    /// - Returns: Derived key as Data
    private func deriveKey(fromPassword password: String, salt: Data) -> Data? {
        guard let passwordData = password.data(using: .utf8) else {
            return nil
        }
        
        var derivedKeyData = Data(repeating: 0, count: pbkdf2KeyLength)
        let derivationStatus = derivedKeyData.withUnsafeMutableBytes { derivedKeyBytes in
            salt.withUnsafeBytes { saltBytes in
                passwordData.withUnsafeBytes { passwordBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress, passwordData.count,
                        saltBytes.baseAddress, salt.count,
                        CCPBKDFAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(pbkdf2Iterations),
                        derivedKeyBytes.baseAddress, pbkdf2KeyLength
                    )
                }
            }
        }
        
        return derivationStatus == kCCSuccess ? derivedKeyData : nil
    }
}
