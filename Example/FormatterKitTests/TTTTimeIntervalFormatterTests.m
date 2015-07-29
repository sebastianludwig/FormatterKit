//
//  TTTTimeIntervalFormatter.m
//  FormatterKit Example
//
//  Created by Andrea Bizzotto on 18/04/2015.
//  Copyright (c) 2015 Gowalla. All rights reserved.
//

#import "TTTTimeIntervalFormatter.h"
#import <XCTest/XCTest.h>

@interface TTTTimeIntervalFormatterTests : XCTestCase

@property(strong, nonatomic) TTTTimeIntervalFormatter *formatter;
@property(strong, nonatomic) NSDate *referenceDate;

@end


@implementation TTTTimeIntervalFormatterTests

- (void)setUp {
    [super setUp];
    self.formatter = [TTTTimeIntervalFormatter new];
    self.formatter.calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    self.referenceDate = [NSDate date];
}

#pragma mark - suffixes checks
- (void)checkSuffix:(NSString *)expectedSuffix forTimeInterval:(NSTimeInterval)timeInterval {

    NSDate *toDate = [self.referenceDate dateByAddingTimeInterval:timeInterval];
    NSString *observed = [self.formatter stringForTimeIntervalFromDate:self.referenceDate toDate:toDate];
    NSRange range = [observed rangeOfString:expectedSuffix];
    BOOL suffixFound = range.location != NSNotFound;
    XCTAssert(suffixFound, @"expected: %@", expectedSuffix);
}

- (void)testPositiveTimeIntervalSuffix {

    NSTimeInterval interval = 60;
    NSString *expectedSuffix = self.formatter.futureDeicticExpression;
    [self checkSuffix:expectedSuffix forTimeInterval:interval];
}

- (void)testNegativeTimeIntervalSuffix {

    NSTimeInterval interval = -60;
    NSString *expectedSuffix = self.formatter.pastDeicticExpression;
    [self checkSuffix:expectedSuffix forTimeInterval:interval];
}

- (void)testZeroTimeIntervalSuffix {

    NSTimeInterval interval = 0;
    NSString *expectedSuffix = self.formatter.presentDeicticExpression;
    [self checkSuffix:expectedSuffix forTimeInterval:interval];
}

#pragma mark - singular/plural
- (void)checkTimeUnit:(NSString *)timeUnit forTimeInterval:(NSTimeInterval)timeInterval {

    NSString *expected = [timeUnit stringByAppendingString:@" "];

    NSDate *toDate = [self.referenceDate dateByAddingTimeInterval:timeInterval];
    NSString *observed = [self.formatter stringForTimeIntervalFromDate:self.referenceDate toDate:toDate];
    NSRange range = [observed rangeOfString:expected];
    BOOL found = range.location != NSNotFound;
    XCTAssert(found, @"expected: %@", expected);
}
- (void)testSingularTimeUnit {
    NSTimeInterval interval = 1;
    NSString *singularUnit = @"second";
    [self checkTimeUnit:singularUnit forTimeInterval:interval];
}
- (void)testPluralTimeUnit {
    NSTimeInterval interval = 2;
    NSString *singularUnit = @"seconds";
    [self checkTimeUnit:singularUnit forTimeInterval:interval];
}

#pragma mark - second / minute / hour / day tests
- (void)testSecondMinuteHourDayUnits
{
    NSArray *units = @[@"second", @"minute", @"hour", @"day"];
    NSTimeInterval multiples[] = {1, 60, 60, 24};

    NSTimeInterval interval = 1;
    for (NSUInteger i = 0; i < 4; i++) {
        interval *= multiples[i];
        NSString *expected = units[i];
        [self checkTimeUnit:expected forTimeInterval:interval];
    }
}

#pragma mark - idiomatic deictic expressions
#pragma mark yesterday

- (NSString *)idiomaticDeicticExpressionFromDate:(NSString *)from toDate:(NSString *)to
{
    NSDateFormatter *parser = [[NSDateFormatter alloc] init];
    parser.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    
    NSDate *fromDate = [parser dateFromString:from];
    NSDate *toDate = [parser dateFromString:to];
    
    self.formatter.usesIdiomaticDeicticExpressions = YES;
    
    return [self.formatter stringForTimeIntervalFromDate:fromDate toDate:toDate];
}

- (NSArray *)generateIdioaticDeicticExpressionsWithStepInterval:(NSDateComponents *)interval count:(NSUInteger)count
{
    self.formatter.usesIdiomaticDeicticExpressions = YES;
    
    NSDate *date = [NSDate date];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSDate *nextStep = [self.formatter.calendar dateByAddingComponents:interval toDate:date options:0];
        NSString *expression = [self.formatter stringForTimeIntervalFromDate:date toDate:nextStep];
        [result addObject:@{@"expression": expression, @"from": date, @"to": nextStep}];
        date = nextStep;
    }
    
    return result;
}

