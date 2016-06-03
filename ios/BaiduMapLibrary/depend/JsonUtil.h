
#import <Foundation/Foundation.h>

@interface JsonUtil : NSObject

+ (NSString *)dictToJsonStr:(NSDictionary *)dict;
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;

@end
