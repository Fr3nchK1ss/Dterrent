/**
	Defines a Camera Node which can be included in a Scene

	Authors: Poggel / Fr3nchK1ss
	Copyright: Contact Fr3nchK1ss

 */

module dterrent.scene.cameranode;
import dterrent.system.logger;

import dterrent.scene.scene;
import dterrent.scene.node;
import dterrent.core.color;
import dterrent.core.math;
import std.math; // PI
import gl3n.frustum;
import gl3n.aabb;

/+
import yage.scene.light;
import yage.scene.visible;
import yage.resource.graphics.all;
import yage.system.graphics.probe;
import yage.scene.sound;
import yage.resource.sound;
+/


/**
 * Without any rotation, the Camera looks in the direction of the -z axis.
 * TODO: More documentation. */
class CameraNode : Node
{
	// TODO: Replace with projection matrix:
	float near = 1;			/// The camera's near plane.  Nothing closer than this will be rendered.  The default is 1.
	float far = 100_000;		/// The camera's far plane.  Nothing further away than this will be rendered.  The default is 100,000.
	float fov = 45;			/// The field of view of the camera, in degrees.  The default is 45.
	float threshhold = 1;	/// Nodes must be at least this diameter in pixels or they won't be rendered.
	float aspectRatio = 1.25;  /// The aspect ratio of the camera.  This is normally set automatically in Render.scene() based on the size of the Render Target.

	bool createRenderCommands = true; /// Create render and sound commands when update() is called on this Camera's scene.
	bool createSoundCommands = true; /// ditto

	package ulong currentYres; // Used internally for determining visibility

	//protected Plane[6] frustum;
	Frustum frustum;
	protected vec3 frustumSphereCenter;
	protected float frustumSphereRadiusSquared;

	struct TripleBuffer(T)
	{	T[3] lists;
		Object mutex;
		int read=1;
		int write=0;

		// Get a buffer for reading that is guaranteed to not currently being written.
		T getNextRead()
		{	synchronized (mutex)
			{	const int next = 3-(read+write);
				if (lists[next].timestamp > lists[read].timestamp)
					read = next; // advance the read list only if what's available is newer.
				assert(read < 3);
				assert(read != write);

				return lists[read];
			}
		}

		// Get the next write buffer that is guaranteed to not currently being read
		private T* getNextWrite()
		{	synchronized (mutex)
			{	write = 3 - (read+write);
				assert(read < 3);
				assert(read != write);
				return &lists[write];
			}
		}
	}
/+
	TripleBuffer!(SoundList) soundLists;
	TripleBuffer!(RenderList) renderLists;

	/**
	 * Get a render list for the scene and each of the skyboxes this camera sees. */
	RenderList getRenderList()
	{	return renderLists.getNextRead();
	}

	/**
	 * List of SoundCommands that this camera can hear, in order from loudest to most quiet. */
	SoundList getSoundList()
	{	return soundLists.getNextRead();
	}

	package void updateSoundCommands()
	{
		SoundList* list = soundLists.getNextWrite();
		list.commands.reserveAndClear(); // reset content

		vec3 wp = getWorldPosition();
		scope allSounds = scene.getAllSounds();
		int i;
		foreach (soundNode; allSounds) // Make a deep copy of the scene's sounds
		{
			if (!soundNode.paused() && soundNode.getSound())
			{	//Log.write(2);
				SoundCommand command;
				command.intensity = soundNode.getVolumeAtPosition(wp);
				if (command.intensity > 0.002) // A very quiet sound, arbitrary number
				{
					command.sound = soundNode.getSound();
					command.worldPosition = soundNode.getWorldPosition();
					command.worldVelocity = soundNode.getWorldVelocity();
					command.pitch = soundNode.pitch;
					command.volume = soundNode.volume;
					command.radius = soundNode.radius;
					command.looping = soundNode.looping;
					command.position = soundNode.tell();
					command.soundNode = soundNode;
					command.reseek = soundNode.reseek;
					soundNode.reseek = false; // the value has been consumed
					addSorted!(SoundCommand, float)(list.commands, command, false, (SoundCommand s) { return s.intensity; }); // fails!!!
				}
			}
			i++;
		}
		list.timestamp = Clock.now().ticks(); // 100-nanosecond precision
		list.cameraPosition = getWorldPosition();
		list.cameraRotation = getWorldRotation();
		list.cameraVelocity = getWorldVelocity();
	}

	static RenderList* currentRenderList;

