// 
//  APHAppDelegate.m 
//  GlucoSuccess 
// 
// Copyright (c) 2015, Massachusetts General Hospital. All rights reserved. 
// 
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
// 
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
// 
// 2.  Redistributions in binary form must reproduce the above copyright notice, 
// this list of conditions and the following disclaimer in the documentation and/or 
// other materials provided with the distribution. 
// 
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors 
// may be used to endorse or promote products derived from this software without 
// specific prior written permission. No license is granted to the trademarks of 
// the copyright holders even if such marks are included in this software. 
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
// 
 
#import "APHAppDelegate.h"
#import "APHProfileExtender.h"
#import "APHGlucoseLevelsMealTimesViewController.h"

#pragma mark - Survey Identifiers

static NSString* const kDailyCheckSurveyIdentifier      = @"DailyCheck-1E174061-5B02-11E4-8ED6-0800200C9A66";
static NSString* const kWeeklyCheckSurveyIdentifier     = @"WeeklyCheck-1E174061-5B02-11E4-8ED6-0800200C9A66";
static NSString* const kWaistCheckSurveyIdentifier      = @"APHMeasureWaist-8BCC1BB7-4991-4018-B9CA-4DE820B1CC73";
static NSString* const kWeightCheckSurveyIdentifier     = @"APHEnterWeight-76C03691-4417-4AD6-8F67-F708A8897FF6";
NSString* const kGlucoseLogSurveyIdentifier             = @"APHLogGlucose-42449E07-7124-40EF-AC93-CA5BBF95FC15";
static NSString* const kFoodLogSurveyIdentifier         = @"FoodLog-92F2B523-C7A1-40DF-B89E-BC60EB801AF0";
static NSString* const kSevenDayAllocationIdentifier    = @"APHSevenDayAllocation-00000000-1111-1111-1111-F810BE28D995";
static NSString* const kBaselineSurveyIdentifier        = @"BaselineSurvey-1E77771-5B02-11E4-8ED6-0800200C9A66";
static NSString* const kSleepSurveyIdentifier           = @"SleepSurvey-1E77771-5B02-11E4-8ED6-0811200C9A66";
static NSString* const kQualityOfLifeSurveyIdentifier   = @"QualityOfLife-1E77771-5B02-11E4-8ED6-0811200C9A66";

static NSString *kFeetCheckStepIdentifier               = @"foot_check";

#pragma mark - Data Collector Identifiers

static NSString* const kMotionActivityCollector   = @"motionActivityCollector";
static NSString* const kHealthKitWorkoutCollector = @"HealthKitWorkoutCollector";
static NSString* const kHealthKitDataCollector    = @"HealthKitDataCollector";
static NSString* const kHealthKitSleepCollector   = @"HealthKitSleepCollector";

#pragma mark - Initializations Options

static NSString* const kStudyIdentifier                 = @"studyname";
static NSString* const kAppPrefix                       = @"studyname";
static NSString* const kConsentPropertiesFileName       = @"APHConsentSection";

static NSString *const kJSONScheduleStringKey           = @"scheduleString";
static NSString *const kJSONTasksKey                    = @"tasks";
static NSString *const kJSONScheduleTaskIDKey           = @"taskID";
static NSString *const kJSONSchedulesKey                = @"schedules";

static NSString *const kMigrationTaskIdKey              = @"taskId";
static NSString *const kMigrationOffsetByDaysKey        = @"offsetByDays";
static NSString *const kMigrationGracePeriodInDaysKey   = @"gracePeriodInDays";
static NSString *const kMigrationRecurringKindKey       = @"recurringKind";

static NSString *const kVideoShownKey = @"VideoShown";

static NSString *const kHealthKitMetadataKeyFoodType = @"HKFoodType";
static NSString *const kHealthKitMetadataKeyFoodMeal = @"HKFoodMeal";
static NSString * const kGlucoseMealTimePickedDays   = @"glucoseMealTimePickedDays";

typedef NS_ENUM(NSUInteger, APHMigrationRecurringKinds)
{
    APHMigrationRecurringKindWeekly = 0,
    APHMigrationRecurringKindMonthly,
    APHMigrationRecurringKindQuarterly,
    APHMigrationRecurringKindSemiAnnual,
    APHMigrationRecurringKindAnnual
};

@interface APHAppDelegate ()

