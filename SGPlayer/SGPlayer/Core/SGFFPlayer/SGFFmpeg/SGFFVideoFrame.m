//
//  SGFFVideoFrame.m
//  SGMediaKit
//
//  Created by Single on 2017/2/17.
//  Copyright © 2017年 single. All rights reserved.
//

#import "SGFFVideoFrame.h"
#import "SGFFTools.h"
#import "SGYUVTools.h"

@implementation SGFFVideoFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeVideo;
}

- (void)startDrawing
{
    self->_drawing = YES;
    if ([self.delegate respondsToSelector:@selector(videoFrameDidStartDrawing:)]) {
        [self.delegate videoFrameDidStartDrawing:self];
    }
}

- (void)stopDrawing
{
    self->_drawing = NO;
    if ([self.delegate respondsToSelector:@selector(videoFrameDidStopDrawing:)]) {
        [self.delegate videoFrameDidStopDrawing:self];
    }
}

- (void)cancel
{
    if ([self.delegate respondsToSelector:@selector(videoFrameDidCancel:)]) {
        [self.delegate videoFrameDidCancel:self];
    }
}

@end


@implementation SGFFAVYUVVideoFrame

{
    size_t channel_pixels_buffer_size[SGYUVChannelCount];
    size_t channel_lenghts[SGYUVChannelCount];
}

- (SGFFFrameType)type
{
    return SGFFFrameTypeAVYUVVideo;
}

+ (instancetype)videoFrame
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
        channel_lenghts[SGYUVChannelLuma] = 0;
        channel_lenghts[SGYUVChannelChromaB] = 0;
        channel_lenghts[SGYUVChannelChromaR] = 0;
        channel_pixels_buffer_size[SGYUVChannelLuma] = 0;
        channel_pixels_buffer_size[SGYUVChannelChromaB] = 0;
        channel_pixels_buffer_size[SGYUVChannelChromaR] = 0;
        channel_pixels[SGYUVChannelLuma] = NULL;
        channel_pixels[SGYUVChannelChromaB] = NULL;
        channel_pixels[SGYUVChannelChromaR] = NULL;
        static int count = 0;
        count++;
        NSLog(@"SGFFAVYUVVideoFrame 新建, count : %d", count);
    }
    return self;
}

- (void)setFrameData:(AVFrame *)frame width:(int)width height:(int)height
{
    self->_width = width;
    self->_height = height;
    
    int linesize_y = frame->linesize[SGYUVChannelLuma];
    int linesize_u = frame->linesize[SGYUVChannelChromaB];
    int linesize_v = frame->linesize[SGYUVChannelChromaR];
    
    UInt8 * buffer_y = channel_pixels[SGYUVChannelLuma];
    UInt8 * buffer_u = channel_pixels[SGYUVChannelChromaB];
    UInt8 * buffer_v = channel_pixels[SGYUVChannelChromaR];
    
    size_t buffer_size_y = channel_pixels_buffer_size[SGYUVChannelLuma];
    size_t buffer_size_u = channel_pixels_buffer_size[SGYUVChannelChromaB];
    size_t buffer_size_v = channel_pixels_buffer_size[SGYUVChannelChromaR];
    
    size_t need_size_y = SGYUVChannelFilterNeedSize(linesize_y, width, height, 1);
    if (buffer_size_y < need_size_y) {
        if (buffer_size_y > 0 && buffer_y != NULL) {
            free(buffer_y);
        }
        channel_pixels_buffer_size[SGYUVChannelLuma] = need_size_y;
        channel_pixels[SGYUVChannelLuma] = malloc(need_size_y);
    }
    size_t need_size_u = SGYUVChannelFilterNeedSize(linesize_u, width / 2, height / 2, 1);
    if (buffer_size_u < need_size_u) {
        if (buffer_size_u > 0 && buffer_u != NULL) {
            free(buffer_u);
        }
        channel_pixels_buffer_size[SGYUVChannelChromaB] = need_size_u;
        channel_pixels[SGYUVChannelChromaB] = malloc(need_size_u);
    }
    size_t need_size_v = SGYUVChannelFilterNeedSize(linesize_v, width / 2, height / 2, 1);
    if (buffer_size_v < need_size_v) {
        if (buffer_size_v > 0 && buffer_v != NULL) {
            free(buffer_v);
        }
        channel_pixels_buffer_size[SGYUVChannelChromaR] = need_size_v;
        channel_pixels[SGYUVChannelChromaR] = malloc(need_size_v);
    }
    
    SGYUVChannelFilter(frame->data[SGYUVChannelLuma],
            linesize_y,
            width,
            height,
            channel_pixels[SGYUVChannelLuma],
            channel_pixels_buffer_size[SGYUVChannelLuma],
            1);
    SGYUVChannelFilter(frame->data[SGYUVChannelChromaB],
            linesize_u,
            width / 2,
            height / 2,
            channel_pixels[SGYUVChannelChromaB],
            channel_pixels_buffer_size[SGYUVChannelChromaB],
            1);
    SGYUVChannelFilter(frame->data[SGYUVChannelChromaR],
            linesize_v,
            width / 2,
            height / 2,
            channel_pixels[SGYUVChannelChromaR],
            channel_pixels_buffer_size[SGYUVChannelChromaR],
            1);
}