- (void)testYesterdayForLessThan24Hours
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-02-24 10:13:39 +0000"
                                                         toDate:@"2015-02-23 20:33:50 +0000"];
    XCTAssertEqualObjects(result, @"yesterday");
}

- (void)testYesterdayForMoreThan24Hours
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-02-24 20:13:39 +0000"
                                                         toDate:@"2015-02-23 10:33:50 +0000"];
    XCTAssertEqualObjects(result, @"yesterday");
}

- (void)testYesterdayAroundMidnight
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-02-24 01:00:00 +0000"
                                                         toDate:@"2015-02-23 23:30:00 +0000"];
    XCTAssertEqualObjects(result, @"yesterday");
}

- (void)testYesterdayGeneric
{
    NSDateComponents *minusOneDay = [NSDateComponents new];
    minusOneDay.day = -1;
    
    NSArray *expressions = [self generateIdioaticDeicticExpressionsWithStepInterval:minusOneDay count:1000];
    
    for (NSDictionary *entry in expressions) {
        XCTAssertEqualObjects(entry[@"expression"], @"yesterday", @"for dates %@ and %@", entry[@"from"], entry[@"to"]);
    }
}

- (void)testSignificantUnit
{
    self.formatter.significantUnits = self.formatter.significantUnits ^ NSCalendarUnitDay;
    
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-07-31 23:00:00 +0000"
                                                         toDate:@"2015-07-30 10:30:00 +0000"];
    XCTAssertNotEqualObjects(result, @"yesterday");
}

#pragma mark tomorrow

- (void)testTomorrowForLessThan24Hours
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-02-23 15:13:39 +0000"
                                                         toDate:@"2015-02-24 10:33:50 +0000"];
    XCTAssertEqualObjects(result, @"tomorrow");
}

- (void)testTomorrowForMoreThan24Hours
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-02-23 10:13:39 +0000"
                                                         toDate:@"2015-02-24 15:33:50 +0000"];
    XCTAssertEqualObjects(result, @"tomorrow");
}

- (void)testTomrrowAroundMidnight
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-02-23 23:30:00 +0000"
                                                         toDate:@"2015-02-24 01:00:00 +0000"];
    XCTAssertEqualObjects(result, @"tomorrow");
}

- (void)testTomrrowOverMonthSpan
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-02-17 13:30:00 +0000"
                                                         toDate:@"2015-03-18 11:00:00 +0000"];
    XCTAssertNotEqualObjects(result, @"tomorrow");
}

- (void)testTomorrowGeneric
{
    NSDateComponents *plusOneDay = [NSDateComponents new];
    plusOneDay.day = 1;
    
    NSArray *expressions = [self generateIdioaticDeicticExpressionsWithStepInterval:plusOneDay count:1000];
    
    for (NSDictionary *entry in expressions) {
        XCTAssertEqualObjects(entry[@"expression"], @"tomorrow", @"for dates %@ and %@", entry[@"from"], entry[@"to"]);
    }
}

#pragma mark last week

- (void)testLastWeekForMoreThan7Days
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-07-23 10:13:00 +0000"
                                                         toDate:@"2015-07-14 10:13:00 +0000"];
    XCTAssertEqualObjects(result, @"last week");
}

- (void)testLastWeekForLessThan7Days
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-07-23 10:13:00 +0000"
                                                         toDate:@"2015-07-17 10:13:00 +0000"];
    XCTAssertEqualObjects(result, @"last week");
}

- (void)testLastWeekAroundWeekStart
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-07-19 10:13:00 +0000"
                                                         toDate:@"2015-07-17 10:13:00 +0000"];
    XCTAssertEqualObjects(result, @"last week");
}

- (void)testLastWeekWithYearChangeFromFirstWeekToLastWeek
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-01-02 10:13:00 +0000"        // wk  1 2015
                                                         toDate:@"2014-12-27 10:13:00 +0000"];      // wk 52 2014
    XCTAssertEqualObjects(result, @"last week");
}

- (void)testLastWeekWithYearChangeFromSecondWeekToFirstWeek
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-01-06 07:16:25 +0000"        // wk 2 2015
                                                         toDate:@"2014-12-30 07:16:25 +0000"];      // wk 1 2015
    XCTAssertEqualObjects(result, @"last week");
}

- (void)testLastWeekWith53WeeksWithYearWrap
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2012-01-03 07:52:00 +0000"        // wk  1 2012
                                                         toDate:@"2011-12-27 07:52:00 +0000"];      // wk 53 2011
    XCTAssertEqualObjects(result, @"last week");
}

- (void)testLastWeekWith53Weeks
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2011-12-27 21:55:47 +0000"        // wk 53 2011
                                                         toDate:@"2011-12-20 21:55:47 +0000"];      // wk 52 2011
    XCTAssertEqualObjects(result, @"last week");
}