@property (nonatomic, strong) APHProfileExtender* profileExtender;
@property  (nonatomic, assign)  NSInteger environment;

@end

@implementation APHAppDelegate

- (BOOL)application:(UIApplication*) __unused application willFinishLaunchingWithOptions:(NSDictionary*) __unused launchOptions
{
    [super application:application willFinishLaunchingWithOptions:launchOptions];
    
    [self enableBackgroundDeliveryForHealthKitTypes];
    
    return YES;
}

- (void)enableBackgroundDeliveryForHealthKitTypes
{
    NSArray* dataTypesWithReadPermission = self.initializationOptions[kHKReadPermissionsKey];
    
    if (dataTypesWithReadPermission)
    {
        for (id dataType in dataTypesWithReadPermission)
        {
            HKObjectType*   sampleType  = nil;
            
            if ([dataType isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* categoryType = (NSDictionary*) dataType;
                
                //Distinguish
                if (categoryType[kHKWorkoutTypeKey])
                {
                    sampleType = [HKObjectType workoutType];
                }
                else if (categoryType[kHKCategoryTypeKey])
                {
                    sampleType = [HKObjectType categoryTypeForIdentifier:categoryType[kHKCategoryTypeKey]];
                }
            }
            else
            {
                sampleType = [HKObjectType quantityTypeForIdentifier:dataType];
            }
            
            if (sampleType)
            {
                [self.dataSubstrate.healthStore enableBackgroundDeliveryForType:sampleType
                                                                      frequency:HKUpdateFrequencyHourly
                                                                 withCompletion:^(BOOL success, NSError *error)
                 {
                     if (!success)
                     {
                         if (error)
                         {
                             APCLogError2(error);
                         }
                     }
                     else
                     {
                         APCLogDebug(@"Enabling background delivery for healthkit");
                     }
                 }];
            }
        }
    }
}

- (void) setUpInitializationOptions
{
    
    NSMutableDictionary * dictionary = [super defaultInitializationOptions];
    
#ifdef DEBUG
    self.environment = SBBEnvironmentStaging;
#else
    self.environment = SBBEnvironmentProd;
#endif
    
    [dictionary addEntriesFromDictionary:@{
                                           kStudyIdentifierKey                  : kStudyIdentifier,
                                           kAppPrefixKey                        : kAppPrefix,
                                           kBridgeEnvironmentKey                : @(self.environment)
                                           }];
    
    self.initializationOptions = dictionary;
    
    self.profileExtender = [[APHProfileExtender alloc] init];
}

- (NSDictionary*)researcherSpecifiedUnits
{
    NSDictionary* hkUnits =
    @{
      HKQuantityTypeIdentifierStepCount                 : [HKUnit countUnit],
      HKQuantityTypeIdentifierBodyMass                  : [HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo],
      HKQuantityTypeIdentifierHeight                    : [HKUnit meterUnit],
      
      
      HKQuantityTypeIdentifierDietaryCarbohydrates      : [HKUnit gramUnit],
      HKQuantityTypeIdentifierDietarySugar              : [HKUnit gramUnit],
      HKQuantityTypeIdentifierDietaryEnergyConsumed     : [HKUnit calorieUnit],
      HKQuantityTypeIdentifierBloodGlucose              : [[HKUnit gramUnitWithMetricPrefix:HKMetricPrefixMilli] unitDividedByUnit:[HKUnit literUnitWithMetricPrefix:HKMetricPrefixDeci]]
      };
    
    return hkUnits;
}

-(void)setUpTasksReminder{
    APCTaskReminder *dailySurveyReminder = [[APCTaskReminder alloc] initWithTaskID:kDailyCheckSurveyIdentifier
                                                                      reminderBody:NSLocalizedString(@"Complete Daily Check", nil)];
    APCTaskReminder *weeklySurveyReminder = [[APCTaskReminder alloc] initWithTaskID:kWeeklyCheckSurveyIdentifier
                                                                       reminderBody:NSLocalizedString(@"Complete Weekly Survey", nil)];
    APCTaskReminder *waistSurveyReminder = [[APCTaskReminder alloc] initWithTaskID:kWaistCheckSurveyIdentifier
                                                                      reminderBody:NSLocalizedString(@"Complete Waist Measurement", nil)];
    APCTaskReminder *weightSurveyReminder = [[APCTaskReminder alloc] initWithTaskID:kWeightCheckSurveyIdentifier
                                                                       reminderBody:NSLocalizedString(@"Complete Weight Measurement", nil)];
    APCTaskReminder *glucoseSurveyReminder = [[APCTaskReminder alloc] initWithTaskID:kGlucoseLogSurveyIdentifier
                                                                        reminderBody:NSLocalizedString(@"Complete Glucose Log", nil)];
    APCTaskReminder *foodSurveyReminder = [[APCTaskReminder alloc] initWithTaskID:kFoodLogSurveyIdentifier
                                                                     reminderBody:NSLocalizedString(@"Complete Food Log", nil)];
    
    NSPredicate *footCheckPredicate = [NSPredicate predicateWithFormat:@"SELF.integerValue == 1"];
    
    APCTaskReminder *footCheckReminder = [[APCTaskReminder alloc] initWithTaskID:kDailyCheckSurveyIdentifier
                                                               resultsSummaryKey:kFeetCheckStepIdentifier
                                                          completedTaskPredicate:footCheckPredicate
                                                                    reminderBody:NSLocalizedString(@"Complete Activities", nil)];
    
    [self.tasksReminder.reminders removeAllObjects];
    [self.tasksReminder manageTaskReminder:dailySurveyReminder];
    [self.tasksReminder manageTaskReminder:weeklySurveyReminder];
    [self.tasksReminder manageTaskReminder:waistSurveyReminder];
    [self.tasksReminder manageTaskReminder:weightSurveyReminder];
    [self.tasksReminder manageTaskReminder:glucoseSurveyReminder];
    [self.tasksReminder manageTaskReminder:foodSurveyReminder];
    [self.tasksReminder manageTaskReminder:footCheckReminder];
    
    if ([self doesPersisteStoreExist] == NO)
    {
        APCLogEvent(@"This app is being launched for the first time. Turn all reminders on");
        for (APCTaskReminder *reminder in self.tasksReminder.reminders) {
            [[NSUserDefaults standardUserDefaults] setObject:reminder.reminderBody forKey:reminder.reminderIdentifier];
        }
        
        if ([[UIApplication sharedApplication] currentUserNotificationSettings].types != UIUserNotificationTypeNone){
            [self.tasksReminder setReminderOn:@YES];
        }
    }
}

- (void) setUpAppAppearance
{
    [APCAppearanceInfo setAppearanceDictionary:@{
                                                 kPrimaryAppColorKey : [UIColor colorWithRed:0.020 green:0.549 blue:0.737 alpha:1.000],  //#058cbc Diabetes
                                                 kWeightCheckSurveyIdentifier: [UIColor appTertiaryRedColor],
                                                 kGlucoseLogSurveyIdentifier : [UIColor appTertiaryGreenColor],
                                                 kSevenDayAllocationIdentifier: [UIColor appTertiaryBlueColor],
                                                 kDailyCheckSurveyIdentifier: [UIColor lightGrayColor],
                                                 kWeeklyCheckSurveyIdentifier: [UIColor lightGrayColor],
                                                 kWaistCheckSurveyIdentifier: [UIColor appTertiaryRedColor],
                                                 kFoodLogSurveyIdentifier: [UIColor appTertiaryYellowColor],
                                                 kBaselineSurveyIdentifier: [UIColor appTertiaryGrayColor],
                                                 }];
    [[UINavigationBar appearance] setTintColor:[UIColor appPrimaryColor]];
    [[UINavigationBar appearance] setBackgroundColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes: @{
                                                            NSForegroundColorAttributeName : [UIColor appSecondaryColor1],
                                                            NSFontAttributeName : [UIFont appNavBarTitleFont]
                                                            }];
    [[UIView appearance] setTintColor: [UIColor appPrimaryColor]];
    
    self.dataSubstrate.parameters.bypassServer = YES;
    self.dataSubstrate.parameters.hideExampleConsent = NO;
}

- (id <APCProfileViewControllerDelegate>) profileExtenderDelegate {
    
    return self.profileExtender;
}

- (void) showOnBoarding
{
    [super showOnBoarding];
    
    [self showStudyOverview];
}

- (void) showStudyOverview
{
    APCStudyOverviewViewController *studyController = [[UIStoryboard storyboardWithName:@"APCOnboarding" bundle:[NSBundle appleCoreBundle]] instantiateViewControllerWithIdentifier:@"StudyOverviewVC"];
    [self setUpRootViewController:studyController];
}

- (BOOL) isVideoShown
{
    return NO;
}

- (NSArray *)reviewConsentActions
{
    return @[kReviewConsentActionPDF, kReviewConsentActionSlides];
}

- (NSMutableArray *)retireveGlucoseLevels
{
    NSArray *normalizedLevels = nil;
    // retrieve glucose levels from the datastore
    NSString *levels = [self.dataSubstrate.currentUser glucoseLevels];
    
    if (levels) {
        NSData *levelsData = [levels dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        
        normalizedLevels = [NSJSONSerialization JSONObjectWithData:levelsData options:NSJSONReadingAllowFragments error:&error];
    }
    
    return [normalizedLevels mutableCopy];
}

- (NSArray *)metadataKeysForCorrelation
{
    return @[kHealthKitMetadataKeyFoodMeal, kHealthKitMetadataKeyFoodType];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [super applicationDidBecomeActive:application];
    
    [self startActivityTrackerTask];
}

- (void)afterOnBoardProcessIsFinished
{
    [self startActivityTrackerTask];
    
    [self createGlucoseLogScheduleAndTask];
}

- (void)createGlucoseLogScheduleAndTask
{
    NSString *repeatDays = [[NSUserDefaults standardUserDefaults] objectForKey:kGlucoseMealTimePickedDays];
    NSArray *mealTimes = [self retireveGlucoseLevels];
    NSArray *mealTimeHours = [mealTimes valueForKey:kGlucoseLevelScheduledHourKey];
    NSArray *sortedScheduleTimes = [mealTimeHours sortedArrayUsingSelector:@selector(compare:)];
    
    [APHGlucoseLevelsMealTimesViewController createGlucoseLogScheduleAndTaskWithScheduledHours:sortedScheduleTimes
                                                                                 andRepeatDays:repeatDays];
}

- (void)startActivityTrackerTask
{
    BOOL isUserSignedIn = self.dataSubstrate.currentUser.signedIn;
    
    
    if (isUserSignedIn && [APCDeviceHardware isiPhone5SOrNewer]) {
        NSDate *fitnessStartDate = [self checkSevenDayFitnessStartDate];
        if (fitnessStartDate) {
            self.sevenDayFitnessAllocationData = [[APCFitnessAllocation alloc] initWithAllocationStartDate:fitnessStartDate];
            
            [self.sevenDayFitnessAllocationData startDataCollection];
        }
    }
}

- (NSDate *)checkSevenDayFitnessStartDate
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDate *fitnessStartDate = [defaults objectForKey:kSevenDayFitnessStartDateKey];
    
    if (!fitnessStartDate) {
        fitnessStartDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                    minute:0
                                                                    second:0
                                                                    ofDate:[NSDate date]
                                                                   options:0];
        
        [defaults setObject:fitnessStartDate forKey:kSevenDayFitnessStartDateKey];        
    }
    
    return fitnessStartDate;
}

