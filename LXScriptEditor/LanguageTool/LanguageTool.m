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
+ (NSArray*)analyLanguage:(NSString*)lang libPathArr:(NSArray *)libPathArr
{
    NSArray *arr = nil;
    NSString *langStr = [lang lowercaseString];
    
    if ([langStr isEqualToString:@"python"]) {
        arr = [self validatePythonLibPathArr:libPathArr];
    }
    else if ([langStr isEqualToString:@"java"]){
        arr = [self validateJavaLibPath:libPathArr];
//    ls *.java|xargs egrep "public\s{1,10}[a-zA-Z0-9_-]{1,200}\s{1,10}[a-zA-Z0-9_-]{1,200}\([a-zA-Z0-9, -_]{0,}\)\s{1,10}\{"
//        ls *.java|xargs egrep -e "public\s{1,10}[a-zA-Z0-9_-]{1,200}\s{1,10}[a-zA-Z0-9_-]{1,200}\([a-zA-Z0-9, -_]{0,}|\n[a-zA-Z0-9 _-]{0,100}\)\s{0,20}\{"|wc -l
//        ls *.java|xargs awk '/public[ ]+[a-zA-Z0-9<>_-]{1,200}[ ]+[a-zA-Z0-9-_]{1,200} {0,10}\([<>a-zA-Z0-9 ,-_]{0,500}\) {0,20}\{ {0,200}/'
//        sed -e ":begin; /<<</,/>>>/ { />>>/! { $! { N; b begin }; }; s/<<<.*>>>/COMMENT/; };" test
    }
    
    return arr;
}
#pragma mark - validate language
#pragma mark java
+ (NSArray*)validateJavaLibPath:(NSArray*)libPath
{
    NSString *commandStr = @"java -version;echo $?";
    NSString *output = [self runTaskInUserShellWithCommand:commandStr];
    NSMutableArray *keywordArr = [NSMutableArray array];
    
    if ([self isTaskSuccessfulByRC:output] && libPath && libPath.count>0) {
    
        for (NSString *path in libPath) {
            BOOL isDir = NO;
            if ([[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&isDir] && isDir) {
                NSArray *arr = [self enuLibPath:path prefix:@"import" lang:@"Java"];
                if(arr) [keywordArr addObjectsFromArray:arr];
            }
        }
    }
    //    NSLog(@"key:%@",keywordArr);
    return keywordArr;
}
+ (NSArray*)analyJavaFileUnderDir:(NSString*)dir
{
    NSMutableArray *arrM = [NSMutableArray new];
    
    NSError *error = nil;
    NSString *file = [NSString stringWithContentsOfFile:dir encoding:NSUTF8StringEncoding error:&error];
    if(error) NSLog(@"==error:%@",error);
    
    if(error) return nil;
    
    NSString *pattern = @"public\\s{1,20}[\\d\\w-_<>]{1,200}\\s{1,20}[\\d\\w-_]{1,200}\\s{0,20}\\([\\d\\w\\n\\s,-_<>]{0,200}\\)[\\d\\w\\s]{0,50}\\{";
    
    NSUInteger length = file.length;
    NSRegularExpression  *r = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSArray *matchs = [r matchesInString:file options:NSMatchingReportProgress range:NSMakeRange(0, length)];
    if(error) NSLog(@"==eror:%@",error);
    
    for (int i=0; i<matchs.count; i++) {
        NSTextCheckingResult *result = [matchs objectAtIndex:i];
        NSRange range = [result rangeAtIndex:0];
        if (range.location != NSNotFound && range.length<length) {
            NSString *str = [file substringWithRange:range];
//            str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            
//            NSLog(@"==match:%@",str);
            NSString *finalResult = [self analyJavaClassStr:str];
            if(finalResult && ![arrM containsObject:finalResult]) [arrM addObject:finalResult];
        }
    }
    
//    NSString *methodCommand = @"ls *.java|xargs egrep \"public\\s{1,20}[a-zA-Z0-9_-<>]{1,200}\\s{1,20}[a-zA-Z0-9_-]{1,200}\\s{0,10}\\([a-zA-Z0-9, -_';:&!#$\\w]{0,}\\)\\s{1,10}{\"";
//    NSString *methodOutput = [self runTaskInUserShellWithCommand:methodCommand currentPath:dir];
//
////    NSLog(@"dir:%@ ==classOut:%@\n",dir,methodOutput);
//    if(prefix) prefix = [NSString stringWithFormat:@"import %@",libPath];
////    NSLog(@"==prefix:%@",prefix);
//    [arrM addObjectsFromArray:[self analyJavaClassOutput:methodOutput prefix:prefix libPath:libPath]];
    
    //    NSLog(@"analy file key:%@\n",arrM);
    return arrM;
}
+ (NSString *)analyJavaClassStr:(NSString*)classStr
{
    if(!classStr) return nil;
    
    NSRange rangeEnd = [classStr rangeOfString:@")" options:NSBackwardsSearch];
    NSRange rangeTag = [classStr rangeOfString:@"(" options:NSBackwardsSearch];
    
    if (rangeEnd.location!=NSNotFound && rangeTag.location!=NSNotFound && rangeTag.location<rangeEnd.location) {
        
        NSUInteger i = rangeTag.location+1;
        int j=1;
        while (i>9 && i<rangeEnd.location) {
            NSUInteger index = [classStr characterAtIndex:i] ;
            if ('\n' == index || index == 13) {
//                NSLog(@"==found enter");
                classStr = [classStr stringByReplacingCharactersInRange:NSMakeRange(i, 1) withString:@""];
                rangeEnd.location --;
            }
            else if([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[classStr characterAtIndex:i]]) {
                //                NSLog(@"== found==%@,i:%ld,loc:%ld",classStr,i,rangeEnd.location);
                if (j>0) {
                    classStr = [classStr stringByReplacingCharactersInRange:NSMakeRange(i, 1) withString:@""];
                    rangeEnd.location--;
                }
                else{
                    j++;i++;
                }
            }
            else {i++;j=0;}
        }
        
        i=rangeTag.location-1;
        //public ? ?,leng 9
        while (i > 9 && i<classStr.length){
            if([[NSCharacterSet whitespaceCharacterSet] characterIsMember:[classStr characterAtIndex:i]]) {
                classStr = [classStr stringByReplacingCharactersInRange:NSMakeRange(i, 1) withString:@""];
                rangeTag.location--;
                rangeEnd.location--;
                i--;
            }
            else break;
            
        }
    
        NSRange rangeBegin = [classStr rangeOfString:@" " options:NSBackwardsSearch range:NSMakeRange(0, i)];
        if (rangeBegin.location!=NSNotFound && rangeBegin.location<rangeTag.location+1) {
            NSRange range = NSMakeRange(rangeBegin.location+1, rangeEnd.location-rangeBegin.location);
            NSString *resultStr = [classStr substringWithRange:range];
//            NSLog(@"==resultStr:%@",resultStr);

            return resultStr;
        }
    }
    
    return nil;
}
#pragma mark python
+ (NSArray*)validatePythonLibPathArr:(NSArray *)libPathArr
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
                        if([[path pathExtension] isEqualToString:@"egg"] && ![arrM containsObject:path])[arrM addObject:path];
                    }
                }

            }
        }
