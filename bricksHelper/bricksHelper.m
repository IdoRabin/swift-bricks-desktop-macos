//
//  bricksHelper.m
//  bricksHelper
//
//  Created by Ido on 02/12/2021.
//

#import "bricksHelper.h"

@implementation bricksHelper

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

@end
