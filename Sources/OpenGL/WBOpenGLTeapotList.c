//-------------------------------------------------------------------------
//
// (c) Copyright 1994, Mark J. Kilgard.
//     Modifications by Philip Rideout.
//
// (c) Copyright 1993, Silicon Graphics, Inc.
//
// ALL RIGHTS RESERVED
//
// Permission to use, copy, modify, and distribute this software
// for any purpose and without fee is hereby granted, provided
// that the above copyright notice appear in all copies and that
// both the copyright notice and this permission notice appear in
// supporting documentation, and that the name of Silicon
// Graphics, Inc. not be used in advertising or publicity
// pertaining to distribution of the software without specific,
// written prior permission.
//
// THE MATERIAL EMBODIED ON THIS SOFTWARE IS PROVIDED TO YOU
// "AS-IS" AND WITHOUT WARRANTY OF ANY KIND, EXPRESS, IMPLIED OR
// OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF
// MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.  IN NO
// EVENT SHALL SILICON GRAPHICS, INC.  BE LIABLE TO YOU OR ANYONE
// ELSE FOR ANY DIRECT, SPECIAL, INCIDENTAL, INDIRECT OR
// CONSEQUENTIAL DAMAGES OF ANY KIND, OR ANY DAMAGES WHATSOEVER,
// INCLUDING WITHOUT LIMITATION, LOSS OF PROFIT, LOSS OF USE,
// SAVINGS OR REVENUE, OR THE CLAIMS OF THIRD PARTIES, WHETHER OR
// NOT SILICON GRAPHICS, INC.  HAS BEEN ADVISED OF THE POSSIBILITY
// OF SUCH LOSS, HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// ARISING OUT OF OR IN CONNECTION WITH THE POSSESSION, USE OR
// PERFORMANCE OF THIS SOFTWARE.
//
// US Government Users Restricted Rights
//
// Use, duplication, or disclosure by the Government is subject to
// restrictions set forth in FAR 52.227.19(c)(2) or subparagraph
// (c)(1)(ii) of the Rights in Technical UniformData and Computer
// Software clause at DFARS 252.227-7013 and/or in similar or
// successor clauses in the FAR or the DOD or NASA FAR
// Supplement.  Unpublished-- rights reserved under the copyright
// laws of the United States.  Contractor/manufacturer is Silicon
// Graphics, Inc., 2011 N.  Shoreline Blvd., Mountain View, CA
// 94039-7311.
//
// OpenGL(TM) is a trademark of Silicon Graphics, Inc.
//
//-------------------------------------------------------------------------
//
// Rim, body, lid, and bottom data must be reflected in x and y;
// handle and spout data across the y axis only.
//
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
//
//	File: OpenGLTeapotList.c
//
//  Abstract: Draw an OpenGL teapot.
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Apple Inc. ("Apple") in consideration of your agreement to the
//  following terms, and your use, installation, modification or
//  redistribution of this Apple software constitutes acceptance of these
//  terms.  If you do not agree with these terms, please do not use,
//  install, modify or redistribute this Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc.
//  may be used to endorse or promote products derived from the Apple
//  Software without specific prior written permission from Apple.  Except
//  as expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2008 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------

#include "WBOpenGLTeapotList.h"

#import <OpenGL/CGLMacro.h>
//-------------------------------------------------------------------------

//-------------------------------------------------------------------------

#define kNumTeapotPoints 135

//-------------------------------------------------------------------------

//-------------------------------------------------------------------------

static GLint patchdata[kNumTeapotPoints][16] =
{
	// rim
	{102, 103, 104, 105, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},

	// body
	{12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27},
	{24, 25, 26, 27, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40},

	// lid
	{127, 128, 129, 130, 97, 98, 99, 100, 101, 101, 101, 101, 0, 1, 2, 3},
	{0, 1, 2, 3, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117},

	// bottom
	{131, 132, 133, 134, 124, 122, 119, 121, 123, 126, 125, 120, 40, 39, 38, 37},

	// handle
	{41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56},
	{53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 28, 65, 66, 67},

	// spout
	{68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83},
	{80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95}
};

