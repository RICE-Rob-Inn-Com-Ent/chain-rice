package physics
// TODO:
// [ ] PxCreatePhysics; rigid bodies; RICE_PHYSICS_TIMESTEP; GPU RICE_PHYSICS_GPU — https://nvidia-omniverse.github.io/PhysX/physx/5.4.1/_api_build/structPxPhysics.html
//

import "core:c"

when ODIN_OS == .Linux {
	foreign import libphysx {
		"lib/libPhysX.so",
	}
	foreign import libphysx_cooking {
		"lib/libPhysXCooking.so",
	}
} else when ODIN_OS == .Darwin {
	foreign import libphysx {
		"lib/libPhysX.dylib",
	}
	foreign import libphysx_cooking {
		"lib/libPhysXCooking.dylib",
	}
} else when ODIN_OS == .Windows {
	foreign import libphysx {
		"lib/PhysX_64.lib",
	}
	foreign import libphysx_cooking {
		"lib/PhysXCooking_64.lib",
	}
}

PxFoundation :: distinct rawptr
PxPhysics :: distinct rawptr
PxScene :: distinct rawptr
PxSceneDesc :: distinct rawptr
PxRigidActor :: distinct rawptr
PxRigidBody :: distinct rawptr
PxRigidDynamic :: distinct rawptr
PxRigidStatic :: distinct rawptr
PxShape :: distinct rawptr
PxMaterial :: distinct rawptr
PxGeometry :: distinct rawptr
PxBoxGeometry :: distinct rawptr
PxSphereGeometry :: distinct rawptr
PxCapsuleGeometry :: distinct rawptr
PxPlaneGeometry :: distinct rawptr
PxConvexMeshGeometry :: distinct rawptr
PxTriangleMeshGeometry :: distinct rawptr

PxVec3 :: struct {
	x: f32,
	y: f32,
	z: f32,
}
PxVec4 :: struct {
	x: f32,
	y: f32,
	z: f32,
	w: f32,
}
PxQuat :: struct {
	x: f32,
	y: f32,
	z: f32,
	w: f32,
}
PxTransform :: struct {
	p: PxVec3,
	q: PxQuat,
}
PxBounds3 :: struct {
	min: PxVec3,
	max: PxVec3,
}

PxForceMode :: enum c.int {
	FORCE = 0,
	IMPULSE = 1,
	VELOCITY_CHANGE = 2,
	ACCELERATION = 3,
}

PxActorFlag :: enum c.int {
	VISUALIZATION = 0,
	DISABLE_GRAVITY = 1,
	SEND_SLEEP_NOTIFIES = 2,
}

PxRigidBodyFlag :: enum c.int {
	KINEMATIC = 0,
	USE_KINEMATIC_TARGET_FOR_SCENE_QUERIES = 1,
	ENABLE_CCD = 2,
}

PxShapeFlag :: enum c.int {
	SIMULATION_SHAPE = 0,
	SCENE_QUERY_SHAPE = 1,
	TRIGGER_SHAPE = 2,
}