	void resetRenderCommands()
	{
		currentYres = Window.getInstance().getHeight(); // TODO Break dependance on Window.

		auto list = currentRenderList = renderLists.getNextWrite();
		list.cameraInverse = getWorldTransform().inverse(); // must occur before the loop below
		list.timestamp = Clock.now().ticks(); // 100-nanosecond precision
		list.commands.reserveAndClear(); // reset content
		list.scene = scene;

		scope allLights = scene.getAllLights();
		list.lights.length = allLights.length;
		int j;
		foreach (ref light; allLights) // Make a deep copy of the scene's lights
		{	list.lights.data[j] = light.clone(false, list.lights.data[j]); // to prevent locking when the render thread uses them.
			list.lights.data[j].setPosition(light.getWorldPosition());
			list.lights.data[j].cameraSpacePosition = light.getWorldPosition().transform(list.cameraInverse);
			if (light.type == LightNode.Type.SPOT)
				list.lights.data[j].setRotation(light.getWorldRotation());
			list.lights.data[j].transform.worldPosition = list.lights.data[j].transform.position;
			list.lights.data[j].transform.worldDirty = false; // hack to prevent it from being recalculated.
			j++;
		}
	}
+/
	/**
	 * Construct */
	this()
	{	this(null);
	}
	this(Node parent)
	{	super(parent);
		//renderLists.mutex = new Object();
		//soundLists.mutex = new Object();
		if (parent)
		{
			parent.addChild(this);
		}
	}

	///
	Frustum getFrustum()
	{
		return frustum;
	}

/+
	TODO: re-implement if necessary. Add frustum intersect in gl3n
	bool isVisible(vec3 point, float radius)
	{
		// See if it's inside the frustum
		float nr = -radius;
		foreach ( f; retro ( frustum) )
			if (f.x*point.x +f.y*point.y + f.z*point.z + f.d < nr) // plane distance-to-point function, expanded in-line.
				return false;

		// See if it's large enough to be drawn
		float distance2 = (getWorldPosition() - point).length2();
		return distance2*threshhold*threshhold < radius*radius*currentYres*currentYres;
	}
+/

	/**
	 * Will the Axis-aligned bounding box be in the field of view of the camera?
	 *
	 * Trivial using gl3n. Keeping int as return value for compatibility.
	   Returns:
			- 0 if outside
			- 1 if totally inside
			- 2 if partially inside
	 */ 
	int isCulled(vec3 minPoint, vec3 maxPoint)
	{
		return frustum.intersects(AABB(minPoint, maxPoint));
	}

	/*
	 * Update the scene's list of cameras.
	 * This should be protected, but making it anything but public causes it not to be called.
	 * Most likely a D bug? */
	override public void ancestorChange(Node old_ancestor)
	{	super.ancestorChange(old_ancestor); // must be called first so scene is set.

		Scene old_scene = old_ancestor ? old_ancestor.getScene() : null;
		if (scene !is old_scene)
		{	if (old_scene)
				old_scene.removeCamera(this);
			if (scene) // if scene changed.
				scene.addCamera(this);
		}
	}
/+
	/*
	 * Update the frustums when the camera moves.

	 TODO: step by step update of this func
	 */
	override protected void calcWorld()
	{
		super.calcWorld();

		// Create the clipping matrix from the modelview and projection matrices
		Matrix projection = Matrix.createProjection(fov*3.1415927/180f, aspectRatio, near, far);
		//Log.write("camera ", worldRotation);
		Matrix model = Matrix.compose(transform.worldPosition, transform.worldRotation, transform.worldScale).inverse();
		(model*projection).getFrustum(frustum);

		/*
		// TODO: Use frustum optimizations from: http://www.flipcode.com/archives/Frustum_Culling.shtml

		// calculate the radius of the frustum sphere
		float fViewLen = far - near;

		// use some trig to find the height of the frustum at the far plane
		float fHeight = fViewLen * tan(fov*3.1415927/180 * 0.5f);

		// with an aspect ratio of 1, the width will be the same
		float fWidth = fHeight;

		// halfway point between near/far planes starting at the origin and extending along the z axis
		vec3 P = vec3(0.0f, 0.0f, near + fViewLen * 0.5f);

		// the calculate far corner of the frustum
		vec3 Q = vec3(fWidth, fHeight, fViewLen);

		// the vector between P and Q
		vec3 vDiff = P - Q;

		// the radius becomes the length of this vector
		frustumSphereRadiusSquared = vDiff.length() * .5;
		frustumSphereRadiusSquared *= frustumSphereRadiusSquared;

		// get the look vector of the camera from the view matrix
		vec3 vLookVector = vec3(0, 0, -1);

		auto worldTransform = Matrix.compose(worldPosition, worldRotation, worldScale);
		vLookVector = vLookVector.rotate(worldTransform);

		//m_mxView.LookVector(&vLookVector);

		// calculate the center of the sphere
		frustumSphereCenter = worldPosition + (vLookVector * (fViewLen * 0.5f) + near);
		//Log.write(frustumSphereCenter, frustumSphereRadiusSquared);
		*/
	}
+/
}
