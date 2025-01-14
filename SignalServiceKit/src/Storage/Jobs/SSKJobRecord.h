//
//  Copyright (c) 2021 Open Whisper Systems. All rights reserved.
//

#import <SignalServiceKit/BaseModel.h>

NS_ASSUME_NONNULL_BEGIN

@class SDSAnyWriteTransaction;

extern NSErrorDomain const SSKJobRecordErrorDomain;

typedef NS_ERROR_ENUM(SSKJobRecordErrorDomain, JobRecordError) {
    JobRecordError_AssertionError = 100,
    JobRecordError_IllegalStateTransition,
};

typedef NS_CLOSED_ENUM(NSUInteger, SSKJobRecordStatus) {
    SSKJobRecordStatus_Unknown,
    SSKJobRecordStatus_Ready,
    SSKJobRecordStatus_Running,
    SSKJobRecordStatus_PermanentlyFailed,
    SSKJobRecordStatus_Obsolete
};

#pragma mark -

@interface SSKJobRecord : BaseModel

@property (nonatomic) NSUInteger failureCount;
@property (nonatomic) NSString *label;

- (instancetype)initWithLabel:(NSString *)label NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithUniqueId:(NSString *)uniqueId NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithGrdbId:(int64_t)grdbId uniqueId:(NSString *)uniqueId NS_UNAVAILABLE;

// --- CODE GENERATION MARKER

// This snippet is generated by /Scripts/sds_codegen/sds_generate.py. Do not manually edit it, instead run `sds_codegen.sh`.

// clang-format off

- (instancetype)initWithGrdbId:(int64_t)grdbId
                      uniqueId:(NSString *)uniqueId
      exclusiveProcessIdentifier:(nullable NSString *)exclusiveProcessIdentifier
                    failureCount:(NSUInteger)failureCount
                           label:(NSString *)label
                          sortId:(unsigned long long)sortId
                          status:(SSKJobRecordStatus)status
NS_DESIGNATED_INITIALIZER NS_SWIFT_NAME(init(grdbId:uniqueId:exclusiveProcessIdentifier:failureCount:label:sortId:status:));

// clang-format on

// --- CODE GENERATION MARKER

@property (readonly, nonatomic) SSKJobRecordStatus status;

// GRDB TODO: Replace sortId column with autoincremented id column
@property (nonatomic, readonly) UInt64 sortId;
@property (nonatomic, readonly, nullable) NSString *exclusiveProcessIdentifier;
@property (nonatomic, readonly, class) NSString *currentProcessIdentifier;

- (void)flagAsExclusiveForCurrentProcessIdentifier;

- (void)updateWithExclusiveForCurrentProcessIdentifierWithTransaction:(SDSAnyWriteTransaction *)transaction
    NS_SWIFT_NAME(flagAsOnlyValidForCurrentProcessIdentifier(transaction:));

- (BOOL)saveAsStartedWithTransaction:(SDSAnyWriteTransaction *)transaction
                               error:(NSError **)outError NS_SWIFT_NAME(saveAsStarted(transaction:));

- (void)saveAsPermanentlyFailedWithTransaction:(SDSAnyWriteTransaction *)transaction
    NS_SWIFT_NAME(saveAsPermanentlyFailed(transaction:));

- (void)saveAsObsoleteWithTransaction:(SDSAnyWriteTransaction *)transaction NS_SWIFT_NAME(saveAsObsolete(transaction:));

- (BOOL)saveRunningAsReadyWithTransaction:(SDSAnyWriteTransaction *)transaction
                                    error:(NSError **)outError NS_SWIFT_NAME(saveRunningAsReady(transaction:));

- (BOOL)addFailureWithWithTransaction:(SDSAnyWriteTransaction *)transaction
                                error:(NSError **)outError NS_SWIFT_NAME(addFailure(transaction:));

@end

NS_ASSUME_NONNULL_END
