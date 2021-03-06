//
//  KVDatabaseStringQueue.h
//  kvdb
//
//  Created by Dev Sanghani on 04/08/16.
//  Copyright © 2016 etpan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KVDatabaseStringQueue : NSObject

- (instancetype)initDatabaseQueueWithPath:(NSString *)path;

- (NSString *)objectForKey:(NSString *)aKey;
- (void)setObject:(NSString *)obj forKey:(NSString *)aKey;
- (void)removeObjectForKey:(NSString *)aKey;

- (void)purgeCache;

- (void)close;

@end
