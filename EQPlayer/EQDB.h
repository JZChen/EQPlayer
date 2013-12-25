//
//  EQDB.h
//  EQ
//
//  Created by Wildchild on 13/12/20.
//  Copyright (c) 2013年 Wildchild. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface EQDB : NSObject
{


}


@property (readonly, strong , nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong , nonatomic) NSManagedObjectModel *managedOBjectModel;
@property (readonly, strong , nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(NSString *)applicationDocumentsDirectory;

- (void)saveSet:(NSString *)song_id:(NSString *)song_name:(NSString *)song_type:(NSString *)eqSet;
- (NSDictionary*)retrieveSet:(NSString *)song_id;
- (NSArray *)retrieveAllSet;

@end
