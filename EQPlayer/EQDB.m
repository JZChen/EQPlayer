//
//  EQDB.m
//  EQ
//
//  Created by Wildchild on 13/12/20.
//  Copyright (c) 2013年 Wildchild. All rights reserved.
//

#import "EQDB.h"

@implementation EQDB

@synthesize managedOBjectModel=_managedOBjectModel;
@synthesize managedObjectContext=_managedObjectContext;
@synthesize persistentStoreCoordinator=_persistentStoreCoordinator;

-(id)init
{
    /*
     
     NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
     [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
     [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
     
     NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"XPlurk" withExtension:@"momd"];
     _managedOBjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
     
     NSLog(@"%@", [_managedOBjectModel entities]);
     // _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedOBjectModel]];
     
     
     NSString *storePath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"account.db"];
     NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
     
     NSError *error;
     _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedOBjectModel]];
     if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error]) {
     
     NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
     abort();
     }
     
     
     
     if( self.managedObjectContext == nil )
     {
     NSLog(@"init");
     _managedObjectContext = [[NSManagedObjectContext alloc] init];
     [_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
     }
     
     
     
     
     
     //NSError *error;
     NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"PlurkAccount" inManagedObjectContext:self.managedObjectContext];
     NSFetchRequest *request = [[NSFetchRequest alloc] init];
     [request setEntity:entityDesc];
     */
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EQSet"
                                              inManagedObjectContext:context];
    [request setEntity:entity];
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request
                                                                error:&error];
    
    NSLog(@"%d matches found",[objects count]);
    for(NSManagedObject *matches in objects)
    {
        
        
    }
    

    
    
    
    return self;
}

- (void)saveSet:(NSString *)song_id:(NSString *)song_name:(NSString *)song_type:(NSString *)eqSet
{
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EQSet"
                                              inManagedObjectContext:context];
    [request setEntity:entity];
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request
                                                                error:&error];
    
    NSLog(@"%d matches found",[objects count]);
    for(NSManagedObject *matches in objects)
    {
        if( [song_id isEqualToString:[matches valueForKey:@"songid"]] )
        {
            NSLog(@"Got it, perform delete");
            [_managedObjectContext deleteObject:matches];
            [_managedObjectContext save:&error];
            break;
        }
        
    }
    
    
    NSManagedObject *newSet;
    
    
    newSet = [NSEntityDescription
                  insertNewObjectForEntityForName:@"EQSet"
                  inManagedObjectContext:self.managedObjectContext];
    
    [newSet setValue:song_id forKey:@"songid"];
    [newSet setValue:song_name forKey:@"songname"];
    [newSet setValue:song_type forKey:@"songtype"];
    [newSet setValue:eqSet forKey:@"eqset"];
    

    [_managedObjectContext save:&error];
    NSLog(@"save done");

}

- (NSDictionary*)retrieveSet:(NSString *)song_id
{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EQSet"
                                              inManagedObjectContext:context];
    [request setEntity:entity];
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request
                                                                error:&error];
    
    NSLog(@"%d matches found",[objects count]);
    for(NSManagedObject *matches in objects)
    {
        if( [song_id isEqualToString:[matches valueForKey:@"songid"]] )
        {
            NSLog(@"Got it");
            [dictionary setValue:[matches valueForKey:@"songid"] forKey:@"songid"];
            [dictionary setValue:[matches valueForKey:@"songname"] forKey:@"songname"];
            [dictionary setValue:[matches valueForKey:@"songtype"] forKey:@"songtype"];
            [dictionary setValue:[matches valueForKey:@"eqset"] forKey:@"eqset"];
            break;
        }
        
    }
    
    return dictionary;
}

- (NSArray *)retrieveAllSet
{
    NSMutableArray *allSet = [[NSMutableArray alloc] init];
    

    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EQSet"
                                              inManagedObjectContext:context];
    [request setEntity:entity];
    NSError *error;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request
                                                                error:&error];
    
    NSLog(@"%d matches found",[objects count]);
    for(NSManagedObject *matches in objects)
    {
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        [dictionary setValue:[matches valueForKey:@"songid"] forKey:@"songid"];
        
        [dictionary setValue:[matches valueForKey:@"songname"] forKey:@"songname"];
        
        [dictionary setValue:[matches valueForKey:@"songtype"] forKey:@"songtype"];
        
        [dictionary setValue:[matches valueForKey:@"eqset"] forKey:@"eqset"];
        
        [allSet addObject:dictionary];
    }
    
    return allSet;
}

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSURL *)_applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedOBjectModel != nil) {
        return _managedOBjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"EQSet" withExtension:@"momd"];
    _managedOBjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedOBjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self _applicationDocumentsDirectory] URLByAppendingPathComponent:@"account.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

/*
- (void)dealloc
{
    [super dealloc];
    [_managedObjectContext dealloc];
    [_managedOBjectModel dealloc];
    [_persistentStoreCoordinator dealloc];
}
*/

@end