- (void)flush
{
    self->_width = 0;
    self->_height = 0;
    channel_lenghts[SGYUVChannelLuma] = 0;
    channel_lenghts[SGYUVChannelChromaB] = 0;
    channel_lenghts[SGYUVChannelChromaR] = 0;
    if (channel_pixels[SGYUVChannelLuma] != NULL && channel_pixels_buffer_size[SGYUVChannelLuma] > 0) {
        memset(channel_pixels[SGYUVChannelLuma], 0, channel_pixels_buffer_size[SGYUVChannelLuma]);
    }
    if (channel_pixels[SGYUVChannelChromaB] != NULL && channel_pixels_buffer_size[SGYUVChannelChromaB] > 0) {
        memset(channel_pixels[SGYUVChannelChromaB], 0, channel_pixels_buffer_size[SGYUVChannelChromaB]);
    }
    if (channel_pixels[SGYUVChannelChromaR] != NULL && channel_pixels_buffer_size[SGYUVChannelChromaR] > 0) {
        memset(channel_pixels[SGYUVChannelChromaR], 0, channel_pixels_buffer_size[SGYUVChannelChromaR]);
    }
}

- (int)size
{
    return (int)(channel_lenghts[SGYUVChannelLuma] + channel_lenghts[SGYUVChannelChromaB] + channel_lenghts[SGYUVChannelChromaR]);
}

- (void)dealloc
{
    if (channel_pixels[SGYUVChannelLuma] != NULL && channel_pixels_buffer_size[SGYUVChannelLuma] > 0) {
        free(channel_pixels[SGYUVChannelLuma]);
    }
    if (channel_pixels[SGYUVChannelChromaB] != NULL && channel_pixels_buffer_size[SGYUVChannelChromaB] > 0) {
        free(channel_pixels[SGYUVChannelChromaB]);
    }
    if (channel_pixels[SGYUVChannelChromaR] != NULL && channel_pixels_buffer_size[SGYUVChannelChromaR] > 0) {
        free(channel_pixels[SGYUVChannelChromaR]);
    }
    static int count = 0;
    count++;
    NSLog(@"SGFFAVYUVVideoFrame 释放, count : %d", count);
}

@end


@implementation SGFFCVYUVVideoFrame

- (SGFFFrameType)type
{
    return SGFFFrameTypeCVYUVVideo;
}

- (instancetype)initWithAVPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    if (self = [super init]) {
        self->_pixelBuffer = pixelBuffer;
    }
    return self;
}

- (void)dealloc
{
    if (self->_pixelBuffer) {
        CVPixelBufferRelease(self->_pixelBuffer);
        self->_pixelBuffer = NULL;
    }
}

@end
