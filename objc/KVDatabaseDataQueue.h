//
//  KVDatabaseDataQueue.h
//  kvdb
//
//  Created by Dev Sanghani on 8/9/16.
//  Copyright © 2016 etpan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KVDatabaseDataQueue : NSObject

@property (nonatomic, strong) NSData *(^encoderBlock)(id anObject);
@property (nonatomic, strong) id(^decoderBlock)(NSData *data);

@end
