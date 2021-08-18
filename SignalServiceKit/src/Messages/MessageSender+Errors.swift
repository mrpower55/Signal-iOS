//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

import Foundation
import PromiseKit
import SignalMetadataKit
import SignalClient

@objc
public enum MessageSenderError: Int, Error, IsRetryableProvider {
    case prekeyRateLimit
    case missingDevice
    case blockedContactRecipient
    case threadMissing

    // MARK: - IsRetryableProvider

    public var isRetryableProvider: Bool {
        switch self {
        case .prekeyRateLimit:
            // TODO: Retry with backoff.
            // TODO: Can we honor a retry delay hint from the response?
            return true
        case .missingDevice:
            return true
        case .blockedContactRecipient:
            return false
        case .threadMissing:
            return false
        }
    }
}

// MARK: -

@objc
public extension MessageSender {

    class func isPrekeyRateLimitError(_ error: Error) -> Bool {
        switch error {
        case MessageSenderError.prekeyRateLimit:
            return true
        default:
            return false
        }
    }

    class func isMissingDeviceError(_ error: Error) -> Bool {
        switch error {
        case MessageSenderError.missingDevice:
            return true
        default:
            return false
        }
    }
}

// MARK: -

extension NSError {
    @objc
    public var shouldBeIgnoredForGroups: Bool { shouldBeIgnoredForGroupsImpl }

    fileprivate var shouldBeIgnoredForGroupsImpl: Bool {
        let error: Error = self as Error
        if error is MessageSenderNoSuchSignalRecipientError {
            return true
        }

        // Default to NOT fatal.
        return false
    }
}

// MARK: -

extension Error {
    public var shouldBeIgnoredForGroups: Bool { (self as NSError).shouldBeIgnoredForGroupsImpl }
}

// MARK: -

extension NSError {
    @objc
    public var isFatalError: Bool { isFatalErrorImpl }

    fileprivate var isFatalErrorImpl: Bool {
        let error: Error = self as Error
        switch error {
        case is MessageSenderNoSessionForTransientMessageError:
            return true
        case is UntrustedIdentityError:
            return true
        case is SignalServiceRateLimitedError:
            // Avoid exacerbating the rate limiting.
            return true
        case is MessageDeletedBeforeSentError:
            return true
        default:
            // Default to NOT fatal.
            return false
        }
    }
}

// MARK: -

extension Error {
    public var isFatalError: Bool { (self as NSError).isFatalErrorImpl }
}

// MARK: -

@objc
public class MessageSenderNoSuchSignalRecipientError: NSObject, CustomNSError, IsRetryableProvider {

    // MARK: - CustomNSError

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.noSuchSignalRecipient.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [ NSLocalizedDescriptionKey: localizedDescription ]
    }

    var localizedDescription: String {
        NSLocalizedString("ERROR_DESCRIPTION_UNREGISTERED_RECIPIENT",
                          comment: "Error message when attempting to send message")
    }

    @objc
    public class func isNoSuchSignalRecipientError(_ error: Error?) -> Bool {
        error is MessageSenderNoSuchSignalRecipientError
    }

    // MARK: - IsRetryableProvider

    // No need to retry if the recipient is not registered.
    @objc
    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class MessageSenderErrorNoValidRecipients: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        MessageSenderErrorNoValidRecipients() as Error as NSError
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.messageSendNoValidRecipients.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String {
        NSLocalizedString("ERROR_DESCRIPTION_NO_VALID_RECIPIENTS",
                          comment: "Error indicating that an outgoing message had no valid recipients.")
    }

    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class MessageSenderNoSessionForTransientMessageError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        MessageSenderNoSessionForTransientMessageError() as Error as NSError
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.noSessionForTransientMessage.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class UntrustedIdentityError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public let address: SignalServiceAddress

    init(address: SignalServiceAddress) {
        self.address = address
    }

    @objc
    public static func asNSError(withAddress address: SignalServiceAddress) -> NSError {
        UntrustedIdentityError(address: address) as Error as NSError
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.untrustedIdentity.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String {
        let format = NSLocalizedString("FAILED_SENDING_BECAUSE_UNTRUSTED_IDENTITY_KEY",
                                       comment: "action sheet header when re-sending message which failed because of untrusted identity keys")
        return String(format: format, contactsManager.displayName(for: address))
    }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    // Key will continue to be unaccepted, so no need to retry. It'll only cause us to hit the Pre-Key request
    // rate limit.
    public var isRetryableProvider: Bool { false }

    @objc
    public class func isUntrustedIdentityError(_ error: Error?) -> Bool {
        error is UntrustedIdentityError
    }
}

// MARK: -