- (void)testLastWeekGeneric
{
    NSDateComponents *minusOneWeek = [NSDateComponents new];
    minusOneWeek.weekOfYear = -1;
    
    NSArray *expressions = [self generateIdioaticDeicticExpressionsWithStepInterval:minusOneWeek count:1000];
    
    for (NSDictionary *entry in expressions) {
        XCTAssertEqualObjects(entry[@"expression"], @"last week", @"for dates %@ and %@", entry[@"from"], entry[@"to"]);
    }
}

#pragma mark next week

- (void)testNextWeek
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-07-17 10:13:00 +0000"
                                                         toDate:@"2015-07-19 10:13:00 +0000"];
    XCTAssertEqualObjects(result, @"next week");
}

- (void)testNextWeekGeneric
{
    NSDateComponents *plusOneWeek = [NSDateComponents new];
    plusOneWeek.weekOfYear = 1;
    
    NSArray *expressions = [self generateIdioaticDeicticExpressionsWithStepInterval:plusOneWeek count:1000];
    
    for (NSDictionary *entry in expressions) {
        XCTAssertEqualObjects(entry[@"expression"], @"next week", @"for dates %@ and %@", entry[@"from"], entry[@"to"]);
    }
}

#pragma mark last month

- (void)testLastMonth
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-07-17 10:13:00 +0000"
                                                         toDate:@"2015-06-19 10:13:00 +0000"];
    XCTAssertEqualObjects(result, @"last month");
}

- (void)testLastMonthGeneric
{
    NSDateComponents *minusOneMonth = [NSDateComponents new];
    minusOneMonth.month = -1;
    
    NSArray *expressions = [self generateIdioaticDeicticExpressionsWithStepInterval:minusOneMonth count:1000];
    
    for (NSDictionary *entry in expressions) {
        XCTAssertEqualObjects(entry[@"expression"], @"last month", @"for dates %@ and %@", entry[@"from"], entry[@"to"]);
    }
}

#pragma mark next month

- (void)testNextMonth
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-06-17 10:13:00 +0000"
                                                         toDate:@"2015-07-19 10:13:00 +0000"];
    XCTAssertEqualObjects(result, @"next month");
}

- (void)testNextMonthGeneric
{
    NSDateComponents *plusOneMonth = [NSDateComponents new];
    plusOneMonth.month = 1;
    
    NSArray *expressions = [self generateIdioaticDeicticExpressionsWithStepInterval:plusOneMonth count:1000];
    
    for (NSDictionary *entry in expressions) {
        XCTAssertEqualObjects(entry[@"expression"], @"next month", @"for dates %@ and %@", entry[@"from"], entry[@"to"]);
    }
}

#pragma mark last year

- (void)testLastYear
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-07-17 10:13:00 +0000"
                                                         toDate:@"2014-06-19 10:13:00 +0000"];
    XCTAssertEqualObjects(result, @"last year");
}

- (void)testLastYearGeneric
{
    NSDateComponents *minusOneYear = [NSDateComponents new];
    minusOneYear.year = -1;
    
    NSArray *expressions = [self generateIdioaticDeicticExpressionsWithStepInterval:minusOneYear count:100];
    
    for (NSDictionary *entry in expressions) {
        XCTAssertEqualObjects(entry[@"expression"], @"last year", @"for dates %@ and %@", entry[@"from"], entry[@"to"]);
    }
}

#pragma mark next year

- (void)testNextYear
{
    NSString *result = [self idiomaticDeicticExpressionFromDate:@"2015-06-17 10:13:00 +0000"
                                                         toDate:@"2016-07-19 10:13:00 +0000"];
    XCTAssertEqualObjects(result, @"next year");
}

- (void)testNextYearGeneric
{
    NSDateComponents *plusOneYear = [NSDateComponents new];
    plusOneYear.year = 1;
    
    NSArray *expressions = [self generateIdioaticDeicticExpressionsWithStepInterval:plusOneYear count:100];
    
    for (NSDictionary *entry in expressions) {
        XCTAssertEqualObjects(entry[@"expression"], @"next year", @"for dates %@ and %@", entry[@"from"], entry[@"to"]);
    }
}

#pragma mark - other

- (void)testHoursAgo
{
    NSDateFormatter *parser = [[NSDateFormatter alloc] init];
    parser.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    
    self.formatter.usesIdiomaticDeicticExpressions = YES;
    NSDate *date = [parser dateFromString:@"2015-02-24 00:33:50 +0000"];
    NSDate *now = [parser dateFromString:@"2015-02-24 10:13:39 +0000"];
    
    NSString *result = [self.formatter stringForTimeIntervalFromDate:now toDate:date];
    XCTAssertEqualObjects(result, @"9 hours ago");
}

@end
