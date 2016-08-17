//
//  KVDatabaseDataQueue.m
//  kvdb
//
//  Created by Dev Sanghani on 8/9/16.
//  Copyright © 2016 etpan. All rights reserved.
//

#import "KVDatabaseDataQueue.h"

#import "KVDatabase.h"

#ifdef DEBUG
#define AssertDB() NSAssert(self.db != nil, @"Database is nil")
#define AssertDecoder() NSAssert (_decoderBlock != nil, @"Decoder is nil")
#define AssertEncoder() NSAssert (_encoderBlock != nil, @"Encoder is nil")
#else
#define AssertDB()
#define AssertDecoder()
#define AssertEncoder()
#endif

@interface KVDatabaseDataQueue ()

@property (nonatomic, readwrite, strong) dispatch_queue_t syncQueue;

@property (nonatomic, readwrite, strong) NSCache *cache;
@property (nonatomic, readwrite, strong) KVDatabase *db;

@end

@implementation KVDatabaseDataQueue

- (instancetype)initDatabaseQueueWithPath:(NSString *)path {
    if (self = [super init]) {
        // TODO: Might be better to use a CONCURRENT queue with dispatch_barrier_asyncs
        _syncQueue = dispatch_queue_create("com.kvdb.sync", DISPATCH_QUEUE_SERIAL);

        _cache     = [[NSCache alloc] init];
        _cache.countLimit = 1000;

        _db = [[KVDatabase alloc] initWithPath:path];
        if (![_db open]) {
            NSLog(@"Failed to open database with path: %@", path);
        }
    }
    return self;
}

- (id(^)(NSData *))decoderBlock {
    AssertDecoder();
    return _decoderBlock;
}

- (NSData *(^)(id))encoderBlock {
    AssertEncoder();
    return _encoderBlock;
}

- (id)objectForKey:(NSString *)aKey {
    if (!aKey) { return nil; };
    __block id obj = nil;
    dispatch_sync(self.syncQueue, ^{
        AssertDB();
        obj = [_cache objectForKey:aKey];
        if (!obj) {
            NSData *data = [_db dataForKey:aKey];
            if (data) {
                obj = self.decoderBlock(data);
                [_cache setObject:obj forKey:aKey];
            }
        }
    });
    return obj;
}

- (void)setObject:(id)obj forKey:(NSString *)aKey {
    if (!aKey || !obj) { return; };
    dispatch_async(self.syncQueue, ^{
        AssertDB();
        [_db setData:self.encoderBlock(obj) forKey:aKey];
        [_cache setObject:obj forKey:aKey];
    });
}

- (void)removeObjectForKey:(NSString *)aKey {
    if (!aKey) { return; };
    // Using sync to flush the cache of the key
    dispatch_sync(self.syncQueue, ^{
        AssertDB();
        [_db removeDataForKey:aKey];
        [_cache removeObjectForKey:aKey];
    });
}

- (void)purgeCache {
    dispatch_async(self.syncQueue, ^{
        [_cache removeAllObjects];
    });
}

- (void)close {
    dispatch_sync(self.syncQueue, ^{
        [_cache removeAllObjects];
        _cache = nil;

        [_db close];
        _db = nil;
    });
    self.syncQueue = nil;
}

@end
