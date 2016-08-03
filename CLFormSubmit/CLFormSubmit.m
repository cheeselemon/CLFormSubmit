/*
 The MIT License (MIT)
 
 Copyright (c) 2016 Jaeha Kim
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 
 */


#import "CLFormSubmit.h"
#import <UIKit/UIKit.h>

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define SILENCE_DEPRECATION(expr)                                   \
do {                                                                \
_Pragma("clang diagnostic push")                                    \
_Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")   \
expr;                                                               \
_Pragma("clang diagnostic pop")                                     \
} while(0)

#define SILENCE_IOS7_DEPRECATION(expr) SILENCE_DEPRECATION(expr)
#define SILENCE_IOS8_DEPRECATION(expr) SILENCE_DEPRECATION(expr)


@implementation CLFormSubmitFileData



@end

@interface CLFormSubmit () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
	NSURLResponse* resp;
	NSError* connErr;
}
@property (nonatomic, strong) void (^doneBlock)(NSURLResponse* response, NSData* data, NSError* connectionError);
@property (nonatomic, strong) NSMutableData* rcvData;
@end

@implementation CLFormSubmit

- (BOOL)uploadImage:(CLFormSubmitFileData*)file params:(NSDictionary*)params to:(NSString*)url
			   done:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError))doneBlock {
	
	self.doneBlock = doneBlock;
	
	
	NSMutableURLRequest* request= [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	
	[request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
	[request setHTTPShouldHandleCookies:NO];
	[request setTimeoutInterval:360];//
	[request setHTTPMethod:@"POST"];
	
	NSString *boundary = @"-------------------------------B-sOmErAnDoMfOrMbOuNdArIeS2015";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
	[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
	NSMutableData *postbody = [[NSMutableData alloc] init];
	
	// add params (all params are strings)
	for (NSString *param in params) {
		[postbody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
		[postbody appendData:[[NSString stringWithFormat:@"%@\r\n", [params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	//	for (CLFormSubmitFileData* fsfd in files) {
	[postbody appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postbody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", file.paramName, file.fileName] dataUsingEncoding:NSUTF8StringEncoding]];
	[postbody appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[postbody appendData:[NSData dataWithData:file.fileData]];
	[postbody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	//	}
	
	// end boundary
	[postbody appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	
	// set body
	[request setHTTPBody:postbody];
	
	// set the content-length
	NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[postbody length]];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	
	
	//	NSLog(@"%@", [[NSString alloc] initWithData:postbody encoding:NSUTF8StringEncoding]);
	if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")){
		NSURLSessionDataTask* connection = [[NSURLSession sharedSession] dataTaskWithRequest:request
																		   completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
																			   if(error){
																				   NSLog(@"NSURLSessionDataTask Error : %@" ,[error localizedDescription]);
																				   _rcvData = [NSMutableData dataWithData:data];
																				   if(self.doneBlock){
																					   self.doneBlock(resp, _rcvData, error);
																				   }
																			   }
																			   if(data){
																				   _rcvData = [NSMutableData dataWithData:data];
																				   if(self.doneBlock){
																					   self.doneBlock(resp, _rcvData, error);
																				   }
																			   }else{
																			   }
																		   }];
		if(connection){
			_rcvData = [[NSMutableData alloc] init];
			[connection resume];
		}
		return YES;
	}else{
		SILENCE_DEPRECATION(
							NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
							
							if ( connection ){
								_rcvData = [[NSMutableData alloc] init];
								return YES;
							}else{
								return NO;
							}
							);
	}
	
	//	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	//	[NSURLConnection sendAsynchronousRequest:request queue:queue
	//						   completionHandler:doneBlock];
	return NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	[_rcvData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	resp = response;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	connErr = error;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
	NSLog(@"%@", [[NSString alloc] initWithData:_rcvData encoding:NSUTF8StringEncoding]);
	if(self.doneBlock){
		self.doneBlock(resp, _rcvData, connErr);
	}
}


- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
	
}

- (void)URLSession:(NSURLSession *)session
			  task:(NSURLSessionTask *)task
   didSendBodyData:(int64_t)bytesSent
	totalBytesSent:(int64_t)totalBytesSent
totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend{
	
}

@end