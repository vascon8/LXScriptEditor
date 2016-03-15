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
+ (void)analyLanguage:(NSString*)lang path:(NSArray*)pathArr
{
    if ([[lang lowercaseString] isEqualToString:@"python"]) {
        [self validatePython];
    }
}
#pragma mark - validate language
#pragma mark python
+ (void)validatePython
{
    NSString *commandStr = @"python -V;echo $?";
    
    NSString *output = [self runTaskInUserShellWithCommand:commandStr];
    
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
        NSLog(@"%@",arrM);
        NSMutableArray *keywordArr = [NSMutableArray new];
        for (NSString *path in arrM) {
            //judge time
            
            //unzip
            NSDateFormatter *formatter = [NSDateFormatter new];
            [formatter setDateFormat:@"yyMMddHHssSSSS"];
            [formatter setLocale:[NSLocale systemLocale]];
            [formatter setTimeZone:[NSTimeZone systemTimeZone]];
            NSString *timeStr = [formatter stringFromDate:[NSDate date]];
            
            NSString *eggName = [path lastPathComponent];
            eggName = [NSString stringWithFormat:@"%@_%@",timeStr,eggName];
            NSString *tmpPath = [NSString stringWithFormat:@"/tmp/%@",eggName];
            NSString *command = [NSString stringWithFormat:@"unzip -d %@ %@",tmpPath,path];
            [self runTaskInUserShellWithCommand:command];
            
            BOOL isDir;
            if([[NSFileManager defaultManager]fileExistsAtPath:tmpPath isDirectory:&isDir]){
                NSLog(@"=unzip successful:%@",tmpPath);
                if (isDir) {
                    NSDirectoryEnumerator *enumator = [[NSFileManager defaultManager]enumeratorAtPath:tmpPath];
                    NSString *dirName;
                    while (dirName = [enumator nextObject]) {
                        NSLog(@"dirName:%@",dirName);
                        NSRange range = [[eggName lowercaseString] rangeOfString:[dirName lowercaseString]];
                        if (range.location!=NSNotFound) {
                            NSString *libPrefix = [NSString stringWithFormat:@"from %@",dirName];
                            if(![keywordArr containsObject:libPrefix]) [keywordArr addObject:libPrefix];
                            
                            NSString *libPath = [tmpPath stringByAppendingPathComponent:dirName];
                            NSLog(@"libPath:%@",libPath);
                            [self enuLibPath:libPath prefix:libPrefix];
                        }
                    }
                }
            }
        }
    }
}
+ (void)enuLibPath:(NSString*)libPath prefix:(NSString*)prefix
{
    NSDirectoryEnumerator *libEnu = [[NSFileManager defaultManager]enumeratorAtPath:libPath];
    NSString *compName;
    
    NSMutableArray *arrM = [NSMutableArray new];
    [arrM addObjectsFromArray:[self analyFileUnderDir:libPath prefix:prefix]];
    
    while (compName = [libEnu nextObject]) {
        NSString *compPath = [libPath stringByAppendingPathComponent:compName];
        BOOL isDir;
        if([[NSFileManager defaultManager]fileExistsAtPath:compPath isDirectory:&isDir]){
            if (isDir) {
                NSString *dirPrefix = [NSString stringWithFormat:@"%@.%@",prefix,compName];
                if(![arrM containsObject:compName]) [arrM addObject:compName];
                
                [self enuLibPath:compPath prefix:dirPrefix];
            }
        }
    }
    

}
+ (NSArray*)analyFileUnderDir:(NSString*)dir prefix:(NSString*)prefix
{
    NSMutableArray *arrM = [NSMutableArray new];
    NSString *defCommand = @"grep \"def \" *.py|grep -v \"def __\"";
    NSString *defOutput = [self runTaskInUserShellWithCommand:defCommand];
    NSLog(@"dir:%@ ==defOut:%@\n",dir,defOutput);
    [arrM addObjectsFromArray:[self analyDefOutput:defOutput prefix:nil]];
    
    NSString *classCommand = @"grep \"class \" *.py";
    NSString *classOutput = [self runTaskInUserShellWithCommand:classCommand];
    NSLog(@"dir:%@ ==classOut:%@\n",dir,classOutput);
    [arrM addObjectsFromArray:[self analyClassOutput:classOutput prefix:@"import"]];
    
    NSLog(@"analy file key:%@\n",arrM);
    return arrM;
}
+ (NSArray*)analyDefOutput:(NSString*)output prefix:(NSString*)prefix
{
    NSString *bSep = @"def ";
    NSString *fSep = @"(";
    
    return [self analyGrepOutput:output beginSeperator:bSep finishSeperator:fSep prefix:prefix];
}
+ (NSArray*)analyClassOutput:(NSString*)output prefix:(NSString*)prefix
{
    NSString *bSep = @"class ";
    NSString *fSep = @"(";
    
    return [self analyGrepOutput:output beginSeperator:bSep finishSeperator:fSep prefix:prefix];
}
+ (NSArray*)analyGrepOutput:(NSString*)output beginSeperator:(NSString*)bSep finishSeperator:(NSString*)fSep prefix:(NSString*)prefix
{
    NSArray *comps = [output componentsSeparatedByString:@"\n"];
    NSMutableArray *arrM = [NSMutableArray new];
    
    for (NSString *line in comps) {
        NSString *keyName = [self rangeOfString:line byBeginSeperator:bSep finishSeperator:fSep];
        if(keyName) {
            NSString *keywords;
            if(prefix) [NSString stringWithFormat:@"%@.%@",prefix,keyName];
            else keywords = keyName;;
            if(![arrM containsObject:keywords]) [arrM addObject:keywords];
        }
    }
    
    return arrM;
}
+ (NSString*)rangeOfString:(NSString*)str byBeginSeperator:(NSString*)bSep finishSeperator:(NSString*)fSep
{
    NSRange bRange = [str rangeOfString:bSep];
    NSRange fRange = [str rangeOfString:fSep];
    NSString *result=nil;
    if (bRange.location!=NSNotFound&&fRange.location!=NSNotFound&&fRange.location>bRange.location+1) {
        NSRange range = NSMakeRange(bRange.location+1,fRange.location-bRange.location-1);
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
