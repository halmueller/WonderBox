/*
 *  WBGLFrameBuffer.h
 *  WonderBox
 *
 *  Created by Jean-Daniel Dupas.
 *  Copyright (c) 2004 - 2009 Jean-Daniel Dupas. All rights reserved.
 *
 *  This file is distributed under the MIT License. See LICENSE.TXT for details.
 */

#import <WonderBox/WBBase.h>
#import <OpenGL/OpenGL.h>

#import <Cocoa/Cocoa.h>

enum {
  kWBGLAttachementTypeBuffer  = 1,
  kWBGLAttachementTypeTexture = 2,
};

WB_OBJC_EXPORT
@interface WBGLFrameBufferAttachement : NSObject {
@private
  GLuint wb_name;
  GLenum wb_target;
  GLint wb_zoff, wb_level;
  GLuint wb_width, wb_height;

  struct {
    unsigned int type:2;
  } wb_fbaFlags;
}

+ (id)depthBufferWithBitsSize:(NSUInteger)bits width:(GLuint)w height:(GLuint)h context:(CGLContextObj)aContext;
+ (id)stencilBufferWithBitsSize:(NSUInteger)bits width:(GLuint)w height:(GLuint)h context:(CGLContextObj)aContext;

- (id)initWithRendererBuffer:(GLuint)aBuffer width:(GLuint)w height:(GLuint)h;

//- (id)initWithTexture:(GLuint)aTexture target:(GLenum)aTarget context:(CGLContextObj)theContext;

- (id)initWithTexture:(GLuint)aTexture target:(GLenum)aTarget width:(GLuint)w height:(GLuint)h;
- (id)initWithTexture:(GLuint)aTexture target:(GLenum)aTarget level:(GLint)aLevel width:(GLuint)w height:(GLuint)h;
- (id)initWithTexture:(GLuint)aTexture target:(GLenum)aTarget level:(GLint)aLevel zOffset:(GLint)offset width:(GLuint)w height:(GLuint)h;

/* helper */
- (id)initRendererBufferWithFormat:(GLenum)format width:(GLuint)w height:(GLuint)h context:(CGLContextObj)CGL_MACRO_CONTEXT;

// destroy underlying object
- (void)delete:(CGLContextObj)aContext;

- (NSUInteger)type;

- (CGSize)size;

- (GLuint)name;
- (GLenum)target;

- (GLint)level; // texture only
- (GLint)zOffset; // 3D texture

@end

enum {
  kWBGLFrameBufferNoBuffer = -1,
};

WB_OBJC_EXPORT
@interface WBGLFrameBuffer : NSObject {
@private
  GLuint wb_fbo;
  GLint wb_viewport[4];
  NSMapTable *wb_attachements;
  WBGLFrameBufferAttachement *wb_depth, *wb_stencil;
  struct {
    unsigned int blit:1;
  } aty_fbFlags;
}

- (id)initWithContext:(CGLContextObj)aContext;

// cleanup underlying gl objects
// use to release resources in a deterministic way.
- (void)delete:(CGLContextObj)aContext;

- (GLuint)frameBufferObject;

- (NSUInteger)maxBufferCount:(CGLContextObj)aContext;
// return 0 if FBO complete, else return a status enum.
- (GLenum)status:(GLenum)mode context:(CGLContextObj)context;

- (void)bind:(CGLContextObj)aContext;
- (void)unbind:(CGLContextObj)aContext;

// mode can be GL_READ_FRAMEBUFFER_EXT or GL_DRAW_FRAMEBUFFER_EXT
- (void)bindMode:(GLenum)mode context:(CGLContextObj)aContext;
- (void)unbindMode:(GLenum)mode context:(CGLContextObj)aContext;

- (void)resetViewPort:(CGLContextObj)aContext;

// -1 mean GL_NONE
- (void)setReadBuffer:(NSInteger)anIdx context:(CGLContextObj)aContext;
- (void)setWriteBuffer:(NSInteger)anIdx context:(CGLContextObj)aContext;

- (WBGLFrameBufferAttachement *)depthBuffer;
- (void)setDepthBuffer:(WBGLFrameBufferAttachement *)aBuffer context:(CGLContextObj)aContext;

- (WBGLFrameBufferAttachement *)stencilBuffer;
- (void)setStencilBuffer:(WBGLFrameBufferAttachement *)aBuffer context:(CGLContextObj)aContext;

- (NSArray *)colorBuffers;
- (WBGLFrameBufferAttachement *)colorBufferAtIndex:(NSUInteger)anIndex;
- (void)setColorBuffer:(WBGLFrameBufferAttachement *)aBuffer atIndex:(NSUInteger)anIndex context:(CGLContextObj)aContext;

@end

WB_EXPORT
NSString *WBGLFrameBufferGetErrorString(GLenum error);