//-------------------------------------------------------------------------

static GLfloat cpdata[][3] =
{
	{0.2f, 0, 2.7f},
	{0.2f, -0.112f, 2.7f},
	{0.112f, -0.2f, 2.7f},
	{0, -0.2f, 2.7f},
	{1.3375f, 0, 2.53125f},
	{1.3375f, -0.749f, 2.53125f},
	{0.749f, -1.3375f, 2.53125f},
	{0, -1.3375f, 2.53125f},
	{1.4375f, 0, 2.53125f},
	{1.4375f, -0.805f, 2.53125f},
	{0.805f, -1.4375f, 2.53125f},
	{0, -1.4375f, 2.53125f},
	{1.5f, 0, 2.4f},
	{1.5f, -0.84f, 2.4f},
	{0.84f, -1.5f, 2.4f},
	{0, -1.5f, 2.4f},
	{1.75f, 0, 1.875f},
	{1.75f, -0.98f, 1.875f},
	{0.98f, -1.75f, 1.875f},
	{0, -1.75f, 1.875f},
	{2, 0, 1.35f},
	{2, -1.12f, 1.35f},
	{1.12f, -2, 1.35f},
	{0, -2, 1.35f},
	{2, 0, 0.9f},
	{2, -1.12f, 0.9f},
	{1.12f, -2, 0.9f},
	{0, -2, 0.9f},
	{-2, 0, 0.9f},
	{2, 0, 0.45f},
	{2, -1.12f, 0.45f},
	{1.12f, -2, 0.45f},
	{0, -2, 0.45f},
	{1.5f, 0, 0.225f},
	{1.5f, -0.84f, 0.225f},
	{0.84f, -1.5f, 0.225f},
	{0, -1.5f, 0.225f},
	{1.5f, 0, 0.15f},
	{1.5f, -0.84f, 0.15f},
	{0.84f, -1.5f, 0.15f},
	{0, -1.5f, 0.15f},
	{-1.6f, 0, 2.025f},
	{-1.6f, -0.3f, 2.025f},
	{-1.5f, -0.3f, 2.25f},
	{-1.5f, 0, 2.25f},
	{-2.3f, 0, 2.025f},
	{-2.3f, -0.3f, 2.025f},
	{-2.5f, -0.3f, 2.25f},
	{-2.5f, 0, 2.25f},
	{-2.7f, 0, 2.025f},
	{-2.7f, -0.3f, 2.025f},
	{-3, -0.3f, 2.25f},
	{-3, 0, 2.25f},
	{-2.7f, 0, 1.8f},
	{-2.7f, -0.3f, 1.8f},
	{-3, -0.3f, 1.8f},
	{-3, 0, 1.8f},
	{-2.7f, 0, 1.575f},
	{-2.7f, -0.3f, 1.575f},
	{-3, -0.3f, 1.35f},
	{-3, 0, 1.35f},
	{-2.5f, 0, 1.125f},
	{-2.5f, -0.3f, 1.125f},
	{-2.65f, -0.3f, 0.9375f},
	{-2.65f, 0, 0.9375f},
	{-2, -0.3f, 0.9f},
	{-1.9f, -0.3f, 0.6f},
	{-1.9f, 0, 0.6f},
	{1.7f, 0, 1.425f},
	{1.7f, -0.66f, 1.425f},
	{1.7f, -0.66f, 0.6f},
	{1.7f, 0, 0.6f},
	{2.6f, 0, 1.425f},
	{2.6f, -0.66f, 1.425f},
	{3.1f, -0.66f, 0.825f},
	{3.1f, 0, 0.825f},
	{2.3f, 0, 2.1f},
	{2.3f, -0.25f, 2.1f},
	{2.4f, -0.25f, 2.025f},
	{2.4f, 0, 2.025f},
	{2.7f, 0, 2.4f},
	{2.7f, -0.25f, 2.4f},
	{3.3f, -0.25f, 2.4f},
	{3.3f, 0, 2.4f},
	{2.8f, 0, 2.475f},
	{2.8f, -0.25f, 2.475f},
	{3.525f, -0.25f, 2.49375f},
	{3.525f, 0, 2.49375f},
	{2.9f, 0, 2.475f},
	{2.9f, -0.15f, 2.475f},
	{3.45f, -0.15f, 2.5125f},
	{3.45f, 0, 2.5125f},
	{2.8f, 0, 2.4f},
	{2.8f, -0.15f, 2.4f},
	{3.2f, -0.15f, 2.4f},
	{3.2f, 0, 2.4f},
	{0, 0, 3.15f}, // north pole
	{0.8f, 0, 3.15f},
	{0.8f, -0.45f, 3.15f},
	{0.45f, -0.8f, 3.15f},
	{0, -0.8f, 3.15f},
	{0, 0, 2.85f},
	{1.4f, 0, 2.4f},
	{1.4f, -0.784f, 2.4f},
	{0.784f, -1.4f, 2.4f},
	{0, -1.4f, 2.4f},
	{0.4f, 0, 2.55f},
	{0.4f, -0.224f, 2.55f},
	{0.224f, -0.4f, 2.55f},
	{0, -0.4f, 2.55f},
	{1.3f, 0, 2.55f},
	{1.3f, -0.728f, 2.55f},
	{0.728f, -1.3f, 2.55f},
	{0, -1.3f, 2.55f},
	
	// bottom edge of lid
	{1.4f, 0, 2.4f},
	{1.4f, -0.728f, 2.4f},
	{0.728f, -1.4f, 2.4f},
	{0, -1.4f, 2.4f},

	// bottom
	{0, 0, 0},
	{1.425f, -0.798f, 0},
	{1.5f, 0, 0.075f},
	{1.425f, 0, 0},

	{0.798f, -1.425f, 0},
	{0, -1.5f, 0.075f},
	{0, -1.425f, 0},
	{1.5f, -0.84f, 0.075f},
	{0.84f, -1.5f, 0.075f},

	// Top cap
	{.03f, 0, 3.15f},
	{.02f, -.01f, 3.15f},
	{.01f, -.02f, 3.15f},
	{0, -.03f, 3.15f},

	// Bottom cap
	{0, -.03f, 0},
	{.01f, -.02f, 0},
	{.02f, -.01f, 0},
	{.03f, 0, 0},

	// Spout closure
	{2.8f, 0, 2.4f},
	{2.8f, 0.15f, 2.4f},
	{3.2f, 0.15f, 2.4f},
	{3.2f, 0, 2.4f},

	{3.2f, 0, 2.4f},
	{3.2f, -0.15f, 2.4f},
	{2.8f, -0.15f, 2.4f},
	{2.8f, 0, 2.4f},
};