- (NSInteger)fitnessDaysShowing:(APHFitnessDaysShows)showKind
{
    NSInteger numberOfDays = 7;
    
    NSDate *startDate = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                                 minute:0
                                                                 second:0
                                                                 ofDate:[self checkSevenDayFitnessStartDate]
                                                                options:0];
    
    NSDate *today = [[NSCalendar currentCalendar] dateBySettingHour:0
                                                             minute:0
                                                             second:0
                                                             ofDate:[NSDate date]
                                                            options:0];
    
    NSDateComponents *numberOfDaysFromStartDate = [[NSCalendar currentCalendar] components:NSCalendarUnitDay
                                                                                  fromDate:startDate
                                                                                    toDate:today
                                                                                   options:NSCalendarWrapComponents];
    
    NSInteger lapsedDays = numberOfDaysFromStartDate.day;
    
    if (showKind == APHFitnessDaysShowsRemaining) {
        // Compute the remaing days
        if (lapsedDays < 7) {
            numberOfDays = 7 - lapsedDays;
        }
    } else {
        // Compute days lapsed
        if (lapsedDays < 7) {
            numberOfDays = (lapsedDays == 0) ? 1 : lapsedDays;
        }
    }
    
    return numberOfDays;
}

#pragma mark - Helper Method for Datasubstrate Delegate Methods

