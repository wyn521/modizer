//
//  RootViewControllerLocalBrowser.m
//  modizer1
//
//  Created by Yohann Magnien on 04/06/10.
//  Copyright __YoyoFR / Yohann Magnien__ 2010. All rights reserved.
//

#define PRI_SEC_ACTIONS_IMAGE_SIZE 40
#define ROW_HEIGHT 40
#define LIMITED_LIST_SIZE 1024

#include <sys/types.h>
#include <sys/sysctl.h>

#include "gme.h"
//SID2
#import "SidTune.h"


#include "unzip.h"

#include <pthread.h>
extern pthread_mutex_t db_mutex;
//static int shouldFillKeys;
static int local_flag;
static volatile int mPopupAnimation=0;

#import "RootViewControllerLocalBrowser.h"
#import "AppDelegate_Phone.h"
#import "DetailViewControllerIphone.h"
#import "QuartzCore/CAAnimation.h"


@implementation RootViewControllerLocalBrowser

@synthesize mFileMngr;
@synthesize detailViewController;
@synthesize tabView,sBar;
@synthesize list;
@synthesize keys;
@synthesize currentPath;
@synthesize childController;
@synthesize playerButton;
@synthesize mSearchText;

#pragma mark -
#pragma mark View lifecycle

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
}

- (NSString *)machine {
	size_t size;
	
	// Set 'oldp' parameter to NULL to get the size of the data
	// returned so we can allocate appropriate amount of space
	sysctlbyname("hw.machine", NULL, &size, NULL, 0); 
	
	// Allocate the space to store name
	char *name = (char*)malloc(size);
	
	// Get the platform name
	sysctlbyname("hw.machine", name, &size, NULL, 0);
	
	// Place name into a string
	NSString *machine = [[[NSString alloc] initWithCString:name] autorelease];
	
	// Done with this
	free(name);
	
	return machine;
}

-(void)showWaiting{
	waitingView.hidden=FALSE;
}

-(void)hideWaiting{
	waitingView.hidden=TRUE;
}

- (void)viewDidLoad {
	clock_t start_time,end_time;	
	start_time=clock();	
	childController=NULL;
    
    mFileMngr=[[NSFileManager alloc] init];
	
	NSString *strMachine=[self machine];
	mSlowDevice=0;
	NSRange r = [strMachine rangeOfString:@"iPhone1," options:NSCaseInsensitiveSearch];
	if (r.location != NSNotFound) {
		mSlowDevice=1;
	}
	r.location=NSNotFound;
	r = [strMachine rangeOfString:@"iPod1," options:NSCaseInsensitiveSearch];
	if (r.location != NSNotFound) {
		mSlowDevice=1;
	}
	
	mShowSubdir=0;
	
	ratingImg[0] = @"rating0.png";
    ratingImg[1] = @"rating1.png";
	ratingImg[2] = @"rating2.png";
	ratingImg[3] = @"rating3.png";
	ratingImg[4] = @"rating4.png";
	ratingImg[5] = @"rating5.png";
	
	//self.tableView.pagingEnabled;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.tableView.sectionHeaderHeight = 18;
	self.tableView.rowHeight = 50;
	
	shouldFillKeys=1;
	mSearch=0;
	
	search_local=0;
	
	local_nb_entries=0;
	search_local_nb_entries=0;
    
	mSearchText=nil;
	mCurrentWinAskedDownload=0;
	mClickedPrimAction=0;
	list=nil;
	keys=nil;
	
	if (browse_depth==1) { //Local mode
		currentPath = @"Documents";
		[currentPath retain];
	}
	self.navigationItem.rightBarButtonItem = playerButton; //self.editButtonItem;
	
	indexTitles = [[NSMutableArray alloc] init];
	[indexTitles addObject:@"{search}"];
	[indexTitles addObject:@"#"];
	[indexTitles addObject:@"A"];
	[indexTitles addObject:@"B"];
	[indexTitles addObject:@"C"];
	[indexTitles addObject:@"D"];
	[indexTitles addObject:@"E"];
	[indexTitles addObject:@"F"];
	[indexTitles addObject:@"G"];
	[indexTitles addObject:@"H"];	
	[indexTitles addObject:@"I"];
	[indexTitles addObject:@"J"];
	[indexTitles addObject:@"K"];
	[indexTitles addObject:@"L"];
	[indexTitles addObject:@"M"];
	[indexTitles addObject:@"N"];
	[indexTitles addObject:@"O"];
	[indexTitles addObject:@"P"];
	[indexTitles addObject:@"Q"];
	[indexTitles addObject:@"R"];
	[indexTitles addObject:@"S"];
	[indexTitles addObject:@"T"];
	[indexTitles addObject:@"U"];
	[indexTitles addObject:@"V"];
	[indexTitles addObject:@"W"];
	[indexTitles addObject:@"X"];
	[indexTitles addObject:@"Y"];
	[indexTitles addObject:@"Z"];
	
	indexTitlesSpace = [[NSMutableArray alloc] init];
	[indexTitlesSpace addObject:@"{search}"];
	[indexTitlesSpace addObject:@" "];
	[indexTitlesSpace addObject:@"#"];
	[indexTitlesSpace addObject:@"A"];
	[indexTitlesSpace addObject:@"B"];
	[indexTitlesSpace addObject:@"C"];
	[indexTitlesSpace addObject:@"D"];
	[indexTitlesSpace addObject:@"E"];
	[indexTitlesSpace addObject:@"F"];
	[indexTitlesSpace addObject:@"G"];
	[indexTitlesSpace addObject:@"H"];	
	[indexTitlesSpace addObject:@"I"];
	[indexTitlesSpace addObject:@"J"];
	[indexTitlesSpace addObject:@"K"];
	[indexTitlesSpace addObject:@"L"];
	[indexTitlesSpace addObject:@"M"];
	[indexTitlesSpace addObject:@"N"];
	[indexTitlesSpace addObject:@"O"];
	[indexTitlesSpace addObject:@"P"];
	[indexTitlesSpace addObject:@"Q"];
	[indexTitlesSpace addObject:@"R"];
	[indexTitlesSpace addObject:@"S"];
	[indexTitlesSpace addObject:@"T"];
	[indexTitlesSpace addObject:@"U"];
	[indexTitlesSpace addObject:@"V"];
	[indexTitlesSpace addObject:@"W"];
	[indexTitlesSpace addObject:@"X"];
	[indexTitlesSpace addObject:@"Y"];
	[indexTitlesSpace addObject:@"Z"];
	
	UIWindow *window=[[UIApplication sharedApplication] keyWindow];		
	
	waitingView = [[UIView alloc] initWithFrame:CGRectMake(window.bounds.size.width/2-40,window.bounds.size.height/2-40,80,80)];
	waitingView.backgroundColor=[UIColor blackColor];//[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8f];
	waitingView.opaque=TRUE;
	waitingView.hidden=TRUE;
	waitingView.layer.cornerRadius=20;
	
	UIActivityIndicatorView *indView=[[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20,20,37,37)];
	indView.activityIndicatorViewStyle=UIActivityIndicatorViewStyleWhiteLarge;
	[waitingView addSubview:indView];
	[indView startAnimating];		
	[indView autorelease];
	
	[window addSubview:waitingView];
	
	[super viewDidLoad];
	
	end_time=clock();	
#ifdef LOAD_PROFILE
	NSLog(@"rootviewLB : %d",end_time-start_time);
#endif
}

-(void) fillKeys {	
    if (shouldFillKeys) {
		shouldFillKeys=0;						
		[self listLocalFiles];
	}
}

-(void) getFileStatsDB:(NSString *)name fullpath:(NSString *)fullpath playcount:(short int*)playcount rating:(signed char*)rating{
	NSString *pathToDB=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"],DATABASENAME_USER];
	sqlite3 *db;
	int err;	
	
	if (playcount) *playcount=0;
	if (rating) *rating=0;
	
	pthread_mutex_lock(&db_mutex);
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[1024];
		sqlite3_stmt *stmt;
		
		
		//Get playlist name
		sprintf(sqlStatement,"SELECT play_count,rating FROM user_stats WHERE name=\"%s\" and fullpath=\"%s\"",[name UTF8String],[fullpath UTF8String]);
		err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
		if (err==SQLITE_OK){
			while (sqlite3_step(stmt) == SQLITE_ROW) {
				if (playcount) *playcount=(short int)sqlite3_column_int(stmt, 0);
				if (rating) {
					*rating=(signed char)sqlite3_column_int(stmt, 1);
					if (*rating<0) *rating=0;
					if (*rating>5) *rating=5;
				}
			}
			sqlite3_finalize(stmt);
		} else NSLog(@"ErrSQL : %d",err);
		
	};
	sqlite3_close(db);
	pthread_mutex_unlock(&db_mutex);
}
-(void) getFileStatsDB:(NSString *)name fullpath:(NSString *)fullpath playcount:(short int*)playcount rating:(signed char*)rating song_length:(int*)song_length songs:(int*)songs channels_nb:(char*)channels_nb {
	NSString *pathToDB=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"],DATABASENAME_USER];
	sqlite3 *db;
	int err;	
	
	if (playcount) *playcount=0;
	if (rating) *rating=0;
	if (song_length) *song_length=0;
	if (songs) *songs=0;
	if (channels_nb) *channels_nb=0;
	
	pthread_mutex_lock(&db_mutex);
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[1024];
		sqlite3_stmt *stmt;
		
		
		//Get playlist name
		sprintf(sqlStatement,"SELECT play_count,rating,length,songs,channels FROM user_stats WHERE name=\"%s\" and fullpath=\"%s\"",[name UTF8String],[fullpath UTF8String]);
		err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
		if (err==SQLITE_OK){
			while (sqlite3_step(stmt) == SQLITE_ROW) {
				if (playcount) *playcount=(short int)sqlite3_column_int(stmt, 0);
				if (rating) {
					*rating=(signed char)sqlite3_column_int(stmt, 1);
					if (*rating<0) *rating=0;
					if (*rating>5) *rating=5;
				}
				if (song_length) *song_length=(int)sqlite3_column_int(stmt, 2);				
				if (songs) *songs=(int)sqlite3_column_int(stmt, 3);
				if (channels_nb) *channels_nb=(char)sqlite3_column_int(stmt, 4);
			}
			sqlite3_finalize(stmt);
		} else NSLog(@"ErrSQL : %d",err);
		
	};
	sqlite3_close(db);
	pthread_mutex_unlock(&db_mutex);
}

-(int) deleteStatsFileDB:(NSString*)fullpath {
	NSString *pathToDB=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"],DATABASENAME_USER];
	sqlite3 *db;
	int err,ret;	
	pthread_mutex_lock(&db_mutex);
	ret=1;
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[1024];
		
		sprintf(sqlStatement,"DELETE FROM user_stats WHERE fullpath=\"%s\"",[fullpath UTF8String]);
		err=sqlite3_exec(db, sqlStatement, NULL, NULL, NULL);
		if (err==SQLITE_OK){
		} else {ret=0;NSLog(@"ErrSQL : %d",err);}
		
	};
	sqlite3_close(db);
	pthread_mutex_unlock(&db_mutex);
	return ret;
}
-(int) deleteStatsDirDB:(NSString*)fullpath {
	NSString *pathToDB=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"],DATABASENAME_USER];
	sqlite3 *db;
	int err,ret;	
	pthread_mutex_lock(&db_mutex);
	ret=1;
	if (sqlite3_open([pathToDB UTF8String], &db) == SQLITE_OK){
		char sqlStatement[1024];
		
		sprintf(sqlStatement,"DELETE FROM user_stats WHERE fullpath like \"%s%%\"",[fullpath UTF8String]);
		err=sqlite3_exec(db, sqlStatement, NULL, NULL, NULL);
		if (err==SQLITE_OK){
		} else {ret=0;NSLog(@"ErrSQL : %d",err);}
		
	};
	sqlite3_close(db);
	pthread_mutex_unlock(&db_mutex);
	return ret;
}

