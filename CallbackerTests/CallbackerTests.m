//
//  CallbackerTests.m
//  CallbackerTests
//
//  Created by Sergey Fedortsov on 9.1.14.
//  Copyright (c) 2014 Sergey Fedortsov. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "MKCallbacker.h"


typedef struct {
    int y;
    int z;
} TestStruct2;

typedef struct {
    int x;
    TestStruct2 ts;
} TestStruct;

@protocol TestProtocol <NSObject>

- (void) noArguments;
- (void) oneArgument:(NSUInteger)x;
- (void) twoArguments:(NSUInteger)x arg:(NSString*)y;

- (void) testStruct:(TestStruct)s;
@end

@protocol TestProtocol2 <NSObject>
- (void) test2NoArguments;
@end

@interface CallbackerTests : XCTestCase

@end

@implementation CallbackerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testRespondsSelector
{
    MKCallbacker* callbacker = [[MKCallbacker alloc] initWithProtocol:@protocol(TestProtocol)];
    
    id<TestProtocol> test = (id<TestProtocol>)callbacker;
    XCTAssertTrue([test respondsToSelector:@selector(noArguments)], @"Class instance should responds to protocol selectors");
    XCTAssertFalse([test respondsToSelector:NSSelectorFromString(@"nonExistsMethod")], @"Class instance shouldn't responds to non exists selectors");
}

- (void)testArguments
{
    MKCallbacker* callbacker = [[MKCallbacker alloc] initWithProtocol:@protocol(TestProtocol)];
    
    id<TestProtocol> test = (id<TestProtocol>)callbacker;

    [callbacker setCallback:^(SEL selector, NSDictionary *arguments, NSValue** returnValue) {
        XCTAssertTrue(selector == @selector(noArguments), @"Selector in callback isn't equal to called selector");
        
        XCTAssertTrue([arguments count] == 0, @"Arguments count should be zero for methods with no arguments");
    } forSelector:@selector(noArguments)];
    [test noArguments];
    
    [callbacker setCallback:^(SEL selector, NSDictionary *arguments, NSValue** returnValue) {
        XCTAssertTrue(selector == @selector(oneArgument:), @"Selector in callback isn't equal to called selector");
        
        XCTAssertTrue([arguments count] == 1, @"Arguments count should be zero for methods with no arguments");
        
        XCTAssertTrue(arguments[@"oneArgument"], @"There is no requiered argument in argument list");
        XCTAssertTrue([arguments[@"oneArgument"] isKindOfClass:[NSNumber class]], @"Argument type for numbers should be NSNumber");
        XCTAssertTrue([arguments[@"oneArgument"] unsignedIntegerValue] == 1, @"Argument value isn't right");
    } forSelector:@selector(oneArgument:)];
    [test oneArgument:1];
    
    [callbacker setCallback:^(SEL selector, NSDictionary *arguments, NSValue** returnValue) {
        XCTAssertTrue(selector == @selector(twoArguments:arg:), @"Selector in callback isn't equal to called selector");
        
        XCTAssertTrue([arguments count] == 2, @"Arguments count should be zero for methods with no arguments");
        
        
        XCTAssertTrue(arguments[@"twoArguments"], @"There is no requiered argument in argument list");
        XCTAssertTrue([arguments[@"twoArguments"] isKindOfClass:[NSNumber class]], @"Argument type for numbers should be NSNumber");
        XCTAssertTrue([arguments[@"twoArguments"] unsignedIntegerValue] == 2, @"Argument value isn't right");
        
        
        XCTAssertTrue(arguments[@"arg"], @"There is no requiered argument in argument list");
        XCTAssertTrue([arguments[@"arg"] isKindOfClass:[NSString class]], @"Argument type for strings should be NSString");
        XCTAssertTrue([arguments[@"arg"] isEqualToString:@"test"], @"Argument value isn't right");
    } forSelector:@selector(twoArguments:arg:)];
    [test twoArguments:2 arg:@"test"];
}

- (void)testStruct
{
    MKCallbacker* callbacker = [[MKCallbacker alloc] initWithProtocol:@protocol(TestProtocol)];
    
    id<TestProtocol> test = (id<TestProtocol>)callbacker;

    [callbacker setCallback:^(SEL selector, NSDictionary *arguments, NSValue** returnValue) {
        MK_STRUCT_ARGUMENT(TestStruct, testStruct);
        XCTAssertTrue(testStruct.x == 10 && testStruct.ts.y == 20 && testStruct.ts.z == 30, @"Struct test failed");
    } forSelector:@selector(testStruct:)];
    
    TestStruct testStruct;
    testStruct.x = 10;
    testStruct.ts.y = 20;
    testStruct.ts.z = 30;
    [test testStruct:testStruct];
}

- (void)testTwoProtocols
{
    MKCallbacker* callbacker = [[MKCallbacker alloc] initWithProtocols:@protocol(TestProtocol), @protocol(TestProtocol2), nil];
    
    id<TestProtocol, TestProtocol2> test = (id<TestProtocol, TestProtocol2>)callbacker;

    XCTAssertTrue([test respondsToSelector:@selector(noArguments)], @"Class instance should responds to protocol selectors");
    XCTAssertTrue([test respondsToSelector:@selector(test2NoArguments)], @"Class instance should responds to protocol selectors");
    XCTAssertFalse([test respondsToSelector:NSSelectorFromString(@"nonExistsMethod")], @"Class instance shouldn't responds to non exists selectors");
    
    MKMethodCallCallback callback = ^(SEL selector, NSDictionary *arguments, NSValue** returnValue) {
        XCTAssertTrue(selector == @selector(noArguments) || selector == @selector(test2NoArguments), @"Selector in callback isn't equal to called selector");
        
        XCTAssertTrue([arguments count] == 0, @"Arguments count should be zero for methods with no arguments");
    };
    
    [callbacker setCallback:callback forSelector:@selector(noArguments)];
    [callbacker setCallback:callback forSelector:@selector(test2NoArguments)];
    
    [test noArguments];
    [test test2NoArguments];
}

@end
