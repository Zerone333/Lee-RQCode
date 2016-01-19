//
//  S9Image.m
//  SlanissueToolkit
//
//  Created by Moky on 15-8-24.
//  Copyright (c) 2015 Slanissue.com. All rights reserved.
//

#import "S9Image.h"

CGContextRef CGBitmapContextCreateWithCGImage(CGImageRef imageRef, CGSize size)
{
	void * data = NULL;
	size_t width = size.width > 0.0f ? size.width : CGImageGetWidth(imageRef);
	size_t height = size.height > 0.0f ? size.height : CGImageGetHeight(imageRef);
	size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
	size_t bytesPerRow = 0;//CGImageGetBytesPerRow(imageRef);
	CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
	
	CGContextRef ctx = CGBitmapContextCreate(data, width, height,
											 bitsPerComponent, bytesPerRow,
											 colorSpace, bitmapInfo);
	CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
	return ctx;
}

UIImage * UIImageWithCIImage(CIImage * image, CGSize size, CGFloat scale)
{
	size = CGSizeMake(size.width * scale, size.height * scale);
	CGRect extent = CGRectIntegral(image.extent);
	CGFloat width = CGRectGetWidth(extent);
	CGFloat height = CGRectGetHeight(extent);
	CGFloat sx = width > 0.0f ? size.width / width : scale;
	CGFloat sy = height > 0.0f ? size.height / height : scale;
	
	CIContext * context = [CIContext contextWithOptions:nil];
	CGImageRef imageRef = [context createCGImage:image fromRect:extent];
	
	// create bitmap
	CGContextRef ctx = CGBitmapContextCreateWithCGImage(imageRef, size);
	CGContextScaleCTM(ctx, sx, sy);
	
	// draw
	CGContextDrawImage(ctx, extent, imageRef);
	CGImageRef scaledImage = CGBitmapContextCreateImage(ctx);
	UIImage * result = [UIImage imageWithCGImage:scaledImage
										   scale:scale
									 orientation:UIImageOrientationUp];
	
	// clean up
	CGImageRelease(scaledImage);
	CGContextRelease(ctx);
	CGImageRelease(imageRef);
	return result;
}


UIImageFileType UIImageFileTypeFromName(NSString * filename)
{
	NSString * ext = [[filename pathExtension] lowercaseString];
	if ([ext isEqualToString:@"png"]) {
		return UIImageFileTypePNG;
	} else if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"]) {
		return UIImageFileTypeJPEG;
	} else if ([ext isEqualToString:@"gif"]) {
		return UIImageFileTypeGIF;
	} else if ([ext isEqualToString:@"bmp"]) {
		return UIImageFileTypeBMP;
	}
	return UIImageFileTypeUnknown;
}

CGFloat UIImageScaleFromName(NSString * filename)
{
	// '@'
	NSRange range1 = [filename rangeOfString:@"@" options:NSBackwardsSearch];
	if (range1.location == NSNotFound) {
		return 1.0f;
	}
	range1.location += range1.length;
	range1.length = [filename length] - range1.location;
	
	// 'x'
	NSRange range2 = [filename rangeOfString:@"x" options:NSCaseInsensitiveSearch range:range1];
	if (range2.location == NSNotFound) {
		return 1.0f;
	}
	range1.length = range2.location - range1.location;
	
	// scale
	float scale = [[filename substringWithRange:range1] floatValue];
	return scale > 0.0f ? scale : 1.0f;
}

@implementation UIImage (SlanissueToolkit)


- (UIImage *) grayImage
{
	CGSize size = self.size;
	CGImageRef imageRef = self.CGImage;
	
	void * data = NULL;
	size_t width = size.width > 0.0f ? size.width : CGImageGetWidth(imageRef);
	size_t height = size.height > 0.0f ? size.height : CGImageGetHeight(imageRef);
	size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
	size_t bytesPerRow = 0;//CGImageGetBytesPerRow(imageRef);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
	
	// 1. create context
	CGContextRef context = CGBitmapContextCreate(data, width, height,
												 bitsPerComponent, bytesPerRow,
												 colorSpace, bitmapInfo);
	NSAssert(context, @"no enough memory");
	
	// 2. draw it
	CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
	CGContextDrawImage(context, rect, imageRef);
	
	// 3. create gray image
	imageRef = CGBitmapContextCreateImage(context);
	UIImage * grayImage = [UIImage imageWithCGImage:imageRef];
	
	// 4. clean up
	CGImageRelease(imageRef);
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	
	return grayImage;
}

- (UIImage *) imageWithSize:(CGSize)size
{
	UIGraphicsBeginImageContext(size);
	[self drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
	UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

- (UIImage *) imageWithRect:(CGRect)rect
{
	CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
	UIImage * image = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	return image;
}


////
- (UIImage *) imageWithImagesAndRects:(UIImage *)image1, ... NS_REQUIRES_NIL_TERMINATION
{
	UIImage * image = self;
	CGFloat scale = image.scale;
	CGRect rect = CGRectMake(0.0f, 0.0f, image.size.width * scale, image.size.height * scale);
	CGImageRef imageRef = image.CGImage;
	
	// create bitmap
	CGContextRef ctx = CGBitmapContextCreateWithCGImage(imageRef, rect.size);
	
	// draw self
	CGContextDrawImage(ctx, rect, imageRef);
	
	// draw images
	va_list params;
	va_start(params, image1);
	while (image1) {
		CGRect rect1 = va_arg(params, CGRect);
		// scale
		rect1 = CGRectMake(rect1.origin.x * scale,
						   rect1.origin.y * scale,
						   rect1.size.width * scale,
						   rect1.size.height * scale);
		
		// coordinate system: GL => UI
		CGFloat tx = rect1.origin.x;
		CGFloat ty = rect.size.height - rect1.origin.y - rect1.size.height;
		CGFloat sx = rect1.size.width / rect.size.width;
		CGFloat sy = rect1.size.height / rect.size.height;
		
		CGAffineTransform atm = CGAffineTransformIdentity;
		atm = CGAffineTransformTranslate(atm, tx, ty);
		atm = CGAffineTransformScale(atm, sx, sy);
		
		CGContextConcatCTM(ctx, atm);
		CGContextDrawImage(ctx, rect, image1.CGImage);
		CGContextConcatCTM(ctx, CGAffineTransformInvert(atm));
		
		image1 = va_arg(params, UIImage *);
	}
	va_end(params);
	
	imageRef = CGBitmapContextCreateImage(ctx);
	image = [UIImage imageWithCGImage:imageRef
								scale:scale
						  orientation:UIImageOrientationUp];
	
	// clean up
	CGImageRelease(imageRef);
	CGContextRelease(ctx);
	return image;
}

@end
