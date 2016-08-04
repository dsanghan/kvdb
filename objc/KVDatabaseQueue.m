//
//  KVDatabaseQueue.m
//  kvdb
//
//  Created by Dev Sanghani on 04/08/16.
//  Copyright © 2016 etpan. All rights reserved.
//

#import "KVDatabaseQueue.h"

#import "KVDatabase.h"

#ifdef DEBUG
#define AssertDB() NSAssert(self.db != nil, @"Database is nil")
#else
#define AssertDB()
#endif

@interface KVDatabaseQueue ()

@property (nonatomic, readwrite, strong) dispatch_queue_t syncQueue;

@property (nonatomic, readwrite, strong) NSCache *cache;
@property (nonatomic, readwrite, strong) KVDatabase *db;

@end

@implementation KVDatabaseQueue

- (instancetype)initDatabaseQueueWithPath:(NSString *)path {
    if (self = [super init]) {
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

- (NSString *)objectForKey:(NSString *)key {
    __block NSString *obj = nil;
    dispatch_sync(self.syncQueue, ^{
        AssertDB();
        obj = [_cache objectForKey:key];
        if (!obj) {
            NSData *data = [_db dataForKey:key];
            if (data) {
                obj = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                [_cache setObject:obj forKey:key];
            }
        }
    });
    return obj;
}

- (void)setObject:(NSString *)obj forKey:(NSString *)aKey {
    dispatch_async(self.syncQueue, ^{
        AssertDB();
        [_db setData:[obj dataUsingEncoding:NSUTF8StringEncoding] forKey:aKey];
        [_cache setObject:obj forKey:aKey];
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
