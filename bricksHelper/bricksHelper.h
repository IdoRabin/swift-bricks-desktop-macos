//
//  bricksHelper.h
//  bricksHelper
//
//  Created by Ido on 02/12/2021.
//

#import <Foundation/Foundation.h>
#import "bricksHelperProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface bricksHelper : NSObject <bricksHelperProtocol>
@end