-(void)listLocalFiles {
	NSString *file,*cpath;
	NSDirectoryEnumerator *dirEnum,*dirEnum2;
	NSDictionary *fileAttributes;
	NSArray *filetype_extMDX=[SUPPORTED_FILETYPE_MDX componentsSeparatedByString:@","];
	NSArray *filetype_extSID=[SUPPORTED_FILETYPE_SID componentsSeparatedByString:@","];
	NSArray *filetype_extSTSOUND=[SUPPORTED_FILETYPE_STSOUND componentsSeparatedByString:@","];
	NSArray *filetype_extSC68=[SUPPORTED_FILETYPE_SC68 componentsSeparatedByString:@","];
	NSArray *filetype_extARCHIVE=[SUPPORTED_FILETYPE_ARCHIVE componentsSeparatedByString:@","];
	NSArray *filetype_extUADE=[SUPPORTED_FILETYPE_UADE componentsSeparatedByString:@","];
	NSArray *filetype_extMODPLUG=[SUPPORTED_FILETYPE_MODPLUG componentsSeparatedByString:@","];
    NSArray *filetype_extDUMB=[SUPPORTED_FILETYPE_DUMB componentsSeparatedByString:@","];
	NSArray *filetype_extGME=[SUPPORTED_FILETYPE_GME componentsSeparatedByString:@","];
	NSArray *filetype_extADPLUG=[SUPPORTED_FILETYPE_ADPLUG componentsSeparatedByString:@","];
	NSArray *filetype_extSEXYPSF=[SUPPORTED_FILETYPE_SEXYPSF componentsSeparatedByString:@","];
	NSArray *filetype_extAOSDK=[SUPPORTED_FILETYPE_AOSDK componentsSeparatedByString:@","];
	NSArray *filetype_extHVL=[SUPPORTED_FILETYPE_HVL componentsSeparatedByString:@","];
	NSArray *filetype_extGSF=[SUPPORTED_FILETYPE_GSF componentsSeparatedByString:@","];
	NSArray *filetype_extASAP=[SUPPORTED_FILETYPE_ASAP componentsSeparatedByString:@","];
	NSArray *filetype_extWMIDI=[SUPPORTED_FILETYPE_WMIDI componentsSeparatedByString:@","];    
	NSMutableArray *filetype_ext=[NSMutableArray arrayWithCapacity:[filetype_extMDX count]+[filetype_extSID count]+[filetype_extSTSOUND count]+
								  [filetype_extSC68 count]+[filetype_extARCHIVE count]+[filetype_extUADE count]+[filetype_extMODPLUG count]+[filetype_extDUMB count]+
								  [filetype_extGME count]+[filetype_extADPLUG count]+[filetype_extSEXYPSF count]+
								  [filetype_extAOSDK count]+[filetype_extHVL count]+[filetype_extGSF count]+
								  [filetype_extASAP count]+[filetype_extWMIDI count]];
    NSArray *filetype_extARCHIVEFILE=[SUPPORTED_FILETYPE_ARCFILE componentsSeparatedByString:@","];
	NSMutableArray *archivetype_ext=[NSMutableArray arrayWithCapacity:[filetype_extARCHIVEFILE count]];
	NSArray *filetype_extGME_MULTISONGSFILE=[SUPPORTED_FILETYPE_GME_MULTISONGS componentsSeparatedByString:@","];
	NSMutableArray *gme_multisongstype_ext=[NSMutableArray arrayWithCapacity:[filetype_extGME_MULTISONGSFILE count]];
    NSArray *filetype_extSID_MULTISONGSFILE=[SUPPORTED_FILETYPE_SID componentsSeparatedByString:@","];
	NSMutableArray *sid_multisongstype_ext=[NSMutableArray arrayWithCapacity:[filetype_extSID_MULTISONGSFILE count]];
    
    NSMutableArray *all_multisongstype_ext=[NSMutableArray arrayWithCapacity:[filetype_extGME_MULTISONGSFILE count]+[filetype_extSID_MULTISONGSFILE count]];
	
	NSString *pathToDB=[NSString stringWithFormat:@"%@/%@",[NSHomeDirectory() stringByAppendingPathComponent:  @"Documents"],DATABASENAME_USER];
	sqlite3 *db;
	int err;	
	char sqlStatement[1024];
	sqlite3_stmt *stmt;
	int local_entries_index,local_nb_entries_limit;	
    int browseType;
    int shouldStop=0;
	
	NSRange r;
	// in case of search, do not ask DB again => duplicate already found entries & filter them
	search_local=0;
	if (mSearch) {
		search_local=1;
		
		if (search_local_nb_entries) {
			search_local_nb_entries=0;
			free(search_local_entries_data);
		}
		search_local_entries_data=(t_local_browse_entry*)malloc(local_nb_entries*sizeof(t_local_browse_entry));
		
		for (int i=0;i<27;i++) {
			search_local_entries_count[i]=0;
			if (local_entries_count[i]) search_local_entries[i]=&(search_local_entries_data[search_local_nb_entries]);
			for (int j=0;j<local_entries_count[i];j++)  {
				r.location=NSNotFound;
				r = [local_entries[i][j].label rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
				if  ((r.location!=NSNotFound)||([mSearchText length]==0)) {
					search_local_entries[i][search_local_entries_count[i]].label=local_entries[i][j].label;
					search_local_entries[i][search_local_entries_count[i]].fullpath=local_entries[i][j].fullpath;
					search_local_entries[i][search_local_entries_count[i]].playcount=local_entries[i][j].playcount;
					search_local_entries[i][search_local_entries_count[i]].rating=local_entries[i][j].rating;
					search_local_entries[i][search_local_entries_count[i]].type=local_entries[i][j].type;
					
					search_local_entries[i][search_local_entries_count[i]].song_length=local_entries[i][j].song_length;
					search_local_entries[i][search_local_entries_count[i]].songs=local_entries[i][j].songs;
					search_local_entries[i][search_local_entries_count[i]].channels_nb=local_entries[i][j].channels_nb;
                    
					search_local_entries_count[i]++;
					search_local_nb_entries++;
				}
			}
		}
		return;
	}
	
	pthread_mutex_lock(&db_mutex);
	if (sqlite3_open([pathToDB UTF8String], &db) != SQLITE_OK) db=NULL;
	
	[filetype_ext addObjectsFromArray:filetype_extMDX];
	[filetype_ext addObjectsFromArray:filetype_extSID];
	[filetype_ext addObjectsFromArray:filetype_extSTSOUND];
	[filetype_ext addObjectsFromArray:filetype_extSC68];
	[filetype_ext addObjectsFromArray:filetype_extARCHIVE];
	[filetype_ext addObjectsFromArray:filetype_extUADE];
	[filetype_ext addObjectsFromArray:filetype_extMODPLUG];
    [filetype_ext addObjectsFromArray:filetype_extDUMB];
	[filetype_ext addObjectsFromArray:filetype_extGME];
	[filetype_ext addObjectsFromArray:filetype_extADPLUG];
	[filetype_ext addObjectsFromArray:filetype_extSEXYPSF];
	[filetype_ext addObjectsFromArray:filetype_extAOSDK];
	[filetype_ext addObjectsFromArray:filetype_extHVL];
	[filetype_ext addObjectsFromArray:filetype_extGSF];
	[filetype_ext addObjectsFromArray:filetype_extASAP];
	[filetype_ext addObjectsFromArray:filetype_extWMIDI];
    
    [archivetype_ext addObjectsFromArray:filetype_extARCHIVEFILE];
    [gme_multisongstype_ext addObjectsFromArray:filetype_extGME_MULTISONGSFILE];
    [sid_multisongstype_ext addObjectsFromArray:filetype_extSID_MULTISONGSFILE];
    
    [all_multisongstype_ext addObjectsFromArray:filetype_extGME_MULTISONGSFILE];
    [all_multisongstype_ext addObjectsFromArray:filetype_extSID_MULTISONGSFILE];
	
	if (local_nb_entries) {
		for (int i=0;i<local_nb_entries;i++) {		
			[local_entries_data[i].label release];
			[local_entries_data[i].fullpath release];
		}
		free(local_entries_data);local_entries_data=NULL;
		local_nb_entries=0;
	}
	for (int i=0;i<27;i++) local_entries_count[i]=0;
	
	// First check count for each section
	cpath=[NSHomeDirectory() stringByAppendingPathComponent:  currentPath];
    //NSLog(@"%@\n%@",cpath,currentPath);
    //Check if it is a directory or an archive
    BOOL isDirectory;
    browseType=0;
    if ([mFileMngr fileExistsAtPath:cpath isDirectory:&isDirectory]) {        
        if (!isDirectory) {
            //file:check if archive or multisongs
            NSString *extension=[[[cpath lastPathComponent] pathExtension] uppercaseString];
            if ([archivetype_ext indexOfObject:extension]!=NSNotFound) browseType=1;
            //check if Multisongs file
            else if ([gme_multisongstype_ext indexOfObject:extension]!=NSNotFound) browseType=2;
            else if ([sid_multisongstype_ext indexOfObject:extension]!=NSNotFound) browseType=3;
        }
    }
    
    if (browseType==3) {//SID        
        SidTune *mSidTune=new SidTune([cpath UTF8String],0,true);
        
        if ((mSidTune==NULL)||(mSidTune->cache.get()==0)) {
            NSLog(@"SID SidTune init error");
            if (mSidTune) {delete mSidTune;mSidTune=NULL;}
        } else {
            SidTuneInfo sidtune_info;
            sidtune_info=mSidTune->getInfo();
            
            for (int i=0;i<sidtune_info.songs;i++){
                SidTuneInfo s_info;                 
                file=nil;
                mSidTune->selectSong(i);
                s_info=mSidTune->getInfo();
                
                if (s_info.infoString[0][0]) {
                    file=[NSString stringWithFormat:@"%.3d-%s",i,s_info.infoString[0]];
                } else {
                    file=[NSString stringWithFormat:@"%.3d-%@",i,[cpath lastPathComponent]];
                }
                int filtered=0;
                if ((mSearch)&&([mSearchText length]>0)) {
                    filtered=1;
                    NSRange r = [file rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                    if (r.location != NSNotFound) {
                        /*if(r.location== 0)*/ filtered=0;
                    }
                }
                if (!filtered) {
                    
                    const char *str=[file UTF8String];
                    int index=0;
                    if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                    if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                    local_entries_count[index]++;
                    local_nb_entries++;
                }
            }  
            if (local_nb_entries) {
                //2nd initialize array to receive entries
                local_entries_data=(t_local_browse_entry *)malloc(local_nb_entries*sizeof(t_local_browse_entry));
                if (!local_entries_data) {
                    //Not enough memory            
                    //try to allocate less entries
                    local_nb_entries_limit=LIMITED_LIST_SIZE;
                    if (local_nb_entries_limit>local_nb_entries) local_nb_entries_limit=local_nb_entries;
                    local_entries_data=(t_local_browse_entry *)malloc(local_nb_entries_limit*sizeof(t_local_browse_entry));
                    if (local_entries_data==NULL) {
                        //show alert : cannot list
                        UIAlertView *memAlert = [[[UIAlertView alloc] initWithTitle:@"Info" message:NSLocalizedString(@"Browser not enough mem.",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
                        [memAlert show];
                    } else {
                        //show alert : limited list
                        UIAlertView *memAlert = [[[UIAlertView alloc] initWithTitle:@"Info" message:NSLocalizedString(@"Browser not enough mem. Limited.",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
                        [memAlert show];
                        local_nb_entries=local_nb_entries_limit;
                    }
                } else local_nb_entries_limit=0;
                if (local_entries_data) {
                    local_entries_index=0;
                    for (int i=0;i<27;i++) 
                        if (local_entries_count[i]) {
                            if (local_entries_index+local_entries_count[i]>local_nb_entries) {
                                local_entries_count[i]=local_nb_entries-local_entries_index;
                                local_entries[i]=&(local_entries_data[local_entries_index]);
                                local_entries_index+=local_entries_count[i];
                                local_entries_count[i]=0;
                                for (int j=i+1;j<27;j++) local_entries_count[i]=0;
                            } else {
                                local_entries[i]=&(local_entries_data[local_entries_index]);
                                local_entries_index+=local_entries_count[i];                        
                                local_entries_count[i]=0;
                            }
                        }
                    
                    for (int i=0;i<sidtune_info.songs;i++){
                        SidTuneInfo s_info;                 
                        file=nil;
                        mSidTune->selectSong(i);
                        s_info=mSidTune->getInfo();
                        
                        if (s_info.infoString[0][0]) {
                            file=[NSString stringWithFormat:@"%.3d-%s",i,s_info.infoString[0]];
                        } else {
                            file=[NSString stringWithFormat:@"%.3d-%@",i,[cpath lastPathComponent]];
                        }
                        
                        int filtered=0;
                        if ((mSearch)&&([mSearchText length]>0)) {
                            filtered=1;
                            NSRange r = [file rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                            if (r.location != NSNotFound) {
                                /*if(r.location== 0)*/ filtered=0;
                            }
                        }
                        if (!filtered) {
                            
                            const char *str;
                            char tmp_str[1024];//,*tmp_convstr;
                            str=[file UTF8String];
                            int index=0;
                            if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                            if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                            local_entries[index][local_entries_count[index]].type=1;
                            local_entries[index][local_entries_count[index]].label=[[NSString alloc ] initWithString:[file lastPathComponent]];                                
                            local_entries[index][local_entries_count[index]].fullpath=[[NSString alloc] initWithFormat:@"%@?%d",currentPath,i];
                            
                            local_entries[index][local_entries_count[index]].rating=0;
                            local_entries[index][local_entries_count[index]].playcount=0;
                            local_entries[index][local_entries_count[index]].song_length=0;
                            local_entries[index][local_entries_count[index]].songs=1;//0;
                            local_entries[index][local_entries_count[index]].channels_nb=0;
                            
                            sprintf(sqlStatement,"SELECT play_count,rating,length,channels,songs FROM user_stats WHERE name=\"%s\" and fullpath=\"%s\"",[[file lastPathComponent] UTF8String],[local_entries[index][local_entries_count[index]].fullpath UTF8String]);
                            err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
                            if (err==SQLITE_OK){
                                while (sqlite3_step(stmt) == SQLITE_ROW) {
                                    signed char rating=(signed char)sqlite3_column_int(stmt, 1);
                                    if (rating<0) rating=0;
                                    if (rating>5) rating=5;
                                    local_entries[index][local_entries_count[index]].playcount=(short int)sqlite3_column_int(stmt, 0);
                                    local_entries[index][local_entries_count[index]].rating=rating;							
                                    local_entries[index][local_entries_count[index]].song_length=(int)sqlite3_column_int(stmt, 2);
                                    local_entries[index][local_entries_count[index]].channels_nb=(char)sqlite3_column_int(stmt, 3);
                                    //local_entries[index][local_entries_count[index]].songs=(int)sqlite3_column_int(stmt, 4);
                                }
                                sqlite3_finalize(stmt);
                            } else NSLog(@"ErrSQL : %d",err);
                            
                            local_entries_count[index]++;
                            
                            if (local_nb_entries_limit) {
                                local_nb_entries_limit--;
                                if (!local_nb_entries_limit) shouldStop=1;
                            }
                            
                        }
                    }                            
                }
            }
            if (mSidTune) {delete mSidTune;mSidTune=NULL;}
        }
    } else if (browseType==2) { //GME Multisongs
        // Open music file in new emulator
        Music_Emu* gme_emu;
        
        gme_err_t gme_err=gme_open_file( [cpath UTF8String], &gme_emu, gme_info_only );
        if (gme_err) {
            NSLog(@"gme_open_file error: %s",gme_err);
        } else {
            gme_info_t *gme_info;
            for (int i=0;i<gme_track_count( gme_emu );i++) {
                if (gme_track_info( gme_emu, &gme_info, i )==0) {
                    file=nil;
                    if (gme_info->song) {
                        if (gme_info->song[0]) file=[NSString stringWithFormat:@"%s",gme_info->song];
                    }
                    if (!file) {
                        if (gme_info->game) {
                            if (gme_info->game[0]) file=[NSString stringWithFormat:@"%.3d-%s",i,gme_info->game];
                        }
                    }
                    if (!file) {
                        file=[NSString stringWithFormat:@"%.3d-%@",i,[cpath lastPathComponent]];
                    }
                    
                    int filtered=0;
                    if ((mSearch)&&([mSearchText length]>0)) {
                        filtered=1;
                        NSRange r = [file rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                        if (r.location != NSNotFound) {
                            /*if(r.location== 0)*/ filtered=0;
                        }
                    }
                    if (!filtered) {
                        
                        const char *str=[file UTF8String];
                        int index=0;
                        if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                        if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                        local_entries_count[index]++;
                        local_nb_entries++;
                    }
                    gme_free_info(gme_info);
                }                            
            }
            gme_delete(gme_emu);
        }
        if (local_nb_entries) {
            //2nd initialize array to receive entries
            local_entries_data=(t_local_browse_entry *)malloc(local_nb_entries*sizeof(t_local_browse_entry));
            if (!local_entries_data) {
                //Not enough memory            
                //try to allocate less entries
                local_nb_entries_limit=LIMITED_LIST_SIZE;
                if (local_nb_entries_limit>local_nb_entries) local_nb_entries_limit=local_nb_entries;
                local_entries_data=(t_local_browse_entry *)malloc(local_nb_entries_limit*sizeof(t_local_browse_entry));
                if (local_entries_data==NULL) {
                    //show alert : cannot list
                    UIAlertView *memAlert = [[[UIAlertView alloc] initWithTitle:@"Info" message:NSLocalizedString(@"Browser not enough mem.",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
                    [memAlert show];
                } else {
                    //show alert : limited list
                    UIAlertView *memAlert = [[[UIAlertView alloc] initWithTitle:@"Info" message:NSLocalizedString(@"Browser not enough mem. Limited.",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
                    [memAlert show];
                    local_nb_entries=local_nb_entries_limit;
                }
            } else local_nb_entries_limit=0;
            if (local_entries_data) {
                local_entries_index=0;
                for (int i=0;i<27;i++) 
                    if (local_entries_count[i]) {
                        if (local_entries_index+local_entries_count[i]>local_nb_entries) {
                            local_entries_count[i]=local_nb_entries-local_entries_index;
                            local_entries[i]=&(local_entries_data[local_entries_index]);
                            local_entries_index+=local_entries_count[i];
                            local_entries_count[i]=0;
                            for (int j=i+1;j<27;j++) local_entries_count[i]=0;
                        } else {
                            local_entries[i]=&(local_entries_data[local_entries_index]);
                            local_entries_index+=local_entries_count[i];                        
                            local_entries_count[i]=0;
                        }
                    }
                
                gme_err_t gme_err=gme_open_file( [cpath UTF8String], &gme_emu, gme_info_only );
                if (gme_err) {
                    NSLog(@"gme_open_file error: %s",gme_err);
                } else {
                    gme_info_t *gme_info;
                    
                    for (int i=0;i<gme_track_count( gme_emu );i++) {
                        if (gme_track_info( gme_emu, &gme_info, i )==0) {
                            file=nil;
                            if (gme_info->song) {
                                if (gme_info->song[0]) file=[NSString stringWithFormat:@"%s",gme_info->song];
                            }
                            if (!file) {
                                if (gme_info->game) {
                                    if (gme_info->game[0]) file=[NSString stringWithFormat:@"%.3d-%s",i,gme_info->game];
                                }
                            }
                            if (!file) {
                                file=[NSString stringWithFormat:@"%.3d-%@",i,[cpath lastPathComponent]];
                            }
                            
                            int filtered=0;
                            if ((mSearch)&&([mSearchText length]>0)) {
                                filtered=1;
                                NSRange r = [file rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                                if (r.location != NSNotFound) {
                                    /*if(r.location== 0)*/ filtered=0;
                                }
                            }
                            if (!filtered) {
                                
                                const char *str;
                                char tmp_str[1024];//,*tmp_convstr;
                                str=[file UTF8String];
                                int index=0;
                                if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                                if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                                local_entries[index][local_entries_count[index]].type=1;
                                local_entries[index][local_entries_count[index]].label=[[NSString alloc ] initWithString:[file lastPathComponent]];                                
                                local_entries[index][local_entries_count[index]].fullpath=[[NSString alloc] initWithFormat:@"%@?%d",currentPath,i];
                                
                                local_entries[index][local_entries_count[index]].rating=0;
                                local_entries[index][local_entries_count[index]].playcount=0;
                                local_entries[index][local_entries_count[index]].song_length=0;
                                local_entries[index][local_entries_count[index]].songs=1;//0;
                                local_entries[index][local_entries_count[index]].channels_nb=0;
                                
                                sprintf(sqlStatement,"SELECT play_count,rating,length,channels,songs FROM user_stats WHERE name=\"%s\" and fullpath=\"%s\"",[[file lastPathComponent] UTF8String],[local_entries[index][local_entries_count[index]].fullpath UTF8String]);
                                err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
                                if (err==SQLITE_OK){
                                    while (sqlite3_step(stmt) == SQLITE_ROW) {
                                        signed char rating=(signed char)sqlite3_column_int(stmt, 1);
                                        if (rating<0) rating=0;
                                        if (rating>5) rating=5;
                                        local_entries[index][local_entries_count[index]].playcount=(short int)sqlite3_column_int(stmt, 0);
                                        local_entries[index][local_entries_count[index]].rating=rating;							
                                        local_entries[index][local_entries_count[index]].song_length=(int)sqlite3_column_int(stmt, 2);
                                        local_entries[index][local_entries_count[index]].channels_nb=(char)sqlite3_column_int(stmt, 3);
                                        //local_entries[index][local_entries_count[index]].songs=(int)sqlite3_column_int(stmt, 4);
                                    }
                                    sqlite3_finalize(stmt);
                                } else NSLog(@"ErrSQL : %d",err);
                                
                                local_entries_count[index]++;
                                
                                if (local_nb_entries_limit) {
                                    local_nb_entries_limit--;
                                    if (!local_nb_entries_limit) shouldStop=1;
                                }
                                
                            }
                            gme_free_info(gme_info);
                        }                            
                    }
                    gme_delete(gme_emu);
                }
            }	
        }
    } else if (browseType==1) { //FEX Archive (zip,7z,rar,rsn)
        fex_type_t type;
        fex_t* fex;
        const char *path=[cpath UTF8String];
        /* Determine file's type */
        if (fex_identify_file( &type, path)) {
            NSLog(@"fex cannot determine type of %s",path);
        }
        /* Only open files that fex can handle */
        if ( type != NULL ) {
            if (fex_open_type( &fex, path, type )) {
                NSLog(@"cannot fex open : %s / type : %d",path,type);
            } else {
                while ( !fex_done( fex ) ) {
                    file=[NSString stringWithFormat:@"%s",fex_name(fex)]; 
                    NSString *extension = [[file pathExtension] uppercaseString];
                    NSString *file_no_ext = [[[file lastPathComponent] stringByDeletingPathExtension] uppercaseString];
                    
                    int filtered=0;
                    if ((mSearch)&&([mSearchText length]>0)) {
                        filtered=1;
                        NSRange r = [[file lastPathComponent] rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                        if (r.location != NSNotFound) {
                            /*if(r.location== 0)*/ filtered=0;
                        }
                    }
                    if (!filtered) {
                        int found=0;
                        
                        if ([filetype_ext indexOfObject:extension]!=NSNotFound) found=1;
                        else if ([filetype_ext indexOfObject:file_no_ext]!=NSNotFound) found=1;
                        
                        if (found)  {
                            const char *str=[[file lastPathComponent] UTF8String];
                            int index=0;
                            if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                            if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                            local_entries_count[index]++;
                            local_nb_entries++;
                        }
                    }
                    
                    if (fex_next( fex )) {
                        NSLog(@"Error during fex scanning");
                        break;
                    }
                }
                fex_close( fex );
            }
            fex = NULL;
        } else {
            //NSLog( @"Skipping unsupported archive: %s\n", path );
        }
        
        if (local_nb_entries) {
            //2nd initialize array to receive entries
            local_entries_data=(t_local_browse_entry *)malloc(local_nb_entries*sizeof(t_local_browse_entry));
            if (!local_entries_data) {
                //Not enough memory            
                //try to allocate less entries
                local_nb_entries_limit=LIMITED_LIST_SIZE;
                if (local_nb_entries_limit>local_nb_entries) local_nb_entries_limit=local_nb_entries;
                local_entries_data=(t_local_browse_entry *)malloc(local_nb_entries_limit*sizeof(t_local_browse_entry));
                if (local_entries_data==NULL) {
                    //show alert : cannot list
                    UIAlertView *memAlert = [[[UIAlertView alloc] initWithTitle:@"Info" message:NSLocalizedString(@"Browser not enough mem.",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
                    [memAlert show];
                } else {
                    //show alert : limited list
                    UIAlertView *memAlert = [[[UIAlertView alloc] initWithTitle:@"Info" message:NSLocalizedString(@"Browser not enough mem. Limited.",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
                    [memAlert show];
                    local_nb_entries=local_nb_entries_limit;
                }
            } else local_nb_entries_limit=0;
            if (local_entries_data) {
                local_entries_index=0;
                for (int i=0;i<27;i++) 
                    if (local_entries_count[i]) {
                        if (local_entries_index+local_entries_count[i]>local_nb_entries) {
                            local_entries_count[i]=local_nb_entries-local_entries_index;
                            local_entries[i]=&(local_entries_data[local_entries_index]);
                            local_entries_index+=local_entries_count[i];
                            local_entries_count[i]=0;
                            for (int j=i+1;j<27;j++) local_entries_count[i]=0;
                        } else {
                            local_entries[i]=&(local_entries_data[local_entries_index]);
                            local_entries_index+=local_entries_count[i];                        
                            local_entries_count[i]=0;
                        }
                    }
                if (fex_open_type( &fex, path, type )) {
                    NSLog(@"cannot fex open : %s / type : %d",path,type);
                } else {
                    int arc_counter=0;
                    while ( !fex_done( fex ) ) {
                        file=[NSString stringWithFormat:@"%s",fex_name(fex)]; 
                        NSString *extension = [[file pathExtension] uppercaseString];
                        NSString *file_no_ext = [[[file lastPathComponent] stringByDeletingPathExtension] uppercaseString];
                        
                        int filtered=0;
                        if ((mSearch)&&([mSearchText length]>0)) {
                            filtered=1;
                            NSRange r = [[file lastPathComponent] rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                            if (r.location != NSNotFound) {
                                /*if(r.location== 0)*/ filtered=0;
                            }
                        }
                        if (!filtered) {
                            int found=0;
                            
                            if ([filetype_ext indexOfObject:extension]!=NSNotFound) found=1;
                            else if ([filetype_ext indexOfObject:file_no_ext]!=NSNotFound) found=1;
                            
                            if (found)  {
                                const char *str;
                                char tmp_str[1024];//,*tmp_convstr;
                                int toto=0;
                                str=[[file lastPathComponent] UTF8String];
                                if ([extension caseInsensitiveCompare:@"mdx"]==NSOrderedSame ) {							
                                    [[file lastPathComponent] getFileSystemRepresentation:tmp_str maxLength:1024];
                                    //tmp_convstr=mdx_make_sjis_to_syscharset(tmp_str);
                                    toto=1;
                                }
                                int index=0;
                                if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                                if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                                local_entries[index][local_entries_count[index]].type=1;
                                //check if Archive file
                                if ([archivetype_ext indexOfObject:extension]!=NSNotFound) local_entries[index][local_entries_count[index]].type=2;
                                else if ([archivetype_ext indexOfObject:file_no_ext]!=NSNotFound) local_entries[index][local_entries_count[index]].type=2;
                                //check if Multisongs file
                                if (toto) {
                                    local_entries[index][local_entries_count[index]].label=[[NSString alloc ] initWithCString:tmp_str encoding:NSUTF8StringEncoding]; 
                                    //	free(tmp_convstr);
                                } else local_entries[index][local_entries_count[index]].label=[[NSString alloc ] initWithString:[file lastPathComponent]];
                                
                                local_entries[index][local_entries_count[index]].fullpath=[[NSString alloc] initWithFormat:@"%@@%d",currentPath,arc_counter];
                                
                                local_entries[index][local_entries_count[index]].rating=0;
                                local_entries[index][local_entries_count[index]].playcount=0;
                                local_entries[index][local_entries_count[index]].song_length=0;
                                local_entries[index][local_entries_count[index]].songs=0;
                                local_entries[index][local_entries_count[index]].channels_nb=0;
                                
                                sprintf(sqlStatement,"SELECT play_count,rating,length,channels,songs FROM user_stats WHERE name=\"%s\" and fullpath=\"%s\"",[[file lastPathComponent] UTF8String],[local_entries[index][local_entries_count[index]].fullpath UTF8String]);
                                err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
                                if (err==SQLITE_OK){
                                    while (sqlite3_step(stmt) == SQLITE_ROW) {
                                        signed char rating=(signed char)sqlite3_column_int(stmt, 1);
                                        if (rating<0) rating=0;
                                        if (rating>5) rating=5;
                                        local_entries[index][local_entries_count[index]].playcount=(short int)sqlite3_column_int(stmt, 0);
                                        local_entries[index][local_entries_count[index]].rating=rating;							
                                        local_entries[index][local_entries_count[index]].song_length=(int)sqlite3_column_int(stmt, 2);
                                        local_entries[index][local_entries_count[index]].channels_nb=(char)sqlite3_column_int(stmt, 3);
                                        local_entries[index][local_entries_count[index]].songs=(int)sqlite3_column_int(stmt, 4);
                                    }
                                    sqlite3_finalize(stmt);
                                } else NSLog(@"ErrSQL : %d",err);
                                
                                local_entries_count[index]++;
                                arc_counter++;                                
                                
                                if (local_nb_entries_limit) {
                                    local_nb_entries_limit--;
                                    if (!local_nb_entries_limit) shouldStop=1;
                                }
                            }
                        }
                        if (fex_next( fex )) {
                            NSLog(@"Error during fex scanning");
                            break;
                        }
                    }
                    fex_close( fex );
                }
                fex = NULL;
            }
            
        } 
    } else {
        //        clock_t start_time,end_time;
        //        start_time=clock();	
        NSError *error;
        NSRange rdir;
        NSArray *dirContent;//
        BOOL isDir;
        if (mShowSubdir) dirContent=[mFileMngr subpathsOfDirectoryAtPath:cpath error:&error];
        else dirContent=[mFileMngr contentsOfDirectoryAtPath:cpath error:&error];
        for (file in dirContent) {
            //check if dir
            //rdir.location=NSNotFound;
            //rdir = [file rangeOfString:@"." options:NSCaseInsensitiveSearch];
            [mFileMngr fileExistsAtPath:[cpath stringByAppendingFormat:@"/%@",file] isDirectory:&isDir];
            if (isDir) { //rdir.location == NSNotFound) {  //assume it is a dir if no "." in file name
                rdir = [file rangeOfString:@"/" options:NSCaseInsensitiveSearch];
                if ((rdir.location==NSNotFound)||(mShowSubdir)) {
                    if ([file compare:@"tmpArchive"]!=NSOrderedSame) {
                        //do not display dir if subdir mode is on
                        int filtered=mShowSubdir;
                        if (!filtered) {
                            if ((mSearch)&&([mSearchText length]>0)) {
                                filtered=1;
                                NSRange r = [file rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                                if (r.location != NSNotFound) {
                                    /*if(r.location== 0)*/ filtered=0;
                                }
                            }
                            if (!filtered) {
                                const char *str=[file UTF8String];
                                int index=0;
                                if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                                if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                                local_entries_count[index]++;
                                local_nb_entries++;
                            }
                        }                
                    }
                }
            } else {
                rdir.location=NSNotFound;
                rdir = [file rangeOfString:@"/" options:NSCaseInsensitiveSearch];
                if ((rdir.location==NSNotFound)||(mShowSubdir)) {
                    NSString *extension = [[file pathExtension] uppercaseString];
                    NSString *file_no_ext = [[[file lastPathComponent] stringByDeletingPathExtension] uppercaseString];
                    
                    int filtered=0;
                    if ((mSearch)&&([mSearchText length]>0)) {
                        filtered=1;
                        NSRange r = [[file lastPathComponent] rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                        if (r.location != NSNotFound) {
                            /*if(r.location== 0)*/ filtered=0;
                        }
                    }
                    if (!filtered) {
                        int found=0;
                        
                        if ([filetype_ext indexOfObject:extension]!=NSNotFound) found=1;
                        else if ([filetype_ext indexOfObject:file_no_ext]!=NSNotFound) found=1;
                        
                        if (found)  {
                            const char *str=[[file lastPathComponent] UTF8String];
                            int index=0;
                            if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                            if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                            local_entries_count[index]++;
                            local_nb_entries++;
                        }
                    }
                }
            }
        }
        //        end_time=clock();	
        //        NSLog(@"detail1 : %d",end_time-start_time);
        //        start_time=end_time;
        
        
        if (local_nb_entries) {
            //2nd initialize array to receive entries
            local_entries_data=(t_local_browse_entry *)malloc(local_nb_entries*sizeof(t_local_browse_entry));
            if (!local_entries_data) {
                //Not enough memory            
                //try to allocate less entries
                local_nb_entries_limit=LIMITED_LIST_SIZE;
                if (local_nb_entries_limit>local_nb_entries) local_nb_entries_limit=local_nb_entries;
                local_entries_data=(t_local_browse_entry *)malloc(local_nb_entries_limit*sizeof(t_local_browse_entry));
                if (local_entries_data==NULL) {
                    //show alert : cannot list
                    UIAlertView *memAlert = [[[UIAlertView alloc] initWithTitle:@"Info" message:NSLocalizedString(@"Browser not enough mem.",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
                    [memAlert show];
                } else {
                    //show alert : limited list
                    UIAlertView *memAlert = [[[UIAlertView alloc] initWithTitle:@"Info" message:NSLocalizedString(@"Browser not enough mem. Limited.",@"") delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil] autorelease];
                    [memAlert show];
                    local_nb_entries=local_nb_entries_limit;
                }
            } else local_nb_entries_limit=0;
            if (local_entries_data) {
                local_entries_index=0;
                for (int i=0;i<27;i++) 
                    if (local_entries_count[i]) {
                        if (local_entries_index+local_entries_count[i]>local_nb_entries) {
                            local_entries_count[i]=local_nb_entries-local_entries_index;
                            local_entries[i]=&(local_entries_data[local_entries_index]);
                            local_entries_index+=local_entries_count[i];
                            local_entries_count[i]=0;
                            for (int j=i+1;j<27;j++) local_entries_count[i]=0;
                        } else {
                            local_entries[i]=&(local_entries_data[local_entries_index]);
                            local_entries_index+=local_entries_count[i];                        
                            local_entries_count[i]=0;
                        }
                    }
                
                //                end_time=clock();	
                //                NSLog(@"detail2 : %d",end_time-start_time);
                //                start_time=end_time;
                // Second check count for each section
                for (file in dirContent) {
                    if (shouldStop) break;
                    //rdir.location=NSNotFound;
                    // rdir = [file rangeOfString:@"." options:NSCaseInsensitiveSearch];
                    [mFileMngr fileExistsAtPath:[cpath stringByAppendingFormat:@"/%@",file] isDirectory:&isDir];
                    if (isDir) { //rdir.location == NSNotFound) {  //assume it is a dir if no "." in file name                    
                        rdir = [file rangeOfString:@"/" options:NSCaseInsensitiveSearch];
                        if ((rdir.location==NSNotFound)||(mShowSubdir)) {
                            if ([file compare:@"tmpArchive"]!=NSOrderedSame) {
                                //do not display dir if subdir mode is on
                                int filtered=mShowSubdir;
                                if (!filtered) {
                                    if ((mSearch)&&([mSearchText length]>0)) {
                                        filtered=1;
                                        NSRange r = [file rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                                        if (r.location != NSNotFound) {
                                            /*if(r.location== 0)*/ filtered=0;
                                        }
                                    }
                                    if (!filtered) {
                                        const char *str=[file UTF8String];
                                        int index=0;
                                        if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                                        if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                                        local_entries[index][local_entries_count[index]].type=0;												
                                        
                                        local_entries[index][local_entries_count[index]].label=[[NSString alloc] initWithString:file];
                                        local_entries[index][local_entries_count[index]].fullpath=[[NSString alloc] initWithFormat:@"%@/%@",currentPath,file];
                                        local_entries_count[index]++;
                                        if (local_nb_entries_limit) {
                                            local_nb_entries_limit--;
                                            if (!local_nb_entries_limit) shouldStop=1;
                                        }
                                    }
                                }
                            }
                        } 
                    } else {
                        rdir.location=NSNotFound;
                        rdir = [file rangeOfString:@"/" options:NSCaseInsensitiveSearch];
                        if ((rdir.location==NSNotFound)||(mShowSubdir)) {
                            NSString *extension = [[file pathExtension] uppercaseString];
                            NSString *file_no_ext = [[[file lastPathComponent] stringByDeletingPathExtension] uppercaseString];
                            
                            int filtered=0;
                            if ((mSearch)&&([mSearchText length]>0)) {
                                filtered=1;
                                NSRange r = [[file lastPathComponent] rangeOfString:mSearchText options:NSCaseInsensitiveSearch];
                                if (r.location != NSNotFound) {
                                    /*if(r.location== 0)*/ filtered=0;
                                }
                            }
                            if (!filtered) {
                                int found=0;
                                
                                if ([filetype_ext indexOfObject:extension]!=NSNotFound) found=1;
                                else if ([filetype_ext indexOfObject:file_no_ext]!=NSNotFound) found=1;
                                
                                
                                if (found)  {
                                    const char *str;
                                    char tmp_str[1024];//,*tmp_convstr;
                                    int toto=0;
                                    str=[[file lastPathComponent] UTF8String];
                                    if ([extension caseInsensitiveCompare:@"mdx"]==NSOrderedSame ) {							
                                        [[file lastPathComponent] getFileSystemRepresentation:tmp_str maxLength:1024];
                                        //tmp_convstr=mdx_make_sjis_to_syscharset(tmp_str);
                                        toto=1;
                                    }
                                    int index=0;
                                    if ((str[0]>='A')&&(str[0]<='Z') ) index=(str[0]-'A'+1);
                                    if ((str[0]>='a')&&(str[0]<='z') ) index=(str[0]-'a'+1);
                                    local_entries[index][local_entries_count[index]].type=1;
                                    //check if Archive file
                                    if ([archivetype_ext indexOfObject:extension]!=NSNotFound) local_entries[index][local_entries_count[index]].type=2;
                                    else if ([archivetype_ext indexOfObject:file_no_ext]!=NSNotFound) local_entries[index][local_entries_count[index]].type=2;
                                    //check if Multisongs file
                                    else if ([all_multisongstype_ext indexOfObject:extension]!=NSNotFound) local_entries[index][local_entries_count[index]].type=3;
                                    else if ([all_multisongstype_ext indexOfObject:file_no_ext]!=NSNotFound) local_entries[index][local_entries_count[index]].type=3;
                                    if (toto) {
                                        local_entries[index][local_entries_count[index]].label=[[NSString alloc ] initWithCString:tmp_str encoding:NSUTF8StringEncoding]; 
                                        //	free(tmp_convstr);
                                    } else local_entries[index][local_entries_count[index]].label=[[NSString alloc ] initWithString:[file lastPathComponent]];
                                    
                                    local_entries[index][local_entries_count[index]].fullpath=[[NSString alloc] initWithFormat:@"%@/%@",currentPath,file];
                                    
                                    local_entries[index][local_entries_count[index]].rating=0;
                                    local_entries[index][local_entries_count[index]].playcount=0;
                                    local_entries[index][local_entries_count[index]].song_length=0;
                                    local_entries[index][local_entries_count[index]].songs=0;
                                    local_entries[index][local_entries_count[index]].channels_nb=0;
                                    
                                    sprintf(sqlStatement,"SELECT play_count,rating,length,channels,songs FROM user_stats WHERE name=\"%s\" and fullpath=\"%s/%s\"",[[file lastPathComponent] UTF8String],[currentPath UTF8String],[file UTF8String]);
                                    err=sqlite3_prepare_v2(db, sqlStatement, -1, &stmt, NULL);
                                    if (err==SQLITE_OK){
                                        while (sqlite3_step(stmt) == SQLITE_ROW) {
                                            signed char rating=(signed char)sqlite3_column_int(stmt, 1);
                                            if (rating<0) rating=0;
                                            if (rating>5) rating=5;
                                            local_entries[index][local_entries_count[index]].playcount=(short int)sqlite3_column_int(stmt, 0);
                                            local_entries[index][local_entries_count[index]].rating=rating;							
                                            local_entries[index][local_entries_count[index]].song_length=(int)sqlite3_column_int(stmt, 2);
                                            local_entries[index][local_entries_count[index]].channels_nb=(char)sqlite3_column_int(stmt, 3);
                                            local_entries[index][local_entries_count[index]].songs=(int)sqlite3_column_int(stmt, 4);
                                        }
                                        sqlite3_finalize(stmt);
                                    } else NSLog(@"ErrSQL : %d",err);
                                    
                                    local_entries_count[index]++;
                                    
                                    if (local_nb_entries_limit) {
                                        local_nb_entries_limit--;
                                        if (!local_nb_entries_limit) shouldStop=1;
                                    }
                                }
                            }
                        }
                    }
                }                
                //                end_time=clock();	
                //                NSLog(@"detail1 : %d",end_time-start_time);
            }
        }
    }
    
    if (db) {
        sqlite3_close(db);
        pthread_mutex_unlock(&db_mutex);
    }
    
    
    return;
}

-(void) viewWillAppear:(BOOL)animated {
    if (keys) {
        [keys release]; 
        keys=nil;
    }
    if (list) {
        [list release]; 
        list=nil;
    }
    if (childController) {
        [childController release];
        childController = NULL;
    } 
    
    //Reset rating if applicable (ensure updated value)
    if (local_nb_entries) {
        for (int i=0;i<local_nb_entries;i++) {
            local_entries_data[i].rating=-1;
        }            
    }
    if (search_local_nb_entries) {
        for (int i=0;i<search_local_nb_entries;i++) {
            search_local_entries_data[i].rating=-1;
        }            
    }
    /////////////
    if (detailViewController.mShouldHaveFocus) {
        detailViewController.mShouldHaveFocus=0;
        [self.navigationController pushViewController:detailViewController animated:(mSlowDevice?NO:YES)];
    } else {				
        if (shouldFillKeys&&(browse_depth>0)) {
            [self performSelectorInBackground:@selector(showWaiting) withObject:nil];
            [self fillKeys];
            [[super tableView] reloadData];
            [self performSelectorInBackground:@selector(hideWaiting) withObject:nil];
        } else {
            [self fillKeys];
            [[super tableView] reloadData];
        }
    }
    [super viewWillAppear:animated];	
    
}
-(void) refreshMODLANDView {
}

- (void)viewDidAppear:(BOOL)animated {        
    [self performSelectorInBackground:@selector(hideWaiting) withObject:nil];
    
    [super viewDidAppear:animated];		
}

-(void)hideAllWaitingPopup {
    [self performSelectorInBackground:@selector(hideWaiting) withObject:nil];
    if (childController) {
        [childController hideAllWaitingPopup];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [self performSelectorInBackground:@selector(hideWaiting) withObject:nil];
    if (childController) {
        [childController viewDidDisappear:FALSE];
    }
    [super viewDidDisappear:animated];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    [[super tableView] reloadData];
}

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    [[super tableView] reloadData];
    return YES;
}

#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (browse_depth==0) return nil;
    if (mSearch) return nil;	
    int switch_view_subdir=(browse_depth>=1?1:0);		
    
    if (section==0) return nil;
    if ((section==1)&&switch_view_subdir) return @"";
    if ((search_local?search_local_entries_count[section-1-switch_view_subdir]:local_entries_count[section-1-switch_view_subdir])) {
        if (switch_view_subdir) return [indexTitlesSpace objectAtIndex:section];	
        return [indexTitles objectAtIndex:section];
    } else return nil;
    if (browse_depth>=2) return [indexTitles objectAtIndex:section];
    return nil;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    local_flag=0;
    
    if (browse_depth==0) return [keys count];
    int switch_view_subdir=(browse_depth>=SHOW_SUDIR_MIN_LEVEL?1:0);
    if (switch_view_subdir) return 28+1;
    return 28;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (browse_depth>=1) {//local browser
        int switch_view_subdir=(browse_depth>=SHOW_SUDIR_MIN_LEVEL?1:0);
        if (section==0) return 0;
        if ((section==1)&&switch_view_subdir) return 1;
        return (search_local?search_local_entries_count[section-1-switch_view_subdir]:local_entries_count[section-1-switch_view_subdir]);
    } else {
        NSDictionary *dictionary = [keys objectAtIndex:section];
        NSArray *array = [dictionary objectForKey:@"entries"];
        return [array count];
    }
}
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (browse_depth==0) return nil;
    if (mSearch) return nil;	
    int switch_view_subdir=(browse_depth>=SHOW_SUDIR_MIN_LEVEL?1:0);
    if (switch_view_subdir) return indexTitlesSpace;
    return indexTitles;    
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (mSearch) return -1;
    if (index == 0) {
        [tableView setContentOffset:CGPointZero animated:NO];
        return NSNotFound;
    }
    return index;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSString *cellValue;
    const NSInteger TOP_LABEL_TAG = 1001;
    const NSInteger BOTTOM_LABEL_TAG = 1002;
    const NSInteger BOTTOM_IMAGE_TAG = 1003;
    const NSInteger ACT_IMAGE_TAG = 1004;
    const NSInteger SECACT_IMAGE_TAG = 1005;
    UILabel *topLabel;
    UILabel *bottomLabel;
    UIImageView *bottomImageView;
    UIButton *actionView,*secActionView;
    t_local_browse_entry **cur_local_entries=(search_local?search_local_entries:local_entries);
    NSString *playedXtimes=NSLocalizedString(@"Played %d times.",@"");
    NSString *played1time=NSLocalizedString(@"Played once.",@"");	
    NSString *played0time=NSLocalizedString(@"Never played.",@"");	
    NSString *nbFiles=NSLocalizedString(@"%d files.",@"");	
    NSString *nb1File=NSLocalizedString(@"1 file.",@"");	
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
        //
        // Create the label for the top row of text
        //
        topLabel = [[[UILabel alloc] init] autorelease];
        [cell.contentView addSubview:topLabel];
        
        //
        // Configure the properties for the text that are the same on every row
        //
        topLabel.tag = TOP_LABEL_TAG;
        topLabel.backgroundColor = [UIColor clearColor];
        topLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
        topLabel.highlightedTextColor = [UIColor colorWithRed:1.0 green:1.0 blue:0.9 alpha:1.0];
        topLabel.font = [UIFont boldSystemFontOfSize:20];
        topLabel.lineBreakMode=UILineBreakModeMiddleTruncation;
        topLabel.opaque=TRUE;
        
        //
        // Create the label for the top row of text
        //
        bottomLabel = [[[UILabel alloc] init] autorelease];
        [cell.contentView addSubview:bottomLabel];
        //
        // Configure the properties for the text that are the same on every row
        //
        bottomLabel.tag = BOTTOM_LABEL_TAG;
        bottomLabel.backgroundColor = [UIColor clearColor];
        bottomLabel.textColor = [UIColor colorWithRed:0.25 green:0.20 blue:0.20 alpha:1.0];
        bottomLabel.highlightedTextColor = [UIColor colorWithRed:0.75 green:0.8 blue:0.8 alpha:1.0];
        bottomLabel.font = [UIFont systemFontOfSize:12];
        //bottomLabel.font = [UIFont fontWithName:@"courier" size:12];
        bottomLabel.lineBreakMode=UILineBreakModeMiddleTruncation;
        bottomLabel.opaque=TRUE;
        
        
        bottomImageView = [[[UIImageView alloc] initWithImage:nil]  autorelease];
        bottomImageView.frame = CGRectMake(1.0*cell.indentationWidth,
                                           26,
                                           50,9);
        bottomImageView.tag = BOTTOM_IMAGE_TAG;
        bottomImageView.opaque=TRUE;
        [cell.contentView addSubview:bottomImageView];
        
        actionView                = [UIButton buttonWithType: UIButtonTypeCustom];
        [cell.contentView addSubview:actionView];
        actionView.tag = ACT_IMAGE_TAG;        
        
        secActionView                = [UIButton buttonWithType: UIButtonTypeCustom];
        [cell.contentView addSubview:secActionView];
        secActionView.tag = SECACT_IMAGE_TAG;
        
        cell.accessoryView=nil;
        cell.selectionStyle=UITableViewCellSelectionStyleGray;
    } else {
        topLabel = (UILabel *)[cell viewWithTag:TOP_LABEL_TAG];
        bottomLabel = (UILabel *)[cell viewWithTag:BOTTOM_LABEL_TAG];
        bottomImageView = (UIImageView *)[cell viewWithTag:BOTTOM_IMAGE_TAG];
        actionView = (UIButton *)[cell viewWithTag:ACT_IMAGE_TAG];
        secActionView = (UIButton *)[cell viewWithTag:SECACT_IMAGE_TAG];
    }
    actionView.hidden=TRUE;
    secActionView.hidden=TRUE;
    
    topLabel.frame= CGRectMake(1.0 * cell.indentationWidth,
                               0,
                               tableView.bounds.size.width -1.0 * cell.indentationWidth- 32,
                               22);
    bottomLabel.frame = CGRectMake(1.0 * cell.indentationWidth,
                                   22,
                                   tableView.bounds.size.width -1.0 * cell.indentationWidth-32,
                                   18);
    bottomLabel.text=@""; //default value
    bottomImageView.image=nil;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    // Set up the cell...
    int switch_view_subdir=( (browse_depth>=SHOW_SUDIR_MIN_LEVEL));
    if (switch_view_subdir&&(indexPath.section==1)){
        cellValue=(mShowSubdir?NSLocalizedString(@"DisplayDir_MainKey",""):NSLocalizedString(@"DisplayAll_MainKey",""));
        bottomLabel.text=[NSString stringWithFormat:@"%@ %d entries",(mShowSubdir?NSLocalizedString(@"DisplayDir_SubKey",""):NSLocalizedString(@"DisplayAll_SubKey","")),(search_local?search_local_nb_entries:local_nb_entries)];
        
        bottomLabel.frame = CGRectMake( 1.0 * cell.indentationWidth,
                                       22,
                                       tableView.bounds.size.width -1.0 * cell.indentationWidth-32-PRI_SEC_ACTIONS_IMAGE_SIZE-60,
                                       18);
        
        topLabel.textColor=[UIColor colorWithRed:0.4f green:0.4f blue:0.9f alpha:1.0];			
        
        topLabel.frame= CGRectMake(1.0 * cell.indentationWidth,
                                   0,
                                   tableView.bounds.size.width -1.0 * cell.indentationWidth- 32-PRI_SEC_ACTIONS_IMAGE_SIZE-4-PRI_SEC_ACTIONS_IMAGE_SIZE,
                                   22);
        
        
        
        [secActionView setImage:[UIImage imageNamed:@"playlist_add_all.png"] forState:UIControlStateNormal];
        [secActionView setImage:[UIImage imageNamed:@"playlist_add_all.png"] forState:UIControlStateHighlighted];
        [secActionView addTarget: self action: @selector(secondaryActionTapped:) forControlEvents: UIControlEventTouchUpInside];
        
        [actionView setImage:[UIImage imageNamed:@"play_all.png"] forState:UIControlStateNormal];
        [actionView setImage:[UIImage imageNamed:@"play_all.png"] forState:UIControlStateHighlighted];
        [actionView addTarget: self action: @selector(primaryActionTapped:) forControlEvents: UIControlEventTouchUpInside];
        
        int icon_posx=tableView.bounds.size.width-2-PRI_SEC_ACTIONS_IMAGE_SIZE;
        icon_posx-=32;
        actionView.frame = CGRectMake(icon_posx,0,PRI_SEC_ACTIONS_IMAGE_SIZE,PRI_SEC_ACTIONS_IMAGE_SIZE);
        actionView.enabled=YES;
        actionView.hidden=NO;
        secActionView.frame = CGRectMake(icon_posx-PRI_SEC_ACTIONS_IMAGE_SIZE-4,0,PRI_SEC_ACTIONS_IMAGE_SIZE,PRI_SEC_ACTIONS_IMAGE_SIZE);
        secActionView.enabled=YES;
        secActionView.hidden=NO;
        
    } else {
        int section=indexPath.section-1-switch_view_subdir;
        cellValue=cur_local_entries[section][indexPath.row].label;
        
        
        if (cur_local_entries[section][indexPath.row].type==0) { //directory
            topLabel.textColor=[UIColor colorWithRed:0.0f green:0.0f blue:1.0f alpha:1.0f];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;				
            topLabel.frame= CGRectMake(1.0 * cell.indentationWidth,
                                       0,
                                       tableView.bounds.size.width -1.0 * cell.indentationWidth- 32-32,
                                       ROW_HEIGHT);
            
        } else  { //file
            int actionicon_offsetx=0;
            //archive file ?
            if ((cur_local_entries[section][indexPath.row].type==2)||(cur_local_entries[section][indexPath.row].type==3)) {
                actionicon_offsetx=PRI_SEC_ACTIONS_IMAGE_SIZE;
                //                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;                    
                
                secActionView.frame = CGRectMake(tableView.bounds.size.width-2-32-PRI_SEC_ACTIONS_IMAGE_SIZE,0,PRI_SEC_ACTIONS_IMAGE_SIZE,PRI_SEC_ACTIONS_IMAGE_SIZE);
                
                [secActionView setImage:[UIImage imageNamed:@"arc_details.png"] forState:UIControlStateNormal];
                [secActionView setImage:[UIImage imageNamed:@"arc_details.png"] forState:UIControlStateHighlighted];
                [secActionView removeTarget: self action:NULL forControlEvents: UIControlEventTouchUpInside];
                [secActionView addTarget: self action: @selector(accessoryActionTapped:) forControlEvents: UIControlEventTouchUpInside];
                
                secActionView.enabled=YES;
                secActionView.hidden=NO;
                
            }
            
            
            topLabel.textColor=[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
            
            topLabel.frame= CGRectMake(1.0 * cell.indentationWidth,
                                       0,
                                       tableView.bounds.size.width -1.0 * cell.indentationWidth- 32-PRI_SEC_ACTIONS_IMAGE_SIZE-actionicon_offsetx,
                                       22);
            
            actionView.frame = CGRectMake(tableView.bounds.size.width-2-32-PRI_SEC_ACTIONS_IMAGE_SIZE-actionicon_offsetx,0,PRI_SEC_ACTIONS_IMAGE_SIZE,PRI_SEC_ACTIONS_IMAGE_SIZE);
            
            if (detailViewController.sc_DefaultAction.selectedSegmentIndex==0) {
                [actionView setImage:[UIImage imageNamed:@"playlist_add.png"] forState:UIControlStateNormal];
                [actionView setImage:[UIImage imageNamed:@"playlist_add.png"] forState:UIControlStateHighlighted];
                [actionView removeTarget: self action:NULL forControlEvents: UIControlEventTouchUpInside];
                [actionView addTarget: self action: @selector(secondaryActionTapped:) forControlEvents: UIControlEventTouchUpInside];
            } else {
                [actionView setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
                [actionView setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateHighlighted];
                [actionView removeTarget: self action:NULL forControlEvents: UIControlEventTouchUpInside];
                [actionView addTarget: self action: @selector(primaryActionTapped:) forControlEvents: UIControlEventTouchUpInside];
            }
            actionView.enabled=YES;
            actionView.hidden=NO;
            
            
            if (cur_local_entries[section][indexPath.row].rating==-1) {
                [self getFileStatsDB:cur_local_entries[section][indexPath.row].label
                            fullpath:cur_local_entries[section][indexPath.row].fullpath
                           playcount:&cur_local_entries[section][indexPath.row].playcount
                              rating:&cur_local_entries[section][indexPath.row].rating
                         song_length:&cur_local_entries[section][indexPath.row].song_length									 
                               songs:&cur_local_entries[section][indexPath.row].songs
                         channels_nb:&cur_local_entries[section][indexPath.row].channels_nb];
            }
            if (cur_local_entries[section][indexPath.row].rating>=0) bottomImageView.image=[UIImage imageNamed:ratingImg[cur_local_entries[section][indexPath.row].rating]];
            
            NSString *bottomStr;
            int isMonoSong=cur_local_entries[section][indexPath.row].songs==1;
            if (isMonoSong) {
                if (cur_local_entries[section][indexPath.row].song_length>0)
                    bottomStr=[NSString stringWithFormat:@"%02d:%02d",cur_local_entries[section][indexPath.row].song_length/1000/60,(cur_local_entries[section][indexPath.row].song_length/1000)%60];
                else bottomStr=@"--:--";
            } else bottomStr=@"--:--";
            
            if (isMonoSong) {
                if (cur_local_entries[section][indexPath.row].channels_nb)
                    bottomStr=[NSString stringWithFormat:@"%@ / %02dch",bottomStr,cur_local_entries[section][indexPath.row].channels_nb];
                else bottomStr=[NSString stringWithFormat:@"%@ / --ch",bottomStr];
            } else bottomStr=[NSString stringWithFormat:@"%@ / --ch",bottomStr];
            
            if (isMonoSong) {
                if (cur_local_entries[section][indexPath.row].songs==1) bottomStr=[NSString stringWithFormat:@"%@ / 1 song",bottomStr];
                else bottomStr=[NSString stringWithFormat:@"%@ / - song",bottomStr];
            } else {
                if (cur_local_entries[section][indexPath.row].songs>0)
                    bottomStr=[NSString stringWithFormat:@"%@ / %d songs",bottomStr,cur_local_entries[section][indexPath.row].songs];
                else
                    bottomStr=[NSString stringWithFormat:@"%@ / %d files",bottomStr,-cur_local_entries[section][indexPath.row].songs];
            }                								
            
            
            bottomStr=[NSString stringWithFormat:@"%@ / Pl:%d",bottomStr,cur_local_entries[section][indexPath.row].playcount];
            
            
            /*if (!cur_local_entries[section][indexPath.row].playcount) 
             bottomStr = [NSString stringWithFormat:@"%@%@",bottomStr,played0time]; 
             else if (cur_local_entries[section][indexPath.row].playcount==1) 
             bottomStr = [NSString stringWithFormat:@"%@%@",bottomStr,played1time];
             else bottomStr = [NSString stringWithFormat:@"%@%@",bottomStr,[NSString stringWithFormat:playedXtimes,cur_local_entries[section][indexPath.row].playcount]];*/
            
            bottomLabel.text=bottomStr;
            
            bottomLabel.frame = CGRectMake( 1.0 * cell.indentationWidth+60,
                                           22,
                                           tableView.bounds.size.width -1.0 * cell.indentationWidth-32-PRI_SEC_ACTIONS_IMAGE_SIZE-60-actionicon_offsetx,
                                           18);
            
        }
    }
    
    topLabel.text = cellValue;
    
    return cell;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    t_local_browse_entry **cur_local_entries=(search_local?search_local_entries:local_entries);
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        //delete entry
        
        if (browse_depth>=1) {  //Local browse mode ?
            int switch_view_subdir=(browse_depth>=SHOW_SUDIR_MIN_LEVEL?1:0);
            int section=indexPath.section-1-switch_view_subdir;
            NSString *fullpath=[NSHomeDirectory() stringByAppendingPathComponent:cur_local_entries[section][indexPath.row].fullpath];
            NSError *err;
            
            if (cur_local_entries[section][indexPath.row].type==0) { //Dir
                [self deleteStatsDirDB:fullpath];
            }
            if (cur_local_entries[section][indexPath.row].type&3) { //File
                [self deleteStatsFileDB:fullpath];
            }
            
            [mFileMngr removeItemAtPath:fullpath error:&err];
            
            [self listLocalFiles];						
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView reloadData];
        }
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}
/*- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {    
 return proposedDestinationIndexPath;
 }*/
// Override to support rearranging the table view.
/*- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 
 }*/
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.    
    return NO;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    if (browse_depth>=1) return YES;
    return NO;
}

#pragma mark UISearchBarDelegate
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    // only show the status bar’s cancel button while in edit mode
    sBar.showsCancelButton = YES;
    sBar.autocorrectionType = UITextAutocorrectionTypeNo;
    mSearch=1;
    // flush the previous search content
    //[tableData removeAllObjects];
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    //[self fillKeys];
    //[[super tableView] reloadData];
    //mSearch=0;
    sBar.showsCancelButton = NO;
}
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (mSearchText) [mSearchText release];
    
    mSearchText=[[NSString alloc] initWithString:searchText];
    shouldFillKeys=1;
    [self fillKeys];
    [[super tableView] reloadData];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    if (mSearchText) [mSearchText release];
    mSearchText=nil;
    sBar.text=nil;
    mSearch=0;
    sBar.showsCancelButton = NO;
    [searchBar resignFirstResponder];
    
    [[super tableView] reloadData];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [theTextField resignFirstResponder];
    [self validatePlaylistName];
    return YES;
}

-(IBAction)goPlayer {
    [self.navigationController pushViewController:detailViewController animated:(mSlowDevice?NO:YES)];
}

#pragma mark -
#pragma mark Table view delegate
- (void) primaryActionTapped: (UIButton*) sender {
    NSIndexPath *indexPath = [[super tableView] indexPathForRowAtPoint:[[[sender superview] superview] center]];
    t_local_browse_entry **cur_local_entries=(search_local?search_local_entries:local_entries);
    
    [[super tableView] selectRowAtIndexPath:indexPath animated:FALSE scrollPosition:UITableViewScrollPositionNone];
    
    [self performSelectorInBackground:@selector(showWaiting) withObject:nil];                
    
    
    if (browse_depth==0) {
        
    } else {         
        int switch_view_subdir=((browse_depth>=SHOW_SUDIR_MIN_LEVEL));
        int section=indexPath.section-1-switch_view_subdir;
        
        if (indexPath.section==1) {
            // launch Play of current list
            int pos=0;
            int total_entries=0;
            NSMutableArray *array_label = [[[NSMutableArray alloc] init] autorelease];
            NSMutableArray *array_path = [[[NSMutableArray alloc] init] autorelease];
            for (int i=0;i<27;i++) 
                for (int j=0;j<(search_local?search_local_entries_count[i]:local_entries_count[i]);j++)
                    if (cur_local_entries[i][j].type&3) {
                        total_entries++;
                        [array_label addObject:cur_local_entries[i][j].label];
                        [array_path addObject:cur_local_entries[i][j].fullpath];
                        if (i<section) pos++;
                        else if (i==(section))
                            if (j<indexPath.row) pos++;
                    }
            
            signed char *tmp_ratings;
            short int *tmp_playcounts;
            tmp_ratings=(signed char*)malloc(total_entries*sizeof(signed char));
            tmp_playcounts=(short int*)malloc(total_entries*sizeof(short int));
            total_entries=0;
            for (int i=0;i<27;i++) 
                for (int j=0;j<(search_local?search_local_entries_count[i]:local_entries_count[i]);j++)
                    if (cur_local_entries[i][j].type&3) {
                        tmp_ratings[total_entries]=cur_local_entries[i][j].rating;
                        tmp_playcounts[total_entries++]=cur_local_entries[i][j].playcount;
                    }			
            
            //cur_local_entries[section][indexPath.row].rating=-1;
            
            if (section<0) pos=-1;
            [detailViewController play_listmodules:array_label start_index:pos path:array_path ratings:tmp_ratings playcounts:tmp_playcounts];
            if (detailViewController.sc_PlayerViewOnPlay.selectedSegmentIndex) [self goPlayer];
            else [[super tableView] reloadData];				
            
            free(tmp_ratings);
            free(tmp_playcounts);
            
            
        } else {            
            if (cur_local_entries[section][indexPath.row].type&3) {//File selected
                // launch Play of current dir
                int pos=0;
                int total_entries=0;
                NSMutableArray *array_label = [[[NSMutableArray alloc] init] autorelease];
                NSMutableArray *array_path = [[[NSMutableArray alloc] init] autorelease];
                /*for (int i=0;i<27;i++) 
                 for (int j=0;j<(search_local?search_local_entries_count[i]:local_entries_count[i]);j++)
                 if (cur_local_entries[i][j].type==1) {
                 total_entries++;
                 [array_label addObject:cur_local_entries[i][j].label];
                 [array_path addObject:cur_local_entries[i][j].fullpath];
                 if (i<section) pos++;
                 else if (i==(section))
                 if (j<indexPath.row) pos++;
                 }*/
                [array_label addObject:cur_local_entries[section][indexPath.row].label];
                [array_path addObject:cur_local_entries[section][indexPath.row].fullpath];
                total_entries=1;
                
                signed char *tmp_ratings;
                short int *tmp_playcounts;
                tmp_ratings=(signed char*)malloc(total_entries*sizeof(signed char));
                tmp_playcounts=(short int*)malloc(total_entries*sizeof(short int));
                /*total_entries=0;
                 for (int i=0;i<27;i++) 
                 for (int j=0;j<(search_local?search_local_entries_count[i]:local_entries_count[i]);j++)
                 if (cur_local_entries[i][j].type==1) {
                 tmp_ratings[total_entries]=cur_local_entries[i][j].rating;
                 tmp_playcounts[total_entries++]=cur_local_entries[i][j].playcount;
                 }			
                 */
                tmp_ratings[0]=cur_local_entries[section][indexPath.row].rating;
                tmp_playcounts[0]=cur_local_entries[section][indexPath.row].playcount;
                
                
                
                cur_local_entries[section][indexPath.row].rating=-1;
                [detailViewController play_listmodules:array_label start_index:pos path:array_path ratings:tmp_ratings playcounts:tmp_playcounts];
                if (detailViewController.sc_PlayerViewOnPlay.selectedSegmentIndex) [self goPlayer];
                else [[super tableView] reloadData];				
                
                free(tmp_ratings);
                free(tmp_playcounts);
                
            }
        }
    } 
    
    [self performSelectorInBackground:@selector(hideWaiting) withObject:nil];
    
    
}
- (void) secondaryActionTapped: (UIButton*) sender {
    NSIndexPath *indexPath = [[super tableView] indexPathForRowAtPoint:[[[sender superview] superview] center]];
    t_local_browse_entry **cur_local_entries=(search_local?search_local_entries:local_entries);
    
    [[super tableView] selectRowAtIndexPath:indexPath animated:FALSE scrollPosition:UITableViewScrollPositionNone];
    
    [self performSelectorInBackground:@selector(showWaiting) withObject:nil];                
    
    
    if (browse_depth==0) {
    } else {
        //local  browser & favorites
        int switch_view_subdir=((browse_depth>=SHOW_SUDIR_MIN_LEVEL));
        int section=indexPath.section-1-switch_view_subdir;
        if (indexPath.section==1) {
            // launch Play of current dir
            int pos=0;
            int total_entries=0;
            NSMutableArray *array_label = [[[NSMutableArray alloc] init] autorelease];
            NSMutableArray *array_path = [[[NSMutableArray alloc] init] autorelease];
            for (int i=0;i<27;i++) 
                for (int j=0;j<(search_local?search_local_entries_count[i]:local_entries_count[i]);j++)
                    if (cur_local_entries[i][j].type&3) {
                        total_entries++;
                        [array_label addObject:cur_local_entries[i][j].label];
                        [array_path addObject:cur_local_entries[i][j].fullpath];
                        if (i<section) pos++;
                        else if (i==(section))
                            if (j<indexPath.row) pos++;
                    }
            
            signed char *tmp_ratings;
            short int *tmp_playcounts;
            tmp_ratings=(signed char*)malloc(total_entries*sizeof(signed char));
            tmp_playcounts=(short int*)malloc(total_entries*sizeof(short int));
            total_entries=0;
            for (int i=0;i<27;i++) 
                for (int j=0;j<(search_local?search_local_entries_count[i]:local_entries_count[i]);j++)
                    if (cur_local_entries[i][j].type&3) {
                        tmp_ratings[total_entries]=cur_local_entries[i][j].rating;
                        tmp_playcounts[total_entries++]=cur_local_entries[i][j].playcount;
                    }			
            
            if ([detailViewController add_to_playlist:array_path fileNames:array_label forcenoplay:1]) {
                if (detailViewController.sc_PlayerViewOnPlay.selectedSegmentIndex) [self goPlayer];
                else [[super tableView] reloadData];
            }
            
            free(tmp_ratings);
            free(tmp_playcounts);                                
            
        } else {            
            if (cur_local_entries[section][indexPath.row].type&3) {//File selected
                cur_local_entries[section][indexPath.row].rating=-1;
                if ([detailViewController add_to_playlist:cur_local_entries[section][indexPath.row].fullpath fileName:cur_local_entries[section][indexPath.row].label forcenoplay:1]) {
                    if (detailViewController.sc_PlayerViewOnPlay.selectedSegmentIndex) [self goPlayer];
                    else [[super tableView] reloadData];
                }
            }
        }
    }
    [self performSelectorInBackground:@selector(hideWaiting) withObject:nil];
}


- (void) accessoryActionTapped: (UIButton*) sender {
    NSIndexPath *indexPath = [[super tableView] indexPathForRowAtPoint:[[[sender superview] superview] center]];
    [[super tableView] selectRowAtIndexPath:indexPath animated:FALSE scrollPosition:UITableViewScrollPositionNone];
    
    mAccessoryButton=1;
    [self tableView:[super tableView] didSelectRowAtIndexPath:indexPath];
}


-(void) fillKeysSearchWithPopup {
    int old_mSearch=mSearch;
    NSString *old_mSearchText=mSearchText;
    mSearch=0;
    mSearchText=nil;
    [self fillKeys];   //1st load eveything
    mSearch=old_mSearch;
    mSearchText=old_mSearchText;
    if (mSearch) {
        shouldFillKeys=1;
        [self fillKeys];   //2nd filter for drawing
    }
    [[super tableView] reloadData];
}

-(void) fillKeysWithPopup {
    [self fillKeys];
    [[super tableView] reloadData];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    //First get the dictionary object
    NSString *cellValue;
    t_local_browse_entry **cur_local_entries=(search_local?search_local_entries:local_entries);
    
    //HACK to avoid BUG in iOS => if searchbar is not visible (scrolled), it will disappear when going back from child
    /*if (mSearch) {
     int i;
     for (i=0;i<=indexPath.section;i++)
     if ([tableView numberOfRowsInSection:i]) break;
     NSIndexPath *myindex=[NSIndexPath indexPathForRow:0 inSection:i];
     [tableView selectRowAtIndexPath:myindex animated:FALSE scrollPosition:UITableViewScrollPositionMiddle];
     }*/
    
    if (browse_depth==0) {
        NSDictionary *dictionary = [keys objectAtIndex:indexPath.section];
        NSArray *array = [dictionary objectForKey:@"entries"];
        cellValue = [array objectAtIndex:indexPath.row];
        
        
        if (childController == nil) childController = [[RootViewControllerLocalBrowser alloc]  initWithNibName:@"RootViewController" bundle:[NSBundle mainBundle]];
        else {			// Don't cache childviews
        }
        //set new title
        childController.title = cellValue;
        // Set new directory
        ((RootViewControllerLocalBrowser*)childController)->browse_depth = browse_depth+1;
        ((RootViewControllerLocalBrowser*)childController)->detailViewController=detailViewController;
        ((RootViewControllerLocalBrowser*)childController)->playerButton=playerButton;
        // And push the window
        [self.navigationController pushViewController:childController animated:YES];	
        [keys release];keys=nil;
        [list release];list=nil;
        
    } else {
        int switch_view_subdir=((browse_depth>=SHOW_SUDIR_MIN_LEVEL));
        int section=indexPath.section-1-switch_view_subdir;
        if ((indexPath.section==1)&&switch_view_subdir) {
            int donothing=0;
            if (mSearch) {
                if (mSearchText==nil) donothing=1;
            }
            if (!donothing) {
                mShowSubdir^=1;
                shouldFillKeys=1;
                
                [self performSelectorInBackground:@selector(showWaiting) withObject:nil];
                
                int old_mSearch=mSearch;
                NSString *old_mSearchText=mSearchText;
                mSearch=0;
                mSearchText=nil;
                [self fillKeys];   //1st load eveything
                mSearch=old_mSearch;
                mSearchText=old_mSearchText;
                if (mSearch) {
                    shouldFillKeys=1;
                    [self fillKeys];   //2nd filter for drawing
                }
                [[super tableView] reloadData];
                
                [self performSelectorInBackground:@selector(hideWaiting) withObject:nil];
            }
        } else {
            cellValue=cur_local_entries[section][indexPath.row].label;
            
            if (cur_local_entries[section][indexPath.row].type==0) { //Directory selected : change current directory
                
                [self performSelectorInBackground:@selector(showWaiting) withObject:nil];
                
                NSString *newPath=[NSString stringWithFormat:@"%@/%@",currentPath,cellValue];
                [newPath retain];        
                if (childController == nil) childController = [[RootViewControllerLocalBrowser alloc]  initWithNibName:@"RootViewController" bundle:[NSBundle mainBundle]];
                else {// Don't cache childviews
                }
                //set new title
                childController.title = cellValue;
                // Set new depth & new directory
                ((RootViewControllerLocalBrowser*)childController)->currentPath = newPath;				
                ((RootViewControllerLocalBrowser*)childController)->browse_depth = browse_depth+1;
                ((RootViewControllerLocalBrowser*)childController)->detailViewController=detailViewController;
                ((RootViewControllerLocalBrowser*)childController)->playerButton=playerButton;
                // And push the window
                [self.navigationController pushViewController:childController animated:YES];		
                
                
                [self performSelectorInBackground:@selector(hideWaiting) withObject:nil];
                //				[childController autorelease];
            } else if (((cur_local_entries[section][indexPath.row].type==2)||(cur_local_entries[section][indexPath.row].type==3))&&(mAccessoryButton)) { //Archive selected or multisongs: display files inside
                
                [self performSelectorInBackground:@selector(showWaiting) withObject:nil];
                
                NSString *newPath;
                //                    NSLog(@"currentPath:%@\ncellValue:%@\nfullpath:%@",currentPath,cellValue,cur_local_entries[section][indexPath.row].fullpath);
                if (mShowSubdir) newPath=[NSString stringWithString:cur_local_entries[section][indexPath.row].fullpath];
                else newPath=[NSString stringWithFormat:@"%@/%@",currentPath,cellValue];
                [newPath retain];        
                if (childController == nil) childController = [[RootViewControllerLocalBrowser alloc]  initWithNibName:@"RootViewController" bundle:[NSBundle mainBundle]];
                else {// Don't cache childviews
                }
                //set new title
                childController.title = cellValue;
                // Set new depth & new directory
                ((RootViewControllerLocalBrowser*)childController)->currentPath = newPath;				
                ((RootViewControllerLocalBrowser*)childController)->browse_depth = browse_depth+1;
                ((RootViewControllerLocalBrowser*)childController)->detailViewController=detailViewController;
                ((RootViewControllerLocalBrowser*)childController)->playerButton=playerButton;
                // And push the window
                [self.navigationController pushViewController:childController animated:YES];		
                
                
                [self performSelectorInBackground:@selector(hideWaiting) withObject:nil];
                //				[childController autorelease];
            } else {  //File selected
                
                if (detailViewController.sc_DefaultAction.selectedSegmentIndex==0) {
                    // launch Play of current dir
                    int pos=0;
                    int total_entries=0;
                    NSMutableArray *array_label = [[[NSMutableArray alloc] init] autorelease];
                    NSMutableArray *array_path = [[[NSMutableArray alloc] init] autorelease];
                    /*for (int i=0;i<27;i++) 
                     for (int j=0;j<(search_local?search_local_entries_count[i]:local_entries_count[i]);j++)
                     if (cur_local_entries[i][j].type==1) {
                     total_entries++;
                     [array_label addObject:cur_local_entries[i][j].label];
                     [array_path addObject:cur_local_entries[i][j].fullpath];
                     if (i<section) pos++;
                     else if (i==(section))
                     if (j<indexPath.row) pos++;
                     }
                     */
                    total_entries=1;
                    [array_label addObject:cur_local_entries[section][indexPath.row].label];
                    [array_path addObject:cur_local_entries[section][indexPath.row].fullpath];
                    
                    
                    signed char *tmp_ratings;
                    short int *tmp_playcounts;
                    tmp_ratings=(signed char*)malloc(total_entries*sizeof(signed char));
                    tmp_playcounts=(short int*)malloc(total_entries*sizeof(short int));
                    total_entries=0;
                    /*for (int i=0;i<27;i++) 
                     for (int j=0;j<(search_local?search_local_entries_count[i]:local_entries_count[i]);j++)
                     if (cur_local_entries[i][j].type==1) {
                     tmp_ratings[total_entries]=cur_local_entries[i][j].rating;
                     tmp_playcounts[total_entries++]=cur_local_entries[i][j].playcount;
                     }			
                     
                     */
                    tmp_ratings[0]=cur_local_entries[section][indexPath.row].rating;
                    tmp_playcounts[0]=cur_local_entries[section][indexPath.row].playcount;
                    
                    [detailViewController play_listmodules:array_label start_index:pos path:array_path ratings:tmp_ratings playcounts:tmp_playcounts];
                    
                    free(tmp_ratings);
                    free(tmp_playcounts);
                    
                    cur_local_entries[section][indexPath.row].rating=-1;
                    if (detailViewController.sc_PlayerViewOnPlay.selectedSegmentIndex) [self goPlayer];
                    else [tableView reloadData];
                    
                    
                    
                } else {
                    if ([detailViewController add_to_playlist:cur_local_entries[section][indexPath.row].fullpath fileName:cur_local_entries[section][indexPath.row].label forcenoplay:0]) {
                        if (detailViewController.sc_PlayerViewOnPlay.selectedSegmentIndex) [self goPlayer];
                        else [tableView reloadData];
                    }
                }
                
                
            }	
        }
        
    }
    mAccessoryButton=0;
}


/* POPUP functions */
-(void) hidePopup {
    infoMsgView.hidden=YES;
    mPopupAnimation=0;
}

-(void) openPopup:(NSString *)msg {
    CGRect frame;
    if (mPopupAnimation) return;
    mPopupAnimation=1;	
    frame=infoMsgView.frame;
    frame.origin.y=self.view.frame.size.height;
    infoMsgView.frame=frame;
    infoMsgView.hidden=NO;
    infoMsgLbl.text=[NSString stringWithString:msg];
    [UIView beginAnimations:nil context:nil];				
    [UIView setAnimationDelay:0];				
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];
    frame=infoMsgView.frame;
    frame.origin.y=self.view.frame.size.height-64;
    infoMsgView.frame=frame;
    [UIView setAnimationDidStopSelector:@selector(closePopup)];
    [UIView commitAnimations];
}
-(void) closePopup {
    CGRect frame;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelay:1.0];				
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationDelegate:self];	
    frame=infoMsgView.frame;
    frame.origin.y=self.view.frame.size.height;
    infoMsgView.frame=frame;
    [UIView setAnimationDidStopSelector:@selector(hidePopup)];
    [UIView commitAnimations];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc. that aren't in use.
}
- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;;
}
- (void)dealloc {
    [waitingView removeFromSuperview];
    [waitingView release];
    
    [currentPath release];
    if (mSearchText) {
        [mSearchText release];
        mSearchText=nil;
    }
    if (keys) {
        [keys release];
        keys=nil;
    }
    if (list) {
        [list release];
        list=nil;
    }	
    
    if (local_nb_entries) {
        for (int i=0;i<local_nb_entries;i++) {
            [local_entries_data[i].label release];
            [local_entries_data[i].fullpath release];
        }
        free(local_entries_data);
    }
    if (search_local_nb_entries) {
        free(search_local_entries_data);
    }
    
    
    if (indexTitles) {
        [indexTitles release];
        indexTitles=nil;        
    }
    if (indexTitlesSpace) {
        [indexTitlesSpace release];
        indexTitlesSpace=nil;        
    }
    
    if (mFileMngr) {
        [mFileMngr release];
        mFileMngr=nil;
    }
    
    [super dealloc];
}


@end