extends Node
## Global game constants and configuration.

# ── Timing ──
const FPS := 60
const FRAME_TIME := 1.0 / 60.0

# ── Resolution ──
const GAME_WIDTH := 384
const GAME_HEIGHT := 224

# ── Physics ──
const GRAVITY := 1200.0
const MAX_FALL_SPEED := 800.0

# ── Hitstop ──
const HITSTOP_LIGHT := 8
const HITSTOP_MEDIUM := 10
const HITSTOP_HEAVY := 12
const HITSTOP_SUPER := 16

# ── Blockstun ──
const BLOCKSTUN_LIGHT_GROUND := 9
const BLOCKSTUN_MEDIUM_GROUND := 13
const BLOCKSTUN_HEAVY_GROUND := 17
const BLOCKSTUN_LIGHT_AIR := 12
const BLOCKSTUN_MEDIUM_AIR := 16
const BLOCKSTUN_HEAVY_AIR := 20

# ── Chip Damage ──
const CHIP_RATIO := 0.2

# ── Perfect Block ──
const PERFECT_BLOCK_WINDOW := 5
const PERFECT_BLOCK_BLOCKSTUN_MUL := 0.5
const PERFECT_BLOCK_PUSHBACK_MUL := 0.5
const PERFECT_BLOCK_METER := 5

# ── Parry ──
const PARRY_ACTIVE := 5
const PARRY_RECOVERY := 18
const PARRY_FREEZE := 8
const PARRY_METER := 10

# ── Throws ──
const THROW_RANGE := 40.0
const THROW_STARTUP := 5
const THROW_ACTIVE := 3
const THROW_RECOVERY := 25
const THROW_TECH_WINDOW := 7

# ── Stun ──
const STUN_RECOVERY_RATE := 60.0
const STUN_RECOVERY_PAUSE := 120
const STUN_DIZZY_DURATION := 180
const STUN_MASH_REDUCTION := 5

# ── Meter ──
const METER_MAX := 300
const METER_PER_BAR := 100
const METER_EX_COST := 100
const METER_SUPER_1_COST := 100
const METER_SUPER_2_COST := 200
const METER_SUPER_3_COST := 300

# ── Damage Scaling ──
const SCALING := [1.0, 0.9, 0.8, 0.7, 0.6]
const SCALING_FLOOR := 0.6
const SCALING_SUPER_MUL := 0.8

# ── Juggle ──
const JUGGLE_MAX := 8

# ── Movement ──
const PREJUMP_FRAMES := 4
const DASH_STARTUP := 3
const DASH_ACTIVE := 14
const DASH_RECOVERY := 6
const BACKDASH_STARTUP := 3
const BACKDASH_ACTIVE := 18
const BACKDASH_RECOVERY := 8
const BACKDASH_INVULN := 8
const DOUBLE_JUMP_STARTUP := 3
const AIR_DASH_STARTUP := 5
const AIR_DASH_ACTIVE := 12
const AIR_DASH_LAND_RECOVERY := 8
const CROUCH_ENTER := 2
const CROUCH_EXIT := 2

# ── Wakeup ──
const WAKEUP_INVULN := 3

# ── Corner ──
const CORNER_PUSHBACK_MUL := 0.5

# ── Collision Layers ──
const LAYER_PUSHBOX := 1
const LAYER_HURTBOX := 2
const LAYER_HITBOX := 3
const LAYER_PROJECTILE := 4

enum Facing { LEFT = -1, RIGHT = 1 }
enum Stance { STAND, CROUCH, AIR }
enum State {
	IDLE, WALK, CROUCH, PREJUMP, JUMP, DASH, BACKDASH,
	BLOCK_STAND, BLOCK_CROUCH, BLOCK_AIR,
	PARRY, PARRY_RECOV,
	ATTACK_STARTUP, ATTACK_ACTIVE, ATTACK_RECOVERY,
	HITSTUN, BLOCKSTUN, KNOCKDOWN, GETUP,
	THROW, THROW_TECH, THROWN,
	DIZZY, GUARD_CRUSH, KO, VICTORY
}