static NSDate *determineConsentDate(id object)
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString      *filePath    = [[object applicationDocumentsDirectory] stringByAppendingPathComponent:kDatabaseName];
    NSDate        *consentDate = nil;
    
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError      *error      = nil;
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:filePath error:&error];
        
        if (attributes) {
            if (error) {
                APCLogError2(error);
            }
            consentDate = [[NSDate date] startOfDay];
        } else {
            consentDate = [attributes fileCreationDate];
        }
    }
    return consentDate;
}

#pragma mark - Datasubstrate Delegate Methods

- (void) setUpCollectors
{
    if (self.dataSubstrate.currentUser.consented)
    {
        if (!self.passiveDataCollector)
        {
            self.passiveDataCollector = [[APCPassiveDataCollector alloc] init];
        }
        
        [self configureObserverQueries];
        [self configureMotionActivityObserver];
    }
}

- (void)configureMotionActivityObserver
{
    NSString*(^CoreMotionDataSerializer)(id) = ^NSString *(id dataSample)
    {
        CMMotionActivity* motionActivitySample  = (CMMotionActivity*)dataSample;
        NSString* motionActivity                = [CMMotionActivity activityTypeName:motionActivitySample];
        NSNumber* motionConfidence              = @(motionActivitySample.confidence);
        NSString* stringToWrite                 = [NSString stringWithFormat:@"%@,%@,%@\n",
                                                   motionActivitySample.startDate.toStringInISO8601Format,
                                                   motionActivity,
                                                   motionConfidence];
        
        return stringToWrite;
    };
    
    NSDate* (^LaunchDate)() = ^
    {
        APCUser*    user        = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.currentUser;
        NSDate*     consentDate = nil;
        
        if (user.consentSignatureDate)
        {
            consentDate = user.consentSignatureDate;
        }
        else
        {
            consentDate = determineConsentDate(self);
        }
        return consentDate;
    };
    
    APCCoreMotionBackgroundDataCollector *motionCollector = [[APCCoreMotionBackgroundDataCollector alloc] initWithIdentifier:@"motionActivityCollector"
                                                                                                              dateAnchorName:@"APCCoreMotionCollectorAnchorName"
                                                                                                            launchDateAnchor:LaunchDate];
    
    NSArray*            motionColumnNames   = @[@"startTime",@"activityType",@"confidence"];
    APCPassiveDataSink* receiver            = [[APCPassiveDataSink alloc] initWithIdentifier:kMotionActivityCollector
                                                                                 columnNames:motionColumnNames
                                                                          operationQueueName:@"APCCoreMotion Activity Collector"
                                                                               dataProcessor:CoreMotionDataSerializer
                                                                           fileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication];
    
    [motionCollector setReceiver:receiver];
    [motionCollector setDelegate:receiver];
    [motionCollector start];
    [self.passiveDataCollector addDataSink:motionCollector];
}


