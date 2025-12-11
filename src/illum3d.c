#include <stdint.h>

#include "sysdev.h"
#include "fxp32.h"

/* compile: 
 * rv src/illum3d.c,src/fastfxp32.s out/illum3d.riv -r */

#define MIN(X, Y) ((X) < (Y) ? (X) : (Y))

struct vec2i {
    int32_t x, y;
};

struct vec3f {
    fxp32_t x, y, z;
};

void vec3f_zero(struct vec3f *dst) {
    dst->x = FXP32(0,0);
    dst->y = FXP32(0,0);
    dst->z = FXP32(0,0);
}

// sph_pos = {FXP32(0,0), FXP32(2,0), FXP32(16,0)};
// sun_dir = {0x00006880, 0x0000d106, 0x00006880};
// sun_dir = {0x00000000, 0x00010000, 0x00000000};

#define SPH_RADIUS FXP32(4,0) /* sphere radius */
#define FLR_OFFSET FXP32(-4,0) /* floor y offset */
#define TOP_OFFSET FXP32(16,0) /* ray void y offset */
#define ZBA_OFFSET FXP32(256,0) /* ray void z offset */

#define CAST_MIN_LIMIT 0x100
#define ILLUM_MIN_LIMIT 0x10
#define ILLUM_INIT_MOVE 0x1000

#define VP_X0 24 /* viewport x center */
#define VP_Y0 16 /* viewport y center */
#define VP_XL 49
#define VP_YL 33

#define RAY_ZV FRA32(0.74f) /* ray_dir z value */
#define RAY_MM FRA32(0.02313f) /* ray_dir x,y multiplier */
#define RAY_MAX_I 4096 /* max steps for each ray */

/* illumination values */
#define ILLUM_DIRECT FRA32(1.0f)
#define ILLUM_SHADOW FRA32(0.2f)
#define ILLUM_BLACK FRA32(0.0f)

void vp_put(uint32_t x, uint32_t y, uint32_t c) {
    TERM0->x = x;
    TERM0->y = y;
    TERM0->put = c;
}

/* set the unit direction vector from viewport position */
void init_view_ray(
    struct vec3f *ray_pos, 
    struct vec3f *ray_dir,
    const struct vec2i *vp_pos
) {
    ray_pos->x = FRA32(0.0f);
    ray_pos->y = FRA32(0.0f);
    ray_pos->z = FRA32(0.0f);
    ray_dir->x = fxp32_mul(FXP32(vp_pos->x - VP_X0, 0), RAY_MM);
    ray_dir->y = fxp32_mul(FXP32(VP_Y0 - vp_pos->y, 0), RAY_MM);
    ray_dir->z = RAY_ZV;
}

void init_sun_ray(struct vec3f *ray_dir) {
    ray_dir->x = 0x00006880;
    ray_dir->y = 0x0000d106;
    ray_dir->z = 0x00006880;
}

void move_ray_by(
    struct vec3f *ray_pos, 
    const struct vec3f *ray_dir,
    fxp32_t dist
) { 
    ray_pos->x += fxp32_mul(ray_dir->x, dist);
    ray_pos->y += fxp32_mul(ray_dir->y, dist);
    ray_pos->z += fxp32_mul(ray_dir->z, dist);
}

fxp32_t sph_dist_to(struct vec3f *pos) {
    fxp32_t dx = pos->x - FXP32(0,0);
    fxp32_t dy = pos->y - FXP32(2,0);
    fxp32_t dz = pos->z - FXP32(16,0);
    return fxp32_mul(dx, dx) + fxp32_mul(dy, dy) + fxp32_mul(dz, dz);
}

fxp32_t flr_dist_to(struct vec3f *pos) {
    return pos->y - FLR_OFFSET;
}

#define ESCAPED(P) ((P).y > TOP_OFFSET || (P).z > ZBA_OFFSET)

fxp32_t trace_illum(
    struct vec3f *ray_pos, 
    struct vec3f *ray_dir
) {
    init_sun_ray(ray_dir);
    move_ray_by(ray_pos, ray_dir, ILLUM_INIT_MOVE);
    
    uint32_t i;
    fxp32_t prev_dist;
    for (i = 0; i < RAY_MAX_I; i++) {
        fxp32_t sph_dist = sph_dist_to(ray_pos);
        fxp32_t flr_dist = flr_dist_to(ray_pos);
        fxp32_t min_dist = MIN(fxp32_sphsqrt(sph_dist) - SPH_RADIUS, flr_dist);
        if (min_dist < ILLUM_MIN_LIMIT) return ILLUM_SHADOW;
        move_ray_by(ray_pos, ray_dir, min_dist);

        if (ESCAPED(*ray_pos)) return ILLUM_DIRECT; /* full white */
    }

    return ILLUM_BLACK; /* dark */    
}

fxp32_t cast_ray(
    struct vec3f *ray_pos, 
    struct vec3f *ray_dir,
    const struct vec2i *vp_pos
) {
    init_view_ray(ray_pos, ray_dir, vp_pos);

    uint32_t i;
    for (i = 0; i < RAY_MAX_I; i++) {
        fxp32_t sph_dist = sph_dist_to(ray_pos);
        fxp32_t flr_dist = flr_dist_to(ray_pos);
        fxp32_t min_dist = MIN(fxp32_sphsqrt(sph_dist) - SPH_RADIUS, flr_dist);
        if (min_dist < CAST_MIN_LIMIT) return trace_illum(ray_pos, ray_dir);
        move_ray_by(ray_pos, ray_dir, min_dist);

        if (ESCAPED(*ray_pos)) return ILLUM_BLACK;
    }

    return ILLUM_BLACK;
}

char get_illum_char(fxp32_t illum) {
    if (illum < FXP32(0, 0x2000)) return ' ';
    if (illum < FXP32(0, 0x4000)) return '.';
    if (illum < FXP32(0, 0x8000)) return ':';
    if (illum < FXP32(1, 0x2000)) return '#';
    return '!';
}

void main(void) {
    struct vec2i vp_pos;
    struct vec3f ray_pos;
    struct vec3f ray_dir;

    for (vp_pos.y = 0; vp_pos.y < VP_YL; vp_pos.y += 2) {
        for (vp_pos.x = 0; vp_pos.x < VP_XL; vp_pos.x++) {
    // for (vp_pos.y = 16; vp_pos.y < 17; vp_pos.y += 2) {
    //     for (vp_pos.x = 24; vp_pos.x < 25; vp_pos.x++) {
            uint32_t y = vp_pos.y>>1;
            vp_put(vp_pos.x, y, '>');
            fxp32_t illum = cast_ray(&ray_pos, &ray_dir, &vp_pos);
            vp_put(vp_pos.x, y, get_illum_char(illum));
        }
    }
}
