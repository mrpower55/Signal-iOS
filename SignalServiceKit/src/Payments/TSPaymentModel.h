//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import "BaseModel.h"
#import "TSPaymentModels.h"

NS_ASSUME_NONNULL_BEGIN

@class MobileCoinPayment;
@class SDSAnyWriteTransaction;
@class SignalServiceAddress;

// We store payment records seperately from interactions.
//
// * Payment records might correspond to transfers to/from exchanges,
//   without an associated interaction.
// * Interactions might be deleted, but we need to maintain records of
//   all payments.
@interface TSPaymentModel : BaseModel

// Incoming, outgoing, etc.
//
// This is inferred from paymentState.
@property (nonatomic, readonly) TSPaymentType paymentType;

@property (nonatomic, readonly) TSPaymentState paymentState;

// This property only applies if paymentState is .incomingFailure
// or .outgoingFailure.
@property (nonatomic, readonly) TSPaymentFailure paymentFailure;

// Might not be set for unverified incoming payments.
@property (nonatomic, readonly, nullable) TSPaymentAmount *paymentAmount;

@property (nonatomic, readonly) uint64_t createdTimestamp;
@property (nonatomic, readonly) NSDate *createdDate;

// This uses ledgerBlockDate if available and createdDate otherwise.
@property (nonatomic, readonly) NSDate *sortDate;

// Optional. The address of the sender/recipient, if any.
//
// We should not treat this value as valid for unverified incoming payments.
@property (nonatomic, readonly, nullable) NSString *addressUuidString;
@property (nonatomic, readonly, nullable) NSUUID *addressUuid;
@property (nonatomic, readonly, nullable) SignalServiceAddress *address;

// Optional. Used to construct outgoing notifications.
//           This should only be set for outgoing payments from the device that
//           submitted the payment.
//           We should clear this as soon as sending notification succeeds.
@property (nonatomic, readonly, nullable) NSString *requestUuidString;

@property (nonatomic, readonly, nullable) NSString *memoMessage;

@property (nonatomic, readonly) BOOL isUnread;

#pragma mark - MobileCoin

// This only applies to mobilecoin.
@property (nonatomic, readonly, nullable) MobileCoinPayment *mobileCoin;

// The hexadecimal string for the incoming MC transaction.
// Used by PaymentFinder.
//
// This only applies to mobilecoin.
@property (nonatomic, readonly, nullable) NSData *mcIncomingTransaction;

// This only applies to mobilecoin.
// Used by PaymentFinder.
// This value is zero if not set.
@property (nonatomic, readonly) uint64_t mcLedgerBlockIndex;

#pragma mark -

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithUniqueId:(NSString *)uniqueId NS_UNAVAILABLE;
- (instancetype)initWithGrdbId:(int64_t)grdbId uniqueId:(NSString *)uniqueId NS_UNAVAILABLE;

- (instancetype)initWithPaymentType:(TSPaymentType)paymentType
                       paymentState:(TSPaymentState)paymentState
                      paymentAmount:(nullable TSPaymentAmount *)paymentAmount
                        createdDate:(NSDate *)createdDate
                  addressUuidString:(nullable NSString *)addressUuidString
                        memoMessage:(nullable NSString *)memoMessage
                  requestUuidString:(nullable NSString *)requestUuidString
                           isUnread:(BOOL)isUnread
                         mobileCoin:(MobileCoinPayment *)mobileCoin NS_DESIGNATED_INITIALIZER;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run
// `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
               addressUuidString:(nullable NSString *)addressUuidString
                createdTimestamp:(uint64_t)createdTimestamp
                        isUnread:(BOOL)isUnread
           mcIncomingTransaction:(nullable NSData *)mcIncomingTransaction
              mcLedgerBlockIndex:(uint64_t)mcLedgerBlockIndex
                     memoMessage:(nullable NSString *)memoMessage
                      mobileCoin:(nullable MobileCoinPayment *)mobileCoin
                   paymentAmount:(nullable TSPaymentAmount *)paymentAmount
                  paymentFailure:(TSPaymentFailure)paymentFailure
                    paymentState:(TSPaymentState)paymentState
                     paymentType:(TSPaymentType)paymentType
               requestUuidString:(nullable NSString *)requestUuidString
NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(grdbId:uniqueId:addressUuidString:createdTimestamp:isUnread:mcIncomingTransaction:mcLedgerBlockIndex:memoMessage:mobileCoin:paymentAmount:paymentFailure:paymentState:paymentType:requestUuidString:));

// clang-format on

// --- CODE GENERATION MARKER

- (void)updateWithPaymentState:(TSPaymentState)paymentState
                   transaction:(SDSAnyWriteTransaction *)transaction NS_SWIFT_NAME(update(paymentState:transaction:));

- (void)updateWithMCLedgerBlockIndex:(uint64_t)ledgerBlockIndex
                         transaction:(SDSAnyWriteTransaction *)transaction
    NS_SWIFT_NAME(update(mcLedgerBlockIndex:transaction:));

- (void)updateWithMCLedgerBlockTimestamp:(uint64_t)ledgerBlockTimestamp
                             transaction:(SDSAnyWriteTransaction *)transaction
    NS_SWIFT_NAME(update(mcLedgerBlockTimestamp:transaction:));

- (void)updateWithPaymentFailure:(TSPaymentFailure)paymentFailure
                    paymentState:(TSPaymentState)paymentState
                     transaction:(SDSAnyWriteTransaction *)transaction
    NS_SWIFT_NAME(update(withPaymentFailure:paymentState:transaction:));

- (void)updateWithPaymentAmount:(TSPaymentAmount *)paymentAmount
                    transaction:(SDSAnyWriteTransaction *)transaction
    NS_SWIFT_NAME(update(withPaymentAmount:transaction:));

- (void)updateWithIsUnread:(BOOL)isUnread transaction:(SDSAnyWriteTransaction *)transaction;

@end

#pragma mark -

@interface MobileCoinPayment : MTLModel

// This property is only used for transfer in/out flows.
@property (nonatomic, readonly, nullable) NSData *recipientPublicAddressData;

// Optional. Only set for outgoing mobileCoin payments.
@property (nonatomic, readonly, nullable) NSData *transactionData;

// Optional. Set for incoming and outgoing mobileCoin payments.
@property (nonatomic, readonly, nullable) NSData *receiptData;

// Optional. Set for incoming and outgoing mobileCoin payments.
@property (nonatomic, readonly, nullable) NSData *incomingTransactionPublicKey;

// The image keys for the TXOs spent in this outgoing MC transaction.
@property (nonatomic, readonly, nullable) NSArray<NSData *> *spentKeyImages;

// The TXOs spent in this outgoing MC transaction.
@property (nonatomic, readonly, nullable) NSArray<NSData *> *outputPublicKeys;

// This value is zero if not set.
@property (nonatomic, readonly) uint64_t ledgerBlockTimestamp;
@property (nonatomic, readonly, nullable) NSDate *ledgerBlockDate;

// This value is zero if not set.
//
// This only applies to mobilecoin.
@property (nonatomic, readonly) uint64_t ledgerBlockIndex;

// Optional. Only set for outgoing mobileCoin payments.
@property (nonatomic, readonly, nullable) TSPaymentAmount *feeAmount;

- (instancetype)initWithRecipientPublicAddressData:(nullable NSData *)recipientPublicAddressData
                                   transactionData:(nullable NSData *)transactionData
                                       receiptData:(nullable NSData *)receiptData
                      incomingTransactionPublicKey:(nullable NSData *)incomingTransactionPublicKey
                                    spentKeyImages:(nullable NSArray<NSData *> *)spentKeyImages
                                  outputPublicKeys:(nullable NSArray<NSData *> *)outputPublicKeys
                              ledgerBlockTimestamp:(uint64_t)ledgerBlockTimestamp
                                  ledgerBlockIndex:(uint64_t)ledgerBlockIndex
                                         feeAmount:(nullable TSPaymentAmount *)feeAmount;

@end

NS_ASSUME_NONNULL_END
