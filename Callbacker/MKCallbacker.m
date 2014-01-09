//
//  MKCallbacker.m
//  Callbacker
//
//  Created by Sergey Fedortsov on 9.1.14.
//  Copyright (c) 2014 Sergey Fedortsov. All rights reserved.
//

#import "MKCallbacker.h"

#import <objc/runtime.h>
#import "NSInvocation+TKAdditions.h"

@interface NSValue (Selector)
+ (NSValue*) valueWithSelector:(SEL)selector;
- (SEL) selectorValue;
@end

@implementation NSValue (Selector)

+ (NSValue*) valueWithSelector:(SEL)selector
{
    return [NSValue valueWithBytes:&selector objCType:@encode(SEL)];
}

- (SEL) selectorValue
{
    SEL selector;
    [self getValue:&selector];
    return selector;
}

@end

@implementation MKCallbacker
{
    NSMutableDictionary* methods_;
    
    NSMutableDictionary* callbacks_;
}




- (instancetype)initWithProtocols:(Protocol*)protocol, ... 
{
    if (self = [super init]) {
        callbacks_ = [NSMutableDictionary dictionaryWithCapacity:16];
        methods_ = [NSMutableDictionary dictionaryWithCapacity:16];
        
        
        va_list args;
        va_start(args, protocol);
        
        Protocol* arg = protocol;
        do {
            class_addProtocol([self class], arg);
            
            unsigned int methodCount = 0;
            struct objc_method_description* cMethods = protocol_copyMethodDescriptionList(arg, NO, YES, &methodCount);
            
            
            for (NSUInteger methodIdx = 0; methodIdx < methodCount; methodIdx++) {
                struct objc_method_description methodDescription = cMethods[methodIdx];
                
                NSValue* selectorValue = [NSValue valueWithSelector:methodDescription.name];
                NSMethodSignature* signature = [NSMethodSignature signatureWithObjCTypes:methodDescription.types];
                
                NSAssert(!methods_[selectorValue], @"Method names in protocols shouldn't be equal");
                
                methods_[selectorValue] = signature;
            }
            
            free(cMethods);
        } while ((arg = va_arg(args, Protocol*)));
        
        va_end(args);
    }
    return self;
}

- (instancetype)initWithProtocol:(Protocol*)protocol
{
    return [self initWithProtocols:protocol, nil];
}

- (NSMethodSignature*) methodSignatureForSelector:(SEL)aSelector
{
    NSValue* selectorValue = [NSValue valueWithSelector:aSelector];
    return methods_[selectorValue];
}


- (void) setCallback:(MKMethodCallCallback)callback forSelector:(SEL)selector
{
    NSValue* selectorValue = [NSValue valueWithSelector:selector];
    if (callback) {
        callbacks_[selectorValue] = [callback copy];
    } else {
        [callbacks_ removeObjectForKey:selectorValue];
    }
}

- (void) removeCallbackForSelector:(SEL)selector
{
    NSValue* selectorValue = [NSValue valueWithSelector:selector];
    [callbacks_ removeObjectForKey:selectorValue];
}

- (void) forwardInvocation:(NSInvocation *)anInvocation
{
    SEL selector = [anInvocation selector];
    
    NSValue* selectorValue = [NSValue valueWithSelector:selector];
    MKMethodCallCallback callback = callbacks_[selectorValue];
    if (callback) {
        NSArray* arguments = [anInvocation arrayOfArguments];
        NSMutableArray* argumentNames = [[NSStringFromSelector(selector) componentsSeparatedByString:@":"] mutableCopy];
        [argumentNames removeLastObject];
        
        NSAssert([arguments count] == [argumentNames count], @"Argument names array count is not equal to argument array count");
        
        NSMutableDictionary* args = [NSMutableDictionary dictionaryWithObjects:arguments forKeys:argumentNames];
        

        NSMethodSignature* signature = [anInvocation methodSignature];
        if ([signature methodReturnLength]) {
            void* returnValue = malloc([signature methodReturnLength]);
            callback(selector, [NSDictionary dictionaryWithDictionary:args], returnValue);
            [anInvocation setReturnValue:returnValue];
            free(returnValue);
        } else {
            callback(selector, [NSDictionary dictionaryWithDictionary:args], NULL);
        }
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([[self class] instancesRespondToSelector:aSelector]) {
        return YES;
    } else {
        NSValue* selectorValue = [NSValue valueWithSelector:aSelector];
        return callbacks_[selectorValue] != nil;
    }
}

- (void) dealloc
{
    NSLog(@"dealloc");
}

@end
