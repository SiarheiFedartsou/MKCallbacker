//
//  MKCallbacker.h
//  Callbacker
//
//  Created by Sergey Fedortsov on 9.1.14.
//  Copyright (c) 2014 Sergey Fedortsov. All rights reserved.
//

#import <Foundation/Foundation.h>


#define MK_STRUCT_ARGUMENT(argument_type, argument_name) MK_STRUCT_ARGUMENT_WITH_ARGUMENTS(argument_type, argument_name, arguments)
#define MK_STRUCT_ARGUMENT_WITH_ARGUMENTS(argument_type, argument_name, arguments_dict) \
    argument_type argument_name; \
    [arguments_dict[@#argument_name] getValue:&argument_name];

typedef void (^MKMethodCallCallback)(SEL selector, NSDictionary* arguments, void* returnValue);

@interface MKCallbacker : NSObject
- (instancetype)initWithProtocol:(Protocol*)protocol;
- (instancetype)initWithProtocols:(Protocol*)protocol, ... NS_REQUIRES_NIL_TERMINATION;
- (void) setCallback:(MKMethodCallCallback)callback forSelector:(SEL)selector;
- (void) removeCallbackForSelector:(SEL)selector;
@end