- (void)configureObserverQueries
{
    NSDate* (^LaunchDate)() = ^
    {
        APCUser*    user        = ((APCAppDelegate *)[UIApplication sharedApplication].delegate).dataSubstrate.currentUser;
        NSDate*     consentDate = nil;
        
        if (user.consentSignatureDate)
        {
            consentDate = user.consentSignatureDate;
        }
        else
        {
            consentDate = determineConsentDate(self);
        }
        return consentDate;
    };
    
    NSString *(^determineQuantitySource)(NSString *) = ^(NSString  *source)
    {
        NSString  *answer = nil;
        if (source == nil) {
            answer = @"not available";
        } else if ([UIDevice.currentDevice.name isEqualToString:source] == YES) {
            if ([APCDeviceHardware platformString] != nil) {
                answer = [APCDeviceHardware platformString];
            } else {
                answer = @"iPhone";    //    theoretically should not happen
            }
        }
        return answer;
    };
    
    NSString*(^QuantityDataSerializer)(id, HKUnit*) = ^NSString*(id dataSample, HKUnit* unit)
    {
        HKQuantitySample*   qtySample           = (HKQuantitySample *)dataSample;
        NSString*           startDateTimeStamp  = [qtySample.startDate toStringInISO8601Format];
        NSString*           endDateTimeStamp    = [qtySample.endDate toStringInISO8601Format];
        NSString*           healthKitType       = qtySample.quantityType.identifier;
        NSNumber*           quantityValue       = @([qtySample.quantity doubleValueForUnit:unit]);
        NSString*           quantityUnit        = unit.unitString;
        
        NSString*           correlation         = @"No Data";
        NSDictionary*       metaData            = qtySample.metadata;
        
        if (metaData)
        {
            NSString*           meal                = [metaData objectForKey:kHealthKitMetadataKeyFoodMeal];
            NSString*           foodItem            = [metaData objectForKey:kHealthKitMetadataKeyFoodType];
            
            if (meal && foodItem)
            {
                correlation = [NSString stringWithFormat:@"\"%@ - %@\"", meal, foodItem];
            }
        }
        
        NSString*           sourceIdentifier    = qtySample.source.bundleIdentifier;
        NSString*           quantitySource      = qtySample.source.name;
        
        quantitySource = determineQuantitySource(quantitySource);
        
        NSString *stringToWrite = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@\n",
                                   startDateTimeStamp,
                                   endDateTimeStamp,
                                   healthKitType,
                                   quantityValue,
                                   quantityUnit,
                                   correlation,
                                   sourceIdentifier,
                                   quantitySource];
        
        return stringToWrite;
    };
    
    NSString*(^WorkoutDataSerializer)(id) = ^(id dataSample)
    {
        HKWorkout*  sample                      = (HKWorkout*)dataSample;
        NSString*   startDateTimeStamp          = [sample.startDate toStringInISO8601Format];
        NSString*   endDateTimeStamp            = [sample.endDate toStringInISO8601Format];
        NSString*   healthKitType               = sample.sampleType.identifier;
        NSString*   activityType                = [HKWorkout apc_workoutActivityTypeStringRepresentation:(int)sample.workoutActivityType];
        double      energyConsumedValue         = [sample.totalEnergyBurned doubleValueForUnit:[HKUnit kilocalorieUnit]];
        NSString*   energyConsumed              = [NSString stringWithFormat:@"%f", energyConsumedValue];
        NSString*   energyUnit                  = [HKUnit kilocalorieUnit].description;
        double      totalDistanceConsumedValue  = [sample.totalDistance doubleValueForUnit:[HKUnit meterUnit]];
        NSString*   totalDistance               = [NSString stringWithFormat:@"%f", totalDistanceConsumedValue];
        NSString*   distanceUnit                = [HKUnit meterUnit].description;
        NSString*   sourceIdentifier            = sample.source.bundleIdentifier;
        NSString*   quantitySource              = sample.source.name;
        
        quantitySource = determineQuantitySource(quantitySource);
        
        NSError*    error                       = nil;
        NSString*   metaData                    = [NSDictionary apc_stringFromDictionary:sample.metadata error:&error];
        
        if (!metaData)
        {
            if (error)
            {
                APCLogError2(error);
            }
            
            metaData = @"";
        }
        
        NSString*   metaDataStringified         = [NSString stringWithFormat:@"\"%@\"", metaData];
        NSString*   stringToWrite               = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@,%@,%@,%@,%@\n",
                                                   startDateTimeStamp,
                                                   endDateTimeStamp,
                                                   healthKitType,
                                                   activityType,
                                                   totalDistance,
                                                   distanceUnit,
                                                   energyConsumed,
                                                   energyUnit,
                                                   quantitySource,
                                                   sourceIdentifier,
                                                   metaDataStringified];
        
        return stringToWrite;
    };
    
    NSString*(^CategoryDataSerializer)(id) = ^NSString*(id dataSample)
    {
        HKCategorySample*   catSample       = (HKCategorySample *)dataSample;
        NSString*           stringToWrite   = nil;
        
        if ([catSample.categoryType.identifier isEqualToString:HKCategoryTypeIdentifierSleepAnalysis])
        {
            NSString*           startDateTime   = [catSample.startDate toStringInISO8601Format];
            NSString*           healthKitType   = catSample.sampleType.identifier;
            NSString*           categoryValue   = nil;
            
            if (catSample.value == HKCategoryValueSleepAnalysisAsleep)
            {
                categoryValue = @"HKCategoryValueSleepAnalysisAsleep";
            }
            else
            {
                categoryValue = @"HKCategoryValueSleepAnalysisInBed";
            }
            
            NSString*           quantityUnit        = [[HKUnit secondUnit] unitString];
            NSString*           sourceIdentifier    = catSample.source.bundleIdentifier;
            NSString*           quantitySource      = catSample.source.name;
            
            quantitySource = determineQuantitySource(quantitySource);
            
            // Get the difference in seconds between the start and end date for the sample
            NSDateComponents* secondsSpentInBedOrAsleep = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond
                                                                                          fromDate:catSample.startDate
                                                                                            toDate:catSample.endDate
                                                                                           options:NSCalendarWrapComponents];
            NSString*           quantityValue   = [NSString stringWithFormat:@"%ld", (long)secondsSpentInBedOrAsleep.second];
            
            stringToWrite   = [NSString stringWithFormat:@"%@,%@,%@,%@,%@,%@,%@\n",
                               startDateTime,
                               healthKitType,
                               categoryValue,
                               quantityValue,
                               quantityUnit,
                               quantitySource,
                               sourceIdentifier];
        }
        
        return stringToWrite;
    };
    
    NSArray* dataTypesWithReadPermission = [self healthKitQuantityTypesToRead];
    
    if (!self.passiveDataCollector)
    {
        self.passiveDataCollector = [[APCPassiveDataCollector alloc] init];
    }
    
    // Just a note here that we are using n collectors to 1 data sink for quantity sample type data.
    NSArray*                    quantityColumnNames = @[@"startTime,endTime,type,value,unit,source,sourceIdentifier"];
    APCPassiveDataSink*         quantityreceiver    =[[APCPassiveDataSink alloc] initWithQuantityIdentifier:kHealthKitDataCollector
                                                                                                columnNames:quantityColumnNames
                                                                                         operationQueueName:@"APCHealthKitQuantity Activity Collector"
                                                                                              dataProcessor:QuantityDataSerializer
                                                                                          fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    NSArray*                    workoutColumnNames  = @[@"startTime,endTime,type,workoutType,total distance,unit,energy consumed,unit,source,sourceIdentifier,metadata"];
    APCPassiveDataSink*         workoutReceiver     = [[APCPassiveDataSink alloc] initWithIdentifier:kHealthKitWorkoutCollector
                                                                                         columnNames:workoutColumnNames
                                                                                  operationQueueName:@"APCHealthKitWorkout Activity Collector"
                                                                                       dataProcessor:WorkoutDataSerializer
                                                                                   fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    NSArray*                    categoryColumnNames = @[@"startTime,type,category value,value,unit,source,sourceIdentifier"];
    APCPassiveDataSink*         sleepReceiver       = [[APCPassiveDataSink alloc] initWithIdentifier:kHealthKitSleepCollector
                                                                                         columnNames:categoryColumnNames
                                                                                  operationQueueName:@"APCHealthKitSleep Activity Collector"
                                                                                       dataProcessor:CategoryDataSerializer
                                                                                   fileProtectionKey:NSFileProtectionCompleteUnlessOpen];
    
    if (dataTypesWithReadPermission)
    {
        for (id dataType in dataTypesWithReadPermission)
        {
            HKSampleType* sampleType = nil;
            
            if ([dataType isKindOfClass:[NSDictionary class]])
            {
                NSDictionary* categoryType = (NSDictionary *) dataType;
                
                //Distinguish
                if (categoryType[kHKWorkoutTypeKey])
                {
                    sampleType = [HKObjectType workoutType];
                }
                else if (categoryType[kHKCategoryTypeKey])
                {
                    sampleType = [HKObjectType categoryTypeForIdentifier:categoryType[kHKCategoryTypeKey]];
                }
            }
            else
            {
                sampleType = [HKObjectType quantityTypeForIdentifier:dataType];
            }
            
            if (sampleType)
            {
                // This is really important to remember that we are creating as many user defaults as there are healthkit permissions here.
                NSString*                               uniqueAnchorDateName    = [NSString stringWithFormat:@"APCHealthKit%@AnchorDate", dataType];
                APCHealthKitBackgroundDataCollector*    collector               = nil;
                
                //If the HKObjectType is a HKWorkoutType then set a different receiver/data sink.
                if ([sampleType isKindOfClass:[HKWorkoutType class]])
                {
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithIdentifier:sampleType.identifier
                                                                                     sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                               launchDateAnchor:LaunchDate
                                                                                    healthStore:self.dataSubstrate.healthStore];
                    [collector setReceiver:workoutReceiver];
                    [collector setDelegate:workoutReceiver];
                }
                else if ([sampleType isKindOfClass:[HKCategoryType class]])
                {
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithIdentifier:sampleType.identifier
                                                                                     sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                               launchDateAnchor:LaunchDate
                                                                                    healthStore:self.dataSubstrate.healthStore];
                    [collector setReceiver:sleepReceiver];
                    [collector setDelegate:sleepReceiver];
                }
                else
                {
                    NSDictionary* hkUnitKeysAndValues = [self researcherSpecifiedUnits];
                    
                    collector = [[APCHealthKitBackgroundDataCollector alloc] initWithQuantityTypeIdentifier:sampleType.identifier
                                                                                                 sampleType:sampleType anchorName:uniqueAnchorDateName
                                                                                           launchDateAnchor:LaunchDate
                                                                                                healthStore:self.dataSubstrate.healthStore
                                                                                                       unit:[hkUnitKeysAndValues objectForKey:sampleType.identifier]];
                    [collector setReceiver:quantityreceiver];
                    [collector setDelegate:quantityreceiver];
                }
                
                [collector start];
                [self.passiveDataCollector addDataSink:collector];
            }
        }
    }
}

