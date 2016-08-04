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
@property (nonatomic, readwrite, strong) KVDatabase *db;

@property (nonatomic, readwrite, strong) NSMutableDictionary *cache;

@end

@implementation KVDatabaseQueue

- (instancetype)initDatabaseQueueWithPath:(NSString *)path {
    if (self = [super init]) {
        _cache     = [[NSMutableDictionary alloc] init];
        _syncQueue = dispatch_queue_create("com.kvdb.sync", DISPATCH_QUEUE_SERIAL);
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
        obj = _cache[key];
        if (!obj) {
            obj = [[NSString alloc] initWithData:[_db dataForKey:key] encoding:NSUTF8StringEncoding];
            _cache[key] = obj;
        }
    });
    return obj;
}

- (void)setObject:(NSString *)obj forKey:(NSString *)aKey {
    dispatch_async(self.syncQueue, ^{
        AssertDB();
        [_db setData:[obj dataUsingEncoding:NSUTF8StringEncoding] forKey:aKey];
        _cache[aKey] = obj;
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
        [_db close];
        _db = nil;
    });
}

@end
