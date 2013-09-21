//
//  MainViewController.m
//  Hello Couch
//
//  Created by Meiwin Fu on 21/9/13.
//  Copyright (c) 2013 Demo. All rights reserved.
//

#import "MainViewController.h"
#import "DemoAppDelegate.h"

// Documentations: https://github.com/couchbaselabs/TouchDB-iOS/wiki/Guide%3A-Introduction

@interface Cell : UITableViewCell

@end

@implementation Cell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self)
    {
        // do something, if any
    }
    return self;
}

@end
@interface MainViewController () <UIAlertViewDelegate>
{
    NSMutableArray * _records;
    CouchDatabase * _db;
}
@property (nonatomic,strong,readonly) CouchDatabase * db;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.title = @"Hello Couch";
        
        _records = [NSMutableArray array];
    }
    return self;
}
- (CouchDatabase *)db
{
    if (_db == nil)
    {
        _db = [(DemoAppDelegate *)[UIApplication sharedApplication].delegate localCouchDatabase:nil];
    }
    return _db;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view.
    UIBarButtonItem * addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(add:)];
    self.navigationItem.rightBarButtonItem = addButtonItem;
    
    [self.tableView registerClass:[Cell class] forCellReuseIdentifier:@"Cell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseUpdated:) name:kDatabaseUpdatedNotification object:nil];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadContent];
}
- (void)reloadContent
{
    
    CouchQuery * allItems = [self.db getAllDocuments];
    
    NSMutableArray * allRecords = [NSMutableArray array];
    for (CouchQueryRow * row in allItems.rows)
    {
        [allRecords addObject:row.document.properties];
    }
    _records = allRecords;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}
#pragma mark Table View stuff
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _records.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    NSDictionary * d = [_records objectAtIndex:indexPath.row];
    cell.textLabel.text = d[@"text"];
    cell.detailTextLabel.text = d[@"_id"];
    return cell;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary * d = [_records objectAtIndex:indexPath.row];
    CouchDocument * doc = [self.db documentWithID:d[@"_id"]];
    RESTOperation * op = [doc DELETE];
    [op onCompletion:^{
        if (op.error)
        {
            UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Ooops" message:[NSString stringWithFormat:@"Error: %@", [op.error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [errorAlert show];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_records removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        }
    }];
    
}
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSDictionary * d = @{ @"text" : [alertView textFieldAtIndex:0].text, @"created_at" : [RESTBody JSONObjectWithDate:[NSDate date]] };
        
        // adding new document
        CouchDocument * newDoc = [self.db untitledDocument];
        RESTOperation * op = [newDoc putProperties:d];
        
        [op onCompletion:^{
            if (op.error)
            {
                UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Ooops" message:[NSString stringWithFormat:@"Error: %@", [op.error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorAlert show];
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary * data = newDoc.properties;
                    [_records addObject:data];
                    NSInteger row = [_records indexOfObject:data];
                    [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            }
        }];
        
    }
}
#pragma mark Actions
- (void)add:(id)sender
{
    UIAlertView * promptInput = [[UIAlertView alloc] initWithTitle:@"Add" message:@"Say something..." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    promptInput.alertViewStyle = UIAlertViewStylePlainTextInput;
    [promptInput show];
}
#pragma mark Database Updates
- (void)databaseUpdated:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadContent];
    });
}
@end