#pragma mark - APCOnboardingDelegate Methods

- (APCScene *)inclusionCriteriaSceneForOnboarding:(APCOnboarding *) __unused onboarding
{
    APCScene *scene = [APCScene new];
    scene.name = @"APHInclusionCriteriaViewController";
    scene.storyboardName = @"APHOnboarding";
    scene.bundle = [NSBundle mainBundle];
    
    return scene;
}

- (APCScene *)customInfoSceneForOnboarding:(APCOnboarding *) __unused onboarding
{
    APCScene *scene = [APCScene new];
    scene.name = @"APHGlucoseLevels";
    scene.storyboardName = @"APHOnboarding";
    scene.bundle = [NSBundle mainBundle];
    
    return scene;
}

-(APCPermissionsManager * __nonnull)permissionsManager
{
    return [[APCPermissionsManager alloc] initWithHealthKitCharacteristicTypesToRead:[self healthKitCharacteristicTypesToRead]
                                                        healthKitQuantityTypesToRead:[self healthKitQuantityTypesToRead]
                                                       healthKitQuantityTypesToWrite:[self healthKitQuantityTypesToWrite]
                                                                   userInfoItemTypes:[self userInfoItemTypes] signUpPermissionTypes:[self signUpPermissionsTypes]];
}

- (NSArray *)healthKitCharacteristicTypesToRead
{
    return @[
             HKCharacteristicTypeIdentifierBiologicalSex,
             HKCharacteristicTypeIdentifierDateOfBirth
             ];
}

