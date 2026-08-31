/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Modified by:
 * Mateusz Zybura, Gabriel Zawiślak
 * (added the shared playfield geometry parameters)
 *
 * Description:
 * Package with vga related constants.
 */

package vga_pkg;

    // Parameters for VGA Display 1024 x 768 @ 60fps using a 40 MHz clock
    localparam HOR_PIXELS = 1024;
    localparam VER_PIXELS = 768;

    localparam HOR_TOTAL_TIME = 1344;
    localparam HOR_BLNK_START = 1024;
    localparam HOR_BLNK_TIME = 320;
    localparam HOR_SYNC_START = 1048;
    localparam HOR_SYNC_TIME = 136;

    localparam VER_TOTAL_TIME = 806;
    localparam VER_BLNK_START = 768;
    localparam VER_BLNK_TIME = 38;
    localparam VER_SYNC_START = 771;
    localparam VER_SYNC_TIME = 6;

    /**
     * Playfield geometry, shared between the physics (ball_pos,
     * paddle_pos) and the renderer (draw_paddle_ball, draw_bg) so the two
     * can never drift apart - a collision plane and the pixels drawn for
     * it always come from the same constant.
     */
    localparam int BALL_SIZE     = 16;
    localparam int PADDLE_HEIGHT = 100;
    localparam int PADDLE_WIDTH  = 8;

    localparam int P1_X_WALL = 46;                        // paddle 1's ball-facing edge
    localparam int P1_X_BACK = P1_X_WALL - PADDLE_WIDTH;  // paddle 1's back edge (drawing only)
    localparam int P2_X_WALL = HOR_PIXELS - 46;           // paddle 2's ball-facing edge
    localparam int P2_X_BACK = P2_X_WALL + PADDLE_WIDTH;  // paddle 2's back edge (drawing only)

    // Top/bottom playfield border: a visible line inset from the physical
    // screen edge, so the ball's bounce there is never hidden by monitor
    // overscan. Left/right have no such border - touching those edges
    // scores a point instead of bouncing.
    localparam int BORDER_MARGIN    = 12;
    localparam int BORDER_THICKNESS = 3;

endpackage
