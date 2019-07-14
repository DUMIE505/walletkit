//
//  BRCrypto.swift
//  BRCrypto
//
//  Created by Ed Gamble on 3/27/19.
//  Copyright © 2018 Breadwallet AG. All rights reserved.
//
//  See the LICENSE file at the project root for license information.
//  See the CONTRIBUTORS file at the project root for a list of contributors.
//
import Foundation // Data
import BRCryptoC

///
///
///
public final class Account {
    let core: BRCryptoAccount

    // A 'globally unique' ID String for account.  For BlockchainDB this will be the 'walletId'
    let uids: String

    public var timestamp: Date {
        return Date.init(timeIntervalSince1970: TimeInterval (cryptoAccountGetTimestamp (core)))
    }

    ///
    /// Serialize an account.  The serialization is *always* in the current, default format
    ///
    public var serialize: Data {
        var bytesCount: Int = 0
        let bytes = cryptoAccountSerialize (core, &bytesCount)
        return Data (bytes: bytes!, count: bytesCount)
    }

    ///
    /// Recover an account from a BIP-39 'paper key'
    ///
    /// - Parameter paperKey: the 12 word paper key
    /// - Parameter timestamp:
    ///
    /// - Returns: the paperKey's corresponding account, or NIL if the paperKey is invalid.
    ///
    public static func createFrom (phrase: String, timestamp: Date, uids: String) -> Account? {
        let timestampAsInt = UInt64 (timestamp.timeIntervalSince1970)
        return cryptoAccountCreate (phrase, timestampAsInt)
            .map { Account (core: $0, uids: uids) }
    }

    ///
    /// Create an account based on an account serialization
    ///
    /// - Parameter serialization: The result of a prior call to account.serialize.
    ///
    /// - Returns: The serialization's corresponding account or NIL if the serialization is invalid.
    ///    If the serialization is invalid then the account *must be recreated* from the `phrase`
    ///    (aka 'Paper Key').  A serialization will be invald when the serialization format changes
    ///    which will *always occur* when a new blockchain is added.  For example, when XRP is added
    ///    the XRP public key must be serialized; the old serialization w/o the XRP public key will
    ///    be invalid and the `phrase` is *required* in order to produce the XRP public key.
    ///
    public static func createFrom (serialization: Data, uids: String) -> Account? {
        var bytes = [UInt8](serialization)
        return cryptoAccountCreateFromSerialization (&bytes, bytes.count)
            .map { Account (core: $0, uids: uids) }
    }

    ///
    /// Generate a BIP-39 'paper Key'.  Use Account.createFrom(paperKey:) to get the account.  The
    /// wordList is the locale-specifc BIP-39-defined array of BIP39_WORDLIST_COUNT words.  This
    /// function has a precondition on the size of the wordList.
    ///
    /// - Parameter wordList: A local-specific BIP-39-defined array of BIP39_WORDLIST_COUNT words.
    ///
    /// - Returns: A 12 word 'paper key'
    ///
    public static func generatePhrase (wordList: [String]) -> (String,Date)? {
        precondition (CRYPTO_TRUE == cryptoAccountValidateWordsList (Int32(wordList.count)))

        var words = wordList.map { UnsafePointer<Int8> (strdup($0)) }
        defer { words.forEach { free(UnsafeMutablePointer (mutating: $0)) } }
        return (asUTF8String (cryptoAccountGeneratePaperKey (&words)), Date())
    }

    internal init (core: BRCryptoAccount, uids: String) {
        self.core = core
        self.uids = uids
    }

    deinit {
        cryptoAccountGive (core)
    }

    // Test Only
    internal var addressAsETH: String {
        return asUTF8String (cryptoAccountAddressAsETH(core)!)
    }
}
