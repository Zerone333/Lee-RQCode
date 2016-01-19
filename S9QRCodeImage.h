//
//  S9QRCodeImage.h
//  SlanissueToolkit
//
//  Created by Moky on 15-9-22.
//  Copyright (c) 2015 Slanissue.com. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  create a QRCode image with text
 */
CG_EXTERN CIImage * CIImageWithQRCode(NSString * text) NS_AVAILABLE_IOS(6_0);

/**
 *  create a QRCode image with text, and {size, size}
 */
UIKIT_EXTERN UIImage * UIImageWithQRCode(NSString * text, CGFloat size) NS_AVAILABLE_IOS(6_0);

@interface UIImage (QRCode)

/**
 *  create a QRCode image with text, and {size, size}
 */
+ (UIImage *) imageWithQRCode:(NSString *)string size:(CGFloat)size NS_AVAILABLE_IOS(6_0);

/**
 *  create a QRCode image with text, and {size, size}, and a small icon in center
 */
+ (UIImage *) imageWithQRCode:(NSString *)string size:(CGFloat)size small:(UIImage *)icon NS_AVAILABLE_IOS(6_0);

@end