foreign libphysx {
	PxCreateFoundation :: proc(version: u32, allocator: rawptr, errorCallback: rawptr) -> PxFoundation ---
	PxCreatePhysics :: proc(version: u32, foundation: PxFoundation, tolerances: rawptr, track_allocations: bool, profiling: rawptr) -> PxPhysics ---
	PxCreateCooking :: proc(version: u32, foundation: PxFoundation, params: rawptr) -> rawptr ---

	PxCreateScene :: proc(physics: PxPhysics, desc: PxSceneDesc) -> PxScene ---
	PxPhysics_release :: proc(physics: PxPhysics) ---

	PxScene_simulate :: proc(scene: PxScene, elapsedTime: f32, completionTask: rawptr, scratchMem: rawptr, scratchMemSize: u32, controlSimulation: bool) ---
	PxScene_fetchResults :: proc(scene: PxScene, block: bool) -> bool ---
	PxScene_release :: proc(scene: PxScene) ---

	PxScene_addActor :: proc(scene: PxScene, actor: PxRigidActor, bvh: rawptr) ---
	PxScene_removeActor :: proc(scene: PxScene, actor: PxRigidActor, wakeOnLostTouch: bool) ---

	PxScene_setGravity :: proc(scene: PxScene, gravity: PxVec3) ---
	PxScene_getGravity :: proc(scene: PxScene) -> PxVec3 ---

	PxScene_raycast :: proc(scene: PxScene, origin: PxVec3, unitDir: PxVec3, maxDistance: f32, hitCall: rawptr, filter: rawptr, cache: rawptr) -> bool ---
	PxScene_sweep :: proc(scene: PxScene, geometry: rawptr, pose: PxTransform, motion: PxVec3, maxDistance: f32, hitCall: rawptr, filter: rawptr, cache: rawptr) -> bool ---
	PxScene_overlap :: proc(scene: PxScene, geometry: rawptr, pose: PxTransform, hitCall: rawptr, filter: rawptr) -> bool ---

	PxPhysics_createRigidDynamic :: proc(physics: PxPhysics, transform: PxTransform) -> PxRigidDynamic ---
	PxPhysics_createRigidStatic :: proc(physics: PxPhysics, transform: PxTransform) -> PxRigidStatic ---
	PxPhysics_createMaterial :: proc(physics: PxPhysics, staticFriction: f32, dynamicFriction: f32, restitution: f32) -> PxMaterial ---
	PxPhysics_createShape :: proc(physics: PxPhysics, geometry: rawptr, material: PxMaterial, isExclusive: bool, shapeFlags: u8) -> PxShape ---

	PxRigidActor_attachShape :: proc(actor: PxRigidActor, shape: PxShape) ---
	PxRigidActor_detachShape :: proc(actor: PxRigidActor, shape: PxShape, wakeOnLostTouch: bool) ---

	PxRigidActor_setGlobalPose :: proc(actor: PxRigidActor, pose: PxTransform, autowake: bool) ---
	PxRigidActor_getGlobalPose :: proc(actor: PxRigidActor) -> PxTransform ---

	PxRigidBody_setLinearVelocity :: proc(body: PxRigidBody, vel: PxVec3, autowake: bool) ---
	PxRigidBody_getLinearVelocity :: proc(body: PxRigidBody) -> PxVec3 ---
	PxRigidBody_setAngularVelocity :: proc(body: PxRigidBody, vel: PxVec3, autowake: bool) ---
	PxRigidBody_getAngularVelocity :: proc(body: PxRigidBody) -> PxVec3 ---

	PxRigidBody_addForce :: proc(body: PxRigidBody, force: PxVec3, mode: PxForceMode, autowake: bool) ---
	PxRigidBody_addTorque :: proc(body: PxRigidBody, torque: PxVec3, mode: PxForceMode, autowake: bool) ---

	PxRigidBody_setMass :: proc(body: PxRigidBody, mass: f32) ---
	PxRigidBody_setMassSpaceInertiaTensor :: proc(body: PxRigidBody, m: PxVec3) ---

	PxRigidDynamic_setKinematicTarget :: proc(body: PxRigidDynamic, target: PxTransform) ---
	PxRigidDynamic_setSleepThreshold :: proc(body: PxRigidDynamic, threshold: f32) ---

	PxShape_setGeometry :: proc(shape: PxShape, geometry: rawptr) ---
	PxShape_getGeometry :: proc(shape: PxShape, geometry: rawptr) ---

	PxShape_setLocalPose :: proc(shape: PxShape, pose: PxTransform) ---
	PxShape_getLocalPose :: proc(shape: PxShape) -> PxTransform ---

	PxMaterial_setStaticFriction :: proc(material: PxMaterial, coef: f32) ---
	PxMaterial_setDynamicFriction :: proc(material: PxMaterial, coef: f32) ---
	PxMaterial_setRestitution :: proc(material: PxMaterial, rest: f32) ---
}

foreign libphysx_cooking {}