- (NSArray *)healthKitQuantityTypesToWrite
{
    return @[
             HKQuantityTypeIdentifierBodyMass,
             HKQuantityTypeIdentifierHeight
             ];
}

- (NSArray *)healthKitQuantityTypesToRead
{
    return @[
             HKQuantityTypeIdentifierBodyMass,
             HKQuantityTypeIdentifierHeight,
             HKQuantityTypeIdentifierStepCount,
             HKQuantityTypeIdentifierDietaryCarbohydrates,
             HKQuantityTypeIdentifierDietarySugar,
             HKQuantityTypeIdentifierDietaryEnergyConsumed,
             HKQuantityTypeIdentifierBloodGlucose,
             @{kHKWorkoutTypeKey  : HKWorkoutTypeIdentifier},
             @{kHKCategoryTypeKey : HKCategoryTypeIdentifierSleepAnalysis}
             ];
}

- (NSArray *)signUpPermissionsTypes
{
    return @[
             @(kAPCSignUpPermissionsTypeLocalNotifications),
             @(kAPCSignUpPermissionsTypeCoremotion)
             ];
}

- (NSArray *)userInfoItemTypes
{
    return  @[
              @(kAPCUserInfoItemTypeEmail),
              @(kAPCUserInfoItemTypeBiologicalSex),
              @(kAPCUserInfoItemTypeHeight),
              @(kAPCUserInfoItemTypeWeight),
              @(kAPCUserInfoItemTypeWakeUpTime),
              @(kAPCUserInfoItemTypeSleepTime),
              ];
}

#pragma mark - Consent

- (ORKTaskViewController *)consentViewController
{
    APCConsentTask*         task = [[APCConsentTask alloc] initWithIdentifier:@"Consent"
                                                           propertiesFileName:kConsentPropertiesFileName];
    ORKTaskViewController*  consentVC = [[ORKTaskViewController alloc] initWithTask:task
                                                                        taskRunUUID:[NSUUID UUID]];
    
    return consentVC;
}

@end