@objc
public class SignalServiceRateLimitedError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        SignalServiceRateLimitedError() as Error as NSError
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.signalServiceRateLimited.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String {
        NSLocalizedString("FAILED_SENDING_BECAUSE_RATE_LIMIT",
                          comment: "action sheet header when re-sending message which failed because of too many attempts")
    }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    // We're already rate-limited. No need to exacerbate the problem.
    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class SpamChallengeRequiredError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        SpamChallengeRequiredError() as Error as NSError
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.serverRejectedSuspectedSpam.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String {
        NSLocalizedString("ERROR_DESCRIPTION_SUSPECTED_SPAM",
                          comment: "Description for errors returned from the server due to suspected spam.")
    }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    public var isRetryableProvider: Bool { false }

    @objc
    public class func isSpamChallengeRequiredError(_ error: Error) -> Bool {
        error is SpamChallengeRequiredError
    }
}

// MARK: -

@objc
public class SpamChallengeResolvedError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        SpamChallengeResolvedError() as Error as NSError
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.serverRejectedSuspectedSpam.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String {
        NSLocalizedString("ERROR_DESCRIPTION_SUSPECTED_SPAM",
                          comment: "Description for errors returned from the server due to suspected spam.")
    }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    public var isRetryableProvider: Bool { true }

    @objc
    public class func isSpamChallengeResolvedError(_ error: Error) -> Bool {
        error is SpamChallengeResolvedError
    }
}

// MARK: -

@objc
public class OWSRetryableMessageSenderError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        OWSRetryableMessageSenderError() as Error as NSError
    }

    // MARK: - IsRetryableProvider

    public var isRetryableProvider: Bool { true }
}

// MARK: -

// NOTE: We typically prefer to use a more specific error.
@objc
public class OWSUnretryableMessageSenderError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        OWSUnretryableMessageSenderError() as Error as NSError
    }

    // MARK: - IsRetryableProvider

    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class AppExpiredError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        AppExpiredError() as Error as NSError
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.appExpired.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String {
        NSLocalizedString("ERROR_SENDING_EXPIRED",
                          comment: "Error indicating a send failure due to an expired application.")
    }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class AppDeregisteredError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        AppDeregisteredError() as Error as NSError
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.appDeregistered.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String {
        TSAccountManager.shared.isPrimaryDevice
            ? NSLocalizedString("ERROR_SENDING_DEREGISTERED",
                                comment: "Error indicating a send failure due to a deregistered application.")
            : NSLocalizedString("ERROR_SENDING_DELINKED",
                                comment: "Error indicating a send failure due to a delinked application.")
    }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class MessageDeletedBeforeSentError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public static var asNSError: NSError {
        MessageDeletedBeforeSentError() as Error as NSError
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.messageDeletedBeforeSent.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class SenderKeyEphemeralError: NSObject, CustomNSError, IsRetryableProvider {
    private let customLocalizedDescription: String

    init(customLocalizedDescription: String) {
        self.customLocalizedDescription = customLocalizedDescription
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.senderKeyEphemeralFailure.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String { customLocalizedDescription }

    public var isRetryableProvider: Bool { true }
}

// MARK: -

@objc
public class SenderKeyUnavailableError: NSObject, CustomNSError, IsRetryableProvider {
    private let customLocalizedDescription: String

    init(customLocalizedDescription: String) {
        self.customLocalizedDescription = customLocalizedDescription
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.senderKeyUnavailable.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String { customLocalizedDescription }

    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class MessageSendUnauthorizedError: NSObject, CustomNSError, IsRetryableProvider {
    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.messageSendUnauthorized.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorUserInfo: [String: Any] {
        [NSLocalizedDescriptionKey: self.localizedDescription]
    }

    public var localizedDescription: String {
        NSLocalizedString("ERROR_DESCRIPTION_SENDING_UNAUTHORIZED",
                          comment: "Error message when attempting to send message")
    }

    // No need to retry if we've been de-authed.
    public var isRetryableProvider: Bool { false }
}

// MARK: -

@objc
public class MessageSendEncryptionError: NSObject, CustomNSError, IsRetryableProvider {
    @objc
    public let recipientAddress: SignalServiceAddress
    @objc
    public let deviceId: Int32

    required init(recipientAddress: SignalServiceAddress, deviceId: Int32) {
        self.recipientAddress = recipientAddress
        self.deviceId = deviceId
    }

    /// NSError bridging: the domain of the error.
    /// :nodoc:
    @objc
    public static let errorDomain = OWSSignalServiceKitErrorDomain

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    @objc
    public static var errorCode: Int { OWSErrorCode.messageSendEncryptionFailure.rawValue }

    /// NSError bridging: the error code within the given domain.
    /// :nodoc:
    public var errorCode: Int { Self.errorCode }

    public var isRetryableProvider: Bool { true }
}