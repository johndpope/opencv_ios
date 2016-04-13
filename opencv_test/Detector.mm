//
//  Detector.m
//  HelloOpenCV
//
//  Created by Masaaki Uno on 2016/01/06.
//  Copyright © 2016年 Masaaki Uno. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "opencv_test-Bridging-Header.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>


@interface Detector()
{
    cv::CascadeClassifier cascade;
}
@end

@implementation Detector: NSObject

- (id)init {
    self = [super init];
    
    // 分類器の読み込み
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *path = [bundle pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    std::string cascadeName = (char *)[path UTF8String];
    
    if(!cascade.load(cascadeName)) {
        return nil;
    }
    
    return self;
}

- (UIImage *)recognizeFace:(UIImage *)image {
    // UIImage -> cv::Mat変換
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat mat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(mat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    mat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    // 顔検出
    std::vector<cv::Rect> faces;
    cascade.detectMultiScale(mat, faces,
                             1.1, 2,
                             CV_HAAR_SCALE_IMAGE,
                             cv::Size(30, 30));
    
    // 顔の位置に丸を描く
    std::vector<cv::Rect>::const_iterator r = faces.begin();
    for(; r != faces.end(); ++r) {
        cv::Point center;
        int radius;
        center.x = cv::saturate_cast<int>((r->x + r->width*0.5));
        center.y = cv::saturate_cast<int>((r->y + r->height*0.5));
        radius = cv::saturate_cast<int>((r->width + r->height));
        cv::circle(mat, center, radius, cv::Scalar(80,80,255), 3, 8, 0 );
    }
    
    
    // cv::Mat -> UIImage変換
    UIImage *resultImage = MatToUIImage(mat);
    
    return resultImage;
}

@end

@interface Akaze()
{
    cv::Ptr<cv::AKAZE> detector;
    cv::Mat img;
    cv::Mat descriptor;
    std::vector<cv::KeyPoint> keypoints;
}
@end

@implementation Akaze: NSObject
-(id)init{
    self = [super init];
    
    return self;
}

-(UInt64)getPoints {
    return keypoints.size();
}

-(cv::Mat)getDescriptor {
    cv::Mat result;
    detector->compute(img, keypoints, result);
    return result;
}

-(std::vector<cv::KeyPoint>)getKeypoints {
    return std::vector<cv::KeyPoint>();
}

-(UIImage *)recognizePoints:(UIImage *)image {
    // UIImage -> cv::Mat変換
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat mat(rows, cols, CV_8UC4);
    img = mat;
    
    CGContextRef contextRef = CGBitmapContextCreate(mat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    mat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    cv::cvtColor(mat, mat, CV_RGBA2RGB);
    
    detector = cv::AKAZE::create();
    detector->detect(mat, keypoints);
    
    cv::drawKeypoints(mat, keypoints, mat);
    
    UIImage *resultImage = MatToUIImage(mat);
    return resultImage;
}
@end

@interface AkazeMatch()
{
}
@end

@implementation AkazeMatch: Akaze
-(UIImage *)match:(UIImage *)image {
    [self recognizePoints:image];
    return nil; // temp
}
@end




@interface Orb()
{
    UInt64 points;
    cv::Mat descriptor;
    std::vector<cv::KeyPoint> keypoints;
}
@end

@implementation Orb: NSObject
-(id)init{
    self = [super init];
    
    return self;
}

-(UInt64)getPoints {
    return points;
}

-(UIImage *)recognizePoints:(UIImage *)image {
    // UIImage -> cv::Mat変換
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat mat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(mat.data,
                                                    cols,
                                                    rows,
                                                    8,
                                                    mat.step[0],
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    cv::cvtColor(mat, mat, CV_RGBA2RGB);
    
    auto detector = cv::ORB::create();
    std::vector<cv::KeyPoint> keyPoints;
    detector->detect(mat, keyPoints);
    points = keyPoints.size();
    
    //    cv::Mat output;
    cv::drawKeypoints(mat, keyPoints, mat);
    //, cv::Scalar::all(-1),cv::DrawMatchesFlags::DRAW_RICH_KEYPOINTS);
    
    UIImage *resultImage = MatToUIImage(mat);
    return resultImage;
}
@end