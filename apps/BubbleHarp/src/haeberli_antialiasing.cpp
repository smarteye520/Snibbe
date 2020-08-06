
/*
 *   Antialised 2D points, lines and rectangles for iOS devices
 *
 *   The feathered edge of these primitives is width/2.0.
 *
 *   If you are working in screen space, the width should be 1.0.
 *
 *       Paul Haeberli 2010
 *
 */
void fillSmoothRectangle(CGRect *r, float width)
{
    GLfloat rectVertices[10][2];
    GLfloat curc[4]; 
    GLint   ir, ig, ib, ia;
    
    // fill the inside of the rectangle
    rectVertices[0][0] = r->origin.x;
    rectVertices[0][1] = r->origin.y;
    rectVertices[1][0] = r->origin.x+r->size.width;
    rectVertices[1][1] = r->origin.y;
    rectVertices[2][0] = r->origin.x;
    rectVertices[2][1] = r->origin.y+r->size.height;
    rectVertices[3][0] = r->origin.x+r->size.width;
    rectVertices[3][1] = r->origin.y+r->size.height;
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, rectVertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    rectVertices[0][0] = r->origin.x;
    rectVertices[0][1] = r->origin.y;
    rectVertices[1][0] = r->origin.x-width;
    rectVertices[1][1] = r->origin.y-width;
    rectVertices[2][0] = r->origin.x+r->size.width;
    rectVertices[2][1] = r->origin.y;
    rectVertices[3][0] = r->origin.x+r->size.width+width;
    rectVertices[3][1] = r->origin.y-width;
    rectVertices[4][0] = r->origin.x+r->size.width;
    rectVertices[4][1] = r->origin.y+r->size.height;
    rectVertices[5][0] = r->origin.x+r->size.width+width;
    rectVertices[5][1] = r->origin.y+r->size.height+width;
    rectVertices[6][0] = r->origin.x;
    rectVertices[6][1] = r->origin.y+r->size.height;
    rectVertices[7][0] = r->origin.x-width;
    rectVertices[7][1] = r->origin.y+r->size.height+width;
    rectVertices[8][0] = r->origin.x;
    rectVertices[8][1] = r->origin.y;
    rectVertices[9][0] = r->origin.x-width;
    rectVertices[9][1] = r->origin.y-width;
    
    glGetFloatv(GL_CURRENT_COLOR, curc);
    ir = 255.0*curc[0];
    ig = 255.0*curc[1];
    ib = 255.0*curc[2];
    ia = 255.0*curc[3];

    const GLubyte rectColors[] = {
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
    };
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, rectVertices);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, rectColors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 10);
    glDisableClientState(GL_COLOR_ARRAY);
}

void drawSmoothLine(CGPoint *pos1, CGPoint *pos2, float width)
{
    GLfloat lineVertices[12], curc[4]; 
    GLint   ir, ig, ib, ia;
    CGPoint dir, tan;
    
    width = width*8;
    dir.x = pos2->x - pos1->x;
    dir.y = pos2->y - pos1->y;
    float len = sqrtf(dir.x*dir.x+dir.y*dir.y);
    if(len<0.00001)
        return;
    dir.x = dir.x/len;
    dir.y = dir.y/len;
    tan.x = -width*dir.y;
    tan.y = width*dir.x;
    
    lineVertices[0] = pos1->x + tan.x;
    lineVertices[1] = pos1->y + tan.y;
    lineVertices[2] = pos2->x + tan.x;
    lineVertices[3] = pos2->y + tan.y;
    lineVertices[4] = pos1->x;
    lineVertices[5] = pos1->y;
    lineVertices[6] = pos2->x;
    lineVertices[7] = pos2->y;
    lineVertices[8] = pos1->x - tan.x;
    lineVertices[9] = pos1->y - tan.y;
    lineVertices[10] = pos2->x - tan.x;
    lineVertices[11] = pos2->y - tan.y;
    
    glGetFloatv(GL_CURRENT_COLOR,curc);
    ir = 255.0*curc[0];
    ig = 255.0*curc[1];
    ib = 255.0*curc[2];
    ia = 255.0*curc[3];

    const GLubyte lineColors[] = {
        ir, ig, ib, 0,
        ir, ig, ib, 0,
        ir, ig, ib, ia,
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
    };
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, lineVertices);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, lineColors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);
    glDisableClientState(GL_COLOR_ARRAY);
}


void drawSmoothPoint(CGPoint *pos, float width)
{
    GLfloat pntVertices[12], curc[4]; 
    GLint   ir, ig, ib, ia;
    
    pntVertices[0] = pos->x;
    pntVertices[1] = pos->y;
    pntVertices[2] = pos->x - width;
    pntVertices[3] = pos->y - width;
    pntVertices[4] = pos->x - width;
    pntVertices[5] = pos->y + width;
    pntVertices[6] = pos->x + width;
    pntVertices[7] = pos->y + width;
    pntVertices[8] = pos->x + width;
    pntVertices[9] = pos->y - width;
    pntVertices[10] = pos->x - width;
    pntVertices[11] = pos->y - width;
    
    glGetFloatv(GL_CURRENT_COLOR,curc);
    ir = 255.0*curc[0];
    ig = 255.0*curc[1];
    ib = 255.0*curc[2];
    ia = 255.0*curc[3];

    const GLubyte pntColors[] = {
        ir, ig, ib, ia,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
        ir, ig, ib, 0,
    };
    
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, pntVertices);
    glColorPointer(4, GL_UNSIGNED_BYTE, 0, pntColors);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 6);
    glDisableClientState(GL_COLOR_ARRAY);
}