//         NSLog(@"==%@",arrM);
        
        if (libPathArr && libPathArr.count>0) {
            for (NSString *libPath in libPathArr) {
                BOOL isCorrect = NO;
                if (![arrM containsObject:libPath] && [[NSFileManager defaultManager] fileExistsAtPath:libPath isDirectory:&isCorrect]) {
                    if (isCorrect) {
                        NSDirectoryEnumerator *libEnu = [[NSFileManager defaultManager]enumeratorAtPath:libPath];
                        NSString *compName;
                        
                        while (compName = [libEnu nextObject]) {
                            NSString *path = [libPath stringByAppendingPathComponent:compName];
                            if ([[path pathExtension] isEqualToString:@"egg"] && ![arrM containsObject:path]) {
                                [arrM addObject:path];
                            }
                        }
                    }
                }
            }
        }
//        NSLog(@"==%@",arrM);
        
        keywordArr = [NSMutableArray new];
        for (NSString *path in arrM) {
            //judge time
            
            BOOL eggDir = NO;
            [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&eggDir];
            
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
//                        NSLog(@"==isDir:%d,%@",isDir,tmpPath);
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
//                        NSLog(@"libPath:%@",libPath);
                        [keywordArr addObjectsFromArray:[self enuLibPath:libPath prefix:libPrefix lang:@"Python"]];
                    }
                }
            }
        }
    }
    return keywordArr;
}
+ (NSArray*)enuLibPath:(NSString*)libPath prefix:(NSString*)prefix lang:(NSString*)lang
{
    NSMutableArray *arrM = nil;
    
    BOOL isDir;
    if([[NSFileManager defaultManager]fileExistsAtPath:libPath isDirectory:&isDir])
    {
        arrM = [NSMutableArray new];
        NSString *tmpLibKey = [libPath lastPathComponent];
        
        if([[lang lowercaseString]isEqualToString:@"python"])
        {
            [arrM addObjectsFromArray:[self analyFileUnderDir:libPath prefix:prefix libPath:tmpLibKey]];
        }
        
        NSDirectoryEnumerator *libEnu = [[NSFileManager defaultManager]enumeratorAtPath:libPath];
        NSString *compName;
        
        if (isDir)
        {
            while (compName = [libEnu nextObject]) {
                //                NSLog(@"===compName:%@",compName);
                NSString *compPath = [libPath stringByAppendingPathComponent:compName];
                BOOL subIsDir = NO;
                if([[NSFileManager defaultManager]fileExistsAtPath:compPath isDirectory:&subIsDir]){
                    NSString *tmpName = compName;
                    tmpName = [compName stringByReplacingOccurrencesOfString:@"/" withString:@"."];
                    NSString *dirPrefix = [NSString stringWithFormat:@"%@.%@",prefix,tmpName];
                    NSString *libKey = [NSString stringWithFormat:@"%@.%@",[libPath lastPathComponent],tmpName];
                    
                    if (subIsDir) {
                        if([[lang lowercaseString]isEqualToString:@"python"]) [arrM addObjectsFromArray:[self analyFileUnderDir:compPath prefix:dirPrefix libPath:libKey]];
                    }
                    else{
                        if ([[lang lowercaseString]isEqualToString:@"java"] && [compName hasSuffix:@"java"])
                        {
//                            NSLog(@"==tmppath:%@",tmpName);
                            NSArray *arr = [self analyJavaFileUnderDir:compPath];
                            if(arr && arr.count>0) [arrM addObjectsFromArray:arr];
                            
                            NSString *classStr = [tmpName stringByDeletingPathExtension];
                            if(classStr)
                            {
                                if(![arrM containsObject:classStr]) [arrM addObject:classStr];
                                
                                NSString *libStr = [NSString stringWithFormat:@"import %@",classStr];
                                if(![arrM containsObject:libStr]) [arrM addObject:libStr];
                            }
                        }
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
