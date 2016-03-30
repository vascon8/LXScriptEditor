//
//  LanguageTool.m
//  LXScriptEditor
//
//  Created by xinliu on 16-3-14.
//  Copyright (c) 2016年 xinliu. All rights reserved.
//

#import "LanguageTool.h"

@implementation LanguageTool
//+ (void)analyLanguage:(NSString*)lang path:(NSArray*)pathArr scriptCurrentDir:(NSString*)currentDir
//{}
+ (NSArray*)analyLanguage:(NSString*)lang path:(NSArray*)pathArr
{
    NSArray *arr = nil;
    if ([[lang lowercaseString] isEqualToString:@"python"]) {
        arr = [self validatePython];
    }
    
    return arr;
}
#pragma mark - validate language
#pragma mark python
+ (NSArray*)validatePython
{
    NSString *commandStr = @"python -V;echo $?";
    NSString *output = [self runTaskInUserShellWithCommand:commandStr];
    NSMutableArray *keywordArr = nil;
    
    if ([self isTaskSuccessfulByRC:output]) {
        NSString *analyStr = @"python -c \"import sys;print(sys.path);\"";
        NSString *analyOut = [self runTaskInUserShellWithCommand:analyStr];

        NSArray *arr = [analyOut componentsSeparatedByString:@","];
        NSMutableArray *arrM = [NSMutableArray new];
        if (arr && arr.count>0) {
            for (NSString *str in arr) {
                if (str.length>2) {
                    NSString *seperator = @"'";
//                    NSLog(@"str:%@,len:%ld\n",str,str.length);
                    NSRange bRange = [str rangeOfString:seperator];
                    NSRange fRange = [str rangeOfString:seperator options:NSBackwardsSearch];
                    if (bRange.location!=NSNotFound && fRange.location!=NSNotFound && bRange.location+1<fRange.location) {
                        NSRange range = NSMakeRange(bRange.location+1,fRange.location-bRange.location-1);
                        
                        NSString *path = [str substringWithRange:range];
//                        NSLog(@"path:%@\n",path);
                        if([[path pathExtension] isEqualToString:@"egg"])[arrM addObject:path];
                    }
                }

            }
        }
//        NSLog(@"%@",arrM);
        
        keywordArr = [NSMutableArray new];
        for (NSString *path in arrM) {
            //judge time
            
            BOOL eggDir = NO;
            BOOL needUnzip = [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&eggDir];
            
            NSString *eggName = [path lastPathComponent];
            NSString *tmpPath = path;
            if (!eggDir) {
                //unzip
                NSDateFormatter *formatter = [NSDateFormatter new];
                [formatter setDateFormat:@"yyMMddHHssSSSS"];
                [formatter setLocale:[NSLocale systemLocale]];
                [formatter setTimeZone:[NSTimeZone systemTimeZone]];
                NSString *timeStr = [formatter stringFromDate:[NSDate date]];
                
                eggName = [NSString stringWithFormat:@"%@_%@",timeStr,eggName];
                tmpPath = [NSString stringWithFormat:@"/tmp/%@",eggName];
                NSString *command = [NSString stringWithFormat:@"unzip -d %@ %@",tmpPath,path];
                
                [self runTaskInUserShellWithCommand:command];
            }
            
            [keywordArr addObjectsFromArray:[self scanEggPath:tmpPath name:eggName]];

        }
    }
//    NSLog(@"key:%@",keywordArr);
    return keywordArr;
}
+ (NSArray*)scanEggPath:(NSString*)tmpPath name:(NSString*)eggName
{
    NSMutableArray *keywordArr = [NSMutableArray array];
    
    BOOL isDir;
    if([[NSFileManager defaultManager]fileExistsAtPath:tmpPath isDirectory:&isDir]){
        //                NSLog(@"=unzip successful:%@",tmpPath);
        if (isDir) {
            
            NSError *error=nil;
            NSArray *contsArr = [[NSFileManager defaultManager]contentsOfDirectoryAtPath:tmpPath error:&error];
            if (!error && contsArr) {
                for (NSString *dirName in contsArr) {
                    NSRange range = [[eggName lowercaseString] rangeOfString:[dirName lowercaseString]];
                    if (range.location!=NSNotFound) {
                        NSString *libPrefix = [NSString stringWithFormat:@"from %@",dirName];
                        if(![keywordArr containsObject:libPrefix]) [keywordArr addObject:libPrefix];
                        
                        NSString *libPath = [tmpPath stringByAppendingPathComponent:dirName];
                        //                                NSLog(@"libPath:%@",libPath);
                        [keywordArr addObjectsFromArray:[self enuLibPath:libPath prefix:libPrefix]];
                    }
                }
            }
        }
    }
    return keywordArr;
}
+ (NSArray*)enuLibPath:(NSString*)libPath prefix:(NSString*)prefix
{
    BOOL isDir;
    NSMutableArray *arrM = nil;
    if([[NSFileManager defaultManager]fileExistsAtPath:libPath isDirectory:&isDir])
    {
        arrM = [NSMutableArray new];
        NSString *tmpLibKey = [libPath lastPathComponent];
        [arrM addObjectsFromArray:[self analyFileUnderDir:libPath prefix:prefix libPath:tmpLibKey]];
        
        if (isDir)
        {
            NSDirectoryEnumerator *libEnu = [[NSFileManager defaultManager]enumeratorAtPath:libPath];
            NSString *compName;
            
            while (compName = [libEnu nextObject]) {
//                NSLog(@"===compName:%@",compName);
                NSString *compPath = [libPath stringByAppendingPathComponent:compName];
                BOOL subIsDir;
                if([[NSFileManager defaultManager]fileExistsAtPath:compPath isDirectory:&subIsDir]){
                    if (subIsDir) {
                        NSString *tmpName = compName;
                        tmpName = [compName stringByReplacingOccurrencesOfString:@"/" withString:@"."];
                        
//                        if(![arrM containsObject:tmpName]) [arrM addObject:tmpName];
                        
                        NSString *dirPrefix = [NSString stringWithFormat:@"%@.%@",prefix,tmpName];
                        
                        NSString *libKey = [NSString stringWithFormat:@"%@.%@",[libPath lastPathComponent],tmpName];
                        [arrM addObjectsFromArray:[self analyFileUnderDir:compPath prefix:dirPrefix libPath:libKey]];
                    }
                }
            }
        }
    }
    
    return arrM;
}
+ (NSArray*)analyFileUnderDir:(NSString*)dir prefix:(NSString*)prefix libPath:(NSString*)libPath
{
    NSMutableArray *arrM = [NSMutableArray new];
    NSString *defCommand = @"ls *.py|grep -v __*.py|xargs egrep \"^ {0,}def \"|grep -v \"def _\"";
    NSString *defOutput = [self runTaskInUserShellWithCommand:defCommand currentPath:dir];
    NSLog(@"dir:%@ ==defOut:%@\n",dir,defOutput);
    [arrM addObjectsFromArray:[self analyDefOutput:defOutput prefix:nil]];
    
    NSString *classCommand = @"ls *.py|grep -v __*.py|xargs egrep -H \"^ {0,}class \"|grep -v \"class _\"";
    NSString *classOutput = [self runTaskInUserShellWithCommand:classCommand currentPath:dir];
//    NSLog(@"dir:%@ ==classOut:%@\n",dir,classOutput);
//    NSString *cPrefix = @"import";
//    if(prefix) cPrefix = [NSString stringWithFormat:@"%@ import",prefix];
    [arrM addObjectsFromArray:[self analyClassOutput:classOutput prefix:prefix libPath:libPath]];
    
//    NSLog(@"analy file key:%@\n",arrM);
    return arrM;
}
+ (NSArray*)analyDefOutput:(NSString*)output prefix:(NSString*)prefix
{
    NSString *bSep = @"def ";
    NSString *fSep = @":";
    
    NSArray *result = [self analyGrepOutput:output beginSeperator:bSep finishSeperator:fSep backSearch:YES prefix:prefix libPath:nil];
    
    return [self rewrapDef:result];
}
+ (NSArray*)rewrapDef:(NSArray*)defArr
{
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:defArr.count];
    for (NSString *def in defArr) {
        def = [def stringByReplacingOccurrencesOfString:@"self, " withString:@""];
        def = [def stringByReplacingOccurrencesOfString:@"self," withString:@""];
        def = [def stringByReplacingOccurrencesOfString:@"self" withString:@""];
        
        if(![arr containsObject:def]) [arr addObject:def];
    }
    
    return arr;
}
+ (NSArray*)analyClassOutput:(NSString*)output prefix:(NSString*)prefix libPath:(NSString*)libPath
{
    NSString *bSep = @"class ";
    NSString *fSep = @"(";
    
    return [self analyGrepOutput:output beginSeperator:bSep finishSeperator:fSep backSearch:NO prefix:prefix libPath:libPath];
}
+ (NSArray*)analyGrepOutput:(NSString*)output beginSeperator:(NSString*)bSep finishSeperator:(NSString*)fSep backSearch:(BOOL)backSearch prefix:(NSString*)prefix libPath:(NSString*)libPath
{
    NSArray *comps = [output componentsSeparatedByString:@"\n"];
    NSMutableArray *arrM = [NSMutableArray new];
    
    for (NSString *line in comps) {
        NSString *keyName = [self rangeOfString:line byBeginSeperator:bSep finishSeperator:fSep backsearch:backSearch];
        
//        NSLog(@"keyName:%@",keyName);
        if(keyName) {
            NSString *keywords;
            
            //it is class
            if(prefix) {
                if(![arrM containsObject:keyName]) [arrM addObject:keyName];
                
                NSInteger i = 0;
                while ((i < line.length)
                       && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[line characterAtIndex:i]]) {
                    i++;
                }
                line = [line substringFromIndex:i];
                
                NSRange range = [line rangeOfString:@".py"];
                NSString *fileName = nil;
                if(range.location!=NSNotFound) fileName = [line substringToIndex:range.location];
                
                if(fileName) {
                    keywords = [NSString stringWithFormat:@"%@.%@ import %@",prefix,fileName,keyName];
                    if(![arrM containsObject:fileName]) [arrM addObject:fileName];
                    
                    if(libPath){
                        NSString *libToFile = [NSString stringWithFormat:@"%@.%@ import %@",libPath,fileName,keyName];
                        if(![arrM containsObject:libToFile]) [arrM addObject:libToFile];
                    }
                }
                else keywords = [NSString stringWithFormat:@"%@ import %@",prefix,keyName];
            }
            else keywords = keyName;;

            if(![arrM containsObject:keywords]) [arrM addObject:keywords];
        }
    }
