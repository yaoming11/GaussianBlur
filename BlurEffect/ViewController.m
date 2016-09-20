//
//  ViewController.m
//  BlurEffect
//
//  Created by jike on 16/9/19.
//  Copyright © 2016年 YM. All rights reserved.
//

#import "ViewController.h"

// vImage
#import <Accelerate/Accelerate.h>

#define WIDTH [UIScreen mainScreen].bounds.size.width

typedef enum{
    BlurEffect = 0,
    ToolBar,
    VVImage,
    CoreImage
} setType;
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    /*
     BlurEffect = 0,
     ToolBar,
     VVImage,
     CoreImage
     */
    
    [self SetUpImageViewByType:VVImage];
}

- (void)SetUpImageViewByType:(NSInteger)type
{
    UIImage *image = [UIImage imageNamed:@"orange.jpg"];

    UIImageView *imageView;
    if (type != VVImage) {
        imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 20, WIDTH, WIDTH)];
        imageView.image = image;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.view addSubview:imageView];
    }
    
    switch (type) {
        case 0: // blurEffect
        {
            UIBlurEffect *beffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            UIVisualEffectView *view = [[UIVisualEffectView alloc]initWithEffect:beffect];
            view.frame = imageView.frame;
            [self.view addSubview:view];
        }
            break;
        case 1: // toolBar
        {
            UIToolbar *toolBar = [[UIToolbar alloc]initWithFrame:imageView.frame];
            toolBar.barStyle = UIBarStyleDefault;
            [self.view addSubview:toolBar];
        }
            break;
        case 2: // vImage
        {
            UIImage *vImage = [self boxblurImage:image withBlurNumber:0.999999];
            UIImageView *vImgv = [[UIImageView alloc]initWithFrame:CGRectMake(0, 20, WIDTH, WIDTH)];
            vImgv.contentMode = UIViewContentModeScaleAspectFill;
            vImgv.image = vImage;
            [self.view addSubview:vImgv];
        }
            break;
        case 3: // coreImage
        {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                CIContext *context = [CIContext contextWithOptions:nil];
                CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
                CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
                [filter setValue:ciImage forKey:kCIInputImageKey];
                //设置模糊程度
                [filter setValue:@30.0f forKey: @"inputRadius"];
                CIImage *result = [filter valueForKey:kCIOutputImageKey];
                CGRect frame = [ciImage extent];
                NSLog(@"%f,%f,%f,%f",frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
                CGImageRef outImage = [context createCGImage: result fromRect:ciImage.extent];
                UIImage * blurImage = [UIImage imageWithCGImage:outImage];
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = blurImage;
                });
            });
        }
            break;
        default:
            break;
    }
}
- (UIImage *)boxblurImage:(UIImage *)image withBlurNumber:(CGFloat)blur {
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    int boxSize = (int)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = image.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    vImage_Error error;
    
    void *pixelBuffer;
    //从CGImage中获取数据
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    //设置从CGImage获取对象的属性
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) *
                         CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
                                             outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGColorSpaceRelease(colorSpace);
    CGImageRelease(imageRef);
    
    return returnImage;
}

@end