//-------------------------------------------------------------------------

static GLfloat tex[2][2][2] =
{
  { {0, 0}, {1, 0}},
  { {0, 1}, {1, 1}},
};

//-------------------------------------------------------------------------

//-------------------------------------------------------------------------
//
// Returns the number of vertices sent to GL.
//
//-------------------------------------------------------------------------

GLint WBOpenGLTeapotGenerate(CGLContextObj theContext, const GLint theGridCount, const GLdouble theTeapotScale, const GLenum theTeapotType)
{
	register GLint    grid  = theGridCount;
	register GLdouble scale = theTeapotScale; 
  CGLContextObj CGL_MACRO_CONTEXT = theContext;
  
	GLfloat   p[4][4][3];
	GLfloat   q[4][4][3];
	GLfloat   r[4][4][3];
	GLfloat   s[4][4][3];
		
	register GLint  i;
	register GLint  j;
	register GLint  k;
	register GLint  l;
	
	register GLint vertexCount = 0;

	// Make polygons wind CCW by scaling by -1.
	
	scale *= -1;

	glPushAttrib(GL_ENABLE_BIT | GL_EVAL_BIT);
	
		glEnable(GL_AUTO_NORMAL);
		glEnable(GL_NORMALIZE);
		glEnable(GL_MAP2_VERTEX_3);
		glEnable(GL_MAP2_TEXTURE_COORD_2);
		
		glPushMatrix();
		
			glRotatef(90, 1, 0, 0);
			glScaled(0.5 * scale, 0.5 * scale, 0.5 * scale);
			glTranslated(0, 0, -1.5);

			for (i = 0; i < 10; i++)
			{
				for (j = 0; j < 4; j++)
				{
					for (k = 0; k < 4; k++)
					{
						for (l = 0; l < 3; l++)
						{
							p[j][k][l] = cpdata[patchdata[i][j * 4 + k]][l];
							q[j][k][l] = cpdata[patchdata[i][j * 4 + (3 - k)]][l];
							
							if (l == 1)
							{
								q[j][k][l] *= -1;
							} // if
							
							if (i < 6)
							{
								r[j][k][l] = cpdata[patchdata[i][j * 4 + (3 - k)]][l];
								
								if (l == 0)
								{
									r[j][k][l] *= -1;
								} // if
								
								s[j][k][l] = cpdata[patchdata[i][j * 4 + k]][l];
								
								if (l == 0)
								{
									s[j][k][l] *= -1;
								} // if
								
								if (l == 1)
								{
									s[j][k][l] *= -1;
								} // if
							} // if
						} // for l
					} // for k
				} // for j
				
				glMap2f(GL_MAP2_TEXTURE_COORD_2, 0, 1, 2, 2, 1, 0, 4, 2, &tex[0][0][0]);
				glMap2f(GL_MAP2_VERTEX_3, 0, 1, 3, 4, 0, 1, 12, 4, &p[0][0][0]);
				glMapGrid2f(grid, 0, 1, grid, 0, 1);
				glEvalMesh2(theTeapotType, 0, grid, 0, grid);
				
				vertexCount += grid * grid;
				
				glMap2f(GL_MAP2_VERTEX_3, 0, 1, 3, 4, 0, 1, 12, 4, &q[0][0][0]);
				glEvalMesh2(theTeapotType, 0, grid, 0, grid);
				
				vertexCount += grid * grid;
				
				if (i < 6)
				{
					glMap2f(GL_MAP2_VERTEX_3, 0, 1, 3, 4, 0, 1, 12, 4, &r[0][0][0]);
					glEvalMesh2(theTeapotType, 0, grid, 0, grid);
					
					vertexCount += grid * grid;
					
					glMap2f(GL_MAP2_VERTEX_3, 0, 1, 3, 4, 0, 1, 12, 4, &s[0][0][0]);
					glEvalMesh2(theTeapotType, 0, grid, 0, grid);
					
					vertexCount += grid * grid;
				} // if
			} // for i

			// Draw the tiny quads at the top and bottom.
			
			glBegin(GL_QUADS);
			
				glTexCoord2f(.025f,.025f);

				glNormal3f(0, 0, 1);
				glVertex3f(0,.03f,cpdata[127][2]);
				glVertex3f(.03f,0,cpdata[127][2]);
				glVertex3f(0,-.03f,cpdata[127][2]);
				glVertex3f(-.03f,0,cpdata[127][2]);

				glNormal3f(0, 0, -1);
				glVertex3f(-.03f,0,cpdata[131][2]);
				glVertex3f(0,-.03f,cpdata[131][2]);
				glVertex3f(.03f,0,cpdata[131][2]);
				glVertex3f(0,.03f,cpdata[131][2]);

				// Close off the spout.

				glNormal3f(0, 0, 1);

				for (i = 135; i < 143; ++i)
				{
					glVertex3fv(cpdata[i]);
				} // for

			glEnd();

		glPopMatrix();
		
		glDisable(GL_MAP2_TEXTURE_COORD_2);
		glDisable(GL_MAP2_VERTEX_3);
		glDisable(GL_NORMALIZE);
		glDisable(GL_AUTO_NORMAL);

	glPopAttrib();
	
	return vertexCount;
} // DrawTeapot