//    NSLog(@"arrM:%@",arrM);
    return arrM;
}
+ (NSString*)rangeOfString:(NSString*)str byBeginSeperator:(NSString*)bSep finishSeperator:(NSString*)fSep backsearch:(BOOL)backSearch
{
    NSRange bRange = [str rangeOfString:bSep];
    NSRange fRange = [str rangeOfString:fSep options:(backSearch?NSBackwardsSearch:1)];
    NSString *result=nil;
    if (bRange.location!=NSNotFound&&fRange.location!=NSNotFound&&fRange.location>bRange.location+1) {
        NSRange range = NSMakeRange(bRange.location+bSep.length,fRange.location-bRange.location-bSep.length);
        result = [str substringWithRange:range];
    }
    return result;
}
#pragma mark - task method
+ (NSString*)runTaskInUserShellWithCommand:(NSString*)commandStr currentPath:(NSString*)currentPath
{
    NSDictionary *envDict = [[NSProcessInfo processInfo]environment];
    NSString *shellStr = [envDict objectForKey:@"SHELL"];
    
    NSArray *args = @[@"-l",@"-c",commandStr];
    
    NSTask *task = [NSTask new];
    if (currentPath) {
        [task setCurrentDirectoryPath:currentPath];
    }
    [task setLaunchPath:shellStr];
    [task setArguments:args];
    [task setStandardInput:[NSPipe pipe]];
    NSPipe *pipe = [NSPipe pipe];
    
    [task setStandardError:pipe];
    [task setStandardOutput:pipe];
    
    [task launch];
    NSFileHandle *stdOutHandle = [pipe fileHandleForReading];
    NSData *data = [stdOutHandle readDataToEndOfFile];
	[stdOutHandle closeFile];
    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    return output;
}
+ (NSString*)runTaskInUserShellWithCommand:(NSString*)commandStr
{
    return [self runTaskInUserShellWithCommand:commandStr currentPath:nil];
}
+ (BOOL)isTaskSuccessfulByRC:(NSString*)output
{
//    NSLog(@"output:%@",output);
    BOOL success = NO;
    if ([output hasSuffix:@"\n0\n"]) {
//        NSLog(@"successful");
        success = YES;
    }
    else{
        NSLog(@"faile");
    }
    
    return success;
}

@end
